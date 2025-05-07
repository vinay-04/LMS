//
//  AuthViewModel+Firebase.swift
//  lms
//
//  Created by VR on 02/05/25.
//


import FirebaseFirestore
import Foundation

extension AuthViewModel {
    @MainActor
    func mirrorUserToFirebase(
        userId: String,
        fullName: String,
        email: String,
        role: UserRole,
        isVerified: Bool = false,
        mfaEnabled: Bool = false
    ) async {
        let ts = Timestamp(date: Date())
        let userData: [String: Any] = [
            "user_id":          userId,
            "full_name":        fullName,
            "email":            email,
            "role":             role.rawValue,
            "is_verified":      isVerified,
            "mfa_enabled":      mfaEnabled,
            "created_at":       ts
        ]
        await FirebaseService.shared.createUser(
            userId: userId,
            userData: userData
        )
    }

    @MainActor
    func updateUserInFirebase(userId: String,
                              data: [String: Any]) async
    {
        await FirebaseService.shared.updateUser(
            userId: userId,
            userData: data
        )
    }
}
