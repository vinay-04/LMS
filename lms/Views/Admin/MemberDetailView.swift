//
//  MemberDetailView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore

struct MemberDetailView: View {
    let member: Member
    @ObservedObject var viewModel: MembersListViewModel
    @Environment(\.presentationMode) var presentationMode

    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    // Editable fields
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var role: String
    @State private var status: String = "Active"

    // MARK: — Init
    init(member: Member, viewModel: MembersListViewModel) {
        self.member = member
        self.viewModel = viewModel
        _name  = State(initialValue: member.name)
        _email = State(initialValue: member.email)
        _phone = State(initialValue: member.phone)
        _role  = State(initialValue: member.role)
    }

    // MARK: — Computed
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: member.createdAt)
    }

    // MARK: — Body
    var body: some View {
        content
            .navigationBarTitle("Member Details", displayMode: .inline)
            .toolbar { toolbarItems }
            .alert(isPresented: $showDeleteConfirmation) {
                Alert(
                    title: Text("Delete Member"),
                    message: Text("Are you sure you want to delete \(member.name)? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) { deleteMember() },
                    secondaryButton: .cancel()
                )
            }
    }

    // MARK: — Subviews
    private var content: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                headerSection
                dateSection
                detailsFormSection
                editButtonSection
                deleteButtonSection
                Spacer()
            }
            .padding(.top, 20)
            .padding(.horizontal)
        }
    }

    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if isEditing {
                Button("Cancel") {
                    resetFields()
                    isEditing = false
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(member.name)
                .font(.title)
                .fontWeight(.bold)
            Text(member.email)
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    private var dateSection: some View {
        Text("Member since \(formattedDate)")
            .font(.subheadline)
            .foregroundColor(.gray)
    }

    private var detailsFormSection: some View {
        VStack(spacing: 0) {
            DetailsRow(icon: "person.fill",
                       title: "Name",
                       value: $name,
                       isEditing: isEditing)
            Divider()
            DetailsRow(icon: "envelope.fill",
                       title: "Email",
                       value: $email,
                       isEditing: isEditing)
                .keyboardType(isEditing ? .emailAddress : .default)
            Divider()
            DetailsRow(icon: "phone.fill",
                       title: "Phone",
                       value: $phone,
                       isEditing: isEditing)
                .keyboardType(isEditing ? .phonePad : .default)
            Divider()
            if isEditing {
                Picker("Role", selection: $role) {
                    Text("Member").tag("Member")
                    Text("Admin").tag("Admin")
                    Text("Librarian").tag("Librarian")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                Divider()
                Picker("Status", selection: $status) {
                    Text("Active").tag("Active")
                    Text("Inactive").tag("Inactive")
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
            } else {
                DetailsRow(icon: "person.text.rectangle",
                           title: "Role",
                           value: $role,
                           isEditing: false)
                Divider()
                DetailsRow(icon: "checkmark.circle",
                           title: "Status",
                           value: $status,
                           isEditing: false)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05),
                radius: 5, x: 0, y: 2)
    }

    private var editButtonSection: some View {
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
            Text("Delete Member")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
        }
        .padding(.top, 8)
    }

    // MARK: — Actions
    private func saveChanges() {
        guard !name.isEmpty, !email.isEmpty,
              let memberId = member.id else { return }

        let updatedData: [String: Any] = [
            "fullName": name,
            "email": email,
            "phone": phone,
            "role": role,
            "status": status
        ]

        Firestore.firestore()
            .collection("members")
            .document(memberId)
            .updateData(updatedData) { error in
                if let error = error {
                    print("Error updating member: \(error.localizedDescription)")
                } else {
                    print("Member successfully updated")
                    viewModel.fetchMembers()
                }
            }

        isEditing = false
    }

    private func deleteMember() {
        guard let memberId = member.id else { return }
        viewModel.deleteMember(memberId: memberId)
        presentationMode.wrappedValue.dismiss()
    }

    private func resetFields() {
        name  = member.name
        email = member.email
        phone = member.phone
        role  = member.role
    }
}
