//
//  AdminHomeView.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import SwiftUI

struct AdminHomeView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject private var adminViewModel = AdminViewModel()
    let user: User

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Admin header info
                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome, \(user.fullName)")
                        .font(.title2)

                    Text("Role: \(user.role.description)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                // Admin actions section
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // User management section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("User Management")
                                .font(.headline)
                                .padding(.horizontal)

                            if adminViewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView("Loading users...")
                                    Spacer()
                                }
                                .padding()
                            } else if let error = adminViewModel.error {
                                Text(error)
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
                                ForEach(adminViewModel.users) { user in
                                    UserListItem(
                                        user: user,
                                        onRoleChange: { newRole in
                                            Task {
                                                await adminViewModel.updateUserRole(
                                                    userId: user.id, newRole: newRole)
                                            }
                                        }
                                    )
                                }
                            }

                            // Show error message if exists
                            if let error = adminViewModel.actionError {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }

                            // Success message
                            if let message = adminViewModel.successMessage {
                                Text(message)
                                    .foregroundColor(.green)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }

                Spacer()

                // Logout button
                Button("Logout") {
                    Task {
                        await authViewModel.logout()
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Admin Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await adminViewModel.fetchUsers()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                Task {
                    await adminViewModel.fetchUsers()
                }
            }
        }
    }
}

struct UserListItem: View {
    let user: User
    let onRoleChange: (UserRole) -> Void
    @State private var selectedRole: UserRole

    init(user: User, onRoleChange: @escaping (UserRole) -> Void) {
        self.user = user
        self.onRoleChange = onRoleChange
        self._selectedRole = State(initialValue: user.role)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.fullName)
                        .font(.headline)

                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Status indicators
                HStack(spacing: 5) {
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                    }

                    if user.mfaEnabled {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.blue)
                    }
                }
            }

            // Role selector
            HStack {
                Text("Role:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Picker("", selection: $selectedRole) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        Text(role.description).tag(role)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedRole) { newRole in
                    if newRole != user.role {
                        onRoleChange(newRole)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
