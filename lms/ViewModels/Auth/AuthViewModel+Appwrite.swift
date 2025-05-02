//
//  AuthViewModel+Appwrite.swift
//  lms
//
//  Created by VR on 02/05/25.
//

import Appwrite
import Foundation

// This extension adds Firebase mirroring to existing Appwrite functions
extension AuthViewModel {
    // Add this at the end of registerUser function
    @MainActor
    func mirrorRegisterUser(userId: String, fullName: String, email: String) async {
        await mirrorUserToFirebase(
            userId: userId,
            fullName: fullName,
            email: email,
            role: .member,
            isVerified: false,
            mfaEnabled: false
        )
    }

    // Add this at the end of completeMfaSetup function
    @MainActor
    func mirrorMfaSetupCompletion(userId: String) async {
        await updateUserInFirebase(userId: userId, data: ["mfa_enabled": true])
    }

    // Add this at the end of verifyEmailWithCode function
    @MainActor
    func mirrorEmailVerification(userId: String, fullName: String, email: String) async {
        await updateUserInFirebase(
            userId: userId,
            data: [
                "full_name": fullName,
                "email": email,
                "role": UserRole.member.rawValue,
                "is_verified": true,
            ]
        )
    }

    // Add this at the end of verifyOtpAndCompleteRegistration function
    @MainActor
    func mirrorOtpVerification(userId: String) async {
        await updateUserInFirebase(userId: userId, data: ["is_verified": true])
    }
}
