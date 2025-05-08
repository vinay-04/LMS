//
//  explore.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

struct LibraryScreen: View {
    @StateObject private var bookService = BookService()
    @State private var selectedTab = 0
    @State private var isGridView = false
    @State private var searchText = ""
    
    private let tabs = ["Logs", "Borrowed", "Reserved", "Wishlist"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Title at the top
                Text("My Collection")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    TextField("Search", text: $searchText)
                        .padding(8)
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Tab selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<tabs.count, id: \.self) { index in
                            Button(action: {
                                selectedTab = index
                            }) {
                                Text(tabs[index])
                                    .font(.system(size: 14))
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .foregroundColor(selectedTab == index ? .white : Color(.systemGray))
                                    .background(
                                        Capsule()
                                            .fill(selectedTab == index ? Color(.systemIndigo) : Color.clear)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // TabView with swipe gesture
                TabView(selection: $selectedTab) {
                    // Tab 0: My Collection
                    bookCollectionView(for: 0)
                        .tag(0)
                    
                    // Tab 1: Borrowed
                    bookCollectionView(for: 1)
                        .tag(1)
                    
                    // Tab 2: Reserved
                    bookCollectionView(for: 2)
                        .tag(2)
                    
                    // Tab 3: Wishlist
                    bookCollectionView(for: 3)
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(AppTheme.backgroundColor)
            .navigationBarHidden(true)
        }
        .onAppear {
            bookService.fetchAllBooks()
            bookService.fetchTotalBookCount()
            loadMockData()
        }
    }
    
    private func bookCollectionView(for tabIndex: Int) -> some View {
        VStack {
            // Collection label and view toggle
            HStack {
                Text(tabs[tabIndex])
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.black))
                
                Spacer()
                
                Button(action: {
                    isGridView = true
                }) {
                    Image(systemName: "square.grid.2x2")
                        .foregroundColor(isGridView ? Color(.systemIndigo) : Color(.systemGray4))
                        .padding(8)
                }
                
                Button(action: {
                    isGridView = false
                }) {
                    Image(systemName: "list.bullet")
                        .foregroundColor(!isGridView ? Color(.systemIndigo) : Color(.systemGray4))
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            // Book listing
            ScrollView {
                if isGridView {
                    // Grid view
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredBooks(for: tabIndex)) { book in
                            NavigationLink(destination: BookDetailView(book: book.book)) {
                                BookGridCell(book: book)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                } else {
                    // List view
                    LazyVStack(spacing: 0) {
                        ForEach(filteredBooks(for: tabIndex)) { book in
                            NavigationLink(destination: BookDetailView(book: book.book)) {
                                BookRow(book: book)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Divider().background(Color(.systemGray6).opacity(0.3))
                        }
                    }
                }
            }
        }
    }
    
    private func filteredBooks(for tabIndex: Int) -> [BookWithStatus] {
        let tabBooks: [BookWithStatus]
        
        switch tabIndex {
        case 0: // My Collection - all books
            tabBooks = mockUserBooks
        case 1: // Borrowed
            tabBooks = mockUserBooks.filter { $0.status == .borrowed }
        case 2: // Reserved
            tabBooks = mockUserBooks.filter { $0.status == .reserved }
        case 3: // Wishlist
            tabBooks = mockUserBooks.filter { $0.status == .wishlist }
        default:
            tabBooks = []
        }
        
        if searchText.isEmpty {
            return tabBooks
        } else {
            return tabBooks.filter { book in
                book.book.name.localizedCaseInsensitiveContains(searchText) ||
                book.book.author.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // Mock data
    @State private var mockUserBooks: [BookWithStatus] = []
    
    private func loadMockData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yy h:mm:ss a"
        
        let borrowedDate = dateFormatter.date(from: "12 Jun 24 1:22:00 AM") ?? Date()
        let returnedDate = dateFormatter.date(from: "15 Jun 24 1:22:00 AM") ?? Date()
        let dueDate = dateFormatter.date(from: "15 Jun 24") ?? Date()
        
        mockUserBooks = [
            BookWithStatus(
                book: LibraryBook(
                    id: "1",
                    name: "The Girl on the Train",
                    isbn: "1234567890",
                    genre: "Thriller",
                    author: "Paula Hawkins",
                    releaseYear: 2015,
                    language: ["English"],
                    dateCreated: Date(),
                    imageURL: nil,
                    rating: 4.2,
                    location: BookLocation(floor: 1, shelf: "A1"),
                    totalCount: 5,
                    unreservedCount: 0,
                    reservedCount: 0,
                    issuedCount: 5,
                    description: "A thriller novel",
                    coverColor: "#678045",
                    pageCount: 320
                ),
                status: .borrowed,
                borrowedDate: borrowedDate,
                dueDate: dueDate,
                returnedDate: nil
            ),
            BookWithStatus(
                book: LibraryBook(
                    id: "2",
                    name: "The Divine Comedy",
                    isbn: "9876543210",
                    genre: "Classic",
                    author: "Dante Alighieri",
                    releaseYear: 1320,
                    language: ["Italian", "English"],
                    dateCreated: Date(),
                    imageURL: nil,
                    rating: 4.5,
                    location: BookLocation(floor: 2, shelf: "B2"),
                    totalCount: 3,
                    unreservedCount: 3,
                    reservedCount: 0,
                    issuedCount: 0,
                    description: "An epic poem",
                    coverColor: "#2C5545",
                    pageCount: 560
                ),
                status: .returned,
                borrowedDate: borrowedDate,
                dueDate: nil,
                returnedDate: returnedDate
            ),
            BookWithStatus(
                book: LibraryBook(
                    id: "3",
                    name: "A Dance with Dragons",
                    isbn: "1234567891",
                    genre: "Fantasy",
                    author: "George R. R. Martin",
                    releaseYear: 2011,
                    language: ["English"],
                    dateCreated: Date(),
                    imageURL: nil,
                    rating: 4.7,
                    location: BookLocation(floor: 1, shelf: "C3"),
                    totalCount: 4,
                    unreservedCount: 1,
                    reservedCount: 1,
                    issuedCount: 2,
                    description: "A fantasy novel",
                    coverColor: "#255C99",
                    pageCount: 1040
                ),
                status: .returned,
                borrowedDate: borrowedDate,
                dueDate: nil,
                returnedDate: returnedDate
            ),
            BookWithStatus(
                book: LibraryBook(
                    id: "4",
                    name: "The Love Hypothesis",
                    isbn: "9876543211",
                    genre: "Romance",
                    author: "Ali Hazelwood",
                    releaseYear: 2021,
                    language: ["English"],
                    dateCreated: Date(),
                    imageURL: nil,
                    rating: 4.3,
                    location: BookLocation(floor: 2, shelf: "D4"),
                    totalCount: 6,
                    unreservedCount: 3,
                    reservedCount: 1,
                    issuedCount: 2,
                    description: "A romance novel",
                    coverColor: "#678045",
                    pageCount: 384
                ),
                status: .wishlist,
                borrowedDate: borrowedDate,
                dueDate: nil,
                returnedDate: nil
            ),
            BookWithStatus(
                book: LibraryBook(
                    id: "5",
                    name: "Project Hail Mary",
                    isbn: "3456789012",
                    genre: "Science Fiction",
                    author: "Andy Weir",
                    releaseYear: 2021,
                    language: ["English"],
                    dateCreated: Date(),
                    imageURL: nil,
                    rating: 4.8,
                    location: BookLocation(floor: 1, shelf: "E5"),
                    totalCount: 4,
                    unreservedCount: 2,
                    reservedCount: 1,
                    issuedCount: 1,
                    description: "A science fiction novel",
                    coverColor: "#345678",
                    pageCount: 496
                ),
                status: .reserved,
                borrowedDate: Date(),
                dueDate: nil,
                returnedDate: nil
            )
        ]
    }
}

// Model to represent book with borrowing status
struct BookWithStatus: Identifiable {
    var id: String { book.id }
    var book: LibraryBook
    var status: BookBorrowStatus
    var borrowedDate: Date
    var dueDate: Date?
    var returnedDate: Date?
    
    enum BookBorrowStatus: String {
        case none
        case borrowed = "Borrowed"
        case returned = "Returned"
        case reserved = "Reserved"
        case wishlist = "Wishlist"
    }
}

struct BookRow: View {
    let book: BookWithStatus
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Book cover image
            ZStack {
                Color(hex: book.book.coverColor)
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
                
                if let imageURL = book.book.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "book.closed")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.7))
                        @unknown default:
                            Image(systemName: "book.closed")
                                .font(.system(size: 30))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(width: 80, height: 120)
                    .cornerRadius(8)
                    .clipped()
                } else {
                    Image(systemName: "book.closed")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(book.book.name)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(book.book.author)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer().frame(height: 8)
                
                // Borrowing information based on status
                switch book.status {
                case .borrowed:
                    Text("Borrowed on: \(formattedDate(book.borrowedDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let dueDate = book.dueDate {
                        Text("Due on: \(formattedShortDate(dueDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                case .returned:
                    Text("Borrowed on: \(formattedDate(book.borrowedDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let returnedDate = book.returnedDate {
                        Text("Returned on: \(formattedDate(returnedDate))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                case .reserved:
                    Text("Reserved on: \(formattedDate(book.borrowedDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                case .wishlist:
                    Text("Added to wishlist on: \(formattedDate(book.borrowedDate))")
                        .font(.caption)
                        .foregroundColor(.gray)
                case .none:
                    Text("None")
                        .foregroundColor(.white)
                    
                }
            }
            
            Spacer()
            
            // Status indicator
            Text(book.status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(statusColor(for: book.status))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor(for: book.status).opacity(0.2))
                .cornerRadius(4)
                .padding(.top, 4)
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }
    
    private func statusColor(for status: BookWithStatus.BookBorrowStatus) -> Color {
        switch status {
        case .borrowed:
            return Color.yellow
        case .returned:
            return Color.green
        case .reserved:
            return Color.blue
        case .wishlist:
            return Color.purple
        case .none:
            return Color.clear
            
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yy • h:mm a"
        return formatter.string(from: date)
    }
    
    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yy"
        return formatter.string(from: date)
    }
}

struct BookGridCell: View {
    let book: BookWithStatus
    
    var body: some View {
        VStack(alignment: .leading) {
            // Book cover
            ZStack {
                Color(hex: book.book.coverColor)
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(8)
                
                Image(systemName: "book.closed")
                    .font(.system(size: 30))
                    .foregroundColor(.white.opacity(0.7))
                
                // Status badge
                VStack {
                    HStack {
                        Spacer()
                        Text(book.status.rawValue)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(statusColor(for: book.status))
                            .cornerRadius(4)
                            .padding(6)
                    }
                    Spacer()
                }
            }
            
            Text(book.book.name)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(.black)
            
            Text(book.book.author)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }
    
    private func statusColor(for status: BookWithStatus.BookBorrowStatus) -> Color {
        switch status {
        case .borrowed:
            return Color.yellow
        case .returned:
            return Color.green
        case .reserved:
            return Color.blue
        case .wishlist:
            return Color.purple
        case .none:
            return Color.clear
        }
    }
}

struct LibraryScreen_Previews: PreviewProvider {
    static var previews: some View {
        LibraryScreen()
    }
}
