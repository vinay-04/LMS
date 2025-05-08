////
////  profileViewModel.swift
////  lms
////
////  Created by user@79 on 08/05/25.
////

//import Foundation
//import FirebaseFirestore
//import Combine
//
//class ProfileViewModel: ObservableObject {
//    @Published var userName: String = ""
//    @Published var userEmail: String = ""
//    @Published var userPhone: String = ""
//    @Published var memberId: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String?
//
//    private let db = FirebaseService.shared.db
//    private var cancellables = Set<AnyCancellable>()
//
//    func fetchProfile(userId: String) {
//        isLoading = true
//        errorMessage = nil
//
//        db.collection("members").document(userId).getDocument { [weak self] snapshot, error in
//            guard let self = self else { return }
//            self.isLoading = false
//
//            if let error = error {
//                self.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
//                return
//            }
//
//            guard let document = snapshot, document.exists, let data = document.data() else {
//                self.errorMessage = "Profile not found"
//                return
//            }
//
//            self.userName = data["full_name"] as? String ?? ""
//            self.userEmail = data["email"] as? String ?? ""
//            self.userPhone = data["phone"] as? String ?? ""
//            self.memberId = data["member_id"] as? String ?? document.documentID
//        }
//    }
//}
import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userPhone: String = ""
    @Published var memberId: String = ""
    @Published var userId: String = ""  // Added to store the user ID
    @Published var qrCodeImage: UIImage?  // Added to store generated QR code
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = FirebaseService.shared.db
    private var cancellables = Set<AnyCancellable>()

    func fetchProfile(userId: String) {
        isLoading = true
        errorMessage = nil
        self.userId = userId  // Store the user ID

        db.collection("members").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                self.errorMessage = "Failed to fetch profile: \(error.localizedDescription)"
                return
            }

            guard let document = snapshot, document.exists, let data = document.data() else {
                self.errorMessage = "Profile not found"
                return
            }

            self.userName = data["full_name"] as? String ?? ""
            self.userEmail = data["email"] as? String ?? ""
            self.userPhone = data["phone"] as? String ?? ""
            self.memberId = data["member_id"] as? String ?? document.documentID
            
            // Generate QR code with user ID
            self.generateQRCode()
        }
    }
    
    func generateQRCode() {
        // Create a unique string for QR code content
        // Using userId ensures uniqueness for each user
        let qrContent = (userId)
        
        // Generate QR code image
        self.qrCodeImage = UIImage.generateQRCode(from: qrContent, size: 300)
    }
}
