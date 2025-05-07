//
//  NewReleasesSection.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUI

struct NewReleasesSection: View {
    @ObservedObject var bookService: BookService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("New Releases")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                NavigationLink(destination: AllNewReleasesView(bookService: bookService)) {
                    HStack {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
            }
            
            if bookService.newReleases.isEmpty {
                Text("Loading new releases...")
                    .font(.subheadline)
                    .foregroundColor(Color.gray)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(bookService.newReleases) { book in
                            PopularBookView(book: book)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            bookService.fetchNewReleases(limit: 5)
        }
    }
}
struct AllNewReleasesView: View {
    @ObservedObject var bookService: BookService
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(bookService.newReleases) { book in
                    NewReleaseRow(book: book)
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("New Releases")
        .onAppear {
            bookService.fetchNewReleases()
        }
    }
}

struct NewReleaseRow: View {
    let book: LibraryBook
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            if let imageURL = book.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 70, height: 100)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 100)
                            .clipped()
                    case .failure:
                        Image(systemName: "book.fill")
                            .foregroundColor(.gray)
                            .frame(width: 70, height: 100)
                    @unknown default:
                        EmptyView()
                    }
                }
                .cornerRadius(6)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 70, height: 100)
                    .overlay(
                        Image(systemName: "book.fill")
                            .foregroundColor(.gray)
                    )
                    .cornerRadius(6)
            }
            
            // Book Details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

