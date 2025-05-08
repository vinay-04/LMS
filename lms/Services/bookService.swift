import SwiftUI
import Combine
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage


class BookService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var newReleases = [LibraryBook]()
    @Published var allBooks = [LibraryBook]()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isReserving = false
    @Published var reservationSuccess = false
    @Published var totalBookCount: Int = 0
    @Published var currentlyReadingBooks = [LibraryBook]()
    @Published var hasIssuedBooks = false
    @Published var reservedBooks = [LibraryBook]()
    @Published var hasReservedBooks = false
    @Published var historyBookCount: Int = 0
    @Published var isLoadingHistory = false
    @Published var historyErrorMessage: String?
    @Published var wishlistBooks = [LibraryBook]()
    @Published var hasWishlistBooks = false
    @Published var isAddingToWishlist = false
    @Published var isRemovingFromWishlist = false
    @Published var popularBooks = [LibraryBook]()
    @Published var wishlistOperationSuccess = false
    @Published var historyBooks = [BookWithStatus]()
    
    
    func fetchNewReleases(limit: Int = 5) {
        isLoading = true
        errorMessage = nil

        let calendar = Calendar.current
        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()

        let query = db.collection("books")
            .whereField("dateCreated", isGreaterThan: Timestamp(date: tenDaysAgo))
            .order(by: "dateCreated", descending: true)
            .limit(to: limit)

        fetchBooks(from: query) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            switch result {
            case .success(let books):
                self.newReleases = books
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Fetch books by genre, trying server-side sorting first and falling back to client-side if needed.
    func fetchBooksByGenre(genre: String,
                           completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
        // First try with server-side sorting
        let sortedQuery = db.collection("books")
            .whereField("genre", isEqualTo: genre)
            .order(by: "name")

        sortedQuery.getDocuments { [weak self] snapshot, error in
            if let error = error as NSError?, error.code == 9 {
                // If index error occurs, fall back to client-side sorting
                self?.fetchBooksByGenreWithoutSorting(genre: genre, completion: completion)
            } else if let error = error {
                completion(.failure(error))
            } else {
                self?.handleBookDocuments(snapshot: snapshot, completion: completion)
            }
        }
    }

    /// Internal helper to decode documents into `LibraryBook`.
    private func handleBookDocuments(snapshot: QuerySnapshot?,
                                     completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
        guard let documents = snapshot?.documents else {
            completion(.success([]))
            return
        }

        let books = documents.compactMap { document -> LibraryBook? in
            do {
                return try document.data(as: LibraryBook.self)
            } catch {
                print("Error decoding book: \(error.localizedDescription)")
                return nil
            }
        }

        completion(.success(books))
    }

    /// Fetch top-rated books.
    func fetchPopularBooks(limit: Int = 3,
                           completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
        let query = db.collection("books")
            .order(by: "rating", descending: true)
            .limit(to: limit)

        fetchBooks(from: query, completion: completion)
    }

    /// Fetch all popular books.
    func fetchAllPopularBooks(completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
        let query = db.collection("books")
            .order(by: "rating", descending: true)

        fetchBooks(from: query, completion: completion)
    }

    /// Fetch a page of all books, limited to 50.
    func fetchAllBooks() {
        isLoading = true
        errorMessage = nil

        let query = db.collection("books")
            .order(by: "name")
            .limit(to: 50)

        fetchBooks(from: query) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false

            switch result {
            case .success(let books):
                self.allBooks = books
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                print("Error fetching all books: \(error.localizedDescription)")
            }
        }
    }

    /// Client-side sorting fallback for `fetchBooksByGenre`.
    private func fetchBooksByGenreWithoutSorting(genre: String,
                                                 completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
        let query = db.collection("books")
            .whereField("genre", isEqualTo: genre)

        query.getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self?.handleBookDocuments(snapshot: snapshot) { result in
                switch result {
                case .success(let books):
                    completion(.success(books.sorted { $0.name < $1.name }))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Fetch total count of books via aggregation.
    func fetchTotalBookCount() {
        let query = db.collection("books")
        let countQuery = query.count

        countQuery.getAggregation(source: .server) { [weak self] (result, error) in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Failed to fetch total book count: \(error.localizedDescription)"
                print("Error: \(error.localizedDescription)")
            } else if let count = result?.count {
                self.totalBookCount = Int(truncating: count)
            }
        }
    }

    /// Internal helper to fetch and decode books from any query.
    private func fetchBooks(from query: Query,
                            completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
        query.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }

            let books = documents.compactMap { document -> LibraryBook? in
                let data = document.data()
                guard
                    let name = data["name"] as? String,
                    let isbn = data["isbn"] as? String,
                    let genre = data["genre"] as? String,
                    let author = data["author"] as? String,
                    let releaseYear = data["releaseYear"] as? Int,
                    let language = data["language"] as? [String],
                    let timestamp = data["dateCreated"] as? Timestamp,
                    let rating = data["rating"] as? Double,
                    let totalCount = data["totalCount"] as? Int,
                    let unreservedCount = data["unreservedCount"] as? Int,
                    let reservedCount = data["reservedCount"] as? Int,
                    let issuedCount = data["issuedCount"] as? Int,
                    let description = data["description"] as? String,
                    let coverColor = data["coverColor"] as? String,
                    let locationDict = data["location"] as? [String: Any],
                    let floor = locationDict["floor"] as? Int,
                    let shelf = locationDict["shelf"] as? String
                else {
                    print("Missing fields in document \(document.documentID)")
                    return nil
                }

                let imageURL = data["imageURL"] as? String
                let pageCount = data["pageCount"] as? Int

                return LibraryBook(
                    id: document.documentID,
                    name: name,
                    isbn: isbn,
                    genre: genre,
                    author: author,
                    releaseYear: releaseYear,
                    language: language,
                    dateCreated: timestamp.dateValue(),
                    imageURL: imageURL,
                    rating: rating,
                    location: BookLocation(floor: floor, shelf: shelf),
                    totalCount: totalCount,
                    unreservedCount: unreservedCount,
                    reservedCount: reservedCount,
                    issuedCount: issuedCount,
                    description: description,
                    coverColor: coverColor,
                    pageCount: pageCount
                )
            }

            completion(.success(books))
        }
    }

    /// Request creation of a composite index for books by genre and name.
    func createGenreIndexIfNeeded(genre: String) {
        let docRef = db.collection("index_operations").document()

        docRef.setData([
            "type": "create_index",
            "collection": "books",
            "fields": ["genre", "name"],
            "status": "requested",
            "createdAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error requesting index creation: \(error.localizedDescription)")
            }
        }
    }
    
    /// Fetches the count of books in the logged-in user's history.
    func fetchUserHistoryBookCount() {
        isLoadingHistory = true
        historyErrorMessage = nil
        
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            isLoadingHistory = false
            historyErrorMessage = "Please log in to fetch history"
            historyBookCount = 0
            return
        }
        
        // Path to the user's history collection
        let historyRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("history")
        
        // Get count of documents in the history collection
        historyRef.getDocuments { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            self.isLoadingHistory = false
            
            if let error = error {
                self.historyErrorMessage = "Failed to fetch history: \(error.localizedDescription)"
                print("Error fetching history: \(error.localizedDescription)")
                self.historyBookCount = 0
                return
            }
            
            // Count is the number of documents in the collection
            if let documents = snapshot?.documents {
                self.historyBookCount = documents.count
                print("Found \(self.historyBookCount) books in user history")
            } else {
                self.historyBookCount = 0
            }
        }
    }

    func fetchPopularBooks(limit: Int = 20) {
        isLoading = true
        errorMessage = nil
        
        let query = db.collection("books")
            .order(by: "rating", descending: true)
            .limit(to: limit)
        
        fetchBooks(from: query) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let books):
                self.popularBooks = books
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                print("Error fetching popular books: \(error.localizedDescription)")
            }
        }
    }
    
    func reserveBook(bookId: String, completion: @escaping (Bool, String?) -> Void) {
        self.isReserving = true
        self.errorMessage = nil

        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            self.isReserving = false
            self.errorMessage = "Please log in to reserve a book"
            completion(false, self.errorMessage)
            return
        }

        let bookRef = db.collection("books").document(bookId)
        let userRequestedBookRef = db.collection("members").document(userId)
                .collection("requested").document(bookId)

        bookRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }

            if let error = error {
                self.isReserving = false
                self.errorMessage = "Failed to fetch book: \(error.localizedDescription)"
                completion(false, self.errorMessage)
                return
            }

            guard let document = document, document.exists, let bookData = document.data() else {
                self.isReserving = false
                self.errorMessage = "Book not found"
                completion(false, self.errorMessage)
                return
            }

            if let unreservedCount = bookData["unreservedCount"] as? Int, unreservedCount <= 0 {
                self.isReserving = false
                self.errorMessage = "This book is not available for reservation"
                completion(false, self.errorMessage)
                return
            }

            let reservationData: [String: Any] = [
                "bookUUID": bookId,
                "requestedTimestamp": Timestamp(date: Date()),
                "userId": userId
            ]

            // Store in user-specific path
            let userRequestedBookRef = self.db.collection("members").document(userId)
                .collection("userbooks").document("collection")
                .collection("requested").document(bookId)

            let batch = self.db.batch()

            batch.setData(reservationData, forDocument: userRequestedBookRef)

            batch.updateData([
                "reservedCount": FieldValue.increment(Int64(1)),
                "unreservedCount": FieldValue.increment(Int64(-1))
            ], forDocument: bookRef)

            batch.commit { error in
                self.isReserving = false

                if let error = error {
                    self.errorMessage = "Failed to reserve book: \(error.localizedDescription)"
                    completion(false, self.errorMessage)
                    return
                }

                self.reservationSuccess = true
                completion(true, nil)
            }
        }
    }
    func fetchUserReservedBooks(completion: @escaping (Result<[BookRequest], Error>) -> Void) {
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            completion(.failure(NSError(
                domain: "BookService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No logged in user found"]
            )))
            return
        }
        
        let requestsRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("requested")
        
        requestsRef.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let requests = snapshot?.documents.compactMap {
                BookRequest.fromFirestore(document: $0, userID: userId)
            } ?? []
            
            // Fetch book details for each request
            let group = DispatchGroup()
            var enrichedRequests: [BookRequest] = []
            
            for var request in requests {
                group.enter()
                
                self.db.collection("books").document(request.bookID).getDocument { (doc, err) in
                    defer { group.leave() }
                    
                    if let doc = doc, doc.exists, let data = doc.data() {
                        request.bookName = data["name"] as? String
                        request.bookImageURL = data["imageURL"] as? String
                        enrichedRequests.append(request)
                    } else {
                        enrichedRequests.append(request)
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion(.success(enrichedRequests))
            }
        }
    }

    // MARK: - New method to fetch user's reading history

    func fetchUserReadingHistory(completion: @escaping (Result<[BookRequest], Error>) -> Void) {
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            completion(.failure(NSError(
                domain: "BookService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No logged in user found"]
            )))
            return
        }
        
        let historyRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("history")
        
        historyRef.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let history = snapshot?.documents.compactMap {
                BookRequest.fromFirestore(document: $0, userID: userId)
            } ?? []
            
            completion(.success(history))
        }
    }
    
    func fetchHistoryBooks() {
        isLoadingHistory = true
        historyErrorMessage = nil
        historyBooks = []
        
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            isLoadingHistory = false
            historyErrorMessage = "Please log in to fetch history"
            historyBookCount = 0
            return
        }
        // Path to the user's history collection
        let historyRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("history")
        
        historyRef.getDocuments(source: .default) { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoadingHistory = false
                self.historyErrorMessage = "Failed to fetch history books: \(error.localizedDescription)"
                print("Error fetching history books: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                // No history books found
                self.isLoadingHistory = false
                self.historyBooks = []
                return
            }
            
            // Use a dispatch group to wait for all book fetches to complete
            let dispatchGroup = DispatchGroup()
            var fetchedBooksWithStatus = [BookWithStatus]()
            var fetchErrors = [String]()
            
            for document in documents {
                let data = document.data()
                guard let bookUUID = data["bookUUID"] as? String else {
                    print("Missing bookUUID in document \(document.documentID)")
                    continue
                }
                
                // Extract timestamp data
                let borrowedTimestamp = data["borrowedTimestamp"] as? Timestamp
                let returnedTimestamp = data["returnedTimestamp"] as? Timestamp
                let dueDateTimestamp = data["dueTimestamp"] as? Timestamp
                
                dispatchGroup.enter()
                // Fetch the book details using the UUID
                self.fetchBookById(bookUUID) { result in
                    switch result {
                    case .success(let book):
                        if let book = book {
                            // Create BookWithStatus object with extracted timestamps
                            let bookWithStatus = BookWithStatus(
                                book: book,
                                status: .returned,
                                borrowedDate: borrowedTimestamp?.dateValue() ?? Date(),  // Provide default Date if nil
                                dueDate: dueDateTimestamp?.dateValue(),                  // Keep as optional
                                returnedDate: returnedTimestamp?.dateValue() ?? Date()   // Provide default Date if nil
                            )
                            fetchedBooksWithStatus.append(bookWithStatus)
                        } else {
                            print("Book with UUID \(bookUUID) not found in books collection")
                        }
                    case .failure(let error):
                        fetchErrors.append("Failed to fetch book \(bookUUID): \(error.localizedDescription)")
                        print("Error fetching book \(bookUUID): \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isLoadingHistory = false
                
                if !fetchErrors.isEmpty {
                    self.historyErrorMessage = fetchErrors.joined(separator: "\n")
                }
                
                // Sort by return date (most recent first)
                self.historyBooks = fetchedBooksWithStatus.sorted { (book1, book2) -> Bool in
                    // If both have return dates, sort by most recent first
                    if let date1 = book1.returnedDate, let date2 = book2.returnedDate {
                        return date1 > date2
                    }
                    // If only one has a return date, prioritize the one without
                    else if book1.returnedDate == nil {
                        return true
                    }
                    else if book2.returnedDate == nil {
                        return false
                    }
                    // If neither has a return date, sort by book name
                    else {
                        return book1.book.name < book2.book.name
                    }
                }
                
                print("Successfully loaded \(self.historyBooks.count) history books")
            }
        }
    }
    
    

    private func fetchBookById(_ bookId: String, completion: @escaping (Result<LibraryBook?, Error>) -> Void) {
        let bookRef = db.collection("books").document(bookId)
        
        bookRef.getDocument(source: .default) { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.success(nil))
                return
            }
            
            let data = document.data()
            
            guard
                let name = data?["name"] as? String,
                let isbn = data?["isbn"] as? String,
                let genre = data?["genre"] as? String,
                let author = data?["author"] as? String,
                let releaseYear = data?["releaseYear"] as? Int,
                let language = data?["language"] as? [String],
                let timestamp = data?["dateCreated"] as? Timestamp,
                let rating = data?["rating"] as? Double,
                let totalCount = data?["totalCount"] as? Int,
                let unreservedCount = data?["unreservedCount"] as? Int,
                let reservedCount = data?["reservedCount"] as? Int,
                let issuedCount = data?["issuedCount"] as? Int,
                let description = data?["description"] as? String,
                let coverColor = data?["coverColor"] as? String,
                let locationDict = data?["location"] as? [String: Any],
                let floor = locationDict["floor"] as? Int,
                let shelf = locationDict["shelf"] as? String
            else {
                print("Missing fields in book document \(document.documentID)")
                completion(.success(nil))
                return
            }
            
            let imageURL = data?["imageURL"] as? String
            let pageCount = data?["pageCount"] as? Int
            
            let book = LibraryBook(
                id: document.documentID,
                name: name,
                isbn: isbn,
                genre: genre,
                author: author,
                releaseYear: releaseYear,
                language: language,
                dateCreated: timestamp.dateValue(),
                imageURL: imageURL,
                rating: rating,
                location: BookLocation(floor: floor, shelf: shelf),
                totalCount: totalCount,
                unreservedCount: unreservedCount,
                reservedCount: reservedCount,
                issuedCount: issuedCount,
                description: description,
                coverColor: coverColor,
                pageCount: pageCount
            )
            
            completion(.success(book))
        }
    }
    func fetchReservedBooks() {
        isLoading = true
        errorMessage = nil
        
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            isLoading = false
            errorMessage = "Please log in to fetch reserved books"
            hasReservedBooks = false
            reservedBooks = []
            return
        }
        
        // Path to the user's requested books
        let requestedBooksRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("requested")
        
        requestedBooksRef.getDocuments(source: .default) { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Failed to fetch reserved books: \(error.localizedDescription)"
                print("Error fetching reserved books: \(error.localizedDescription)")
                self.hasReservedBooks = false
                self.reservedBooks = []
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                // No reserved books found
                self.isLoading = false
                self.reservedBooks = []
                self.hasReservedBooks = false
                return
            }
            
            // Set flag that user has reserved books
            self.hasReservedBooks = true
            
            // Use a dispatch group to wait for all book fetches to complete
            let dispatchGroup = DispatchGroup()
            var fetchedBooks = [LibraryBook]()
            var fetchErrors = [String]()
            
            for document in documents {
                guard let bookUUID = document.data()["bookUUID"] as? String else {
                    print("Missing bookUUID in document \(document.documentID)")
                    continue
                }
                
                dispatchGroup.enter()
                self.fetchBookById(bookUUID) { result in
                    switch result {
                    case .success(let book):
                        if let book = book {
                            fetchedBooks.append(book)
                        }
                    case .failure(let error):
                        fetchErrors.append("Failed to fetch book \(bookUUID): \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isLoading = false
                if !fetchErrors.isEmpty {
                    self.errorMessage = fetchErrors.joined(separator: "\n")
                }
                self.reservedBooks = fetchedBooks
            }
        }
    }
    
    func fetchCurrentlyReadingBooks() {
        isLoading = true
        errorMessage = nil
        
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            isLoading = false
            errorMessage = "Please log in to fetch currently reading books"
            hasIssuedBooks = false
            currentlyReadingBooks = []
            return
        }
        
        // Path to the user's issued books
        let issuedBooksRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("issued")
        
        issuedBooksRef.getDocuments(source: .default) { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Failed to fetch issued books: \(error.localizedDescription)"
                print("Error fetching issued books: \(error.localizedDescription)")
                self.hasIssuedBooks = false
                self.currentlyReadingBooks = []
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                // No issued books found
                self.isLoading = false
                self.currentlyReadingBooks = []
                self.hasIssuedBooks = false
                return
            }
            
            // Set flag that user has issued books
            self.hasIssuedBooks = true
            
            // Use a dispatch group to wait for all book fetches to complete
            let dispatchGroup = DispatchGroup()
            var fetchedBooks = [LibraryBook]()
            var fetchErrors = [String]()
            
            for document in documents {
                guard let bookUUID = document.data()["bookUUID"] as? String else {
                    print("Missing bookUUID in document \(document.documentID)")
                    continue
                }
                
                dispatchGroup.enter()
                self.fetchBookById(bookUUID) { result in
                    switch result {
                    case .success(let book):
                        if let book = book {
                            fetchedBooks.append(book)
                        }
                    case .failure(let error):
                        fetchErrors.append("Failed to fetch book \(bookUUID): \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isLoading = false
                if !fetchErrors.isEmpty {
                    self.errorMessage = fetchErrors.joined(separator: "\n")
                }
                self.currentlyReadingBooks = fetchedBooks
            }
        }
    }
    
    
    
    func fetchWishlistBooks() {
        isLoading = true
        errorMessage = nil
        
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            isLoadingHistory = false
            historyErrorMessage = "Please log in to fetch history"
            historyBookCount = 0
            return
        }
        // Path to the user's wishlist
        let wishlistRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("wishlist")
        
        wishlistRef.getDocuments(source: .default) { [weak self] (snapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Failed to fetch wishlist: \(error.localizedDescription)"
                print("Error fetching wishlist: \(error.localizedDescription)")
                self.hasWishlistBooks = false
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                // No wishlist books found
                self.isLoading = false
                self.wishlistBooks = []
                self.hasWishlistBooks = false
                return
            }
            
            // Set flag that user has wishlist books
            self.hasWishlistBooks = true
            
            // Use a dispatch group to wait for all book fetches to complete
            let dispatchGroup = DispatchGroup()
            var fetchedBooks = [LibraryBook]()
            var fetchErrors = [String]()
            
            for document in documents {
                guard let bookUUID = document.data()["bookUUID"] as? String else {
                    print("Missing bookUUID in document \(document.documentID)")
                    continue
                }
                
                dispatchGroup.enter()
                self.fetchBookById(bookUUID) { result in
                    switch result {
                    case .success(let book):
                        if let book = book {
                            fetchedBooks.append(book)
                        }
                    case .failure(let error):
                        fetchErrors.append("Failed to fetch book \(bookUUID): \(error.localizedDescription)")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.isLoading = false
                if !fetchErrors.isEmpty {
                    self.errorMessage = fetchErrors.joined(separator: "\n")
                }
                self.wishlistBooks = fetchedBooks.sorted(by: { $0.name < $1.name })
            }
        }
    }

    /// Checks if a book is in the logged-in user's wishlist.
    func checkIfBookInWishlist(bookId: String, completion: @escaping (Bool) -> Void) {
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            print("Error: User not logged in")
            completion(false)
            return
        }
        
        let wishlistBookRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("wishlist").document(bookId)
        
        wishlistBookRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking wishlist status: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(document?.exists ?? false)
        }
    }

    /// Adds a book to the logged-in user's wishlist.
    func addToWishlist(bookId: String, completion: @escaping (Bool, String?) -> Void) {
        self.isAddingToWishlist = true
        self.errorMessage = nil
        
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            self.isAddingToWishlist = false
            self.errorMessage = "Please log in to add to wishlist"
            completion(false, self.errorMessage)
            return
        }
        
        // First check if book is already in wishlist
        checkIfBookInWishlist(bookId: bookId) { [weak self] isInWishlist in
            guard let self = self else { return }
            
            if isInWishlist {
                self.isAddingToWishlist = false
                completion(true, nil) // Already in wishlist, consider this a success
                return
            }
            
            let wishlistData: [String: Any] = [
                "bookUUID": bookId,
                "addedTimestamp": Timestamp(date: Date()),
                "userId": userId
            ]
            
            let wishlistBookRef = self.db.collection("members").document(userId)
                .collection("userbooks").document("collection")
                .collection("wishlist").document(bookId)
            
            wishlistBookRef.setData(wishlistData) { error in
                self.isAddingToWishlist = false
                
                if let error = error {
                    self.errorMessage = "Failed to add book to wishlist: \(error.localizedDescription)"
                    completion(false, self.errorMessage)
                    return
                }
                
                self.wishlistOperationSuccess = true
                completion(true, nil)
            }
        }
    }

    /// Removes a book from the logged-in user's wishlist.
    func removeFromWishlist(bookId: String, completion: @escaping (Bool, String?) -> Void) {
        self.isRemovingFromWishlist = true
        self.errorMessage = nil
        
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            self.isRemovingFromWishlist = false
            self.errorMessage = "Please log in to remove from wishlist"
            completion(false, self.errorMessage)
            return
        }
        
        let wishlistBookRef = self.db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("wishlist").document(bookId)
        
        wishlistBookRef.delete { [weak self] error in
            guard let self = self else { return }
            self.isRemovingFromWishlist = false
            
            if let error = error {
                self.errorMessage = "Failed to remove book from wishlist: \(error.localizedDescription)"
                completion(false, self.errorMessage)
                return
            }
            
            self.wishlistOperationSuccess = true
            completion(true, nil)
        }
    }
}

