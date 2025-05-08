//
//  AuthViewModel+Appwrite.swift
//  lms
//
//  Created by VR on 02/05/25.
//

import Appwrite
import Foundation
import JSONCodable
import SwiftUI
//
//extension AuthViewModel {
//    @MainActor
//    func mirrorRegisterUser(userId: String,
//                            fullName: String,
//                            email: String) async
//    {
//        await mirrorUserToFirebase(
//            userId: userId,
//            fullName: fullName,
//            email: email,
//            role: .member,
//            isVerified: false,
//            mfaEnabled: false
//        )
//    }
//
//    @MainActor
//    func mirrorMfaSetupCompletion(userId: String) async {
//        await updateUserInFirebase(userId: userId,
//                                   data: ["mfa_enabled": true])
//    }
//
//    @MainActor
//    func mirrorEmailVerification(userId: String,
//                                 fullName: String,
//                                 email: String) async
//    {
//        await updateUserInFirebase(
//            userId: userId,
//            data: [
//                "full_name": fullName,
//                "email": email,
//                "role": UserRole.member.rawValue,
//                "is_verified": true
//            ]
//        )
//    }
//
//    @MainActor
//    func mirrorOtpVerification(userId: String) async {
//        await updateUserInFirebase(userId: userId,
//                                   data: ["is_verified": true])
//    }
//}
// MARK: - Firebase Integration

extension AuthViewModel {
    @MainActor
    func mirrorRegisterUser(userId: String,
                            fullName: String,
                            email: String) async
    {
        await mirrorUserToFirebase(
            userId: userId,
            fullName: fullName,
            email: email,
            role: .member,
            isVerified: false,
            mfaEnabled: false
        )
        
        // Set the current user in FirebaseService
        FirebaseService.shared.setCurrentUser(userId)
    }
    
    @MainActor
    func mirrorMfaSetupCompletion(userId: String) async {
        await updateUserInFirebase(userId: userId,
                                   data: ["mfa_enabled": true])
    }
    
    @MainActor
    func mirrorEmailVerification(userId: String,
                                 fullName: String,
                                 email: String) async
    {
        await updateUserInFirebase(
            userId: userId,
            data: [
                "full_name": fullName,
                "email": email,
                "role": UserRole.member.rawValue,
                "is_verified": true
            ]
        )
    }
    
    @MainActor
    func mirrorOtpVerification(userId: String) async {
        await updateUserInFirebase(userId: userId,
                                   data: ["is_verified": true])
    }
    
    // Add this to maintain connection between Appwrite and Firebase
//    @MainActor
//    func synchronizeWithFirebase() async {
//
//        if let userId = appwriteUserId {
//            FirebaseService.shared.setCurrentUser(userId)
//        }
//    }

    // Update the login method to set current user in Firebase
//    @MainActor
//    func loginUser(email: String, password: String) async {
//        authState = .authenticating
//        isLoading = true
//        error     = nil
//        
//        do {
//            try? await account.deleteSession(sessionId: "current")
//            _ = try await account.createEmailPasswordSession(
//                email: email,
//                password: password
//            )
//            
//            let userData = try await account.get()
//            let userDoc  = try await databases.getDocument(
//                databaseId: databaseId,
//                collectionId: usersCollectionId,
//                documentId: userData.id
//            )
//            let hasMfa = userDoc.data["mfa_enabled"]?.value as? Bool ?? false
//            
//            // Set the current user in Firebase service
//            FirebaseService.shared.setCurrentUser(userData.id)
//            
//            if hasMfa {
//                let challenge = try await account.createMfaChallenge(factor: .totp)
//                mfaChallenge = MfaChallenge(
//                    id: challenge.id,
//                    userId: userData.id,
//                    createdAt: Date(),
//                    expiresAt: Date().addingTimeInterval(300)
//                )
//                authState    = .mfaRequired(mfaChallenge!)
//                showMfaSheet = true
//            } else {
//                await setupMfaForUser(userId: userData.id)
//            }
//        } catch let appErr as AppwriteError {
//            handleAppwriteError(appErr)
//        } catch let swiftError {
//            self.error = "Login error: \(swiftError.localizedDescription)"
//            self.authState = .error(self.error!)
//        }
//        
//        isLoading = false
//    }
//    
//    // Update logout to clear current user in Firebase
//    @MainActor
//    func logout() async {
//        isLoading = true
//        defer { isLoading = false }
//        
//        do {
//            if let uid = currentUser?.id {
//                KeychainHelper.standard.delete(
//                    service: mfaCompletionService,
//                    account: uid
//                )
//            }
//            
//            // Clear the current user in Firebase service
//            FirebaseService.shared.clearCurrentUser()
//            
//            try await account.deleteSession(sessionId: "current")
//            currentUser  = nil
//            authState    = .unauthenticated
//            mfaChallenge = nil
//        } catch let swiftError {
//            self.error = "Logout failed: \(swiftError.localizedDescription)"
//        }
//    }
}


