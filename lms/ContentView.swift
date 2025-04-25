//
//  ContentView.swift
//  lms
//
//  Created by VR on 24/04/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showOnboarding: Bool = false

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .unauthenticated, .error:
                SignInView()  // Or your auth entry view

            case .authenticating:
                ProgressView("Authenticating...")
                    .progressViewStyle(CircularProgressViewStyle())

            case .mfaRequired:
                // Show MFA verification as a full screen view in the main flow
                mfaVerificationView()
                    .environmentObject(authViewModel)
                    .transition(.opacity)

            case .authenticated(let user):
                VStack {
                    switch user.role {
                    case .admin:
                        AdminHomeView(user: user)
                    case .librarian:
                        LibrarianHomeView(user: user)
                    case .member:
                        MemberHomeView(user: user)
                    }
                }
                .transition(.slide)
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
        .sheet(isPresented: $authViewModel.showOtpSheet) {
            EmailVerificationSheet()
                .environmentObject(authViewModel)
        }
        .fullScreenCover(
            isPresented: $showOnboarding,
            onDismiss: {
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
            }
        ) {
            onboardingView()
        }
        .overlay(
            Group {
                if let successMessage = authViewModel.successMessage {
                    VStack {
                        Spacer()

                        Text(successMessage)
                            .padding()
                            .background(Color.green.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom))
                            .onAppear {
                                // Auto-dismiss after 3 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        authViewModel.successMessage = nil
                                    }
                                }
                            }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut, value: authViewModel.successMessage)
                }
            }
        )
        .onAppear {
            checkIfFirstLaunch()
        }
    }

    private func checkIfFirstLaunch() {
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if !hasCompletedOnboarding {
            showOnboarding = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
