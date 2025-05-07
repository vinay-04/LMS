//
//  CurrentlyReadingView.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUI

struct CurrentlyReadingView: View {
    let book: LibraryBook
    
    var body: some View {
        if book.issuedCount > 0 {
            HStack(alignment: .top, spacing: 12) {
                BookCoverView(
                    imageURL: book.imageURL,
                    title: book.name,
                    width: 120,
                    height: 180
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.name)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(AppTheme.primaryTextColor)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryTextColor)
                    
                    Text("\(book.releaseYear) • \(book.genre)")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor)
                    
                    HStack {
                        Text("Issued Copies: \(book.issuedCount)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .cornerRadius(4)
                            .foregroundColor(.black)
                        
                        Spacer()
                    }
                }
            }
            .padding(12)
            .background(AppTheme.cardBackgroundColor)
            .cornerRadius(12)
        } else {
            Text("Error: Book is not issued")
        }
    }
}
