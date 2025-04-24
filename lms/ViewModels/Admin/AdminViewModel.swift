import Appwrite
import Foundation
import JSONCodable
import SwiftUI

class AdminViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var actionError: String?
    @Published var successMessage: String?

    private let client: Client
    private let databases: Databases

    init() {
        self.client = Client()
            .setEndpoint(AppwriteConfig.endpoint)
            .setProject(AppwriteConfig.projectId)
            .setSelfSigned(true)

        self.databases = Databases(client)
    }

    @MainActor
    func fetchUsers() async {
        isLoading = true
        error = nil

        do {
            let result = try await databases.listDocuments(
                databaseId: AppwriteConfig.databaseId,
                collectionId: AppwriteConfig.usersCollectionId,
                queries: []
            )

            let fetchedUsers = result.documents.compactMap { document -> User? in
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

            self.users = fetchedUsers
        } catch {
            self.error = "Failed to fetch users: \(error.localizedDescription)"
        }

        isLoading = false
    }

    @MainActor
    func updateUserRole(userId: String, newRole: UserRole) async {
        actionError = nil
        successMessage = nil

        do {
            // Update the user role in the database
            try await databases.updateDocument(
                databaseId: AppwriteConfig.databaseId,
                collectionId: AppwriteConfig.usersCollectionId,
                documentId: userId,
                data: [
                    "role": newRole.rawValue
                ]
            )

            // Update the local users array
            if let index = users.firstIndex(where: { $0.id == userId }) {
                users[index].role = newRole
            }

            successMessage = "Updated role for user successfully"

            // Auto-dismiss the success message after 3 seconds
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
