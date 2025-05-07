//
//  MainTabView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

struct MainTabView: View {
    let user: User
    @EnvironmentObject var appState: AppState
    @State private var isTabBarVisible = true

    init(user: User) {
        self.user = user

        // Tab bar styling
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        UITabBar.appearance().tintColor = .white
        UITabBar.appearance().unselectedItemTintColor = UIColor.white.withAlphaComponent(0.7)
    }

    var body: some View {
        TabView {
            // Summary
            NavigationStack {
                AdminHomeView(user: user)
                    .navigationTitle("Summary")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "chart.pie")
                Text("Summary")
            }

            // Librarians
            NavigationStack {
                LibrariansTabView()
                    .navigationTitle("Librarians")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "person.text.rectangle")
                Text("Librarians")
            }

            // Members
            NavigationStack {
                MembersTabView()
                    .navigationTitle("Members")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "person.3")
                Text("Members")
            }

            // Library
            NavigationStack {
                LibraryTabView()
                    .navigationTitle("Library")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "books.vertical")
                Text("Library")
            }
        }
        .onAppear {
            TabBarManager.shared.showTabBar()
        }
    }
}
