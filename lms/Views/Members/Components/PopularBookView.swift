import SwiftUI

struct PopularBookView: View {
    let book: LibraryBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            BookCoverView(
                imageURL: book.imageURL,
                title: book.name,
                width: 120,
                height: 180,
            )
            
            Text(book.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
                .foregroundColor(AppTheme.primaryTextColor)
            
            Text(book.author)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryTextColor)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}
struct AllPopularBooksView: View {
    @ObservedObject var bookService: BookService
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                ForEach(bookService.popularBooks) { book in
                    VStack(alignment: .leading, spacing: 4) {
                        BookCoverView(
                            imageURL: book.imageURL,
                            title: book.name,
                            width: 160,
                            height: 220
                        )
                        
                        Text(book.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundColor(AppTheme.primaryTextColor)
                        
                        Text(book.author)
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryTextColor)
                            .lineLimit(1)
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            
                            Text(String(format: "%.1f", book.rating))
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryTextColor)
                        }
                    }
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
            }
            .padding()
        }
        .background(AppTheme.backgroundColor)
        .navigationTitle("Popular Books")
        .onAppear {
            if bookService.popularBooks.isEmpty {
                bookService.fetchPopularBooks()
            }
        }
    }
}
struct PopularBooksSection: View {
    @ObservedObject var bookService: BookService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Popular Books")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.darkGray))
                
                Spacer()
                
                NavigationLink(destination: AllPopularBooksView(bookService: bookService)) {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accentColor)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(AppTheme.accentColor)
                }
            }
            
            if bookService.isLoading && bookService.popularBooks.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 40)
            } else if let error = bookService.errorMessage, bookService.popularBooks.isEmpty {
                Text("Failed to load popular books: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
            } else if bookService.popularBooks.isEmpty {
                Text("No popular books found")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(bookService.popularBooks.prefix(5))) { book in
                            PopularBookView(book: book)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }
}
//import SwiftUI
//struct PopularBookView: View {
//    let book: LibraryBook
//    
//    // UI Constants
//    private let cardWidth: CGFloat = 140
//    private let cardHeight: CGFloat = 210
//    private let cornerRadius: CGFloat = 8
//    private let shadowRadius: CGFloat = 6
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            // Book Cover with Netflix-style shadow and gradient
//            ZStack(alignment: .bottomLeading) {
//                BookCoverView(
//                    imageURL: book.imageURL,
//                    title: book.name,
//                    width: cardWidth,
//                    height: cardHeight
//                )
//                .cornerRadius(cornerRadius)
//                .shadow(color: .black.opacity(0.4), radius: shadowRadius, x: 0, y: 4)
//                
//                // Bottom gradient overlay
//                LinearGradient(
//                    gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .frame(height: 60)
//                .cornerRadius(cornerRadius)
//                
//                // Rating badge
//                HStack(spacing: 2) {
//                    Image(systemName: "star.fill")
//                        .font(.caption2)
//                        .foregroundColor(.yellow)
//                    Text(String(format: "%.1f", book.rating))
//                        .font(.caption2)
//                        .fontWeight(.bold)
//                        .foregroundColor(.white)
//                }
//                .padding(.horizontal, 6)
//                .padding(.vertical, 3)
//                .background(Color.black.opacity(0.7))
//                .cornerRadius(4)
//                .padding(8)
//            }
//            
//            // Book title with Netflix-style truncation
//            Text(book.name)
//                .font(.system(size: 14, weight: .semibold))
//                .foregroundColor(AppTheme.primaryTextColor)
//                .lineLimit(1)
//                .frame(width: cardWidth, alignment: .leading)
//            
//            // Author with secondary color
//            Text(book.author)
//                .font(.system(size: 12))
//                .foregroundColor(AppTheme.secondaryTextColor)
//                .lineLimit(1)
//                .frame(width: cardWidth, alignment: .leading)
//        }
//        .frame(width: cardWidth)
//    }
//}
