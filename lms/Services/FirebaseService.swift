import SwiftUI
import Combine
import Firebase
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

// MARK: - Unified FirebaseService

final class FirebaseService {
    static let shared = FirebaseService()

    let db: Firestore
    private let storage: Storage
    private var isConfigured = false
    // Keep track of the current user ID
    private var currentUserId: String?
    
    private init() {
        // Configure Firebase if needed
        if FirebaseApp.app() == nil {
            print("Firebase: Configuring Firebase app")
            FirebaseApp.configure()
            isConfigured = true
        } else {
            print("Firebase: App already configured")
            isConfigured = true
        }

        db = Firestore.firestore()
        storage = Storage.storage()
        print("Firebase: Firestore initialized - Collection path: users")

        // Test connection on startup
        Task {
            await testFirebaseConnection()
        }
    }
    // Set the current user ID when a user logs in
    func setCurrentUser(_ userId: String) {
        self.currentUserId = userId
        print("Firebase: Set current user ID to \(userId)")
    }
    
    // Clear the current user ID when a user logs out
    func clearCurrentUser() {
        self.currentUserId = nil
        print("Firebase: Cleared current user ID")
    }
    
    // Get the current user ID
    func getCurrentUserId() -> String? {
        return currentUserId
    }

    // MARK: — Connection Test

    func testFirebaseConnection() async {
        print("Firebase: Testing connection...")
        do {
            _ = try await db.collection("_test_connection").document("test").getDocument()
            print("Firebase: Connection successful! Firebase is properly configured.")
        } catch {
            print("Firebase: ⚠️ CONNECTION ERROR - \(error.localizedDescription)")
            print("Firebase: Please check your GoogleService-Info.plist and internet connection")
        }
    }
    
    @MainActor
    func createUser(userId: String, userData: [String: Any]) async {
        print("Firebase: Attempting to create user with ID: \(userId)")
        print("Firebase: Data being sent: \(userData)")
        do {
            try await db.collection("members").document(userId).setData(userData)
            print("Firebase: ✅ User created successfully with ID: \(userId)")
            
            // Set as current user after creation
            setCurrentUser(userId)
        } catch {
            print("Firebase: ❌ Error creating user: \(error.localizedDescription)")
            print("Firebase: Error details: \(error)")
        }
    }

    @MainActor
    func updateUser(userId: String, userData: [String: Any]) async {
        print("Firebase: Attempting to update user with ID: \(userId)")
        print("Firebase: Update data: \(userData)")
        do {
            try await db.collection("members").document(userId).updateData(userData)
            print("Firebase: ✅ User updated successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error updating user: \(error.localizedDescription)")
            print("Firebase: Error details: \(error)")
        }
    }

