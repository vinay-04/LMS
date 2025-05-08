//
//  AppState.swift
//  lms
//
//  Created by VR on 06/05/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showOnboarding: Bool = false

    var body: some View {
        VStack {
            switch authViewModel.authState {
            case .unauthenticated, .error:
                SignInView()

            case .authenticating:
                ProgressView("Authenticating...")
                    .progressViewStyle(CircularProgressViewStyle())

            case .mfaRequired:
                if let challenge = authViewModel.mfaChallenge {
                    mfaVerificationView()
                        .environmentObject(authViewModel)
                        .transition(.opacity)
                } else {
                    ProgressView("Preparing verification...")
                        .onAppear {
                            authViewModel.authState = .unauthenticated
                        }
                }

            case .authenticated(let user):
                VStack {
                    switch user.role {
                    case .admin:
                        MainTabView(user: user)
                    case .librarian:
                        LibrarianTabView(user: user)
                    case .member:
                        MemberView(user: user)
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

        .fullScreenCover(isPresented: $authViewModel.showMfaSheet) {
            mfaVerificationView()
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
        .environmentObject(AuthViewModel()) // Ensure environmentObject is passed
}
