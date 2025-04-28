//
//  MemberProfileView.swift
//  lms
//
//  Created by VR on 28/04/25.
//

import SwiftUI

struct MemberProfileView: View {
    let user: User
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 15) {
                        // Profile image
                        if let profileImageUrl = user.profileImageUrl, !profileImageUrl.isEmpty {
                            AsyncImage(url: URL(string: profileImageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundColor(.gray)
                                .frame(width: 80, height: 80)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.fullName)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(
                                "Member since \(user.createdAt.formatted(date: .abbreviated, time: .omitted))"
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 10)
                }

                Section("Account Information") {
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Role", value: user.role.rawValue.capitalized)
                    LabeledContent("Verified", value: user.isVerified ? "Yes" : "No")
                    LabeledContent("MFA Enabled", value: user.mfaEnabled ? "Yes" : "No")
                }

                Section("Reading Statistics") {
                    HStack {
                        VStack {
                            Text("23")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Books Read")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 40)

                        VStack {
                            Text("4")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Currently Reading")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()
                            .frame(height: 40)

                        VStack {
                            Text("2")
                                .font(.title)
                                .fontWeight(.bold)
                            Text("Reserved")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 8)
                }

                Section("Preferences") {
                    NavigationLink {
                        Text("Notification Settings")
                    } label: {
                        Label("Notifications", systemImage: "bell.badge")
                    }

                    NavigationLink {
                        Text("Privacy Settings")
                    } label: {
                        Label("Privacy", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        Text("Reading Preferences")
                    } label: {
                        Label("Reading Preferences", systemImage: "book")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            await authViewModel.logout()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .bold()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MemberProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let mockUser = User(
            id: "preview-id",
            fullName: "Preview User",
            email: "preview@example.com",
            profileImageUrl: nil,
            role: .member,
            isVerified: true,
            mfaEnabled: false,
            preferences: nil,
            createdAt: Date().addingTimeInterval(-60 * 60 * 24 * 90)  // 90 days ago
        )

        MemberProfileView(user: mockUser)
            .environmentObject(AuthViewModel())
    }
}
