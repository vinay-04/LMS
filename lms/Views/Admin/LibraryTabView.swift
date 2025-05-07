//
//  LibraryTabView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

struct LibraryTabView: View {
    @State private var searchText = ""
    @State private var books: [Book] = []
    @State private var lastDocument: DocumentSnapshot?
    @State private var isLoadingMore = false
    @State private var hasMoreBooks = true
    @State private var showAddBook = false

    private let db = Firestore.firestore()
    private let booksPerPage = 25

    var body: some View {
        ZStack(alignment: .top) {
            // 1) background color
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()

            // 2) decorative gradient at the top
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .ignoresSafeArea(edges: .top)
                Spacer()
            }

            // 3) main content stack
            VStack(spacing: 25) {
                // — Search bar, 30pt below large-title nav bar —
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: $searchText)
                    Image(systemName: "mic.fill")
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 30)

                // — Add New Book button —
                Button {
                    showAddBook = true
                } label: {
                    HStack {
                        Text("Add New Book")
                        Spacer()
                        Image(systemName: "plus.circle")
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 60)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 16)

                // — Book list with pagination —
                List {
                    ForEach(filteredBooks, id: \.isbn) { book in
                        NavigationLink(destination: BooksDetailView(book: book)) {
                            EnhancedBooksRowView(book: book)
                        }
                        .onAppear {
                            if book.isbn == filteredBooks.last?.isbn &&
                               searchText.isEmpty &&
                               hasMoreBooks &&
                               !isLoadingMore {
                                loadMoreBooks()
                            }
                        }
                        .listRowBackground(Color(UIColor.secondarySystemBackground))
                    }

                    if isLoadingMore && searchText.isEmpty {
                        LoadingView()
                            .listRowBackground(Color(UIColor.secondarySystemBackground))
                    }
                }
                .listStyle(.plain)
                // iOS16+: hide default white behind empty list space
                .scrollContentBackground(.hidden)
            }
        }
        // sheet for adding
        .sheet(isPresented: $showAddBook) {
            AddBooksView()
        }
        // initial load
        .onAppear {
            if books.isEmpty {
                fetchInitialBooks()
            }
        }
    }

    // MARK: — Filtering
    private var filteredBooks: [Book] {
        guard !searchText.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.author.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: — Firestore pagination
    private func fetchInitialBooks() {
        isLoadingMore = true
        db.collection("books")
            .limit(to: booksPerPage)
            .getDocuments { snapshot, error in
                isLoadingMore = false
                guard let docs = snapshot?.documents, !docs.isEmpty, error == nil else {
                    hasMoreBooks = false
                    return
                }
                books = docs.compactMap { docToBook(document: $0) }
                lastDocument = docs.last
                hasMoreBooks = docs.count == booksPerPage
            }
    }

    private func loadMoreBooks() {
        guard let last = lastDocument, hasMoreBooks else { return }
        isLoadingMore = true
        db.collection("books")
            .start(afterDocument: last)
            .limit(to: booksPerPage)
            .getDocuments { snapshot, error in
                isLoadingMore = false
                guard let docs = snapshot?.documents, !docs.isEmpty, error == nil else {
                    hasMoreBooks = false
                    return
                }
                let newOnes = docs.compactMap { docToBook(document: $0) }
                books.append(contentsOf: newOnes)
                lastDocument = docs.last
                hasMoreBooks = docs.count == booksPerPage
            }
    }

    // MARK: — Document → Book mapping
    private func docToBook(document: QueryDocumentSnapshot) -> Book? {
        let data = document.data()
        let isbn = data["isbn"] as? String ?? ""
        let title = data["title"] as? String ?? ""
        let author = data["author"] as? String ?? ""
        let genre = data["genre"] as? String ?? ""
        let language = data["language"] as? String ?? ""
        let pages = data["pageCount"] as? Int ?? 0
        let total = data["totalCount"] as? Int ?? 0
        let reserved = data["reservedCount"] as? Int ?? 0
        let unreserved = data["unreservedCount"] as? Int ?? 0

        // build release date
        var releaseDate = Date()
        if let year = data["releaseYear"] as? Int {
            if let date = Calendar.current.date(from: DateComponents(year: year)) {
                releaseDate = date
            }
        } else if let ts = data["dateCreated"] as? Timestamp {
            releaseDate = ts.dateValue()
        }

        // location string
        let loc = data["location"] as? [String:Any] ?? [:]
        let floor = loc["floor"] as? String ?? ""
        let shelf = loc["shelf"] as? String ?? ""
        let locationString = "\(floor), \(shelf)"

        let summary = data["description"] as? String ?? ""
        let imageURLString = data["imageURL"] as? String ?? ""

        // create the Book
        var book = Book(
            isbn: isbn,
            title: title,
            author: author,
            genre: genre,
            releaseDate: releaseDate,
            language: language,
            pages: pages,
            totalCopies: total,
            reservedCount: reserved,
            unreservedCount: unreserved,
            location: locationString,
            summary: summary,
            coverImage: nil
        )

        // async load cover
        if let url = URL(string: imageURLString) {
            DispatchQueue.global(qos: .userInitiated).async {
                if let data = try? Data(contentsOf: url),
                   let img = UIImage(data: data) {
                    DispatchQueue.main.async {
                        if let idx = books.firstIndex(where: { $0.isbn == isbn }) {
                            var updated = books[idx]
                            updated.coverImage = img
                            books[idx] = updated
                        }
                    }
                }
            }
        }
        return book
    }
}
