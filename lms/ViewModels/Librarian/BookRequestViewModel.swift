//
//  BookRequestViewModel.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import Foundation
import FirebaseFirestore
import Combine

class BookRequestViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var requestedBooks: [BookRequest] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var selectedRequest: BookRequest?
    @Published var selectedBook: RequestBookDetail?
    @Published var showDetailView: Bool = false
    
    // Firestore reference
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    // Debug function to help identify issues
    private func printDebugInfo(message: String) {
        print("DEBUG: \(message)")
    }
    
    // Fetch all book requests from users based on your exact Firebase structure
    func fetchRequestedBooks() {
        isLoading = true
        requestedBooks.removeAll()
        errorMessage = ""
        
        printDebugInfo(message: "Starting to fetch requested books")
        
        // First, get all members
        db.collection("members").getDocuments { [weak self] (membersSnapshot, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Error fetching members: \(error.localizedDescription)"
                self.printDebugInfo(message: "Error fetching members: \(error.localizedDescription)")
                return
            }
            
            self.printDebugInfo(message: "Found \(membersSnapshot?.documents.count ?? 0) members")
            
            // Use a dispatch group to track all the async operations
            let dispatchGroup = DispatchGroup()
            var tempRequests: [BookRequest] = []
            
            // For each member, check their requested books
            for memberDoc in membersSnapshot?.documents ?? [] {
                let userID = memberDoc.documentID
                self.printDebugInfo(message: "Checking user: \(userID)")
                
                dispatchGroup.enter()
                
                // Following the exact path from your screenshot: members → userId → userbooks → collection → requested
                let requestedRef = self.db.collection("members").document(userID)
                    .collection("userbooks").document("collection")
                    .collection("requested")
                
                requestedRef.getDocuments { (requestsSnapshot, error) in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        self.printDebugInfo(message: "Error fetching requests for user \(userID): \(error.localizedDescription)")
                        return
                    }
                    
                    let requestCount = requestsSnapshot?.documents.count ?? 0
                    self.printDebugInfo(message: "Found \(requestCount) requests for user \(userID)")
                    
                    // Process each request document
                    for requestDoc in requestsSnapshot?.documents ?? [] {
                        let data = requestDoc.data()
                        self.printDebugInfo(message: "Processing request document: \(requestDoc.documentID) with data: \(data)")
                        
                        // Extract data from the document - match exactly what's in your Firebase
                        let bookID = data["bookUUID"] as? String ?? requestDoc.documentID
                        let requestTimestamp = data["requestedTimestamp"] as? Timestamp
                        let docUserID = data["userId"] as? String ?? userID
                        
                        self.printDebugInfo(message: "Extracted data - bookID: \(bookID), userID: \(docUserID), timestamp: \(String(describing: requestTimestamp))")
                        
                        // Only proceed if we have the required timestamp
                        guard let timestamp = requestTimestamp else {
                            self.printDebugInfo(message: "Missing timestamp for request document: \(requestDoc.documentID)")
                            continue
                        }
                        
                        // Create a book request object
                        let request = BookRequest(
                            id: requestDoc.documentID,
                            bookID: bookID,
                            userID: docUserID,
                            requestTimestamp: timestamp.dateValue(),
                            bookName: nil,
                            bookImageURL: nil,
                            userName: nil
                        )
                        
                        self.printDebugInfo(message: "Created book request object for book: \(bookID)")
                        
                        // Fetch additional book and user details
                        dispatchGroup.enter()
                        self.fetchBookAndUserDetails(for: request) { updatedRequest in
                            defer { dispatchGroup.leave() }
                            
                            if let updatedRequest = updatedRequest {
                                self.printDebugInfo(message: "Successfully updated request with book and user details")
                                tempRequests.append(updatedRequest)
                            } else {
                                self.printDebugInfo(message: "Failed to update request with book and user details")
                            }
                        }
                    }
                }
            }
            
            // When all operations are complete
            dispatchGroup.notify(queue: .main) {
                self.requestedBooks = tempRequests.sorted(by: { $0.requestTimestamp > $1.requestTimestamp })
                self.isLoading = false
                
                self.printDebugInfo(message: "Finished fetching all requests. Found \(tempRequests.count) total requests")
                
                if self.requestedBooks.isEmpty && self.errorMessage.isEmpty {
                    self.printDebugInfo(message: "No book requests found in the database")
                }
            }
        }
    }
    
    // Fetch both book and user details in parallel
    private func fetchBookAndUserDetails(for request: BookRequest, completion: @escaping (BookRequest?) -> Void) {
        var updatedRequest = request
        let dispatchGroup = DispatchGroup()
        
        printDebugInfo(message: "Fetching details for book: \(request.bookID) and user: \(request.userID)")
        
        // Fetch book details
        dispatchGroup.enter()
        db.collection("books").document(request.bookID).getDocument { [weak self] (document, error) in
            defer { dispatchGroup.leave() }
            guard let self = self else { return }
            
            if let error = error {
                self.printDebugInfo(message: "Error fetching book details: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                self.printDebugInfo(message: "Found book document: \(document.documentID)")
                
                if let data = document.data() {
                    updatedRequest.bookName = data["name"] as? String
                    updatedRequest.bookImageURL = data["imageURL"] as? String
                    
                    self.printDebugInfo(message: "Book name: \(String(describing: updatedRequest.bookName)), image URL: \(String(describing: updatedRequest.bookImageURL))")
                }
            } else {
                self.printDebugInfo(message: "Book document not found: \(request.bookID)")
            }
        }
        
        // Fetch user name
        dispatchGroup.enter()
        db.collection("members").document(request.userID).getDocument { [weak self] (document, error) in
            defer { dispatchGroup.leave() }
            guard let self = self else { return }
            
            if let error = error {
                self.printDebugInfo(message: "Error fetching user details: \(error.localizedDescription)")
                return
            }
            
            if let document = document, document.exists {
                self.printDebugInfo(message: "Found user document: \(document.documentID)")
                
                if let data = document.data() {
                    updatedRequest.userName = data["name"] as? String ?? data["fullName"] as? String
                    self.printDebugInfo(message: "User name: \(String(describing: updatedRequest.userName))")
                }
            } else {
                self.printDebugInfo(message: "User document not found: \(request.userID)")
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            self.printDebugInfo(message: "Completed fetching details for book and user")
            completion(updatedRequest)
        }
    }
    
    // Get detailed book information
    func getBookDetails(for bookID: String) {
        isLoading = true
        errorMessage = ""
        
        printDebugInfo(message: "Getting detailed book info for: \(bookID)")
        
        db.collection("books").document(bookID).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Error fetching book details: \(error.localizedDescription)"
                self.printDebugInfo(message: "Error fetching book details: \(error.localizedDescription)")
                return
            }
            
            guard let document = document, document.exists else {
                self.errorMessage = "Book not found"
                self.printDebugInfo(message: "Book document not found: \(bookID)")
                return
            }
            
            if let bookDetail = RequestBookDetail.fromFirestore(document: document) {
                self.selectedBook = bookDetail
                self.showDetailView = true
                self.printDebugInfo(message: "Successfully retrieved book details: \(String(describing: bookDetail.name))")
            } else {
                self.errorMessage = "Failed to process book data"
                self.printDebugInfo(message: "Failed to process book data for: \(bookID)")
            }
        }
    }
    
    // Issue book to user
    func issueBook(request: BookRequest) {
        guard let book = selectedBook else {
            errorMessage = "Book details not available"
            printDebugInfo(message: "Cannot issue book - book details not available")
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        printDebugInfo(message: "Issuing book \(request.bookID) to user \(request.userID)")
        
        // Create a batch to ensure all operations succeed or fail together
        let batch = db.batch()
        
        // 1. Update book counts
        let bookRef = db.collection("books").document(request.bookID)
        batch.updateData([
            "reservedCount": FieldValue.increment(Int64(-1)),
            "issuedCount": FieldValue.increment(Int64(1))
        ], forDocument: bookRef)
        
        printDebugInfo(message: "Added book count updates to batch")
        
        // 2. Add to issued collection
        // Create path: members/{userId}/userbooks/collection/issued/{bookId}
        let issuedBookRef = db.collection("members").document(request.userID)
                             .collection("userbooks").document("collection")
                             .collection("issued").document(request.bookID)
        
        batch.setData([
            "bookUUID": request.bookID,
            "issuedTimestamp": Timestamp(date: Date()),
            "requestedTimestamp": Timestamp(date: request.requestTimestamp),
            "userId": request.userID
        ], forDocument: issuedBookRef)
        
        printDebugInfo(message: "Added issued record to batch")
        
        // 3. Delete from requested collection
        // Path: members/{userId}/userbooks/collection/requested/{bookId}
        let requestedBookRef = db.collection("members").document(request.userID)
                                .collection("userbooks").document("collection")
                                .collection("requested").document(request.bookID)
        batch.deleteDocument(requestedBookRef)
        
        printDebugInfo(message: "Added delete request to batch")
        
        // Commit the batch
        batch.commit { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to issue book: \(error.localizedDescription)"
                self.printDebugInfo(message: "Error committing batch: \(error.localizedDescription)")
                return
            }
            
            // Success
            self.printDebugInfo(message: "Successfully issued book")
            self.showDetailView = false
            self.selectedRequest = nil
            self.selectedBook = nil
            self.fetchRequestedBooks()
        }
    }
    
    // Cancel book request and create history entry
    func cancelRequest(request: BookRequest) {
        isLoading = true
        errorMessage = ""
        
        printDebugInfo(message: "Cancelling request for book \(request.bookID) from user \(request.userID)")
        
        // Create a batch to ensure all operations succeed or fail together
        let batch = db.batch()
        
        // 1. Create history record with status "rejected"
        // Path: members/{userId}/userbooks/collection/history/{bookId}
        let historyRef = db.collection("members").document(request.userID)
                          .collection("userbooks").document("collection")
                          .collection("history").document(request.bookID)
        
        let historyData = BookHistory.createRejected(
            bookID: request.bookID,
            userID: request.userID,
            requestTimestamp: request.requestTimestamp
        )
        batch.setData(historyData, forDocument: historyRef)
        
        printDebugInfo(message: "Added history record to batch")
        
        // 2. Update book counts (decrease reserved count)
        let bookRef = db.collection("books").document(request.bookID)
        batch.updateData([
            "reservedCount": FieldValue.increment(Int64(-1))
        ], forDocument: bookRef)
        
        printDebugInfo(message: "Added book count update to batch")
        
        // 3. Delete from requested collection
        // Path: members/{userId}/userbooks/collection/requested/{bookId}
        let requestedBookRef = db.collection("members").document(request.userID)
                                .collection("userbooks").document("collection")
                                .collection("requested").document(request.bookID)
        batch.deleteDocument(requestedBookRef)
        
        printDebugInfo(message: "Added delete request to batch")
        
        // Commit the batch
        batch.commit { [weak self] error in
            guard let self = self else { return }
            self.isLoading = false
            
            if let error = error {
                self.errorMessage = "Failed to cancel request: \(error.localizedDescription)"
                self.printDebugInfo(message: "Error committing batch: \(error.localizedDescription)")
                return
            }
            
            // Success
            self.printDebugInfo(message: "Successfully cancelled request")
            self.showDetailView = false
            self.selectedRequest = nil
            self.selectedBook = nil
            self.fetchRequestedBooks()
        }
    }
}
