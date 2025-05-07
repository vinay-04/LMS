//
//  AddMemberViewModel.swift
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
class AddMemberViewModel: ObservableObject {
    // MARK: – Published form fields
    @Published var name = ""
    @Published var role = ""
    @Published var phone = ""
    @Published var email = ""
    @Published var password = ""
    @Published var image: UIImage?
    @Published var showPhotoPicker = false
    @Published var photoItem: PhotosPickerItem?

    // MARK: – Clients
    private let account: Account
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    init() {
        let client = Client()
            .setEndpoint(AppwriteConfig.endpoint)
            .setProject(AppwriteConfig.projectId)
            .setSelfSigned(true)
        self.account = Account(client)
    }

    var canSave: Bool {
        !name.isEmpty &&
        !role.isEmpty &&
        !phone.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty
    }

    func save(onSuccess: @escaping () -> Void) {
        guard canSave else { return }

        Task {
            do {
                let createdUser = try await account.create(
                    userId: ID.unique(),
                    email: email,
                    password: password,
                    name: name
                )
                let uid = createdUser.id

                let member = Member(
                    id: uid,
                    name: name,
                    phone: phone,
                    email: email,
                    role: role,
                    createdAt: Date()
                )
                try db.collection("members")
                    .document(uid)
                    .setData(from: member)

                if let img = image,
                   let data = img.jpegData(compressionQuality: 0.8)
                {
                    let ref = storage.reference()
                        .child("member_images/\(uid).jpg")

                    _ = try await ref.putDataAsync(data)
                    let url = try await ref.downloadURL()

                    try await db.collection("members")
                        .document(uid)
                        .updateData(["photoURL": url.absoluteString])
                }

                onSuccess()
            } catch {
                print("Failed to save member:", error.localizedDescription)
            }
        }
    }
}
