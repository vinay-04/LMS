import SwiftUI

struct EmailVerificationSheet: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var verificationCode = ""
    @State private var isVerifying = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Image(systemName: "envelope.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 70, height: 70)
                    .foregroundColor(.black)
                    .padding(.top, 30)

                Text("Verify Your Email")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(
                    "We've sent a verification code to your email. Please enter it below to verify your account."
                )
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

                // 6-box code input field
                HStack(spacing: 10) {
                    ForEach(0..<6, id: \.self) { index in
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 45, height: 60)
                            
                            if index < verificationCode.count {
                                Text(String(Array(verificationCode)[index]))
                                    .font(.system(size: 24, weight: .medium))
                            }
                        }
                    }
                }
                .overlay(
                    TextField("", text: $verificationCode)
                        .keyboardType(.numberPad)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .focused($isInputFocused)
                        .onAppear {
                            isInputFocused = true
                        }
                        .onChange(of: verificationCode) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                verificationCode = String(newValue.prefix(6))
                            }
                            
                            // Only allow digits
                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                verificationCode = filtered
                            }
                        }
                )
                .padding(.vertical)

                // Error message if any
                if let error = authViewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // Success message if any
                if let success = authViewModel.successMessage {
                    Text(success)
                        .foregroundColor(.green)
                        .font(.caption)
                }

                // Verify button
                Button(action: verifyCode) {
                    if isVerifying {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        HStack {
                            Text("Verify Email")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                    }
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
                .cornerRadius(12)
                .disabled(verificationCode.count != 6 || isVerifying)
                .opacity((verificationCode.count == 6 && !isVerifying) ? 1 : 0.7)
                .padding(.horizontal)

                // Resend button
                Button(action: resendCode) {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Resend Code")
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                    }
                }
                .padding(.vertical, 10)
                .disabled(authViewModel.isLoading)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Email Verification")
                        .font(.headline)
                }
            }
        }
        .interactiveDismissDisabled()  // Prevent dismissal by dragging down
    }

    private func verifyCode() {
        isVerifying = true

        Task {
            await authViewModel.verifyEmailWithCode(code: verificationCode)

            // Check if verification was successful
            if authViewModel.error == nil {
                // Wait briefly to show success message
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await authViewModel.completeRegistration()
            }

            isVerifying = false
        }
    }

    private func resendCode() {
        Task {
            await authViewModel.verifyEmail()
        }
    }
}


#Preview {
    EmailVerificationSheet()
        .environmentObject(AuthViewModel())
}
