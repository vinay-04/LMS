//
//  EnhancedBooksRowView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct EnhancedBooksRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 16) {
            if let coverImage = book.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
                    .cornerRadius(8)
                    .overlay(
                        Image(systemName: "book.closed")
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(yearString(from: book.releaseDate)) • \(book.genre)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                let availableCopies = book.unreservedCount
                Text("Available: \(availableCopies) of \(book.totalCopies)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            let availableCopies = book.unreservedCount
            Text(availableCopies > 0 ? "Available" : "Unavailable")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(availableCopies > 0 ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
        }
        .padding(.vertical, 6)
    }
    
    private func yearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
}

struct LoadingView: View {
    var body: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
            Spacer()
        }
        .padding()
    }
}

