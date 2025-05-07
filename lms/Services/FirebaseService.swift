//
//  FirebaseService.swift
//  lms
//
//  Created by VR on 02/05/25.
//

import Foundation
import UIKit
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

    // MARK: — Generic User CRUD

    /// Create (or overwrite) a user document in the "users" collection.
    @MainActor
    func createUser(userId: String, userData: [String: Any]) async {
        print("Firebase: Attempting to create user with ID: \(userId)")
        print("Firebase: Data being sent: \(userData)")
        do {
            try await db.collection("users").document(userId).setData(userData)
            print("Firebase: ✅ User created successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error creating user: \(error.localizedDescription)")
            print("Firebase: Error details: \(error)")
        }
    }

    /// Update fields on an existing user document in the "users" collection.
    @MainActor
    func updateUser(userId: String, userData: [String: Any]) async {
        print("Firebase: Attempting to update user with ID: \(userId)")
        print("Firebase: Update data: \(userData)")
        do {
            try await db.collection("users").document(userId).updateData(userData)
            print("Firebase: ✅ User updated successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error updating user: \(error.localizedDescription)")
            print("Firebase: Error details: \(error)")
        }
    }

    /// Fetch a user document from the "users" collection.
    func getUser(userId: String) async -> [String: Any]? {
        print("Firebase: Attempting to get user with ID: \(userId)")
        do {
            let document = try await db.collection("users").document(userId).getDocument()
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

    /// Delete a user document in the "users" collection.
    func deleteUser(userId: String) async {
        print("Firebase: Attempting to delete user with ID: \(userId)")
        do {
            try await db.collection("users").document(userId).delete()
            print("Firebase: ✅ User deleted successfully with ID: \(userId)")
        } catch {
            print("Firebase: ❌ Error deleting user: \(error.localizedDescription)")
        }
    }

    /// List all user documents in the "users" collection.
    func listUsers() async -> [[String: Any]] {
        print("Firebase: Attempting to list all users")
        do {
            let querySnapshot = try await db.collection("users").getDocuments()
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

    // MARK: — Librarian Profiles

    /// Create (or overwrite) a librarian document in the "librarians" collection,
    /// then upload optional photo to Storage and update the document with its URL.
    func createLibrarianProfile(_ librarian: Librarian,
                                photo: UIImage?,
                                completion: @escaping (Result<Void, Error>) -> Void)
    {
        guard let uid = librarian.id else {
            return completion(.failure(NSError(
                domain: "FirebaseService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Librarian ID missing"]
            )))
        }

        do {
            try db.collection("librarians")
                  .document(uid)
                  .setData(from: librarian) { error in
                if let error = error {
                    return completion(.failure(error))
                }
                // If no photo, done
                guard let image = photo,
                      let data = image.jpegData(compressionQuality: 0.8)
                else {
                    return completion(.success(()))
                }

                let ref = self.storage
                    .reference()
                    .child("librarian_images/\(uid).jpg")

                ref.putData(data, metadata: nil) { _, uploadError in
                    if let uploadError = uploadError {
                        return completion(.failure(uploadError))
                    }
                    ref.downloadURL { url, urlError in
                        if let urlError = urlError {
                            return completion(.failure(urlError))
                        }
                        guard let url = url else {
                            return completion(.failure(NSError(
                                domain: "FirebaseService",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Invalid image URL"]
                            )))
                        }
                        // Update document with photoURL
                        self.db.collection("librarians")
                            .document(uid)
                            .updateData(["photoURL": url.absoluteString]) { updError in
                                if let updError = updError {
                                    completion(.failure(updError))
                                } else {
                                    completion(.success(()))
                                }
                            }
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    /// Fetch a librarian document from the "librarians" collection.
    func fetchLibrarianProfile(uid: String,
                               completion: @escaping (Result<Librarian, Error>) -> Void)
    {
        db.collection("librarians").document(uid)
          .getDocument { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let snapshot = snapshot,
                  snapshot.exists,
                  let lib = try? snapshot.data(as: Librarian.self)
            else {
                return completion(.failure(NSError(
                    domain: "FirebaseService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Librarian not found"]
                )))
            }
            completion(.success(lib))
        }
    }

    /// Fetch all librarian documents from the "librarians" collection.
    func fetchAllLibrarians(completion: @escaping (Result<[Librarian], Error>) -> Void) {
        db.collection("librarians")
          .getDocuments { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            let libs: [Librarian] = snapshot?.documents.compactMap {
                try? $0.data(as: Librarian.self)
            } ?? []
            completion(.success(libs))
        }
    }

    // MARK: — Admin Profiles

    /// Create (or overwrite) an admin document in the "admins" collection.
    func createAdminProfile(_ admin: Admin,
                            completion: @escaping (Result<Void, Error>) -> Void)
    {
        let uid = admin.id
        db.collection("admins")
          .document(uid)
          .setData(["email": admin.email]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    /// Fetch an admin document from the "admins" collection.
    func fetchAdminProfile(uid: String,
                           completion: @escaping (Result<Admin, Error>) -> Void)
    {
        db.collection("admins").document(uid)
          .getDocument { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            guard let snapshot = snapshot,
                  snapshot.exists,
                  let email = snapshot.get("email") as? String
            else {
                return completion(.failure(NSError(
                    domain: "FirebaseService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Admin not found"]
                )))
            }
            completion(.success(Admin(id: uid, email: email)))
        }
    }

    /// Fetch all admin documents from the "admins" collection.
    func fetchAllAdmins(completion: @escaping (Result<[Admin], Error>) -> Void) {
        db.collection("admins")
          .getDocuments { snapshot, error in
            if let error = error {
                return completion(.failure(error))
            }
            let admins: [Admin] = snapshot?.documents.compactMap {
                guard let email = $0.get("email") as? String else { return nil }
                return Admin(id: $0.documentID, email: email)
            } ?? []
            completion(.success(admins))
        }
    }

    // MARK: — Determine User Role

    /// Check members, librarians, and admins collections to find a user’s role.
    func fetchRole(for uid: String,
                   completion: @escaping (Result<UserRole, Error>) -> Void)
    {
        let group = DispatchGroup()
        var found: UserRole?
        var lastError: Error?

        // member?
        group.enter()
        db.collection("members").document(uid).getDocument { doc, err in
            if let err = err { lastError = err }
            else if doc?.exists == true { found = .member }
            group.leave()
        }

        // librarian?
        group.enter()
        db.collection("librarians").document(uid).getDocument { doc, err in
            if let err = err { lastError = err }
            else if doc?.exists == true { found = .librarian }
            group.leave()
        }

        // admin?
        group.enter()
        db.collection("admins").document(uid).getDocument { doc, err in
            if let err = err { lastError = err }
            else if doc?.exists == true { found = .admin }
            group.leave()
        }

        group.notify(queue: .main) {
            if let role = found {
                completion(.success(role))
            } else if let err = lastError {
                completion(.failure(err))
            } else {
                completion(.failure(NSError(
                    domain: "FirebaseService",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "Role not found"]
                )))
            }
        }
    }
}

// MARK: - BookService

class BookService: ObservableObject {
    private let db = Firestore.firestore()
    @Published var newReleases = [LibraryBook]()
    @Published var allBooks = [LibraryBook]()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isReserving = false
    @Published var reservationSuccess = false
    @Published var totalBookCount: Int = 0

    /// Fetch books created in the last `limit` days, ordered by creation date.
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

    /// Reserve one copy of a book and record the reservation under the member.
    func reserveBook(bookId: String, completion: @escaping (Bool, String?) -> Void) {
        self.isReserving = true
        self.errorMessage = nil

        let userId = "defaultUserId" // In production, get this from your user management system

        let bookRef = db.collection("books").document(bookId)

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
}

