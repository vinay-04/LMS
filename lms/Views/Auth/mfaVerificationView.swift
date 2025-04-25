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
    @State private var showAppRecommendations = false

    // Colors for consistent theme
    private let primaryColor = Color.black
    private let accentColor = Color.blue
    private let backgroundColor = Color(UIColor.systemBackground)
    private let secondaryBackgroundColor = Color(UIColor.secondarySystemBackground)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    if authViewModel.isMfaSetupRequired {
                        mfaSetupView
                    } else {
                        mfaVerificationView
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(
                        authViewModel.isMfaSetupRequired
                            ? "Two-Factor Setup" : "Two-Factor Authentication"
                    )
                    .font(.headline)
                }

                // Only show logout option for setup, not for regular verification
                if authViewModel.isMfaSetupRequired {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Logout") {
                            Task {
                                await authViewModel.logout()
                            }
                        }
                    }
                }
            }
            .interactiveDismissDisabled(true)  // Prevent dismissal by any means
            .background(backgroundColor)
        }
    }

    // MFA Verification View
    private var mfaVerificationView: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "lock.shield.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundStyle(
                    .linearGradient(
                        colors: [primaryColor, .gray], startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                )
                .padding(.bottom, 5)

            // Title and description
            VStack(spacing: 6) {
                Text("Verification Required")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)

                Text("Enter the code from your authenticator app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // OTP input field - smaller and more elegant
            HStack(spacing: 8) {
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
                    .onAppear { isInputFocused = true }
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

                        // Auto-verify when 6 digits entered
                        if newValue.count == 6 {
                            verifyCode()
                        }
                    }
            )
            .onTapGesture { isInputFocused = true }

            // Error message
            if let error = authViewModel.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.top, -5)
            }

            // Verify button
            Button(action: verifyCode) {
                HStack {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Verify")
                            .fontWeight(.semibold)

                        if verificationCode.count == 6 {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                        }
                    }
                }
                .foregroundColor(.white)
                .frame(height: 24)
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(
                verificationCode.count == 6 && !authViewModel.isLoading ? primaryColor : Color.gray
            )
            .cornerRadius(12)
            .disabled(verificationCode.count != 6 || authViewModel.isLoading)
            .animation(.spring(), value: verificationCode.count == 6)
        }
        .padding(.horizontal)
    }

    // MFA Setup View - Streamlined
    private var mfaSetupView: some View {
        VStack(spacing: 20) {
            if let setupData = authViewModel.mfaSetupData {
                // Icon
                Image(systemName: "shield.lock.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [primaryColor, .gray], startPoint: .topLeading,
                            endPoint: .bottomTrailing))

                // Title and concise description
                Text("Secure Your Account")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(primaryColor)

                Text("Scan this QR code with an authenticator app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                // QR code
                Image(uiImage: setupData.qrCode)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 2)

                // Secret key with copy button
                HStack {
                    Text(setupData.secret)
                        .font(.system(.footnote, design: .monospaced))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(secondaryBackgroundColor)
                        .cornerRadius(6)

                    Button(action: {
                        UIPasteboard.general.string = setupData.secret
                        copiedToClipboard = true

                        // Reset after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedToClipboard = false
                        }
                    }) {
                        Image(
                            systemName: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc"
                        )
                        .foregroundColor(copiedToClipboard ? .green : primaryColor)
                        .padding(8)
                        .background(secondaryBackgroundColor)
                        .cornerRadius(6)
                    }
                }
                .padding(.bottom, 5)

                // Enter verification code text
                Text("Enter the 6-digit code from your app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // OTP input - smaller and consistent with verification view
                HStack(spacing: 8) {
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
                        .onAppear { isInputFocused = true }
                        .onChange(of: verificationCode) { newValue in
                            if newValue.count > 6 {
                                verificationCode = String(newValue.prefix(6))
                            }

                            let filtered = newValue.filter { $0.isNumber }
                            if filtered != newValue {
                                verificationCode = filtered
                            }
                        }
                )
                .onTapGesture { isInputFocused = true }

                // Error message
                if let error = authViewModel.error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }

                // Complete setup button
                Button(action: {
                    Task {
                        await authViewModel.completeMfaSetup(code: verificationCode)
                    }
                }) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Complete Setup")
                                .fontWeight(.semibold)

                            if verificationCode.count == 6 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .frame(height: 24)
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(
                    verificationCode.count == 6 && !authViewModel.isLoading
                        ? primaryColor : Color.gray
                )
                .cornerRadius(12)
                .disabled(verificationCode.count != 6 || authViewModel.isLoading)
                .animation(.spring(), value: verificationCode.count == 6)

                // Collapsible app recommendations
                DisclosureGroup("Recommended apps", isExpanded: $showAppRecommendations) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Google Authenticator")
                        Text("• Microsoft Authenticator")
                        Text("• Authy")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 5)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.top, 5)

            } else {
                VStack {
                    Text("Loading setup...")
                    ProgressView()
                }
                .frame(height: 200)
            }
        }
    }

    private func verifyCode() {
        Task {
            await authViewModel.verifyMfa(code: verificationCode)
        }
    }
}

// Reuse the OTPDigitBox from EmailVerificationSheet
struct OTPDigitBox: View {
    let index: Int
    let verificationCode: String
    let isFocused: Bool

    var body: some View {
        ZStack {
            // Box background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(UIColor.secondarySystemBackground))
                .frame(width: 40, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.black : Color.clear, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)

            // Digit or cursor
            if index < verificationCode.count {
                // Show digit
                Text(String(Array(verificationCode)[index]))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.black)
                    .transition(.scale.combined(with: .opacity))
            } else if isFocused {
                // Show cursor for current position
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 2, height: 20)
                    .opacity(0.6)
                    .blinking(duration: 0.8)
            }
        }
        .animation(.spring(response: 0.2), value: index < verificationCode.count)
    }
}

// Blinking modifier for cursor
extension View {
    func blinking(duration: Double = 1.0) -> some View {
        self.modifier(BlinkingModifier(duration: duration))
    }
}

struct BlinkingModifier: ViewModifier {
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
    mfaVerificationView()
        .environmentObject(AuthViewModel())
}
