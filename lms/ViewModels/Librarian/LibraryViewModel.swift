//
//  LibraryViewModel.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//

import Foundation
import FirebaseFirestore
import Combine

class LibraryViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var books: [LibraryBook] = []
    @Published var searchResults: [LibraryBook] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var existingBook: LibraryBook?
    @Published var showDuplicateAlert = false

    // MARK: - Private Properties
    private let db = Firestore.firestore()
    private let booksCollection = "books"
    private var searchTask: DispatchWorkItem?
    private var lastLoadedDoc: QueryDocumentSnapshot?

    // MARK: - Initialization
    init() {
        print("🔄 LibraryViewModel initialized")
        fetchBooks()
    }

    // MARK: - Public Methods

    /// Fetches initial set of books from Firestore
    func fetchBooks() {
        print("📚 Fetching initial books from Firestore")
        isLoading = true

        db.collection(booksCollection)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("❌ Error fetching books: \(error.localizedDescription)")
                    self.errorMessage = "Error fetching books: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ No books found in database")
                    self.errorMessage = "No books found in database"
                    return
                }

                print("📥 Retrieved \(documents.count) book documents")
                self.books = documents.compactMap { doc in
                    let book = self.decodeBook(
                        from: doc.data(),
                        documentId: doc.documentID
                    )
                    if let book = book {
                        print("📗 Loaded book: \(book.name) (ID: \(book.id))")
                    } else {
                        print("⚠️ Failed to decode book: \(doc.documentID)")
                    }
                    return book
                }
                self.lastLoadedDoc = documents.last
                print("📊 Successfully loaded \(self.books.count) books")
            }
    }

    /// Loads more books for pagination
    func loadMoreBooks() {
        guard let lastDoc = lastLoadedDoc else {
            print("⚠️ No more books to load")
            return
        }

        print("📚 Loading more books after \(lastDoc.documentID)")
        isLoading = true

        db.collection(booksCollection)
            .start(afterDocument: lastDoc)
            .limit(to: 20)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("❌ Error loading more books: \(error.localizedDescription)")
                    self.errorMessage = "Error loading more books: \(error.localizedDescription)"
                    return
                }

                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("⚠️ No more books to load")
                    return
                }

                print("📥 Retrieved \(documents.count) additional documents")
                let newBooks = documents.compactMap { doc in
                    let book = self.decodeBook(
                        from: doc.data(),
                        documentId: doc.documentID
                    )
                    if let book = book {
                        print("📗 Loaded additional book: \(book.name)")
                    }
                    return book
                }
                self.books.append(contentsOf: newBooks)
                self.lastLoadedDoc = documents.last
                print("📊 Total books now: \(self.books.count)")
            }
    }

    /// Searches for books by query text
    func searchBooks(query: String) {
        searchTask?.cancel()

        guard !query.isEmpty else {
            print("🔍 Empty search query")
            isSearching = false
            searchResults = []
            return
        }

        print("🔍 Preparing search for: \(query)")
        isSearching = true

        let task = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            print("🔍 Executing search: \(query)")

            let lowerQuery = query.lowercased()
            let localResults = self.books.filter {
                $0.name.lowercased().contains(lowerQuery) ||
                $0.author.lowercased().contains(lowerQuery) ||
                $0.genre.lowercased().contains(lowerQuery) ||
                $0.isbn.lowercased().contains(lowerQuery)
            }

            if !localResults.isEmpty {
                print("🔍 Found \(localResults.count) local results")
                self.searchResults = localResults
                return
            }

            print("🔍 No local results, querying Firestore")
            self.isLoading = true

            let searchQuery = self.db.collection(self.booksCollection)
                .whereField("name", isGreaterThanOrEqualTo: query)
                .whereField("name", isLessThanOrEqualTo: query + "\\uf8ff")
                .limit(to: 50)

            searchQuery.getDocuments { snapshot, error in
                self.isLoading = false

                if let error = error {
                    print("❌ Search error: \(error.localizedDescription)")
                    self.errorMessage = "Search error: \(error.localizedDescription)"
                    return
                }

                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    print("🔍 No Firestore results, searching author")
                    self.searchByField("author", query: query)
                    return
                }

                print("🔍 Found \(docs.count) Firestore results")
                self.searchResults = docs.compactMap { doc in
                    let book = self.decodeBook(
                        from: doc.data(),
                        documentId: doc.documentID
                    )
                    if let book = book {
                        print("📗 Result: \(book.name) by \(book.author)")
                    }
                    return book
                }
            }
        }

        searchTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    /// Adds a new book to Firestore
    func addBook(_ book: LibraryBook, completion: @escaping (Bool, String) -> Void) {
        print("➕ Adding book: \(book.name) (ID: \(book.id))")

        var data: [String: Any] = [
            "id":               book.id,
            "name":             book.name,
            "isbn":             book.isbn,
            "genre":            book.genre,
            "author":           book.author,
            "releaseYear":      book.releaseYear,
            "language":         book.language,
            "dateCreated":      Timestamp(date: book.dateCreated),
            "rating":           book.rating,
            "location": [
                "floor": book.location.floor,
                "shelf": book.location.shelf
            ],
            "totalCount":       book.totalCount,
            "unreservedCount":  book.unreservedCount,
            "reservedCount":    book.reservedCount,
            "issuedCount":      book.issuedCount,
            "description":      book.description,
            "coverColor":       book.coverColor
        ]

        if let url = book.imageURL {
            print("🖼️ Image URL: \(url)")
            data["imageURL"] = url
        } else {
            print("⚠️ No image URL")
        }

        if let pageCount = book.pageCount {
            data["pageCount"] = pageCount
        }

        db.collection(booksCollection)
            .document(book.id)
            .setData(data) { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Add error: \(error.localizedDescription)")
                    self.errorMessage = "Error adding book: \(error.localizedDescription)"
                    completion(false, book.id)
                    return
                }

                print("✅ Book added with ID: \(book.id)")
                DispatchQueue.main.async {
                    self.books.append(book)
                    completion(true, book.id)
                }
            }
    }

    /// Updates an existing book in Firestore
    func updateBook(_ book: LibraryBook, completion: @escaping (Bool) -> Void) {
        print("✏️ Updating book: \(book.name) (ID: \(book.id))")

        var data: [String: Any] = [
            "name":        book.name,
            "isbn":        book.isbn,
            "genre":       book.genre,
            "author":      book.author,
            "releaseYear": book.releaseYear,
            "location": [
                "floor": book.location.floor,
                "shelf": book.location.shelf
            ],
            "totalCount":  book.totalCount,
            "unreservedCount": book.unreservedCount,
            "description": book.description,
            "coverColor":  book.coverColor
        ]

        if let url = book.imageURL {
            data["imageURL"] = url
        }
        if let pageCount = book.pageCount {
            data["pageCount"] = pageCount
        }

        db.collection(booksCollection)
            .document(book.id)
            .updateData(data) { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Update error: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                print("✅ Book updated: \(book.id)")
                DispatchQueue.main.async {
                    if let i = self.books.firstIndex(where: { $0.id == book.id }) {
                        self.books[i] = book
                        print("📝 Updated local book at index \(i)")
                    }
                    if let j = self.searchResults.firstIndex(where: { $0.id == book.id }) {
                        self.searchResults[j] = book
                        print("📝 Updated search result at index \(j)")
                    }
                    completion(true)
                }
            }
    }

    /// Deletes a book from Firestore
    func deleteBook(_ book: LibraryBook, completion: @escaping (Bool) -> Void) {
        print("🗑️ Deleting book: \(book.name) (ID: \(book.id))")

        db.collection(booksCollection)
            .document(book.id)
            .delete { [weak self] error in
                guard let self = self else { return }

                if let error = error {
                    print("❌ Delete error: \(error.localizedDescription)")
                    completion(false)
                    return
                }

                print("✅ Book deleted: \(book.id)")
                DispatchQueue.main.async {
                    self.books.removeAll { $0.id == book.id }
                    self.searchResults.removeAll { $0.id == book.id }
                    print("🗑️ Removed from local arrays")
                    completion(true)
                }
            }
    }

    /// Fetches a book by ISBN or via Google Books API
    func fetchBookByISBN(isbn: String,
                         completion: @escaping (Bool, LibraryBook?) -> Void) {
        print("📚 Checking ISBN: \(isbn) in Firestore")

        db.collection(booksCollection)
            .whereField("isbn", isEqualTo: isbn)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }

                if let doc = snapshot?.documents.first {
                    print("⚠️ ISBN exists in DB")
                    if let existing = self.decodeBook(
                        from: doc.data(),
                        documentId: doc.documentID
                    ) {
                        DispatchQueue.main.async {
                            self.existingBook = existing
                            self.showDuplicateAlert = true
                        }
                        completion(false, existing)
                        return
                    }
                }

                print("✅ ISBN not in DB, calling Google Books API")
                self.fetchFromGoogleBooks(isbn: isbn, completion: completion)
            }
    }

    // MARK: - Private Methods

    /// Search helper for a given field
    private func searchByField(_ field: String, query: String) {
        print("🔍 Searching by \(field): \(query)")
        isLoading = true

        let q = db.collection(booksCollection)
            .whereField(field, isGreaterThanOrEqualTo: query)
            .whereField(field, isLessThanOrEqualTo: query + "\\uf8ff")
            .limit(to: 50)

        q.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            self.isLoading = false

            if let error = error {
                print("❌ Error in \(field) search: \(error.localizedDescription)")
                return
            }

            guard let docs = snapshot?.documents, !docs.isEmpty else {
                if field == "author" {
                    self.searchByExactField("isbn", query: query)
                }
                return
            }

            print("🔍 Found \(docs.count) results by \(field)")
            self.searchResults = docs.compactMap {
                self.decodeBook(from: $0.data(), documentId: $0.documentID)
            }
        }
    }

    /// Exact match search helper
    private func searchByExactField(_ field: String, query: String) {
        print("🔍 Exact search by \(field): \(query)")
        isLoading = true

        db.collection(booksCollection)
            .whereField(field, isEqualTo: query)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("❌ Exact search error: \(error.localizedDescription)")
                    return
                }

                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    print("🔍 No exact matches for: \(query)")
                    self.searchResults = []
                    return
                }

                print("🔍 Found \(docs.count) exact matches")
                self.searchResults = docs.compactMap {
                    self.decodeBook(from: $0.data(), documentId: $0.documentID)
                }
            }
    }

    /// Decodes a book from Firestore data
    private func decodeBook(from data: [String: Any],
                            documentId: String) -> LibraryBook? {
        guard
            let loc = data["location"] as? [String: Any],
            let floor = loc["floor"] as? Int,
            let shelf = loc["shelf"] as? String
        else {
            print("❌ Missing location for book \(documentId)")
            return nil
        }

        let location = BookLocation(floor: floor, shelf: shelf)

        let dateCreated: Date
        if let ts = data["dateCreated"] as? Timestamp {
            dateCreated = ts.dateValue()
        } else {
            print("⚠️ Missing dateCreated, using now for \(documentId)")
            dateCreated = Date()
        }

        return LibraryBook(
            id:            documentId,
            name:          data["name"] as? String ?? "Unknown",
            isbn:          data["isbn"] as? String ?? "N/A",
            genre:         data["genre"] as? String ?? "Uncategorized",
            author:        data["author"] as? String ?? "Unknown",
            releaseYear:   data["releaseYear"] as? Int
                          ?? Calendar.current.component(.year, from: Date()),
            language:      data["language"] as? [String] ?? ["en"],
            dateCreated:   dateCreated,
            imageURL:      data["imageURL"] as? String,
            rating:        data["rating"] as? Double ?? 0.0,
            location:      location,
            totalCount:    data["totalCount"] as? Int ?? 0,
            unreservedCount: data["unreservedCount"] as? Int ?? 0,
            reservedCount: data["reservedCount"] as? Int ?? 0,
            issuedCount:   data["issuedCount"] as? Int ?? 0,
            description:   data["description"] as? String
                           ?? "No description available",
            coverColor:    data["coverColor"] as? String ?? "blue",
            pageCount:     data["pageCount"] as? Int
        )
    }

    /// Fetch book data from Google Books API
    private func fetchFromGoogleBooks(
        isbn: String,
        completion: @escaping (Bool, LibraryBook?) -> Void
    ) {
        let apiKey = "AIzaSyDyRn1CTEsqli-r_Bg2hvSWy2XeVND9hnc"
        let urlString =
            "https://www.googleapis.com/books/v1/volumes?q=isbn:\(isbn)&key=\(apiKey)"
        print("🌐 Google Books API URL: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ Invalid API URL")
            completion(false, nil)
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("❌ Network error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            if let http = response as? HTTPURLResponse {
                print("📡 API response status: \(http.statusCode)")
            }

            guard let data = data else {
                print("❌ No data from API")
                DispatchQueue.main.async {
                    completion(false, nil)
                }
                return
            }

            print("📦 Received \(data.count) bytes from API")

            do {
                guard
                    let json = try JSONSerialization
                                .jsonObject(with: data) as? [String: Any],
                    let totalItems = json["totalItems"] as? Int,
                    totalItems > 0,
                    let items = json["items"] as? [[String: Any]],
                    let volume = items.first?["volumeInfo"] as? [String: Any]
                else {
                    print("⚠️ No books found for ISBN \(isbn)")
                    DispatchQueue.main.async {
                        completion(false, nil)
                    }
                    return
                }

                print("📕 Parsing API book data")

                let title = volume["title"] as? String ?? "Unknown Title"
                let authors = volume["authors"] as? [String] ?? ["Unknown Author"]
                let description =
                    volume["description"] as? String
                    ?? "No description available"
                let publishedDate =
                    volume["publishedDate"] as? String ?? ""
                let categories =
                    volume["categories"] as? [String] ?? ["Uncategorized"]

                var year = Calendar.current.component(.year, from: Date())
                if publishedDate.count >= 4,
                   let py = Int(publishedDate.prefix(4)) {
                    year = py
                }

                // Image selection
                var imageURL: String?
                if let links = volume["imageLinks"] as? [String: Any] {
                    print("🖼️ Image links found")
                    if let xl = links["extraLarge"] as? String {
                        imageURL = xl
                    } else if let l = links["large"] as? String {
                        imageURL = l
                    } else if let m = links["medium"] as? String {
                        imageURL = m
                    } else if let s = links["small"] as? String {
                        imageURL = s
                    } else if let t = links["thumbnail"] as? String {
                        imageURL = t
                    } else if let st = links["smallThumbnail"] as? String {
                        imageURL = st
                    }
                    if let url = imageURL, url.hasPrefix("http:") {
                        imageURL = "https:" + url.dropFirst(5)
                        print("🔒 Converted image URL to HTTPS")
                    }
                } else {
                    print("⚠️ No image links in API data")
                }

                let bookId = UUID().uuidString
                print("🆔 Generated UUID: \(bookId)")

                let location = BookLocation(floor: 1, shelf: "A1")
                let language = [volume["language"] as? String ?? "en"]
                let rating = volume["averageRating"] as? Double ?? 4.0
                let pageCount = volume["pageCount"] as? Int

                let newBook = LibraryBook(
                    id:            bookId,
                    name:          title,
                    isbn:          isbn,
                    genre:         categories.first ?? "Uncategorized",
                    author:        authors.joined(separator: ", "),
                    releaseYear:   year,
                    language:      language,
                    dateCreated:   Date(),
                    imageURL:      imageURL,
                    rating:        rating,
                    location:      location,
                    totalCount:    1,
                    unreservedCount: 1,
                    reservedCount: 0,
                    issuedCount:   0,
                    description:   description,
                    coverColor:    "blue",
                    pageCount:     pageCount
                )

                print("✅ Created LibraryBook from API")
                DispatchQueue.main.async {
                    completion(true, newBook)
                }
            } catch {
                print("❌ JSON parse error: \(error.localizedDescription)")
                if let resp = String(data: data, encoding: .utf8) {
                    print("📄 Raw response (200 chars): \(String(resp.prefix(200)))…")
                }
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
        .resume()
    }
}

