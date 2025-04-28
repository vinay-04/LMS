//
//  TabBarView.swift
//  lms
//
//  Created by VR on 27/04/25.
//

import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Int

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", text: "Home", isSelected: selectedTab == 0)
                .onTapGesture { selectedTab = 0 }

            TabBarItem(icon: "magnifyingglass", text: "Explore", isSelected: selectedTab == 1)
                .onTapGesture { selectedTab = 1 }

            TabBarItem(icon: "books.vertical.fill", text: "Library", isSelected: selectedTab == 2)
                .onTapGesture { selectedTab = 2 }
        }
        .padding(.top, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(.systemGray5)),
            alignment: .top
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let text: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 24))
            Text(text)
                .font(.caption)
        }
        .foregroundColor(isSelected ? .blue : .gray)
        .frame(maxWidth: .infinity)
    }
}
