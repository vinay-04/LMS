//
//  MemberHomeView.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import SwiftUI

struct MemberHomeVieww: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    let user: User

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Member Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Welcome, \(user.fullName)")
                        .font(.title2)

                    Text("Member since: \(formattedDate(user.createdAt))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Spacer()

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
            }
            .padding()
            .navigationTitle("Library Portal")
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
