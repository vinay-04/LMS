//
//  LibrarianDetailView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseStorage

struct LibrarianDetailView: View {
    let librarian: Librarian
    
    @StateObject private var viewModel = LibrarianViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var profileImage: UIImage?
    @State private var showImagePicker = false
    
    // Color theme
    private let accentColor = Color.blue
    private let secondaryAccentColor = Color.indigo
    private let destructiveColor = Color.red
    private let cardBackground: Color
    
    // Note: iconColors dictionary removed as it's no longer used

    // Editable fields
    @State private var name: String
    @State private var designation: String
    @State private var salary: String
    @State private var phone: String
    @State private var email: String
    @State private var status: String

    init(librarian: Librarian) {
        self.librarian = librarian
        _name = State(initialValue: librarian.name)
        _designation = State(initialValue: librarian.designation)
        _salary = State(initialValue: String(format: "%.2f", librarian.salary))
        _phone = State(initialValue: librarian.phone)
        _email = State(initialValue: librarian.email)
        _status = State(initialValue: librarian.status)
        
        // Initialize computed properties
        self.cardBackground = Color(UIColor.systemBackground)
    }

    var body: some View {
        content
            .navigationTitle("Librarian Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Cancel") {
                            resetFields()
                            isEditing = false
                        }
                        .foregroundColor(destructiveColor)
                    } else {
                        Menu {
                            Button(action: { isEditing = true }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(accentColor)
                                .font(.title3)
                        }
                    }
                }
            }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Librarian"),
                    message: Text("Are you sure you want to delete \(librarian.name)? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        deleteLibrarian()
                    },
                    secondaryButton: .cancel()
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $profileImage, sourceType: .photoLibrary)
            }
            .onAppear { loadProfileImage() }
    }

    // MARK: - Main Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 24) {
                profileImageSection
                    .padding(.top, 12)
                
                dateSection
                
                VStack(spacing: 24) {
                    detailsFormSection
                    
                    if isEditing {
                        saveButton
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Subviews

    private var profileImageSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [accentColor.opacity(0.7), secondaryAccentColor.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            if let image = profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
            } else {
                Text(String(name.prefix(1)))
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }
            
            if isEditing {
                Button(action: { showImagePicker = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        
                        Image(systemName: "camera.fill")
                            .foregroundColor(accentColor)
                    }
                }
                .offset(x: 50, y: 50)
            }
        }
        .padding(.bottom, 8)
    }

    private var dateSection: some View {
        VStack(spacing: 4) {
            Text(librarian.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                Text("Member since \(librarian.formattedDate)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 8)
    }

    private var detailsFormSection: some View {
        VStack(spacing: 0) {
            Group {
                DetailsRow(
                    icon: "person.fill",
                    title: "Name",
                    value: $name,
                    isEditing: isEditing
                )
                
                Divider().padding(.leading, 56)
                
                DetailsRow(
                    icon: "briefcase",
                    title: "Designation",
                    value: $designation,
                    isEditing: isEditing
                )
                
                Divider().padding(.leading, 56)
                
                DetailsRow(
                    icon: "dollarsign.circle",
                    title: "Salary",
                    value: $salary,
                    isEditing: isEditing,
                    keyboardType: isEditing ? .decimalPad : .default
                )
            }
            
            Divider().padding(.leading, 56)
            
            Group {
                DetailsRow(
                    icon: "phone.fill",
                    title: "Contact",
                    value: $phone,
                    isEditing: isEditing,
                    keyboardType: isEditing ? .phonePad : .default
                )
                
                Divider().padding(.leading, 56)
                
                DetailsRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: $email,
                    isEditing: isEditing,
                    keyboardType: isEditing ? .emailAddress : .default
                )
            }
            
            Divider().padding(.leading, 56)
            
            if isEditing {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Status")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 15)
                    
                    Picker("Status", selection: $status) {
                        Text("Active").tag("Active")
                        Text("Inactive").tag("Inactive")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 15)
                }
            } else {
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(status == "Active" ? .green : .red)
                        .font(.system(size: 12))
                        .frame(width: 30)
                    
                    Text("Status")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(status)
                        .foregroundColor(.primary)
                        .padding(6)
                        .padding(.horizontal, 4)
                        .background(
                            Capsule()
                                .fill(status == "Active" ?
                                      Color.green.opacity(0.2) :
                                      Color.red.opacity(0.2))
                        )
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 16)
            }
        }
        .background(cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
    
    private var saveButton: some View {
        Button(action: saveChanges) {
            HStack {
                Image(systemName: "checkmark")
                Text("Save Changes")
            }
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [.green, .green.opacity(0.7)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.green.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }

    // MARK: - Actions

    private func loadProfileImage() {
        guard let id = librarian.id else { return }
        let ref = Storage.storage()
            .reference()
            .child("librarian_images/\(id).jpg")
        ref.getData(maxSize: 5 * 1024 * 1024) { data, _ in
            if let data = data, let image = UIImage(data: data) {
                profileImage = image
            }
        }
    }

    private func saveChanges() {
        guard !name.isEmpty, !email.isEmpty else { return }
        let salaryValue = Double(salary) ?? 0.0
        let updatedData: [String: Any] = [
            "name": name,
            "designation": designation,
            "salary": salaryValue,
            "phone": phone,
            "email": email,
            "status": status
        ]
        viewModel.updateLibrarian(librarian, with: updatedData)
        
        // Upload profile image if changed
        if let newImage = profileImage, let id = librarian.id {
            uploadProfileImage(image: newImage, id: id)
        }
        
        isEditing = false
    }
    
    private func uploadProfileImage(image: UIImage, id: String) {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
        let ref = Storage.storage().reference().child("librarian_images/\(id).jpg")
        ref.putData(imageData, metadata: nil)
    }

    private func deleteLibrarian() {
        viewModel.deleteLibrarian(librarian)
        dismiss()
    }

    private func resetFields() {
        name = librarian.name
        designation = librarian.designation
        salary = String(format: "%.2f", librarian.salary)
        phone = librarian.phone
        email = librarian.email
        status = librarian.status
    }
}
