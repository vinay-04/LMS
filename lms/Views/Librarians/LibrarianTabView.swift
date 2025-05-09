//
//  LibrarianTabView.swift
//  lms
//
//  Created by palak seth on 01/05/25.
//

import SwiftUI

struct LibrarianTabView: View {
    let user: User // Pass the user to the tab view and its child views
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            LibrarianHomeView(user: user)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            // Library Tab - Using the new MVVM implementation
            LibraryView()
                .tabItem {
                    Image(systemName: "books.vertical.fill")
                    Text("Library")
                }
                .tag(1)

            // Reservations Tab (New Implementation)
            BookRequestsView()
                .tabItem {
                    Image(systemName: "list.bullet.clipboard")
                    Text("Reservations")
                }
                .tag(2)
        }
        .accentColor(Color(.systemIndigo)) // Updated to use systemIndigo
    }
}

struct LibrarianTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibrarianTabView(
            user: User(
                id: "preview_id",
                fullName: "Vansh",
                email: "vansh@example.com",
                profileImageUrl: nil,
                role: UserRole.librarian,
                isVerified: true,
                mfaEnabled: false,
                preferences: nil,
                createdAt: Date()
            )
        )
    }
}

extension User {
    static var mockLibrarian: User {
        User(
            id: "librarian_id",
            fullName: "Librarian",
            email: "librarian@example.com",
            profileImageUrl: nil,
            role: .librarian,
            isVerified: true,
            mfaEnabled: false,
            preferences: nil,
            createdAt: Date()
        )
    }
}
