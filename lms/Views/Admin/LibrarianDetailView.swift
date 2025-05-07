//
//  LibrarianDetailView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseStorage

struct LibrarianDetailView: View {
    let librarian: Librarian
    @StateObject private var viewModel = LibrarianViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var profileImage: UIImage?

    // Editable fields
    @State private var name: String
    @State private var designation: String
    @State private var salary: String
    @State private var phone: String
    @State private var email: String
    @State private var status: String

    init(librarian: Librarian) {
        self.librarian = librarian
        _name        = State(initialValue: librarian.name)
        _designation = State(initialValue: librarian.designation)
        _salary      = State(initialValue: String(format: "%.2f", librarian.salary))
        _phone       = State(initialValue: librarian.phone)
        _email       = State(initialValue: librarian.email)
        _status      = State(initialValue: librarian.status)
    }

    var body: some View {
        content
            .navigationTitle("Librarian Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isEditing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            resetFields()
                            isEditing = false
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
            .onAppear { loadProfileImage() }
    }

    // MARK: - Main Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                profileImageSection
                dateSection
                detailsFormSection
                actionButtonsSection
                deleteButtonSection
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }

    // MARK: - Subviews

    private var profileImageSection: some View {
        Circle()
            .fill(Color.blue.opacity(0.3))
            .frame(width: 120, height: 120)
            .overlay(
                Group {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipShape(Circle())
                    } else {
                        Text(String(name.prefix(1)))
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                }
            )
    }

    private var dateSection: some View {
        Text("Member since \(librarian.formattedDate)")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }

    private var detailsFormSection: some View {
        VStack(spacing: 0) {
            DetailsRow(icon: "person.fill",
                      title: "Name",
                      value: $name,
                      isEditing: isEditing)
            Divider()
            DetailsRow(icon: "briefcase",
                      title: "Designation",
                      value: $designation,
                      isEditing: isEditing)
            Divider()
            DetailsRow(icon: "dollarsign.circle",
                      title: "Salary",
                      value: $salary,
                      isEditing: isEditing)
                .keyboardType(isEditing ? .decimalPad : .default)
            Divider()
            DetailsRow(icon: "phone.fill",
                      title: "Contact",
                      value: $phone,
                      isEditing: isEditing)
                .keyboardType(isEditing ? .phonePad : .default)
            Divider()
            DetailsRow(icon: "envelope.fill",
                      title: "Email",
                      value: $email,
                      isEditing: isEditing)
                .keyboardType(isEditing ? .emailAddress : .default)
            Divider()
            if isEditing {
                Picker("Status", selection: $status) {
                    Text("Active").tag("Active")
                    Text("Inactive").tag("Inactive")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            } else {
                HStack {
                    Image(systemName: "circle.fill")
                        .foregroundColor(status == "Active" ? .green : .red)
                        .frame(width: 30)
                    Text("Status")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(status)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 15)
                .padding(.horizontal, 16)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private var actionButtonsSection: some View {
        Group {
            if isEditing {
                Button(action: saveChanges) {
                    Text("Save Changes")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            } else {
                Button(action: { isEditing = true }) {
                    Text("Edit Details")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.top, 10)
    }

    private var deleteButtonSection: some View {
        Button(action: { showDeleteConfirmation = true }) {
            Text("Delete Librarian")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
        .padding(.top, 8)
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
            "name":        name,
            "designation": designation,
            "salary":      salaryValue,
            "phone":       phone,
            "email":       email,
            "status":      status
        ]
        viewModel.updateLibrarian(librarian, with: updatedData)
        isEditing = false
    }

    private func deleteLibrarian() {
        viewModel.deleteLibrarian(librarian)
        dismiss()
    }

    private func resetFields() {
        name        = librarian.name
        designation = librarian.designation
        salary      = String(format: "%.2f", librarian.salary)
        phone       = librarian.phone
        email       = librarian.email
        status      = librarian.status
    }
}
