//
//  LibraryProgressView.swift
//  LMS_USER
//
//  Created by user@79 on 25/04/25.
//

import SwiftUI

struct LibraryProgressView: View {
    @ObservedObject var bookService: BookService
    let booksRead: Int

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Text("Complete your Collection")
                .font(.headline)
                .foregroundColor(AppTheme.primaryTextColor)
            
            if bookService.isLoading {
                ProgressView()
            } else if let errorMessage = bookService.errorMessage {
                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("\(booksRead)/\(bookService.totalBookCount)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text("Books Read")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor)
            }
            
            Button(action: {
                // Add to collection action
            }) {
                Text("Add to Collection")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(AppTheme.cardBackgroundColor)
        .cornerRadius(12)
        .onAppear {
            bookService.fetchTotalBookCount()
        }
    }
}
