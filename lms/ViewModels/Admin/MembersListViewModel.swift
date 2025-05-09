//
//  MembersListViewModel.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore

@MainActor
class MembersListViewModel: ObservableObject {
    @Published var members: [Member] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchMembers() {
        isLoading = true
        errorMessage = nil

        db.collection("members")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Failed to fetch members: \(error.localizedDescription)"
                    print("Error fetching members: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No members found"
                    return
                }
                
                print("Found \(documents.count) member documents")

                var loaded: [Member] = []
                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    
                    // Check if this is a member document with fullName field (as seen in screenshot)
                    if let fullName = data["full_name"] as? String {
                        let id = data["id"] as? String ?? docId
                        let phone = data["phone"] as? String ?? ""
                        let email = data["email"] as? String ?? ""
                        let role = data["role"] as? String ?? "Member"
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        
                        return Member(
                            id: id,
                            name: fullName,
                            phone: phone,
                            email: email,
                            role: role,
                            createdAt: createdAt
                        )
                    }
                    // Alternative: Check if document has name field instead
                    else if let name = data["name"] as? String {
                        let id = data["id"] as? String ?? docId
                        let phone = data["phone"] as? String ?? ""
                        let email = data["email"] as? String ?? ""
                        let role = data["role"] as? String ?? "Member"
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        
                        return Member(
                            id: id,
                            name: name,
                            phone: phone,
                            email: email,
                            role: role,
                            createdAt: createdAt
                        )
                    }
                    
                    let phone = data["phone"] as? String ?? "No phone"
                    
                    // Normalize role case for consistency
                    let roleValue = data["role"] as? String ?? "Member"
                    let role = roleValue.capitalized
                    
                    // Better timestamp handling with more field name options
                    let createdAt: Date
                    if let timestamp = data["createdAt"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    } else if let timestamp = data["created_at"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    } else if let timestampDouble = data["createdAt"] as? Double {
                        createdAt = Date(timeIntervalSince1970: timestampDouble)
                    } else if let timestampDouble = data["created_at"] as? Double {
                        createdAt = Date(timeIntervalSince1970: timestampDouble)
                    } else {
                        createdAt = Date()
                        print("Missing or invalid createdAt timestamp in document: \(id)")
                    }
                    
                    // Debug info
                    print("Processing member: \(name), email: \(email), role: \(role)")
                    
                    let member = Member(
                        id: id,
                        name: name,
                        phone: phone,
                        email: email,
                        role: role,
                        createdAt: createdAt
                    )
                    
                    loaded.append(member)
                }

                if loaded.isEmpty {
                    self.errorMessage = "No valid member data found"
                } else {
                    print("Successfully loaded \(loaded.count) members")
                    self.members = loaded
                }
            }
    }

    func addMember(name: String, email: String, phone: String, role: String) {
        isLoading = true

        let newMember: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "role": role,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("members")
          .addDocument(data: newMember) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = "Failed to add member: \(error.localizedDescription)"
            } else {
                self.fetchMembers()
            }
        }
    }

    /// Delete a member by its document ID.
    func deleteMember(memberId: String) {
        isLoading = true

        db.collection("members")
          .document(memberId)
          .delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = "Failed to delete member: \(error.localizedDescription)"
            } else {
                // locally remove without refetching
                self.members.removeAll { $0.id == memberId }
            }
        }
    }

    /// Update a member document with arbitrary fields.
    func updateMember(memberId: String, data: [String: Any]) {
        isLoading = true

        db.collection("members")
          .document(memberId)
          .updateData(data) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = "Failed to update member: \(error.localizedDescription)"
            } else {
                self.fetchMembers()
            }
        }
    }
}
