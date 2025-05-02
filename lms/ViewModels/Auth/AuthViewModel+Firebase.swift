//
//  AuthViewModel+Firebase.swift
//  lms
//
//  Created by VR on 02/05/25.
//

import FirebaseFirestore
import Foundation

extension AuthViewModel {
    // Mirror user creation to Firebase
    @MainActor
    func mirrorUserToFirebase(
        userId: String, fullName: String, email: String, role: UserRole, isVerified: Bool = false,
        mfaEnabled: Bool = false
    ) async {
        let userData: [String: Any] = [
            "user_id": userId,
            "full_name": fullName,
            "email": email,
            "role": role.rawValue,
            "is_verified": isVerified,
            "mfa_enabled": mfaEnabled,
            "created_at": Timestamp(date: Date()),
        ]

        await FirebaseService.shared.createUser(userId: userId, userData: userData)
    }

    // Update user information in Firebase
    @MainActor
    func updateUserInFirebase(userId: String, data: [String: Any]) async {
        await FirebaseService.shared.updateUser(userId: userId, userData: data)
    }

    // Delete user from Firebase
    @MainActor
    func deleteUserFromFirebase(userId: String) async {
        await FirebaseService.shared.deleteUser(userId: userId)
    }

    // Convert User model to Firebase data
    func userToFirebaseData(_ user: User) -> [String: Any] {
        var userData: [String: Any] = [
            "user_id": user.id,
            "full_name": user.fullName,
            "email": user.email,
            "role": user.role.rawValue,
            "is_verified": user.isVerified,
            "mfa_enabled": user.mfaEnabled,
            "created_at": Timestamp(date: user.createdAt),
        ]

        if let profileImageUrl = user.profileImageUrl {
            userData["profile_image_url"] = profileImageUrl
        }

        if let preferences = user.preferences {
            userData["preferences"] = preferences
        }

        return userData
    }
}
