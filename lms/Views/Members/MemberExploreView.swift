//
//  MemberExploreView.swift
//  lms
//
//  Created by VR on 28/04/25.
//

import FirebaseFirestore
import SwiftUI

// MARK: - Explore Screen View
struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()
    @State private var searchText = ""
    @State private var selectedGenre: String? = nil

    var filteredBooks: [Book] {
        var result = viewModel.books

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText)
                    || book.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by genre if not "All"
        if let genre = selectedGenre, genre != "All" {
            result = result.filter { $0.genre == genre }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Genre filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(
                                [
                                    "All", "Fiction", "Mystery", "Romance", "Sci-Fi", "Biography",
                                    "History", "Fantasy",
                                ], id: \.self
                            ) { genre in
                                GenreChip(
                                    title: genre,
                                    isSelected: selectedGenre == genre
                                        || (genre == "All" && selectedGenre == nil),
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedGenre = genre == "All" ? nil : genre
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }

                    // All Books
                    VStack(alignment: .leading, spacing: 16) {
                        Text("All Books")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        ForEach(filteredBooks) { book in
                            NavigationLink(destination: BookDetailsView(book: book)) {
                                EnhancedBookRowView(book: book)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Explore")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search books, authors..."
            )
            .background(Color(.systemGroupedBackground))
            .task {
                await viewModel.fetchExploreBooks()
            }
        }
    }
}

// MARK: - Genre Chip
struct GenreChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? .blue : .primary)
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
            .onTapGesture(perform: onTap)
    }
}

// MARK: - Enhanced Row View
struct EnhancedBookRowView: View {
    let book: Book

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Book cover image
            BookCoverImage(url: book.coverImage, width: 80, height: 120)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Text(book.releaseDate ?? "")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)

                    Text(book.genre)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.1))
                        .foregroundColor(.purple)
                        .cornerRadius(4)
                }

                Text(book.summary)
                    .font(.footnote)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 8)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.bottom, 8)
    }
}

// MARK: - Book Cover Image
struct BookCoverImage: View {
    let url: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .empty:
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    ProgressView()
                }
                .frame(width: width, height: height)
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            case .failure:
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    Image(systemName: "book.closed")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
                .frame(width: width, height: height)
            @unknown default:
                EmptyView()
            }
        }
    }
}

// MARK: - ViewModel
@MainActor
class ExploreViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchExploreBooks() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await Firestore.firestore().collection("books").getDocuments()

            print("Found \(snapshot.documents.count) book documents")

            // Parse books with comprehensive field mapping
            let fetchedBooks = snapshot.documents.compactMap { document -> Book? in
                let id = document.documentID
                var data = document.data()

                // Print raw data for debugging
                print("Raw data for book \(id): \(data)")

                // Comprehensive field mapping
                let fieldMappings: [(String, String)] = [
                    ("name", "title"),
                    ("description", "summary"),
                    ("imageURL", "coverImage"),
                    ("year", "releaseDate"),
                    ("numberOfPages", "length"),
                    ("languageCode", "language"),
                    ("publishingHouse", "publisher"),
                    ("isbnCode", "isbn"),
                    ("location", "bookLocation"),
                    ("popularity", "popularityScore"),
                ]

                // Apply all field mappings
                for (sourceField, targetField) in fieldMappings {
                    if data[targetField] == nil && data[sourceField] != nil {
                        data[targetField] = data[sourceField]
                    }
                }

                // Ensure all required fields have at least default values
                let requiredFields = [
                    "isbn": "",
                    "title": "Unknown Title",
                    "author": "Unknown Author",
                    "genre": "Uncategorized",
                    "language": "Unknown",
                    "length": "0 pages",
                    "summary": "No summary available",
                    "publisher": "Unknown Publisher",
                    "availability": "Unknown",
                    "bookLocation": "Unknown",
                    "coverColor": "gray",
                    "coverImage": "https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=600",
                ]

                // Fill in missing required fields with defaults
                for (field, defaultValue) in requiredFields {
                    if data[field] == nil {
                        data[field] = defaultValue
                    }
                }

                // Ensure status field is properly formatted
                if data["status"] == nil {
                    data["status"] = ["type": "available"]
                }

                // Create and return the Book object
                let book = Book(id: id, data: data)

                // Debug log the created book
                print("Parsed book: \(book.title) (ID: \(book.id))")
                print("  Fields: ISBN=\(book.isbn), Author=\(book.author), Genre=\(book.genre)")
                print(
                    "  Length=\(book.length), Language=\(book.language), Publisher=\(book.publisher)"
                )

                return book
            }

            self.books = fetchedBooks
            print("Successfully loaded \(books.count) books")

            // If no books were loaded from Firestore, use mock data
            if books.isEmpty {
                createMockBooks()
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching books: \(error.localizedDescription)")
            // Fall back to mock data
            createMockBooks()
        }
    }

    private func createMockBooks() {
        print("Creating mock books data")

        let mockBooks: [[String: Any]] = [
            [
                "isbn": "9781234567897",
                "title": "The Great Adventure",
                "author": "Jane Smith",
                "genre": "Fiction",
                "releaseDate": "2023",
                "language": "English",
                "length": "320 pages",
                "summary":
                    "A captivating story about adventure and discovery in modern times. Follow the protagonist as they journey through unexpected challenges and personal growth.",
                "publisher": "Penguin Books",
                "availability": "Available",
                "bookLocation": "Floor 2, Section A",
                "coverColor": "blue",
                "coverImage":
                    "https://images.unsplash.com/photo-1544947950-fa07a98d237f?q=80&w=1000&auto=format&fit=crop",
                "status": ["type": "available"],
                "popularityScore": 85,
            ],
            [
                "isbn": "9780987654321",
                "title": "Mystery of the Ages",
                "author": "Robert Johnson",
                "genre": "Mystery",
                "releaseDate": "2022",
                "language": "English",
                "length": "422 pages",
                "summary":
                    "A thrilling mystery that spans centuries and continents. Detective Sarah Blake must uncover ancient secrets before time runs out.",
                "publisher": "HarperCollins",
                "availability": "Available",
                "bookLocation": "Floor 1, Section C",
                "coverColor": "red",
                "coverImage":
                    "https://images.unsplash.com/photo-1543002588-bfa74002ed7e?q=80&w=1000&auto=format&fit=crop",
                "status": ["type": "available"],
                "popularityScore": 92,
            ],
            [
                "isbn": "9780123456789",
                "title": "Science of Tomorrow",
                "author": "Dr. Alice Chen",
                "genre": "Sci-Fi",
                "releaseDate": "2024",
                "language": "English",
                "length": "276 pages",
                "summary":
                    "An exploration of future technology and its impact on society. Dr. Chen presents a fascinating vision of what our world might become in the next century.",
                "publisher": "MIT Press",
                "availability": "Available",
                "bookLocation": "Floor 3, Section B",
                "coverColor": "green",
                "coverImage":
                    "https://images.unsplash.com/photo-1532012197267-da84d127e765?q=80&w=1000&auto=format&fit=crop",
                "status": [
                    "type": "reserved", "reservedBy": "user123",
                    "reservedDate": Timestamp(date: Date()), "timeLeft": "2 days",
                ],
                "popularityScore": 78,
            ],
        ]

        self.books = mockBooks.enumerated().map { index, data in
            Book(id: "mock-\(index)", data: data)
        }

        print("Created \(books.count) mock books")
    }
}

// MARK: - Preview
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
