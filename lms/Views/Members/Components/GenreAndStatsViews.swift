//
//  GenreAndStatsViews.swift
//  lms
//
//  Created by VR on 27/04/25.
//

import SwiftUI

struct CollectionStatsView: View {
    let booksRead: Int
    let totalBooks: Int
    var onAddToCollection: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Complete your Collection")
                .font(.title3)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)

            Text("\(booksRead)/\(totalBooks)")
                .font(.title)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)

            Text("Books Read")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)

            Button(action: onAddToCollection) {
                Text("Add to Collection")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(22)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct GenreCardView: View {
    let title: String
    var onTapped: () -> Void

    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .onTapGesture(perform: onTapped)
    }
}
