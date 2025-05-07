//
//  AuthViewModel.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import Appwrite
import Foundation
import JSONCodable
import SwiftUI
import UIKit

@MainActor
class AuthViewModel: ObservableObject {
    // MARK: — Appwrite clients
    private let client: Client
    private let account: Account
    private let databases: Databases

    // MARK: — Configuration keys
    private let endpoint: String = AppwriteConfig.endpoint
    private let projectId: String = AppwriteConfig.projectId
    private let databaseId: String = AppwriteConfig.databaseId
    private let usersCollectionId: String = AppwriteConfig.usersCollectionId

    // MARK: — Published state
    @Published var authState: AuthState = .unauthenticated
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var successMessage: String?
    @Published var registrationEmail: String?

    @Published var mfaChallenge: MfaChallenge?
    @Published var showMfaSheet: Bool = false

    @Published var isMfaSetupRequired: Bool = false
    @Published var mfaSetupData: MfaSetupData?

    @Published var showEmailVerificationSheet: Bool = false
    @Published var showOtpSheet: Bool = false
    @Published var registrationInProgress: Bool = false

    @Published var verificationCode: String = ""

    private var otpUserId: String?
    private let mfaCompletionService = "mfa-completion"

    // Computed helper
    var isAuthenticating: Bool {
        if case .authenticating = authState { return true }
        return false
    }

    // MARK: — Init
    init() {
        client = Client()
            .setEndpoint(endpoint)
            .setProject(projectId)
            .setSelfSigned(true)
        account = Account(client)
        databases = Databases(client)

        Task { await checkCurrentSession() }
    }

    // MARK: — Check existing session on launch
    func checkCurrentSession() async {
        isLoading = true
        error = nil

        do {
            let session = try await account.getSession(sessionId: "current")
            let userData = try await account.get()
            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id
            )

            guard let user = parseUserFromDocument(userDoc) else {
                throw NSError(domain: "Auth", code: 0,
                              userInfo: [NSLocalizedDescriptionKey: "Failed to parse user"])
            }

            let hasMfa = userDoc.data["mfa_enabled"]?.value as? Bool ?? false
            if hasMfa && !isMfaCompleted(for: session.id, userId: userData.id) {
                let challenge = try await account.createMfaChallenge(factor: .totp)
                mfaChallenge = MfaChallenge(
                    id: challenge.id,
                    userId: userData.id,
                    createdAt: Date(),
                    expiresAt: Date().addingTimeInterval(300)
                )
                authState    = .mfaRequired(mfaChallenge!)
                showMfaSheet = true
            } else {
                currentUser = user
                authState   = .authenticated(user)
            }
        } catch {
            authState   = .unauthenticated
            currentUser = nil
        }

