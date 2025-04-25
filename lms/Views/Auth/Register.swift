//
//  Register.swift
//  lms
//
//  Created by VR on 24/04/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreeToTerms = false
    private let role: UserRole = .member

    // Navigation state - remove redundant authState
    @State private var validationErrors: [ValidationError] = []
    @State private var navigateToSignIn = false
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "books.vertical")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.black)

                    Text("Create Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("Sign up to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)

                // Form
                VStack(spacing: 20) {
                    // Fields with matched styling
                    FormField(
                        title: "Full Name", placeholder: "Enter your full name", text: $fullName)

                    FormField(title: "Email", placeholder: "Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    FormField(
                        title: "Password", placeholder: "Enter your password", text: $password,
                        isSecure: true)

                    FormField(
                        title: "Confirm Password", placeholder: "Confirm your password",
                        text: $confirmPassword, isSecure: true)

                    // Role selection removed - default is member

                    HStack(alignment: .center) {
                        Toggle("", isOn: $agreeToTerms)
                            .toggleStyle(SwitchToggleStyle(tint: .black))
                            .labelsHidden()

                        Text("I agree to the Terms and Privacy Policy")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Display validation errors
                    if !validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(validationErrors) { error in
                                Text(error.message)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Register button
                Button(action: registerUser) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        HStack {
                            Text("Create Account")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
                .padding(.horizontal, 30)
                .disabled(!formIsValid || authViewModel.isLoading)
                .opacity(formIsValid ? 1 : 0.7)

                // Sign In link
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)

                    Button("Sign In") {
                        navigateToSignIn = true
                    }
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                }
                .padding(.vertical)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 4)
                    .padding(.bottom, 20)
            }
            .navigationDestination(isPresented: $navigateToSignIn) {
                SignInView()
            }
            .onChange(of: authViewModel.authState) { newValue in
                if case .authenticated = newValue {
                }
            }
            .onChange(of: authViewModel.error) { newError in
                showingAlert = newError != nil
            }
            .alert("Registration Error", isPresented: $showingAlert) {
                Button("OK") {
                    authViewModel.error = nil
                }
            } message: {
                Text(authViewModel.error ?? "Unknown error")
            }
        }
    }

    // Computed property to check if form is valid
    private var formIsValid: Bool {
        let errors = RegisterRequest.validate(
            fullName: fullName,
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )
        return errors.isEmpty && agreeToTerms
    }

    // Function to handle user registration
    private func registerUser() {
        // Validate form
        validationErrors = RegisterRequest.validate(
            fullName: fullName,
            email: email,
            password: password,
            confirmPassword: confirmPassword
        )

        if !validationErrors.isEmpty {
            return
        }

        if !agreeToTerms {
            validationErrors.append(
                ValidationError(message: "You must agree to the terms and conditions"))
            return
        }

        Task {
            await authViewModel.registerUser(
                fullName: fullName,
                email: email,
                password: password
            )
        }
    }
}

struct FormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthViewModel())
}
