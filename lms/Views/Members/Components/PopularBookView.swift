//
//  PopularBookView.swift
//  LMS_USER
//
//  Created by user@79 on 25/04/25.
//

import SwiftUI
struct PopularBookView: View {
    let book: LibraryBook
    
    // UI Constants
    private let cardWidth: CGFloat = 140
    private let cardHeight: CGFloat = 210
    private let cornerRadius: CGFloat = 8
    private let shadowRadius: CGFloat = 6
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Book Cover with Netflix-style shadow and gradient
            ZStack(alignment: .bottomLeading) {
                BookCoverView(
                    imageURL: book.imageURL,
                    title: book.name,
                    width: cardWidth,
                    height: cardHeight
                )
                .cornerRadius(cornerRadius)
                .shadow(color: .black.opacity(0.4), radius: shadowRadius, x: 0, y: 4)
                
                // Bottom gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 60)
                .cornerRadius(cornerRadius)
                
                // Rating badge
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    Text(String(format: "%.1f", book.rating))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
                .padding(8)
            }
            
            // Book title with Netflix-style truncation
            Text(book.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.primaryTextColor)
                .lineLimit(1)
                .frame(width: cardWidth, alignment: .leading)
            
            // Author with secondary color
            Text(book.author)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.secondaryTextColor)
                .lineLimit(1)
                .frame(width: cardWidth, alignment: .leading)
        }
        .frame(width: cardWidth)
    }
}