    func getUser(userId: String) async -> [String: Any]? {
        print("Firebase: Attempting to get user with ID: \(userId)")
        do {
            let document = try await db.collection("members").document(userId).getDocument()
            if document.exists, let data = document.data() {
                print("Firebase: ✅ User document retrieved: \(data)")
                return data
            } else {
                print("Firebase: User document doesn't exist")
                return nil
            }
        } catch {
            print("Firebase: ❌ Error getting user: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteUser(userId: String) async {
        print("Firebase: Attempting to delete user with ID: \(userId)")
        do {
            try await db.collection("members").document(userId).delete()
            print("Firebase: ✅ User deleted successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error deleting user: \(error.localizedDescription)")
        }
    }

    func listUsers() async -> [[String: Any]] {
        print("Firebase: Attempting to list all users")
        do {
            let querySnapshot = try await db.collection("members").getDocuments()
            let users = querySnapshot.documents.compactMap { $0.data() }
            print("Firebase: ✅ Retrieved \(users.count) users")
            return users
        } catch {
            print("Firebase: ❌ Error listing users: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: — Member Profiles

    /// Create (or overwrite) a member document in the "members" collection.
    func createMemberProfile(_ member: Member,
                             completion: @escaping (Result<Void, Error>) -> Void)
    {
        guard let uid = member.id else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Member ID missing"]
            )))
        }

        do {
            try db.collection("members")
                  .document(uid)
                  .setData(from: member) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    /// Fetch a member document from the "members" collection.
    func fetchMemberProfile(uid: String,
                            completion: @escaping (Result<Member, Error>) -> Void)
    {
        db.collection("members").document(uid)
          .getDocument { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let snapshot = snapshot,
                  snapshot.exists,
                  let member = try? snapshot.data(as: Member.self)
            else {
                return completion(.failure(NSError(
                    domain: "FirebaseService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Member not found"]
                )))
            }
            completion(.success(member))
        }
    }

    /// Fetch all member documents from the "members" collection.
    func fetchAllMembers(completion: @escaping (Result<[Member], Error>) -> Void) {
        db.collection("members")
          .getDocuments { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            let members: [Member] = snapshot?.documents.compactMap {
                try? $0.data(as: Member.self)
            } ?? []
            completion(.success(members))
        }
    }

    // MARK: - User-specific Collections
    
    // Generic function to create a document in a user's subcollection
    func createUserDocument<T: Encodable>(
        userId: String? = nil,
        collection: String,
        subcollection: String? = nil,
        documentId: String? = nil,
        data: T,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Use provided userId or fall back to currentUserId
        guard let uid = userId ?? currentUserId else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user ID available"]
            )))
        }
        
        let docId = documentId ?? UUID().uuidString
        
        do {
            var docRef: DocumentReference
            
            if let subcollection = subcollection {
                // Create in subcollection
                docRef = db.collection("members").document(uid)
                         .collection(collection).document(subcollection)
                         .collection("items").document(docId)
            } else {
                // Create directly in collection
                docRef = db.collection("members").document(uid)
                         .collection(collection).document(docId)
            }
            
            try docRef.setData(from: data) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(docId))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // Generic function to fetch documents from a user's collection
    func fetchUserDocuments<T: Decodable>(
        userId: String? = nil,
        collection: String,
        subcollection: String? = nil,
        limit: Int? = nil,
        completion: @escaping (Result<[T], Error>) -> Void
    ) {
        // Use provided userId or fall back to currentUserId
        guard let uid = userId ?? currentUserId else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user ID available"]
            )))
        }
        
        var query: Query
        
        if let subcollection = subcollection {
            // Query from subcollection
            query = db.collection("members").document(uid)
                     .collection(collection).document(subcollection)
                     .collection("items")
        } else {
            // Query directly from collection
            query = db.collection("members").document(uid)
                     .collection(collection)
        }
        
        if let limit = limit {
            query = query.limit(to: limit)
        }
        
        query.getDocuments { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            
            let documents: [T] = snapshot?.documents.compactMap {
                try? $0.data(as: T.self)
            } ?? []
            
            completion(.success(documents))
        }
    }
    
    // MARK: - Book-specific methods
    
    // Add book to user's favorites
    func addBookToFavorites(userId: String? = nil, bookId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let uid = userId ?? currentUserId else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user ID available"]
            )))
        }
        
        let data: [String: Any] = [
            "bookId": bookId,
            "addedAt": Timestamp(date: Date())
        ]
        
        db.collection("members").document(uid)
          .collection("favorites").document(bookId)
          .setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Get user's favorite books
    func getFavoriteBooks(userId: String? = nil, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let uid = userId ?? currentUserId else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user ID available"]
            )))
        }
        
        db.collection("members").document(uid)
          .collection("favorites").getDocuments { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            
            let bookIds = snapshot?.documents.map { $0.documentID } ?? []
            completion(.success(bookIds))
        }
    }
    
    // Request a book for the current user
    func requestBook(bookId: String, bookData: BookRequest, completion: @escaping (Result<String, Error>) -> Void) {
        guard let uid = currentUserId else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user ID available"]
            )))
        }
        
        do {
            // Create request in user's requests collection
            let requestRef = db.collection("members").document(uid)
                .collection("userbooks").document("collection")
                .collection("requested").document(bookId)
            
            let requestData: [String: Any] = [
                "bookUUID": bookId,
                "requestedTimestamp": Timestamp(date: Date()),
                "userId": uid
            ]
            
            requestRef.setData(requestData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // Update book counts in main books collection
                    self.db.collection("books").document(bookId).updateData([
                        "reservedCount": FieldValue.increment(Int64(1)),
                        "unreservedCount": FieldValue.increment(Int64(-1))
                    ]) { updateError in
                        if let updateError = updateError {
                            completion(.failure(updateError))
                        } else {
                            completion(.success(bookId))
                        }
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // Get user's requested books
    func getRequestedBooks(completion: @escaping (Result<[BookRequest], Error>) -> Void) {
        guard let uid = currentUserId else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No user ID available"]
            )))
        }
        
        let requestsRef = db.collection("members").document(uid)
            .collection("userbooks").document("collection")
            .collection("requested")
        
        requestsRef.getDocuments { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            
            let requests = snapshot?.documents.compactMap {
                BookRequest.fromFirestore(document: $0, userID: uid)
            } ?? []
            
            completion(.success(requests))
        }
    }

}
//class BookService: ObservableObject {
//    private let db = Firestore.firestore()
//    @Published var newReleases = [LibraryBook]()
//    @Published var allBooks = [LibraryBook]()
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//    @Published var isReserving = false
//    @Published var reservationSuccess = false
//    @Published var totalBookCount: Int = 0
//    /// Fetch books created in the last `limit` days, ordered by creation date.
//    func fetchNewReleases(limit: Int = 5) {
//        isLoading = true
//        errorMessage = nil
//
//        let calendar = Calendar.current
//        let tenDaysAgo = calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()
//
//        let query = db.collection("books")
//            .whereField("dateCreated", isGreaterThan: Timestamp(date: tenDaysAgo))
//            .order(by: "dateCreated", descending: true)
//            .limit(to: limit)
//
//        fetchBooks(from: query) { [weak self] result in
//            guard let self = self else { return }
//            self.isLoading = false
//
//            switch result {
//            case .success(let books):
//                self.newReleases = books
//            case .failure(let error):
//                self.errorMessage = error.localizedDescription
//            }
//        }
//    }
//
//    /// Fetch books by genre, trying server-side sorting first and falling back to client-side if needed.
//    func fetchBooksByGenre(genre: String,
//                           completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
//        // First try with server-side sorting
//        let sortedQuery = db.collection("books")
//            .whereField("genre", isEqualTo: genre)
//            .order(by: "name")
//
//        sortedQuery.getDocuments { [weak self] snapshot, error in
//            if let error = error as NSError?, error.code == 9 {
//                // If index error occurs, fall back to client-side sorting
//                self?.fetchBooksByGenreWithoutSorting(genre: genre, completion: completion)
//            } else if let error = error {
//                completion(.failure(error))
//            } else {
//                self?.handleBookDocuments(snapshot: snapshot, completion: completion)
//            }
//        }
//    }
//
//    /// Internal helper to decode documents into `LibraryBook`.
//    private func handleBookDocuments(snapshot: QuerySnapshot?,
//                                     completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
//        guard let documents = snapshot?.documents else {
//            completion(.success([]))
//            return
//        }
//
//        let books = documents.compactMap { document -> LibraryBook? in
//            do {
//                return try document.data(as: LibraryBook.self)
//            } catch {
//                print("Error decoding book: \(error.localizedDescription)")
//                return nil
//            }
//        }
//
//        completion(.success(books))
//    }
//
//    /// Fetch top-rated books.
//    func fetchPopularBooks(limit: Int = 3,
//                           completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
//        let query = db.collection("books")
//            .order(by: "rating", descending: true)
//            .limit(to: limit)
//
//        fetchBooks(from: query, completion: completion)
//    }
//
//    /// Fetch all popular books.
//    func fetchAllPopularBooks(completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
//        let query = db.collection("books")
//            .order(by: "rating", descending: true)
//
//        fetchBooks(from: query, completion: completion)
//    }
//
//    /// Fetch a page of all books, limited to 50.
//    func fetchAllBooks() {
//        isLoading = true
//        errorMessage = nil
//
//        let query = db.collection("books")
//            .order(by: "name")
//            .limit(to: 50)
//
//        fetchBooks(from: query) { [weak self] result in
//            guard let self = self else { return }
//            self.isLoading = false
//
//            switch result {
//            case .success(let books):
//                self.allBooks = books
//            case .failure(let error):
//                self.errorMessage = error.localizedDescription
//                print("Error fetching all books: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    /// Client-side sorting fallback for `fetchBooksByGenre`.
//    private func fetchBooksByGenreWithoutSorting(genre: String,
//                                                 completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
//        let query = db.collection("books")
//            .whereField("genre", isEqualTo: genre)
//
//        query.getDocuments { [weak self] snapshot, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            self?.handleBookDocuments(snapshot: snapshot) { result in
//                switch result {
//                case .success(let books):
//                    completion(.success(books.sorted { $0.name < $1.name }))
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
//        }
//    }
//
//    /// Fetch total count of books via aggregation.
//    func fetchTotalBookCount() {
//        let query = db.collection("books")
//        let countQuery = query.count
//
//        countQuery.getAggregation(source: .server) { [weak self] (result, error) in
//            guard let self = self else { return }
//
//            if let error = error {
//                self.errorMessage = "Failed to fetch total book count: \(error.localizedDescription)"
//                print("Error: \(error.localizedDescription)")
//            } else if let count = result?.count {
//                self.totalBookCount = Int(truncating: count)
//            }
//        }
//    }
//
//    /// Internal helper to fetch and decode books from any query.
//    private func fetchBooks(from query: Query,
//                            completion: @escaping (Result<[LibraryBook], Error>) -> Void) {
//        query.getDocuments { (snapshot, error) in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let documents = snapshot?.documents else {
//                completion(.success([]))
//                return
//            }
//
//            let books = documents.compactMap { document -> LibraryBook? in
//                let data = document.data()
//                guard
//                    let name = data["name"] as? String,
//                    let isbn = data["isbn"] as? String,
//                    let genre = data["genre"] as? String,
//                    let author = data["author"] as? String,
//                    let releaseYear = data["releaseYear"] as? Int,
//                    let language = data["language"] as? [String],
//                    let timestamp = data["dateCreated"] as? Timestamp,
//                    let rating = data["rating"] as? Double,
//                    let totalCount = data["totalCount"] as? Int,
//                    let unreservedCount = data["unreservedCount"] as? Int,
//                    let reservedCount = data["reservedCount"] as? Int,
//                    let issuedCount = data["issuedCount"] as? Int,
//                    let description = data["description"] as? String,
//                    let coverColor = data["coverColor"] as? String,
//                    let locationDict = data["location"] as? [String: Any],
//                    let floor = locationDict["floor"] as? Int,
//                    let shelf = locationDict["shelf"] as? String
//                else {
//                    print("Missing fields in document \(document.documentID)")
//                    return nil
//                }
//
//                let imageURL = data["imageURL"] as? String
//                let pageCount = data["pageCount"] as? Int
//
//                return LibraryBook(
//                    id: document.documentID,
//                    name: name,
//                    isbn: isbn,
//                    genre: genre,
//                    author: author,
//                    releaseYear: releaseYear,
//                    language: language,
//                    dateCreated: timestamp.dateValue(),
//                    imageURL: imageURL,
//                    rating: rating,
//                    location: BookLocation(floor: floor, shelf: shelf),
//                    totalCount: totalCount,
//                    unreservedCount: unreservedCount,
//                    reservedCount: reservedCount,
//                    issuedCount: issuedCount,
//                    description: description,
//                    coverColor: coverColor,
//                    pageCount: pageCount
//                )
//            }
//
//            completion(.success(books))
//        }
//    }
//
//    /// Request creation of a composite index for books by genre and name.
//    func createGenreIndexIfNeeded(genre: String) {
//        let docRef = db.collection("index_operations").document()
//
//        docRef.setData([
//            "type": "create_index",
//            "collection": "books",
//            "fields": ["genre", "name"],
//            "status": "requested",
//            "createdAt": FieldValue.serverTimestamp()
//        ]) { error in
//            if let error = error {
//                print("Error requesting index creation: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    /// Reserve one copy of a book and record the reservation under the member.
//    func reserveBook(bookId: String, completion: @escaping (Bool, String?) -> Void) {
//        self.isReserving = true
//        self.errorMessage = nil
//
//        // Get the current user ID from Firebase Service
//        guard let userId = FirebaseService.shared.getCurrentUserId() else {
//            self.isReserving = false
//            self.errorMessage = "Please log in to reserve a book"
//            completion(false, self.errorMessage)
//            return
//        }
//
//        let bookRef = db.collection("books").document(bookId)
//        let userRequestedBookRef = db.collection("members").document(userId)
//                .collection("requested").document(bookId)
//
//        bookRef.getDocument { [weak self] (document, error) in
//            guard let self = self else { return }
//
//            if let error = error {
//                self.isReserving = false
//                self.errorMessage = "Failed to fetch book: \(error.localizedDescription)"
//                completion(false, self.errorMessage)
//                return
//            }
//
//            guard let document = document, document.exists, let bookData = document.data() else {
//                self.isReserving = false
//                self.errorMessage = "Book not found"
//                completion(false, self.errorMessage)
//                return
//            }
//
//            if let unreservedCount = bookData["unreservedCount"] as? Int, unreservedCount <= 0 {
//                self.isReserving = false
//                self.errorMessage = "This book is not available for reservation"
//                completion(false, self.errorMessage)
//                return
//            }
//
//            let reservationData: [String: Any] = [
//                "bookUUID": bookId,
//                "requestedTimestamp": Timestamp(date: Date()),
//                "userId": userId
//            ]
//
//            // Store in user-specific path
//            let userRequestedBookRef = self.db.collection("members").document(userId)
//                .collection("userbooks").document("collection")
//                .collection("requested").document(bookId)
//
//            let batch = self.db.batch()
//
//            batch.setData(reservationData, forDocument: userRequestedBookRef)
//
//            batch.updateData([
//                "reservedCount": FieldValue.increment(Int64(1)),
//                "unreservedCount": FieldValue.increment(Int64(-1))
//            ], forDocument: bookRef)
//
//            batch.commit { error in
//                self.isReserving = false
//
//                if let error = error {
//                    self.errorMessage = "Failed to reserve book: \(error.localizedDescription)"
//                    completion(false, self.errorMessage)
//                    return
//                }
//
//                self.reservationSuccess = true
//                completion(true, nil)
//            }
//        }
//    }
//    func fetchUserReservedBooks(completion: @escaping (Result<[BookRequest], Error>) -> Void) {
//        // Get the current user ID from Firebase Service
//        guard let userId = FirebaseService.shared.getCurrentUserId() else {
//            completion(.failure(NSError(
//                domain: "BookService",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "No logged in user found"]
//            )))
//            return
//        }
//        
//        let requestsRef = db.collection("members").document(userId)
//            .collection("userbooks").document("collection")
//            .collection("requested")
//        
//        requestsRef.getDocuments { (snapshot, error) in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            let requests = snapshot?.documents.compactMap {
//                BookRequest.fromFirestore(document: $0, userID: userId)
//            } ?? []
//            
//            // Fetch book details for each request
//            let group = DispatchGroup()
//            var enrichedRequests: [BookRequest] = []
//            
//            for var request in requests {
//                group.enter()
//                
//                self.db.collection("books").document(request.bookID).getDocument { (doc, err) in
//                    defer { group.leave() }
//                    
//                    if let doc = doc, doc.exists, let data = doc.data() {
//                        request.bookName = data["name"] as? String
//                        request.bookImageURL = data["imageURL"] as? String
//                        enrichedRequests.append(request)
//                    } else {
//                        enrichedRequests.append(request)
//                    }
//                }
//            }
//            
//            group.notify(queue: .main) {
//                completion(.success(enrichedRequests))
//            }
//        }
//    }
//
//    // MARK: - New method to fetch user's reading history
//
//    func fetchUserReadingHistory(completion: @escaping (Result<[BookRequest], Error>) -> Void) {
//        // Get the current user ID from Firebase Service
//        guard let userId = FirebaseService.shared.getCurrentUserId() else {
//            completion(.failure(NSError(
//                domain: "BookService",
//                code: -1,
//                userInfo: [NSLocalizedDescriptionKey: "No logged in user found"]
//            )))
//            return
//        }
//        
//        let historyRef = db.collection("members").document(userId)
//            .collection("userbooks").document("collection")
//            .collection("history")
//        
//        historyRef.getDocuments { (snapshot, error) in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            let history = snapshot?.documents.compactMap {
//                BookRequest.fromFirestore(document: $0, userID: userId)
//            } ?? []
//            
//            completion(.success(history))
//        }
//    }
//}
