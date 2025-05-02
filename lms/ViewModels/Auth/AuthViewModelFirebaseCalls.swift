//
//  AuthViewModelFirebaseCalls.swift
//  lms
//
//  Created by VR on 02/05/25.
//

import Foundation

extension AuthViewModel {

    // Call with direct parameters to avoid reliance on instance variables
    func mirrorRegistration(userId: String, email: String, fullName: String = "") async {
        await mirrorUserToFirebase(
            userId: userId,
            fullName: fullName,
            email: email,
            role: .member,
            isVerified: false,
            mfaEnabled: false
        )
    }

    // Call with direct parameters
    func mirrorMfaComplete(userId: String) async {
        await mirrorMfaSetupCompletion(userId: userId)
    }

    // Call with direct parameters
    func mirrorVerification(userId: String, email: String, fullName: String) async {
        await mirrorEmailVerification(userId: userId, fullName: fullName, email: email)
    }

    // Call with direct parameters
    func mirrorOtpComplete(userId: String) async {
        await mirrorOtpVerification(userId: userId)
    }
}