        isLoading = false
    }

    // MARK: — Registration flow
    func registerUser(fullName: String, email: String, password: String) async {
        authState = .authenticating
        isLoading = true
        error     = nil

        do {
            let result = try await account.create(
                userId: ID.unique(),
                email: email,
                password: password,
                name: fullName
            )
            let userId = result.id

            // Create Firestore mirror
            try await databases.createDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userId,
                data: [
                    "user_id":     userId,
                    "full_name":   fullName,
                    "email":       email,
                    "role":        UserRole.member.rawValue,
                    "is_verified": false,
                    "mfa_enabled": false,
                    "created_at":  Date().ISO8601Format()
                ]
            )
            await mirrorRegisterUser(userId: userId, fullName: fullName, email: email)

            // Send email OTP
            let token = try await account.createEmailToken(
                userId: userId,
                email: email,
                phrase: false
            )
            otpUserId             = token.userId
            showOtpSheet          = true
            registrationInProgress = true
        } catch let appErr as AppwriteError {
            handleAppwriteError(appErr)
        } catch let swiftError {
            self.error = "Registration error: \(swiftError.localizedDescription)"
            self.authState = .error(self.error!)
        }

        isLoading = false
    }

    // MARK: — Email OTP
    func verifyOtpAndCompleteRegistration(code: String) async {
        guard let userId = otpUserId else {
            self.error = "OTP flow not initiated"
            return
        }
        isLoading = true
        error     = nil

        do {
            _ = try await account.createSession(userId: userId, secret: code)
            try await databases.updateDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userId,
                data: ["is_verified": true]
            )
            await mirrorOtpVerification(userId: userId)

            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userId
            )
            if let user = parseUserFromDocument(userDoc) {
                currentUser = user
                authState   = .authenticated(user)
            }
        } catch let appErr as AppwriteError {
            handleAppwriteError(appErr)
        } catch let swiftError {
            self.error = "OTP verification failed: \(swiftError.localizedDescription)"
            self.authState = .error(self.error!)
        }

        showOtpSheet = false
        otpUserId    = nil
        isLoading    = false
    }

    // MARK: — Login flow
    func loginUser(email: String, password: String) async {
        authState = .authenticating
        isLoading = true
        error     = nil

        do {
            try? await account.deleteSession(sessionId: "current")
            _ = try await account.createEmailPasswordSession(
                email: email,
                password: password
            )

            let userData = try await account.get()
            let userDoc  = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id
            )
            let hasMfa = userDoc.data["mfa_enabled"]?.value as? Bool ?? false

            if hasMfa {
                let challenge = try await account.createMfaChallenge(factor: .totp)
                mfaChallenge = MfaChallenge(
                    id: challenge.id,
                    userId: userData.id,
                    createdAt: Date(),
                    expiresAt: Date().addingTimeInterval(300)
                )
                authState    = .mfaRequired(mfaChallenge!)
                showMfaSheet = true
            } else {
                await setupMfaForUser(userId: userData.id)
            }
        } catch let appErr as AppwriteError {
            handleAppwriteError(appErr)
        } catch let swiftError {
            self.error = "Login error: \(swiftError.localizedDescription)"
            self.authState = .error(self.error!)
        }

        isLoading = false
    }

    // MARK: — MFA Setup & Verification
    func setupMfaForUser(userId: String) async {
        do {
            let resp = try await account.createMfaAuthenticator(type: .totp)
            mfaSetupData = MfaSetupData(
                userId: userId,
                secret: resp.secret,
                uri: resp.uri,
                qrCode: generateQRCode(from: resp.uri)
            )
            isMfaSetupRequired = true
            showMfaSheet = true
        } catch let swiftError {
            self.error = "MFA setup failed: \(swiftError.localizedDescription)"
        }
    }

    func completeMfaSetup(code: String) async {
        guard let setup = mfaSetupData else {
            self.error = "No MFA setup data"
            return
        }
        isLoading = true
        error     = nil

        do {
            _ = try await account.updateMfaAuthenticator(type: .totp, otp: code)
            let u = try await account.get()
            try await databases.updateDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: u.id,
                data: ["mfa_enabled": true]
            )
            await mirrorMfaSetupCompletion(userId: u.id)

            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: u.id
            )
            if let user = parseUserFromDocument(userDoc) {
                currentUser = user
                authState   = .authenticated(user)
            }

            isMfaSetupRequired = false
            showMfaSheet       = false
            successMessage     = "Two-factor enabled!"
        } catch let appErr as AppwriteError {
            handleAppwriteError(appErr)
        } catch let swiftError {
            self.error = "MFA completion failed: \(swiftError.localizedDescription)"
            self.authState = .error(self.error!)
        }

        isLoading = false
    }

    func verifyMfa(code: String) async {
        guard let challenge = mfaChallenge else {
            self.error = "No MFA challenge found"
            return
        }
        isLoading = true
        error     = nil

        do {
            _ = try await account.updateMfaChallenge(
                challengeId: challenge.id,
                otp: code
            )
            let u     = try await account.get()
            let sess  = try await account.getSession(sessionId: "current")
            let doc   = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: u.id
            )
            markMfaCompleted(for: sess.id, userId: u.id)
            if let user = parseUserFromDocument(doc) {
                currentUser = user
                authState   = .authenticated(user)
            }
        } catch let appErr as AppwriteError {
            handleAppwriteError(appErr)
        } catch let swiftError {
            self.error = "MFA verification failed: \(swiftError.localizedDescription)"
            self.authState = .error(self.error!)
        }

        showMfaSheet = false
        isLoading    = false
    }

    // MARK: — Resend Email OTP
    func verifyEmail() async {
        guard let userId = otpUserId,
              let email = registrationEmail else {
            self.error = "Cannot send OTP – missing info"
            return
        }
        isLoading = true
        defer { isLoading = false }

        do {
            _ = try await account.createEmailToken(
                userId: userId,
                email: email,
                phrase: false
            )
            successMessage = "OTP sent to your email."
        } catch let appErr as AppwriteError {
            handleAppwriteError(appErr)
        } catch let swiftError {
            self.error = "Send OTP failed: \(swiftError.localizedDescription)"
        }
    }

    // MARK: — Complete Registration
    func completeRegistration() async {
        showOtpSheet            = false
        showEmailVerificationSheet = false
        if let uid = currentUser?.id {
            await setupMfaForUser(userId: uid)
        }
    }

    // MARK: — Check Verification Status
    func checkEmailVerificationStatus() async {
        guard let uid = currentUser?.id else { return }
        do {
            let u = try await account.get()
            if u.emailVerification {
                successMessage = "Email verified!"
            }
        } catch {
            print("Verification status check failed: \(error)")
        }
    }

    // MARK: — Logout
    func logout() async {
        isLoading = true
        defer { isLoading = false }

        do {
            if let uid = currentUser?.id {
                KeychainHelper.standard.delete(
                    service: mfaCompletionService,
                    account: uid
                )
            }
            try await account.deleteSession(sessionId: "current")
            currentUser  = nil
            authState    = .unauthenticated
            mfaChallenge = nil
        } catch let swiftError {
            self.error = "Logout failed: \(swiftError.localizedDescription)"
        }
    }

    // MARK: — Private Helpers

    private func markMfaCompleted(for sessionId: String, userId: String) {
        KeychainHelper.standard.save(
            sessionId,
            service: mfaCompletionService,
            account: userId
        )
    }

    private func isMfaCompleted(for sessionId: String, userId: String) -> Bool {
        guard let stored = KeychainHelper.standard.read(
            service: mfaCompletionService,
            account: userId
        ) else { return false }
        return stored == sessionId
    }

    private func parseUserFromAppwrite(
        _ appwriteUser: AppwriteModels.User<[String: AnyCodable]>
    ) -> User? {
        let createdAt: Date
        if let dbl = Double(appwriteUser.createdAt) {
            createdAt = Date(timeIntervalSince1970: dbl/1000)
        } else {
            createdAt = Date()
        }
        return User(
            id: appwriteUser.id,
            fullName: appwriteUser.name,
            email: appwriteUser.email,
            profileImageUrl: nil,
            role: .member,
            isVerified: appwriteUser.emailVerification,
            mfaEnabled: false,
            preferences: nil,
            createdAt: createdAt
        )
    }

    private func parseUserFromDocument(
        _ doc: AppwriteModels.Document<[String: AnyCodable]>
    ) -> User? {
        guard
            let fn   = doc.data["full_name"]?.value as? String,
            let em   = doc.data["email"]?.value as? String,
            let role = (doc.data["role"]?.value as? String).flatMap(UserRole.init),
            let createdStr = doc.data["created_at"]?.value as? String
        else {
            return nil
        }

        let isVerified = doc.data["is_verified"]?.value as? Bool ?? false
        let mfaEnabled = doc.data["mfa_enabled"]?.value as? Bool ?? false
        let profURL    = doc.data["profile_image_url"]?.value as? String
        let prefs      = doc.data["preferences"]?.value as? [String:String]

        let date = ISO8601DateFormatter().date(from: createdStr) ?? Date()

        return User(
            id: doc.id,
            fullName: fn,
            email: em,
            profileImageUrl: profURL,
            role: role,
            isVerified: isVerified,
            mfaEnabled: mfaEnabled,
            preferences: prefs,
            createdAt: date
        )
    }

    private func handleAppwriteError(_ err: AppwriteError) {
        switch err.code {
        case 401: error = "Invalid credentials"
        case 404: error = "User not found"
        case 409: error = "Email already registered"
        default: error = "Error \(err.code): \(err.message)"
        }
        authState = .error(error!)
    }

    private func generateQRCode(from string: String) -> UIImage {
        let data   = Data(string.utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")
        let img    = filter.outputImage!
            .transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let cg     = CIContext().createCGImage(img, from: img.extent)!
        return UIImage(cgImage: cg)
    }
}

