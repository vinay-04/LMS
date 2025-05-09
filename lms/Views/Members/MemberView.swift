//
//  MemberView.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUI

struct MemberView: View {
    var user: User // Define a property to accept user
    
    var body: some View {
        TabView {
            MemberHomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            ExploreView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Explore")
                }
                .background(AppTheme.backgroundColor)
            
            LibraryScreen()
                .tabItem {
                    Image(systemName: "square.stack.3d.up")
                    Text("My Collection")
                }
                .background(AppTheme.backgroundColor)
        }
        .accentColor(AppTheme.accentColor)
    }
}
