//
//  AddLibrarianView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import PhotosUI

// MARK: – Custom Colors
extension Color {
    static let primaryBlue    = Color(red: 0.0,  green: 0.48, blue: 1.0)
    static let darkBackground = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let cardBackground = Color.white
}

// MARK: – AddLibrarianView

struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AddLibrarianViewModel()

    var body: some View {
        ZStack {
            Color.darkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    profileImageSection
                    personalInfoSection
                    professionalInfoSection
                    accountDetailsSection

                    Button(action: { vm.save() }) {
                        HStack {
                            Image(systemName: "person.badge.plus")
                            Text("Save Librarian")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemIndigo))
                        .cornerRadius(12)
                        .shadow(color: Color(.systemIndigo).opacity(0.3),
                                radius: 5, x: 0, y: 3)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .disabled(!vm.canSave)
                }
            }

            // Loading overlay
            if vm.isLoading {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: .white))
                            .scaleEffect(2)
                        Text("Saving librarian…")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .padding(30)
                    .background(Color.gray.opacity(0.7))
                    .cornerRadius(20)
                }
            }
        }
        // Only the system back button remains, tinted indigo:
        .navigationBarTitle("Add New Librarian", displayMode: .inline)
        .tint(.indigo)

        // Photo picker integration
        .photosPicker(isPresented: $vm.showPhotoPicker,
                      selection: $vm.photoItem)
        .onChange(of: vm.photoItem) { item in
            guard let item = item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui   = UIImage(data: data) {
                    vm.image = ui
                }
            }
        }

        // Success / error alert
        .alert(vm.isSuccess ? "Success" : "Error",
               isPresented: $vm.showAlert)
        {
            Button("OK") {
                if vm.isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(vm.alertMessage)
        }
    }

    // MARK: — Subviews

    private var profileImageSection: some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundColor(.primaryBlue)
                    .font(.system(size: 20, weight: .semibold))
                Text("Profile Picture")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            Button { vm.showPhotoPicker = true } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 120, height: 120)
                        .shadow(color: Color.black.opacity(0.1),
                                radius: 5, x: 0, y: 2)
                    if let img = vm.image {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 118, height: 118)
                            .clipShape(Circle())
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                            Text("Upload Photo")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05),
                radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var personalInfoSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(.green)
                    .font(.system(size: 20, weight: .semibold))
                Text("Personal Information")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            EnhancedTextField(
                title:             "Full Name",
                placeholder:       "Enter full name",
                text:              $vm.name,
                isValid:           $vm.isNameValid,
                validationMessage: vm.nameError,
                keyboardType:      .default,
                icon:              "person.fill"
            )

            EnhancedTextField(
                title:             "Contact Number",
                placeholder:       "Enter phone number",
                text:              $vm.phone,
                isValid:           $vm.isContactValid,
                validationMessage: vm.phoneError,
                keyboardType:      .phonePad,
                icon:              "phone.fill"
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05),
                radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var professionalInfoSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "briefcase.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 20, weight: .semibold))
                Text("Professional Information")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            EnhancedTextField(
                title:             "Designation",
                placeholder:       "Enter designation",
                text:              $vm.designation,
                isValid:           .constant(true),
                validationMessage: "",
                keyboardType:      .default,
                icon:              "tag.fill"
            )

            EnhancedTextField(
                title:             "Salary",
                placeholder:       "Enter annual salary",
                text:              $vm.salary,
                isValid:           .constant(true),
                validationMessage: "",
                keyboardType:      .decimalPad,
                icon:              "dollarsign.circle.fill"
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05),
                radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var accountDetailsSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.pink.opacity(0.7))
                    .font(.system(size: 20, weight: .semibold))
                Text("Account Details")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)

            EnhancedTextField(
                title:             "Email Address",
                placeholder:       "Enter email address",
                text:              $vm.email,
                isValid:           $vm.isEmailValid,
                validationMessage: vm.emailError,
                keyboardType:      .emailAddress,
                icon:              "envelope.fill"
            )

            EnhancedSecureField(
                title:             "Password",
                placeholder:       "Create a strong password",
                text:              $vm.password,
                isValid:           $vm.isPasswordValid,
                validationMessage: vm.passwordError,
                icon:              "lock.shield.fill"
            )
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05),
                radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: — Helper Fields

struct EnhancedTextField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    @Binding var isValid: Bool
    var validationMessage: String
    var keyboardType: UIKeyboardType
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isValid ? .gray : .red)
                    .frame(width: 25)
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isValid ? Color.gray.opacity(0.3) : Color.red,
                            lineWidth: 1)
                    .background(Color.white)
                    .cornerRadius(10)
            )
            if !isValid {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 5)
            }
        }
    }
}

struct EnhancedSecureField: View {
    var title: String
    var placeholder: String
    @Binding var text: String
    @Binding var isValid: Bool
    var validationMessage: String
    var icon: String
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isValid ? .gray : .red)
                    .frame(width: 25)
                if isVisible {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
                Button { isVisible.toggle() } label: {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isValid ? Color.gray.opacity(0.3) : Color.red,
                            lineWidth: 1)
                    .background(Color.white)
                    .cornerRadius(10)
            )
            if !isValid {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 5)
            }
        }
    }
}


