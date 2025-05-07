//
//  ReservedBookView.swift
//  LMS_USER
//
//  Created by user@79 on 25/04/25.
//

import SwiftUI

struct ReservedBookView: View {
    let book: LibraryBook
    
    var body: some View {
        if book.reservedCount > 0 {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Book Reserved")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor)
                    
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
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Reserved Copies")
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryTextColor)
                    
                    Text("\(book.reservedCount)")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryTextColor)
                }
            }
            .padding(12)
            .background(AppTheme.cardBackgroundColor)
            .cornerRadius(12)
        } else {
            Text("Error: Book is not reserved")
        }
    }
}
