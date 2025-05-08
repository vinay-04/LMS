//
//  CurrentlyReadingView.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUI
//
//struct CurrentlyReadingView: View {
//    let book: LibraryBook
//    
//    var body: some View {
//        if book.issuedCount > 0 {
//            HStack(alignment: .top, spacing: 12) {
//                BookCoverView(
//                    imageURL: book.imageURL,
//                    title: book.name,
//                    width: 120,
//                    height: 180
//                )
//                
//                VStack(alignment: .leading, spacing: 4) {
//                    Text(book.name)
//                        .font(.headline)
//                        .lineLimit(2)
//                        .foregroundColor(AppTheme.primaryTextColor)
//                    
//                    Text(book.author)
//                        .font(.subheadline)
//                        .foregroundColor(AppTheme.secondaryTextColor)
//                    
//                    Text("\(book.releaseYear) • \(book.genre)")
//                        .font(.caption)
//                        .foregroundColor(AppTheme.secondaryTextColor)
//                    
//                    HStack {
//                        Text("Issued Copies: \(book.issuedCount)")
//                            .font(.caption)
//                            .padding(.horizontal, 8)
//                            .padding(.vertical, 4)
//                            .background(Color.yellow)
//                            .cornerRadius(4)
//                            .foregroundColor(.black)
//                        
//                        Spacer()
//                    }
//                }
//            }
//            .padding(12)
//            .background(AppTheme.cardBackgroundColor)
//            .cornerRadius(12)
//        } else {
//            Text("Error: Book is not issued")
//        }
//    }
//}

struct CurrentlyReadingView: View {
    let book: LibraryBook
    
    var body: some View {
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
                    Text("Currently Reading")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.7))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(AppTheme.cardBackgroundColor)
        .cornerRadius(12)
    }
}
struct CurrentlyReadingSection: View {
    @ObservedObject var bookService: BookService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if bookService.isLoading {
                ProgressView("Loading your books...")
            } else if !bookService.hasIssuedBooks {
                // Don't show anything if there are no issued books
                EmptyView()
            } else if let error = bookService.errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if bookService.currentlyReadingBooks.isEmpty {
                // This case would only happen if we have issued books but failed to fetch them
                Text("Unable to load your currently reading books")
                    .foregroundColor(.orange)
            } else {
                // Header
                Text("Currently Reading")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                // List of currently reading books
                VStack(spacing: 16) {
                    ForEach(bookService.currentlyReadingBooks) { book in
                        CurrentlyReadingView(book: book)
                    }
                }
            }
        }
        .padding(.horizontal)
        .onAppear {
            if bookService.currentlyReadingBooks.isEmpty {
                bookService.fetchCurrentlyReadingBooks()
            }
        }
    }
}
