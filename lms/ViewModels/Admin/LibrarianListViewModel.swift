//
//  LibrarianListViewModel.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class LibrarianListViewModel: ObservableObject {
    @Published var librarians: [Librarian] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func fetchLibrarians() {
        isLoading = true
        errorMessage = nil

        db.collection("librarians")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = "Failed to fetch librarians: \(error.localizedDescription)"
                    print("Error fetching librarians: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No librarians found"
                    return
                }
                
                print("Found \(documents.count) librarian documents")

                var loaded: [Librarian] = []
                for doc in documents {
                    let data = doc.data()
                    let id = doc.documentID
                    
                    let name = data["name"] as? String ?? "Unknown"
                    let email = data["email"] as? String ?? "No email"
                    let phone = data["phone"] as? String ?? "No phone"
                    let salary = data["salary"] as? Double ?? 0.0
                    
                    // Get designation field
                    let designation = data["designation"] as? String ?? "Librarian"
                    
                    // Get status field
                    let status = data["status"] as? String ?? "Active"
                    
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
                    print("Processing librarian: \(name), email: \(email), designation: \(designation)")
                    
                    let librarian = Librarian(
                        id: id,
                        name: name,
                        email: email,
                        phone: phone,
                        salary: salary,
                        designation: designation,
                        createdAt: createdAt, status: status
                    )
                    
                    loaded.append(librarian)
                }

                if loaded.isEmpty {
                    self.errorMessage = "No valid librarian data found"
                } else {
                    print("Successfully loaded \(loaded.count) librarians")
                    self.librarians = loaded
                }
            }
    }

    func addLibrarian(name: String, email: String, phone: String, salary: Double, designation: String, status: String) {
        isLoading = true

        let newLibrarian: [String: Any] = [
            "name": name,
            "email": email,
            "phone": phone,
            "salary": salary,
            "designation": designation,
            "status": status,
            "createdAt": Timestamp(date: Date())
        ]

        db.collection("librarians")
          .addDocument(data: newLibrarian) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = "Failed to add librarian: \(error.localizedDescription)"
            } else {
                self.fetchLibrarians()
            }
        }
    }

    /// Delete a librarian by its document ID.
    func deleteLibrarian(librarianId: String) {
        isLoading = true

        db.collection("librarians")
          .document(librarianId)
          .delete { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = "Failed to delete librarian: \(error.localizedDescription)"
            } else {
                // locally remove without refetching
                self.librarians.removeAll { $0.id == librarianId }
            }
        }
    }

    /// Update a librarian document with arbitrary fields.
    func updateLibrarian(librarianId: String, data: [String: Any]) {
        isLoading = true

        db.collection("librarians")
          .document(librarianId)
          .updateData(data) { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = "Failed to update librarian: \(error.localizedDescription)"
            } else {
                self.fetchLibrarians()
            }
        }
    }
}
