//
//  AddLibrarianViewModel.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import Appwrite
import JSONCodable
import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
class AddLibrarianViewModel: ObservableObject {
    // MARK: – Form Data
    @Published var name        = ""
    @Published var designation = ""
    @Published var salary      = ""
    @Published var phone       = ""
    @Published var email       = ""
    @Published var password    = ""
    @Published var status      = "Active"

    // MARK: – Photo Picker
    @Published var image           : UIImage?
    @Published var showPhotoPicker = false
    @Published var photoItem       : PhotosPickerItem?

    // MARK: – Validation State
    @Published var isNameValid     = true
    @Published var isContactValid  = true
    @Published var isEmailValid    = true
    @Published var isPasswordValid = true
    @Published var nameError       = ""
    @Published var phoneError      = ""
    @Published var emailError      = ""
    @Published var passwordError   = ""

    // MARK: – Loading & Alert
    @Published var isLoading    = false
    @Published var showAlert    = false
    @Published var isSuccess    = false
    @Published var alertMessage = ""

    // MARK: – Backends
    private let account   : Account
    private let databases : Databases
    private let db        = Firestore.firestore()
    private let storage   = Storage.storage()

    init() {
        let client = Client()
            .setEndpoint(AppwriteConfig.endpoint)
            .setProject(AppwriteConfig.projectId)
            .setSelfSigned(true)

        account   = Account(client)
        databases = Databases(client)
    }

    // MARK: – Validation

    func validateName() {
        if name.isEmpty {
            nameError   = "Name cannot be empty"
            isNameValid = false
        } else {
            nameError   = ""
            isNameValid = true
        }
    }

    func validatePhone() {
        let pattern = "^[0-9]{10}$"
        let pred    = NSPredicate(format: "SELF MATCHES %@", pattern)
        if !pred.evaluate(with: phone) {
            phoneError      = "Phone must be exactly 10 digits"
            isContactValid  = false
        } else {
            phoneError      = ""
            isContactValid  = true
        }
    }

    func validateEmail() {
        if email.isEmpty {
            emailError   = "Email cannot be empty"
            isEmailValid = false
            return
        }
        if !email.lowercased().hasSuffix("@gmail.com") {
            emailError   = "Must end in @gmail.com"
            isEmailValid = false
            return
        }
        let regex = "[A-Z0-9a-z._%+-]+@gmail\\.com"
        let pred  = NSPredicate(format: "SELF MATCHES %@", regex)
        if !pred.evaluate(with: email) {
            emailError   = "Enter a valid Gmail address"
            isEmailValid = false
        } else {
            emailError   = ""
            isEmailValid = true
        }
    }

    func validatePassword() {
        if password.count < 6 {
            passwordError    = "At least 6 characters"
            isPasswordValid  = false
        } else {
            passwordError    = ""
            isPasswordValid  = true
        }
    }

    var canSave: Bool {
        !name.isEmpty
        && !phone.isEmpty
        && !email.isEmpty
        && !password.isEmpty
        && isNameValid
        && isContactValid
        && isEmailValid
        && isPasswordValid
    }

    // MARK: – Save Flow

    func save() {
        // run all validations
        validateName()
        validatePhone()
        validateEmail()
        validatePassword()
        guard canSave else {
            alertMessage = "Please fix the errors first."
            isSuccess    = false
            showAlert    = true
            return
        }

        isLoading = true

        Task {
            do {
                // 1) Create Appwrite account
                let created = try await account.create(
                    userId:   ID.unique(),
                    email:    email,
                    password: password,
                    name:     name
                )
                let uid = created.id

                // 2) Mirror into your Appwrite Database users collection
                try await databases.createDocument(
                    databaseId:     AppwriteConfig.databaseId,
                    collectionId:   AppwriteConfig.usersCollectionId,
                    documentId:     uid,
                    data: [
                        "user_id":     uid,
                        "full_name":   name,
                        "email":       email,
                        "role":        UserRole.librarian.rawValue,
                        "is_verified": true,
                        "mfa_enabled": false,
                        "created_at":  Date().ISO8601Format()
                    ]
                )

                // 3) Build your Firestore model
                let salaryValue = Double(salary) ?? 0
                let lib = Librarian(
                    id:               uid,
                    name:             name,
                    email:            email,
                    phone:            phone,
                    salary:           salaryValue,
                    designation:      designation,
                    createdAt:        Date(),
                    status:           status,
                    profileImageURL:  nil
                )

                // 4) Write to Firestore
                try db.collection("librarians")
                    .document(uid)
                    .setData(from: lib)

                // 5) Optional: upload profile photo
                if let uiImage = image,
                   let data    = uiImage.jpegData(compressionQuality: 0.8)
                {
                    let ref = storage.reference()
                        .child("librarian_images/\(uid).jpg")
                    _ = try await ref.putDataAsync(data)
                    let url = try await ref.downloadURL()
                    try await db.collection("librarians")
                        .document(uid)
                        .updateData(["profileImageURL": url.absoluteString])
                }

                // 6) Notify success on main thread
                DispatchQueue.main.async {
                    self.isLoading    = false
                    self.alertMessage = "Librarian added successfully!"
                    self.isSuccess    = true
                    self.showAlert    = true
                }

            } catch {
                DispatchQueue.main.async {
                    self.isLoading    = false
                    self.alertMessage = "Save failed: \(error.localizedDescription)"
                    self.isSuccess    = false
                    self.showAlert    = true
                }
            }
        }
    }
}
