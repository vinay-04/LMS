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

    init(user: User) {
        self.user = user

        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = .clear

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }

        UITabBar.appearance().tintColor = .systemIndigo
        UITabBar.appearance().unselectedItemTintColor = UIColor.systemIndigo.withAlphaComponent(0.7)

        UITabBar.appearance().isTranslucent = true
    }

    var body: some View {
        TabView {
            NavigationStack {
                AdminHomeView(user: user)
                    .navigationTitle("Summary")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "chart.pie")
                Text("Summary")
                Color(.indigo)
            }
            

            NavigationStack {
                LibrariansTabView()
                    .navigationTitle("Librarians")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "person.text.rectangle")
                Text("Librarians")
                Color(.indigo)
            }

            NavigationStack {
                MembersTabView()
                    .navigationTitle("Members")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "person.3")
                Text("Members")
                Color(.indigo)
            }

            NavigationStack {
                LibraryTabView()
                    .navigationTitle("Library")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "books.vertical")
                Text("Library")
                Color(.indigo)
            }
        }
        .accentColor(Color(.systemIndigo))
        .onAppear {
            TabBarManager.shared.showTabBar()
        }
    }
}

