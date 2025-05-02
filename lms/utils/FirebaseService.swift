//
//  FirebaseService.swift
//  lms
//
//  Created by VR on 02/05/25.
//

import FirebaseCore
import FirebaseFirestore
import Foundation

class FirebaseService {
    static let shared = FirebaseService()
    private let db: Firestore
    private var isConfigured = false

    private init() {
        // Configure Firebase if not already configured
        if FirebaseApp.app() == nil {
            print("Firebase: Configuring Firebase app")
            FirebaseApp.configure()
            isConfigured = true
        } else {
            print("Firebase: App already configured")
            isConfigured = true
        }

        db = Firestore.firestore()
        print("Firebase: Firestore initialized - Collection path: users")

        // Test connection to verify Firebase is working
        Task {
            await testFirebaseConnection()
        }
    }

    func testFirebaseConnection() async {
        print("Firebase: Testing connection...")
        do {
            let testDoc = try await db.collection("_test_connection").document("test").getDocument()
            print("Firebase: Connection successful! Firebase is properly configured.")
        } catch {
            print("Firebase: ⚠️ CONNECTION ERROR - \(error.localizedDescription)")
            print("Firebase: Please check your GoogleService-Info.plist and internet connection")
        }
    }

    func createUser(userId: String, userData: [String: Any]) async {
        print("Firebase: Attempting to create user with ID: \(userId)")
        print("Firebase: Data being sent: \(userData)")
        do {
            try await db.collection("users").document(userId).setData(userData)
            print("Firebase: ✅ User created successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error creating user: \(error.localizedDescription)")
            print("Firebase: Error details: \(error)")
        }
    }

    func updateUser(userId: String, userData: [String: Any]) async {
        print("Firebase: Attempting to update user with ID: \(userId)")
        print("Firebase: Update data: \(userData)")
        do {
            try await db.collection("users").document(userId).updateData(userData)
            print("Firebase: ✅ User updated successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error updating user: \(error.localizedDescription)")
            print("Firebase: Error details: \(error)")
        }
    }

    func getUser(userId: String) async -> [String: Any]? {
        print("Firebase: Attempting to get user with ID: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            if document.exists, let data = document.data() {
                print("Firebase: ✅ User document retrieved: \(data)")
                return data
            } else {
                print("Firebase: User document doesn't exist")
                return nil
            }
        } catch {
            print("Firebase: ❌ Error getting user: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteUser(userId: String) async {
        print("Firebase: Attempting to delete user with ID: \(userId)")
        do {
            try await db.collection("users").document(userId).delete()
            print("Firebase: ✅ User deleted successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error deleting user: \(error.localizedDescription)")
        }
    }

    func listUsers() async -> [[String: Any]] {
        print("Firebase: Attempting to list all users")
        do {
            let querySnapshot = try await db.collection("users").getDocuments()
            let users = querySnapshot.documents.compactMap { $0.data() }
            print("Firebase: ✅ Retrieved \(users.count) users")
            return users
        } catch {
            print("Firebase: ❌ Error listing users: \(error.localizedDescription)")
            return []
        }
    }
}
