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

class AuthViewModel: ObservableObject {

    private let client: Client
    private let account: Account
    private let databases: Databases

    @Published var authState: AuthState = .unauthenticated
    @Published var currentUser: User?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var mfaChallenge: MfaChallenge?

    @Published var isMfaSetupRequired: Bool = false
    @Published var mfaSetupData: MfaSetupData? = nil
    @Published var showMfaSheet: Bool = false
    @Published var successMessage: String?
    @Published var showEmailVerificationSheet: Bool = false
    @Published var registrationInProgress: Bool = false
    @Published var verificationCode: String = ""

    // New OTP state
    @Published var otpUserId: String?
    @Published var showOtpSheet: Bool = false
    @Published var otpCode: String = ""
    @Published var registrationPassword: String = ""
    @Published var registrationEmail: String?  // ← store for resends

    private let endpoint: String
    private let projectId: String
    private let databaseId: String
    private let usersCollectionId: String

    init() {

        self.endpoint = AppwriteConfig.endpoint
        self.projectId = AppwriteConfig.projectId
        self.databaseId = AppwriteConfig.databaseId
        self.usersCollectionId = AppwriteConfig.usersCollectionId

        self.client = Client()
            .setEndpoint(endpoint)
            .setProject(projectId)
            .setSelfSigned(true)

        self.account = Account(client)
        self.databases = Databases(client)

        Task {
            await checkCurrentSession()
        }
    }

