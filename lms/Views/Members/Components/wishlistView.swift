import SwiftUI

struct WishlistView: View {
    @StateObject private var bookService = BookService()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var bookToRemove: LibraryBook?
    @State private var isPresentingConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if bookService.isLoading {
                    ProgressView("Loading wishlist...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if bookService.wishlistBooks.isEmpty {
                    emptyWishlistView
                } else {
                    wishlistBooksListView
                }
            }
            .navigationTitle("My Wishlist")
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .task {
                bookService.fetchWishlistBooks()
            }
            .refreshable {
                bookService.fetchWishlistBooks()
            }
        }

    }
    
    private var emptyWishlistView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Your wishlist is empty")
                .font(.headline)
            
            Text("Books added to your wishlist will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var wishlistBooksListView: some View {
        List {
            ForEach(bookService.wishlistBooks) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookRowView(book: book)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        bookToRemove = book
                        confirmRemoval(book: book)
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .confirmationDialog(
            "Remove from Wishlist",
            isPresented: .constant(bookToRemove != nil),
            presenting: bookToRemove
        ) { book in
            Button("Remove \"\(book.name)\"", role: .destructive) {
                removeFromWishlist(book: book)
            }
            Button("Cancel", role: .cancel) {
                bookToRemove = nil
            }
        } message: { book in
            Text("Remove \"\(book.name)\" from your wishlist?")
        }
    }

    
    private func confirmRemoval(book: LibraryBook) {
        bookToRemove = book
        
    }

    private func removeFromWishlist(book: LibraryBook) {
        guard let bookToRemove = bookToRemove else { return }
        
        bookService.removeFromWishlist(bookId: bookToRemove.id) { success, errorMessage in
            if success {
                // Refresh the wishlist
                bookService.fetchWishlistBooks()
                alertTitle = "Success"
                alertMessage = "\"\(bookToRemove.name)\" removed from wishlist"
            } else {
                alertTitle = "Error"
                alertMessage = errorMessage ?? "Failed to remove book from wishlist"
            }
            showAlert = true
            self.bookToRemove = nil
        }
    }

}

struct BookRowView: View {
    let book: LibraryBook
    
    var body: some View {
        HStack(spacing: 16) {
            // Book Cover
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(book.coverColor))
                .frame(width: 60, height: 90)
                .overlay(
                    Group {
                        if let imageURL = book.imageURL, !imageURL.isEmpty {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Text(book.name.prefix(1).uppercased())
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(book.genre)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // Rating display
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", book.rating))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

