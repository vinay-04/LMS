//
//  mfaVerificationView.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import SwiftUI

struct mfaVerificationView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var verificationCode = ""
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    if authViewModel.isMfaSetupRequired {
                        mfaSetupView
                    } else {
                        mfaVerificationView
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(
                        authViewModel.isMfaSetupRequired
                            ? "Set Up Two-Factor Authentication" : "Two-Factor Authentication"
                    )
                    .font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        Task {
                            await authViewModel.logout()
                            authViewModel.showMfaSheet = false
                        }
                    }
                }
            }
            .interactiveDismissDisabled()  // Prevent dismissal by dragging down
        }
        .presentationDetents([.large, .medium])
        .presentationDragIndicator(.visible)
    }

    // MFA Verification View
    private var mfaVerificationView: some View {
        VStack(spacing: 25) {
            Image(systemName: "lock.shield.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 70, height: 70)
                .foregroundColor(.blue)
                .padding(.bottom, 10)

            Text("Verification Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("Enter the 6-digit verification code from your authenticator app to continue")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // Code input field
            TextField("000000", text: $verificationCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.system(size: 32, weight: .medium, design: .monospaced))
                .padding()
                .frame(height: 70)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .focused($isInputFocused)
                .onAppear {
                    isInputFocused = true
                }
                .onChange(of: verificationCode) { newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        verificationCode = String(newValue.prefix(6))
                    }

                    // Auto-verify when 6 digits entered
                    if newValue.count == 6 {
                        verifyCode()
                    }
                }

            // Error message if any
            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, -10)
            }

            // Verify button
            Button(action: verifyCode) {
                if authViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Verify")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .cornerRadius(12)
            .disabled(verificationCode.count != 6 || authViewModel.isLoading)
            .opacity((verificationCode.count == 6 && !authViewModel.isLoading) ? 1 : 0.7)
        }
        .padding(.horizontal)
    }

    // MFA Setup View
    private var mfaSetupView: some View {
        VStack(spacing: 25) {
            if let setupData = authViewModel.mfaSetupData {
                Image(systemName: "shield.lock.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .foregroundColor(.blue)

                Text("Enhance Your Account Security")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Two-factor authentication adds an extra layer of security to your account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 15) {
                    Text("1. Scan this QR code with your authenticator app")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Display the generated QR code image
                    Image(uiImage: setupData.qrCode)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .background(Color.white)
                        .cornerRadius(8)
                        .padding(.vertical, 5)

                    Text("2. Or enter this code manually:")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Text(setupData.secret)
                            .font(.system(.body, design: .monospaced))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)

                        Button(action: {
                            UIPasteboard.general.string = setupData.secret
                            copiedToClipboard = true

                            // Reset the copied status after 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                copiedToClipboard = false
                            }
                        }) {
                            Image(
                                systemName: copiedToClipboard
                                    ? "checkmark.circle.fill" : "doc.on.doc"
                            )
                            .foregroundColor(copiedToClipboard ? .green : .blue)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                        .transition(.opacity)
                        .animation(.easeInOut, value: copiedToClipboard)
                    }

                    Text("3. Enter the verification code from your app")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 10)

                    TextField("000000", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 32, weight: .medium, design: .monospaced))
                        .padding()
                        .frame(height: 70)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($isInputFocused)
                        .onChange(of: verificationCode) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                verificationCode = String(newValue.prefix(6))
                            }
                        }

                    // Error message if any
                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 10)

                Button(action: {
                    Task {
                        await authViewModel.completeMfaSetup(code: verificationCode)
                    }
                }) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Complete Setup")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .disabled(verificationCode.count != 6 || authViewModel.isLoading)
                .opacity((verificationCode.count == 6 && !authViewModel.isLoading) ? 1 : 0.7)

                // Recommended authenticator apps
                VStack(alignment: .leading, spacing: 5) {
                    Text("Recommended authenticator apps:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("• Google Authenticator")
                    Text("• Microsoft Authenticator")
                    Text("• Authy")
                }
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)

            } else {
                VStack {
                    Text("Loading MFA setup...")
                    ProgressView()
                }
                .frame(height: 300)
            }
        }
    }

    private func verifyCode() {
        Task {
            await authViewModel.verifyMfa(code: verificationCode)
        }
    }
}