    @MainActor
    func checkCurrentSession() async {
        do {
            print("Checking for existing session...")
            _ = try await account.getSession(sessionId: "current")
            print("Session found, fetching user data...")

            let userData = try await account.get()
            print("Basic user data fetched: ID = \(userData.id)")

            print("Fetching complete user document...")
            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id
            )
            print("User document fetched successfully")

            if let user = parseUserFromDocument(userDoc) {
                print("User document parsed: \(user.fullName)")
                currentUser = user
                authState = .authenticated(user)
                print("Auth state set to authenticated from existing session")
            } else {
                print("Failed to parse user document")
                authState = .unauthenticated
            }
        } catch {
            print("No valid session found: \(error.localizedDescription)")
            authState = .unauthenticated
            currentUser = nil
        }
    }

    @MainActor
    func registerUser(fullName: String, email: String, password: String) async {
        print("Starting registration for \(email)")
        authState = .authenticating
        isLoading = true
        error = nil
        registrationInProgress = true

        // Keep password to login after OTP verify
        registrationPassword = password
        // Remember email for resend flow
        registrationEmail = email

        do {
            let result = try await account.create(
                userId: ID.unique(),
                email: email,
                password: password,
                name: fullName
            )

            let userId = result.id

            try await databases.createDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userId,
                data: [
                    "user_id": userId,
                    "full_name": fullName,
                    "email": email,
                    "role": UserRole.member.rawValue,
                    "is_verified": false,
                    "mfa_enabled": false,
                    "created_at": Date().ISO8601Format(),
                ]
            )

            // 2) Send OTP to email
            let token = try await account.createEmailToken(
                userId: userId,
                email: email,
                phrase: false
            )  // Sends 6-digit code

            // Keep for verification step
            otpUserId = token.userId
            showOtpSheet = true

        } catch let appwriteError as AppwriteError {
            print(
                "Appwrite error during registration: \(appwriteError.message) (code: \(appwriteError.code))"
            )
            handleAppwriteError(appwriteError)
            registrationInProgress = false
        } catch {
            print("Unexpected error during registration: \(error.localizedDescription)")
            self.error = "An unexpected error occurred: \(error.localizedDescription)"
            authState = .error(error.localizedDescription)
            registrationInProgress = false
        }

        isLoading = false
    }

    @MainActor
    func completeRegistration() async {
        showEmailVerificationSheet = false

        if let userId = currentUser?.id {
            await setupMfaForUser(userId: userId)
        }
    }

    @MainActor
    func loginUser(email: String, password: String) async {
        authState = .authenticating
        isLoading = true
        error = nil

        print("Login attempt for: \(email)")

        do {
            // Clear any existing session first
            try? await account.deleteSession(sessionId: "current")

            print("Creating email session...")
            let session = try await account.createEmailPasswordSession(
                email: email,
                password: password
            )
            print("Session created successfully")

            let userData = try await account.get()
            print("User data fetched: ID = \(userData.id)")

            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id
            )

            let mfaEnabled = userDoc.data["mfa_enabled"]?.value as? Bool ?? false

            if mfaEnabled {
                print("User has MFA enabled, creating challenge")
                do {
                    let challenge = try await account.createMfaChallenge(
                        factor: .totp
                    )
                    mfaChallenge = MfaChallenge(
                        id: challenge.id,
                        userId: userData.id,
                        createdAt: Date(),
                        expiresAt: Date().addingTimeInterval(300)
                    )
                    showMfaSheet = true
                    authState = .mfaRequired(mfaChallenge!)
                } catch {
                    print("Failed to create MFA challenge: \(error)")
                    self.error = "Failed to create MFA challenge: \(error.localizedDescription)"
                    authState = .error(self.error ?? "Unknown error")
                }
            } else {

                print("User doesn't have MFA enabled, initiating setup")
                await setupMfaForUser(userId: userData.id)
            }
        } catch let appwriteError as AppwriteError {
            print(
                "Appwrite error during login: \(appwriteError.message) (code: \(appwriteError.code))"
            )
            handleAppwriteError(appwriteError)
        } catch {
            print("Unexpected error during login: \(error.localizedDescription)")
            self.error = "An unexpected error occurred: \(error.localizedDescription)"
            authState = .error(error.localizedDescription)
        }

        isLoading = false
    }

    @MainActor
    func setupMfaForUser(userId: String) async {
        do {
            let response = try await account.createMfaAuthenticator(
                type: .totp
            )

            let qrCodeImage = generateQRCode(from: response.uri)

            mfaSetupData = MfaSetupData(
                userId: userId,
                secret: response.secret,
                uri: response.uri,
                qrCode: qrCodeImage
            )

            isMfaSetupRequired = true
            showMfaSheet = true
        } catch {
            print("Failed to set up MFA: \(error)")
            self.error = "Failed to set up MFA: \(error.localizedDescription)"
        }
    }

    @MainActor
    func completeMfaSetup(code: String) async {
        guard let setupData = mfaSetupData else {
            self.error = "No MFA setup data found"
            return
        }

        isLoading = true

        do {
            _ = try await account.updateMfaAuthenticator(
                type: .totp,
                otp: code
            )

            let userData = try await account.get()
            try await databases.updateDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id,
                data: [
                    "mfa_enabled": true
                ]
            )

            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id
            )

            if let user = parseUserFromDocument(userDoc) {
                currentUser = user
                authState = .authenticated(user)
                isMfaSetupRequired = false
                mfaSetupData = nil
                showMfaSheet = false

                // Add success message
                successMessage = "Account setup complete with two-factor authentication!"
            }
        } catch let appwriteError as AppwriteError {
            handleAppwriteError(appwriteError)
        } catch {
            self.error = "Failed to complete MFA setup: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func verifyMfa(code: String) async {
        guard let challenge = mfaChallenge else {
            self.error = "No MFA challenge found"
            return
        }

        isLoading = true

        do {
            let result = try await account.updateMfaChallenge(
                challengeId: challenge.id,
                otp: code
            )

            let userData = try await account.get()

            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id
            )

            if let user = parseUserFromDocument(userDoc) {
                currentUser = user
                authState = .authenticated(user)
                mfaChallenge = nil
                showMfaSheet = false
            }
        } catch let appwriteError as AppwriteError {
            handleAppwriteError(appwriteError)
        } catch {
            self.error = "An unexpected error occurred: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func verifyEmail() async {
        isLoading = true
        error = nil
        successMessage = nil

        do {
            guard let userId = otpUserId,
                let email = registrationEmail
            else {
                throw NSError(
                    domain: "LMS", code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "User not found"])
            }

            // Resend OTP to the same userId/email pair
            let token = try await account.createEmailToken(
                userId: userId,
                email: email
            )

            successMessage = "OTP sent to your email. Please enter the 6-digit code."
        } catch {
            self.error = "Failed to send OTP: \(error.localizedDescription)"
            print("Email OTP error:", error)
        }

        isLoading = false
    }

    @MainActor
    func verifyEmailWithCode(code: String) async {
        isLoading = true
        error = nil

        guard let userId = currentUser?.id,
            let email = currentUser?.email,
            let fullName = currentUser?.fullName
        else {
            error = "User information not found"
            isLoading = false
            return
        }

        do {
            try await account.updateVerification(userId: userId, secret: code)

            try await databases.updateDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userId,
                data: [
                    "user_id": userId,
                    "full_name": fullName,
                    "email": email,
                    "role": UserRole.member.rawValue,
                    "is_verified": true,
                    "mfa_enabled": false,
                ]
            )

            _ = try await account.updateVerification(userId: userId, secret: code)

            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userId
            )

            if let updatedUser = parseUserFromDocument(userDoc) {
                currentUser = updatedUser
                authState = .authenticated(updatedUser)
            }

            successMessage = "Email verified successfully!"

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showEmailVerificationSheet = false
            }
        } catch {
            self.error = "Failed to verify code: \(error.localizedDescription)"
            print("Email verification error:", error)

            if registrationInProgress {
                //                try? await account.delete(
                try? await databases.deleteDocument(
                    databaseId: databaseId,
                    collectionId: usersCollectionId,
                    documentId: userId
                )
                currentUser = nil
                authState = .unauthenticated

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.error = "Verification failed. Please register again."
                    self.showEmailVerificationSheet = false
                }
            }
        }

        isLoading = false
    }

    @MainActor
    func verifyOtpAndCompleteRegistration(code: String) async {
        guard let userId = otpUserId else {
            self.error = "OTP flow not initiated."
            return
        }
        isLoading = true
        error = nil

        do {
            // 👉 Use createSession(userId:secret:) to turn the 6-digit code into a logged-in session
            let session = try await account.createSession(
                userId: userId,
                secret: code
            )  // ← OTP login endpoint

            // Now you have a valid session—fetch user info
            let userData = try await account.get()
            let userDoc = try await databases.getDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id
            )

            // Mark user as verified in your own collection
            try await databases.updateDocument(
                databaseId: databaseId,
                collectionId: usersCollectionId,
                documentId: userData.id,
                data: [
                    "is_verified": true
                ]
            )

            if let user = parseUserFromDocument(userDoc) {
                currentUser = user
                authState = .authenticated(user)
            }

            // Clean up OTP context
            showOtpSheet = false
            otpUserId = nil
            registrationEmail = nil
            registrationPassword = ""
            registrationInProgress = false

        } catch let appwriteError as AppwriteError {
            handleAppwriteError(appwriteError)
        } catch {
            self.error = "Verification failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func checkEmailVerificationStatus() async {
        // This function is no longer needed with the new approach
        // but keeping a minimal implementation to avoid breaking code
        guard let userId = currentUser?.id else { return }

        do {
            let userData = try await account.get()
            if userData.emailVerification {
                successMessage = "Email verification complete!"
            }
        } catch {
            print("Failed to check verification status: \(error)")
        }
    }

    @MainActor
    func logout() async {
        isLoading = true

        do {
            try await account.deleteSession(sessionId: "current")
            currentUser = nil
            authState = .unauthenticated
            mfaChallenge = nil
        } catch {
            self.error = "Logout failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    private func parseUserFromAppwrite(_ appwriteUser: AppwriteModels.User<[String: AnyCodable]>)
        -> User?
    {

        let createdAt: Date
        if let createdAtDouble = Double(appwriteUser.createdAt) {
            createdAt = Date(timeIntervalSince1970: createdAtDouble / 1000)
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

    private func parseUserFromDocument(_ document: AppwriteModels.Document<[String: AnyCodable]>)
        -> User?
    {
        guard
            let fullName = document.data["full_name"]?.value as? String,
            let email = document.data["email"]?.value as? String,
            let roleString = document.data["role"]?.value as? String,
            let role = UserRole(rawValue: roleString),
            let createdAtString = document.data["created_at"]?.value as? String
        else {
            return nil
        }

        let isVerified = document.data["is_verified"]?.value as? Bool ?? false
        let mfaEnabled = document.data["mfa_enabled"]?.value as? Bool ?? false

        let userId = document.id
        let profileImageUrl = document.data["profile_image_url"]?.value as? String
        let preferences = document.data["preferences"]?.value as? [String: String]

        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()

        return User(
            id: userId,
            fullName: fullName,
            email: email,
            profileImageUrl: profileImageUrl,
            role: role,
            isVerified: isVerified,
            mfaEnabled: mfaEnabled,
            preferences: preferences,
            createdAt: createdAt
        )
    }

    private func handleAppwriteError(_ error: AppwriteError) {
        let message = error.message
        let code = error.code

        print("Handling Appwrite error: \(message)")

        if code == 401 {
            self.error = "Authentication failed: Invalid credentials"
        } else if code == 404 {
            self.error = "User document not found. Please contact support."
        } else if code == 409 {
            self.error = "User already exists with this email"
        } else {
            self.error = "Error (\(String(describing: code))): \(message)"
        }

        authState = .error(self.error ?? "Unknown error")
    }

    private func generateQRCode(from string: String) -> UIImage {
        let data = Data(string.utf8)
        let filter = CIFilter(name: "CIQRCodeGenerator")!
        filter.setValue(data, forKey: "inputMessage")

        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQRImage = filter.outputImage!.transformed(by: transform)

        let context = CIContext()
        let cgImage = context.createCGImage(scaledQRImage, from: scaledQRImage.extent)!

        return UIImage(cgImage: cgImage)
    }

    var isAuthenticating: Bool {
        if case .authenticating = authState {
            return true
        }
        return false
    }
}
