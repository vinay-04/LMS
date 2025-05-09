//
//  BooksDetailView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

struct BooksDetailView: View {
    let book: Book
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Book Cover
                if let coverImage = book.coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 260)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                } else {
                    Image(systemName: "book.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 260)
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .foregroundColor(.gray)
                }
                
                // Book Title and Author
                VStack(spacing: 4) {
                    Text(book.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(book.genre)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                // Book Details
                HStack(spacing: 40) {
                    VStack {
                        Image(systemName: "theatermasks")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Genre")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(book.genre)
                            .font(.subheadline)
                    }
                    
                    VStack {
                        Image(systemName: "globe")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Language")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        Text(book.language)
                            .font(.subheadline)
                    }
                }
                .padding(.vertical)
                
                // Summary Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(book.summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .padding(.vertical)
        }
    }
}

struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BooksDetailView(book: Book(
            title: "One of Us is Lying",
            author: "Karen M. McManus",
            genre: "Mystery",
            language: "English",
            summary: "A thrilling mystery novel about five students who walk into detention, but only four walk out alive. The story follows four high school students who become suspects when their fellow student dies during detention. As the case unfolds, secrets are revealed, and the characters must confront their own truths. The novel is a modern take on the classic whodunit with plenty of twists and turns to keep readers guessing until the very end.",
            coverImage: nil
        ))
    }
}
