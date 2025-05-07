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
        
        print("Fetching members...")
        
        // Based on the Firebase screenshot, fetch from members collection directly
        db.collection("members")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    print("Error fetching members: \(error.localizedDescription)")
                    self.errorMessage = "Failed to fetch members: \(error.localizedDescription)"
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents found in members collection")
                    self.errorMessage = "No members found"
                    return
                }
                
                print("Found \(documents.count) documents in members collection")
                
                // Process each document
                self.members = documents.compactMap { document -> Member? in
                    let data = document.data()
                    let docId = document.documentID
                    
                    // Check if this is a member document with fullName field (as seen in screenshot)
                    if let fullName = data["fullName"] as? String {
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
                    
                    return nil
                }
                
                if self.members.isEmpty {
                    print("No valid member data found in documents")
                    self.errorMessage = "No valid member data found"
                } else {
                    print("Successfully loaded \(self.members.count) members")
                }
            }
    }
    
    // Add new member function
    func addMember(name: String, email: String, phone: String, role: String) {
        isLoading = true
        
        let newMember = [
            "fullName": name,
            "email": email,
            "phone": phone,
            "role": role,
            "createdAt": Timestamp(date: Date())
        ] as [String : Any]
        
        let docRef = db.collection("members").document()
        
        docRef.setData(newMember) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                print("Error adding member: \(error.localizedDescription)")
                self.errorMessage = "Failed to add member: \(error.localizedDescription)"
                return
            }
            
            print("Member successfully added")
            self.fetchMembers() // Refresh the list
        }
    }
    
    // Delete member function
    func deleteMember(memberId: String) {
        isLoading = true
        
        db.collection("members").document(memberId).delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                print("Error deleting member: \(error.localizedDescription)")
                self.errorMessage = "Failed to delete member: \(error.localizedDescription)"
                return
            }
            
            print("Member successfully deleted")
            self.members.removeAll { $0.id == memberId }
        }
    }
}
