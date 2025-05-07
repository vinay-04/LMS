import Appwrite
import JSONCodable
import Foundation
import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

@MainActor
class AddLibrarianViewModel: ObservableObject {
    // MARK: – Published form fields
    @Published var name = ""
    @Published var designation = ""
    @Published var salary = ""
    @Published var phone = ""
    @Published var email = ""
    @Published var password = ""
    @Published var status = "Active"
    @Published var image: UIImage?
    @Published var showPhotoPicker = false
    @Published var photoItem: PhotosPickerItem?
    
    // MARK: - Validation States
    @Published var nameError = ""
    @Published var designationError = ""
    @Published var salaryError = ""
    @Published var phoneError = ""
    @Published var emailError = ""
    @Published var passwordError = ""
    
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
    
    // MARK: - Validation Methods
    
    func validateName() {
        if name.isEmpty {
            nameError = "Name cannot be empty"
        } else {
            nameError = ""
        }
    }
    
    func validateDesignation() {
        if designation.isEmpty {
            designationError = "Designation cannot be empty"
        } else {
            designationError = ""
        }
    }
    
    func validateSalary() {
        // Check if salary is empty
        if salary.isEmpty {
            salaryError = "Salary cannot be empty"
            return
        }
        
        // Check if salary contains only digits
        if !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: salary)) {
            salaryError = "Salary must contain integers only"
            return
        }
        
        salaryError = ""
    }
    
    func validatePhone() {
        // Check if phone is exactly 10 digits
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        
        if !phonePredicate.evaluate(with: phone) {
            phoneError = "Phone number must be exactly 10 digits"
        } else {
            phoneError = ""
        }
    }
    
    func validateEmail() {
        // Check if email is not empty
        if email.isEmpty {
            emailError = "Email cannot be empty"
            return
        }
        
        // Check if email ends with @gmail.com
        if !email.lowercased().hasSuffix("@gmail.com") {
            emailError = "Email must be a Gmail address (@gmail.com)"
            return
        }
        
        // Additional check for a valid email format
        let emailRegex = "[A-Z0-9a-z._%+-]+@gmail\\.com"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "Please enter a valid Gmail address"
        } else {
            emailError = ""
        }
    }
    
    func validatePassword() {
        if password.isEmpty {
            passwordError = "Password cannot be empty"
            return
        }
        
        if password.count < 6 {
            passwordError = "Password must be at least 6 characters"
        } else {
            passwordError = ""
        }
    }
    
    var canSave: Bool {
        // Check if all fields are filled
        let fieldsNotEmpty = !name.isEmpty &&
                           !designation.isEmpty &&
                           !salary.isEmpty &&
                           !phone.isEmpty &&
                           !email.isEmpty &&
                           !password.isEmpty
        
        // Check if there are no validation errors
        let noErrors = nameError.isEmpty &&
                      designationError.isEmpty &&
                      salaryError.isEmpty &&
                      phoneError.isEmpty &&
                      emailError.isEmpty &&
                      passwordError.isEmpty
        
        return fieldsNotEmpty && noErrors
    }
    
    func save(onSuccess: @escaping () -> Void) {
        // Run all validations one more time
        validateName()
        validateDesignation()
        validateSalary()
        validatePhone()
        validateEmail()
        validatePassword()
        
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
                
                // Convert salary to integer
                let salaryValue = Int(salary) ?? 0
                
                let lib = Librarian(
                    id: uid,
                    name: name,
                    email: email,
                    phone: phone,
                    salary: Double(salaryValue),
                    designation: designation,
                    createdAt: Date(),
                    status: status
                )
                
                try db.collection("librarians")
                    .document(uid)
                    .setData(from: lib)
                
                if let img = image,
                   let data = img.jpegData(compressionQuality: 0.8)
                {
                    let ref = storage.reference()
                        .child("librarian_images/\(uid).jpg")
                    _ = try await ref.putDataAsync(data)
                    let url = try await ref.downloadURL()
                    try await db.collection("librarians")
                        .document(uid)
                        .updateData(["photoURL": url.absoluteString])
                }
                
                DispatchQueue.main.async {
                    onSuccess()
                }
            } catch {
                print("Failed to save librarian:", error.localizedDescription)
            }
        }
    }
}
