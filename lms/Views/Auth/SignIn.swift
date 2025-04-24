//
//  SignIn.swift
//  lms
//
//  Created by VR on 24/04/25.
//

import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var navigateToRegister = false
    @State private var navigateToMFA = false
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

                    Text("Welcome Back")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)

                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 60)

                // Form
                VStack(spacing: 20) {
                    // Email field
                    FormField(title: "Email", placeholder: "Enter your email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)

                    // Password field
                    FormField(
                        title: "Password", placeholder: "Enter your password", text: $password,
                        isSecure: true)

                    // Remember me and Forgot password
                    HStack {
                        Spacer()

                        Button("Forgot Password?") {
                            // Add forgot password action
                        }
                        .font(.subheadline)
                        .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                // Sign In button
                Button(action: signIn) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        HStack {
                            Text("Sign In")
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

                // Registration link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)

                    Button("Register") {
                        navigateToRegister = true
                    }
                    .foregroundColor(.black)
                    .fontWeight(.semibold)
                }
                .padding(.vertical)

            }
            .navigationDestination(isPresented: $navigateToRegister) {
                RegisterView()
            }
            .navigationDestination(isPresented: $navigateToMFA) {
                mfaVerificationView()
            }
            .onChange(of: authViewModel.authState) { newValue in
                if case .mfaRequired = newValue {
                    navigateToMFA = true
                }
            }
            .onChange(of: authViewModel.error) { newError in
                showingAlert = newError != nil
            }
            .alert("Sign In Error", isPresented: $showingAlert) {
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
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
    }

    // Function to handle sign in
    private func signIn() {
        Task {
            await authViewModel.loginUser(email: email, password: password)
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthViewModel())
}
