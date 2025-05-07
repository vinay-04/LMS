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
}
