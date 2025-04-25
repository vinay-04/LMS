//
//  EmailVerificationSheet.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import SwiftUI

struct EmailVerificationSheet: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var verificationCode = ""
    @State private var isVerifying = false
    @FocusState private var isInputFocused: Bool

    // Timer states
    @State private var resendCooldown: Int = 15
    @State private var isResendAvailable: Bool = false
    @State private var timer: Timer? = nil

    private let primaryColor = Color.black
    private let accentColor = Color.blue
    private let backgroundColor = Color(UIColor.systemBackground)
    private let secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)

    var body: some View {
        NavigationStack {
            VStack(spacing: 25) {
                Image(systemName: "envelope.badge.shield.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.black, .gray], startPoint: .topLeading,
                            endPoint: .bottomTrailing)
                    )
                    .padding(.top, 30)
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)

                Text("Verify Your Email")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(primaryColor)

                Text(
                    "We've sent a verification code to your email. Please enter the 6-digit code to verify your account."
                )
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPDigitBox(
                            index: index,
                            verificationCode: verificationCode,
                            isFocused: isInputFocused && index == verificationCode.count
                        )
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

                .onTapGesture {
                    isInputFocused = true
                }

                Group {
                    if let error = authViewModel.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(error)
                                .foregroundColor(.red)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }

                    if let success = authViewModel.successMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(success)
                                .foregroundColor(.green)
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                    }
                }
                .frame(height: 20)
                .padding(.vertical, 8)

                Button(action: verifyCode) {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Verify Email")
                                .fontWeight(.semibold)

                            if verificationCode.count == 6 {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 18))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(height: 24)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    verificationCode.count == 6 && !isVerifying
                        ? primaryColor
                        : Color.gray
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
                .disabled(verificationCode.count != 6 || isVerifying)
                .animation(.spring(), value: verificationCode.count == 6)
                .padding(.horizontal)

                Button(action: resendCode) {
                    HStack(spacing: 8) {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else if !isResendAvailable {
                            Image(systemName: "clock.fill")
                            Text("Resend in \(resendCooldown)s")
                                .fontWeight(.medium)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Resend Code")
                                .fontWeight(.medium)
                        }
                    }
                    .foregroundColor(isResendAvailable ? primaryColor : Color.gray)
                }
                .padding(.vertical, 10)
                .disabled(!isResendAvailable || authViewModel.isLoading)

                Spacer()
            }
            .padding()
            .background(backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Email Verification")
                        .font(.headline)
                        .foregroundColor(primaryColor)
                }
            }
            .onAppear {
                startResendTimer()
            }
            .onDisappear {
                stopResendTimer()
            }
        }
        .interactiveDismissDisabled()  // Prevent dismissal by dragging down
    }

    private func verifyCode() {
        isVerifying = true

        Task {
            await authViewModel.verifyOtpAndCompleteRegistration(code: verificationCode)

            if authViewModel.error == nil {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await authViewModel.completeRegistration()
            }

            isVerifying = false
        }
    }

    private func resendCode() {
        Task {
            await authViewModel.verifyEmail()

            startResendTimer()
        }
    }

    private func startResendTimer() {
        // Reset states
        resendCooldown = 15
        isResendAvailable = false

        // Cancel any existing timer
        stopResendTimer()

        // Create a new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                isResendAvailable = true
                stopResendTimer()
            }
        }
    }

    private func stopResendTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct EmailOTPDigitBox: View {
    let index: Int
    let verificationCode: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            // Box background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
                .frame(width: 50, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.black : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

            // Digit or cursor
            if index < verificationCode.count {
                // Show digit
                Text(String(Array(verificationCode)[index]))
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.black)
                    .transition(.scale.combined(with: .opacity))
            } else if isFocused {
                // Show cursor for current position
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 24)
                    .opacity(0.6)
                    .blinking(duration: 0.8)
            }
        }
        .animation(.spring(response: 0.2), value: index < verificationCode.count)
    }
}

// Blinking modifier for cursor
extension View {
    func emailBlinking(duration: Double = 1.0) -> some View {
        self.modifier(EmailBlinkingModifier(duration: duration))
    }
}

struct EmailBlinkingModifier: ViewModifier {
    let duration: Double
    @State private var isVisible: Bool = true

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever()) {
                    isVisible.toggle()
                }
            }
    }
}

#Preview {
    EmailVerificationSheet()
        .environmentObject(AuthViewModel())
}
