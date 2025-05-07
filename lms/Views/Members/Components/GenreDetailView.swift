//
//  GenreDetailView.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUI
import FirebaseFirestore

struct GenreDetailView: View {
    let genre: String
    @StateObject private var viewModel = GenreDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Genre Header
                ZStack(alignment: .bottomLeading) {
                    Image(genre.lowercased() + "_genre")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                    
                    LinearGradient(
                        gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    
                    Text(genre)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                }
                .frame(height: 200)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Books Content
                switch viewModel.state {
                case .loading:
                    ProgressView()
                        .padding(.vertical, 40)
                    
                case .loaded(let books):
                    if books.isEmpty {
                        emptyStateView
                    } else {
                        booksGrid(books: books)
                    }
                    
                case .error(let message):
                    errorView(message: message)
                }
            }
            .padding(.bottom, 20)
        }
        .navigationTitle(genre)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.fetchBooks(for: genre)
        }
    }
    
    private func booksGrid(books: [LibraryBook]) -> some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 160), spacing: 16)],
            spacing: 16
        ) {
            ForEach(books) { book in
                BookCardView(book: book)
            }
        }
        .padding(.horizontal)
    }
    
    private var emptyStateView: some View {
        VStack {
            Image(systemName: "books.vertical")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text("No books found in this genre")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
                .padding(.bottom, 8)
            
            Text("Error loading books")
                .font(.headline)
                .foregroundColor(.red)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 40)
    }
}

// ViewModel for GenreDetailView
class GenreDetailViewModel: ObservableObject {
    enum State {
        case loading
        case loaded([LibraryBook])
        case error(String)
    }
    
    @Published var state: State = .loading
    private let bookService = BookService()
    
    func fetchBooks(for genre: String) {
        state = .loading
        
        bookService.fetchBooksByGenre(genre: genre) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let books):
                    self?.state = .loaded(books)
                case .failure(let error):
                    self?.state = .error(error.localizedDescription)
                }
            }
        }
    }
}

// BookCardView (separate file or in the same file)
struct BookCardView: View {
    let book: LibraryBook
    
    var body: some View {
        NavigationLink(destination: BookDetailView(book: book)) {
            VStack(alignment: .leading, spacing: 8) {
                // Book Cover
                Group {
                    if let imageURL = book.imageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                placeholderCover
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            @unknown default:
                                placeholderCover
                            }
                        }
                    } else {
                        placeholderCover
                    }
                }
                .frame(width: 160, height: 220)
                .cornerRadius(8)
                .clipped()
                .shadow(radius: 4)
                
                // Book Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(book.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(book.author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    HStack {
                        // Availability
                        Text(book.unreservedCount > 0 ? "Available" : "Unavailable")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(book.unreservedCount > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(book.unreservedCount > 0 ? .green : .red)
                            .cornerRadius(4)
                        
                        Spacer()
                        
                        // Rating
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", book.rating))
                                .font(.caption2)
                        }
                    }
                }
                .frame(width: 160)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var placeholderCover: some View {
        ZStack {
            Color(hex: book.coverColor)
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

