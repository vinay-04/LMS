//
//  AdminViewModel.swift
//  lms
//
//  Created by VR on 24/04/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

@MainActor
class AdminViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var actionError: String?
    @Published var successMessage: String?

    private let db = Firestore.firestore()

    func fetchUsers() async {
        isLoading = true
        error = nil

        do {
            let snap = try await db.collection("users").getDocuments()
            users = snap.documents.compactMap { (doc) -> User? in
                let d = doc.data()
                guard
                    let fullName = d["full_name"] as? String,
                    let email    = d["email"] as? String,
                    let roleStr  = d["role"] as? String,
                    let role     = UserRole(rawValue: roleStr),
                    let ts       = d["created_at"] as? Timestamp
                else {
                    return nil
                }

                let isVerified   = d["is_verified"] as? Bool ?? false
                let mfaEnabled   = d["mfa_enabled"] as? Bool ?? false
                let profileImage = d["profile_image_url"] as? String
                let preferences  = d["preferences"] as? [String:String]
                let createdAt    = ts.dateValue()

                return User(
                    id: doc.documentID,
                    fullName: fullName,
                    email: email,
                    profileImageUrl: profileImage,
                    role: role,
                    isVerified: isVerified,
                    mfaEnabled: mfaEnabled,
                    preferences: preferences,
                    createdAt: createdAt
                )
            }
        } catch {
            self.error = "Failed to fetch users: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func updateUserRole(userId: String, newRole: UserRole) async {
        actionError = nil
        successMessage = nil

        do {
            try await db.collection("users").document(userId)
                .updateData(["role": newRole.rawValue])

            if let idx = users.firstIndex(where: { $0.id == userId }) {
                users[idx].role = newRole
            }

            successMessage = "Updated role for user successfully"
            
            // Auto‐dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    self.successMessage = nil
                }
            }
        } catch {
            actionError = "Failed to update role: \(error.localizedDescription)"
        }
    }
}
