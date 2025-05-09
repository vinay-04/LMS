//
//  BookRequestViewModel.swift
//  lms
//
//  Created by palak seth on 01/05/25.
//

import Foundation
import FirebaseFirestore
import Combine
import FirebaseCore
import FirebaseStorage
import SwiftUI

// Structure to track a book during the issuing/returning process
struct IssuedBook: Identifiable {
    let id = UUID()
    let isbn: String
    let timestamp: Date
    var memberID: String?
    var status: IssuedBookStatus
    var isReturn: Bool // Whether this is a return or an issue
    
    
    enum IssuedBookStatus: Equatable {
        case pending // Just scanned, waiting for member
        case processing // Member selected, currently processing
        case completed // Successfully issued/returned
        case failed(String) // Failed with error message
        
        // Implement Equatable manually since case with associated value requires it
        static func == (lhs: IssuedBookStatus, rhs: IssuedBookStatus) -> Bool {
            switch (lhs, rhs) {
            case (.pending, .pending):
                return true
            case (.processing, .processing):
                return true
            case (.completed, .completed):
                return true
            case (.failed(let lhsMessage), .failed(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    init(isbn: String, isReturn: Bool = false) {
        self.isbn = isbn
        self.timestamp = Date()
        self.memberID = nil
        self.status = .pending
        self.isReturn = isReturn
    }
}

// Activity model needed by both ViewModel and View
struct Activity: Identifiable {
    let id: UUID
    let name: String
    let bookTitle: String
    let date: Date
    let status: String
    let dues: Double?
    let iconName: String
    let colorName: String
}

// Library Activity Type for recording activities
enum LibraryActivityType: String, Codable {
    case issue = "issue"
    case `return` = "return"
    case requestApproved = "request_approved"
    case requestRejected = "request_rejected"
    case finePaid = "fine_paid"
    
    var displayText: String {
        switch self {
        case .issue: return "Borrowed"
        case .return: return "Returned"
        case .requestApproved: return "Request Approved"
        case .requestRejected: return "Request Rejected"
        case .finePaid: return "Fine Paid"
        }
    }
    
    var iconName: String {
        switch self {
        case .issue: return "arrow.up.forward.circle.fill"
        case .return: return "arrow.down.forward.circle.fill"
        case .requestApproved: return "checkmark.circle.fill"
        case .requestRejected: return "xmark.circle.fill"
        case .finePaid: return "indianrupeesign.circle.fill"
        }
    }
    
    var colorName: String {
        switch self {
        case .issue: return "orange"
        case .return: return "green"
        case .requestApproved: return "blue"
        case .requestRejected: return "red"
        case .finePaid: return "purple"
        }
    }
}

// Stat Card data structure for home view
struct StatCardData {
    let title: String
    let value: String
}

class LibrarianHomeViewModel: ObservableObject {
    @Published var borrowedCount: Int = 0
    @Published var returnedCount: Int = 0
    @Published var requestCount: Int = 0
    @Published var memberCount: Int = 0
    @Published var recentActivities: [Activity] = []
    @Published var isLoading: Bool = false
    
    // Issue/Return book tracking
    @Published var currentIssue: IssuedBook?
    
    // Stat cards for home view
    @Published var statCards: [StatCardData] = []
    
    // Reference to Firestore database
    let db = Firestore.firestore()
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        // Create a dispatch group to wait for all async operations
        let group = DispatchGroup()
        
        // 1. Fetch borrowed count
        group.enter()
        fetchBorrowedCount { [weak self] count in
            self?.borrowedCount = count
            group.leave()
        }
        
        // 2. Fetch returned count
        group.enter()
        fetchReturnedCount { [weak self] count in
            self?.returnedCount = count
            group.leave()
        }
        
        // 3. Fetch request count
        group.enter()
        fetchRequestCount { [weak self] count in
            self?.requestCount = count
            group.leave()
        }
        
        // 4. Fetch member count
        group.enter()
        fetchMemberCount { [weak self] count in
            self?.memberCount = count
            group.leave()
        }
        
        // 5. Fetch recent activities
        group.enter()
        fetchRecentActivities { [weak self] activities in
            self?.recentActivities = activities
            group.leave()
        }
        
        // When all fetches are complete
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            
            // Update stat cards
            self.updateStatCards()
        }
    }
    
    private func updateStatCards() {
        statCards = [
            StatCardData(
                title: "Borrowed",
                value: "\(borrowedCount)"
            ),
            StatCardData(
                title: "Returned",
                value: "\(returnedCount)"
            ),
            StatCardData(
                title: "Requests",
                value: "\(requestCount)"
            ),
            StatCardData(
                title: "Members",
                value: "\(memberCount)"
            )
        ]
    }
    
    // MARK: - Firestore Data Fetching Methods
    
    private func fetchBorrowedCount(completion: @escaping (Int) -> Void) {
        var totalBorrowed = 0
        
        // Fetch all members first
        db.collection("members").getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let documents = snapshot?.documents else {
                print("Error fetching members: \(error?.localizedDescription ?? "Unknown error")")
                completion(0)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            // For each member, check their issued books
            for memberDoc in documents {
                let userID = memberDoc.documentID
                
                dispatchGroup.enter()
                
                // Path: members/{userID}/userbooks/collection/issued
                let issuedPath = self.db.collection("members").document(userID)
                    .collection("userbooks").document("collection")
                    .collection("issued")
                
                issuedPath.getDocuments { (issuedSnapshot, error) in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error fetching issued books for \(userID): \(error.localizedDescription)")
                        return
                    }
                    
                    if let issuedCount = issuedSnapshot?.documents.count {
                        totalBorrowed += issuedCount
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(totalBorrowed)
            }
        }
    }
    
    private func fetchReturnedCount(completion: @escaping (Int) -> Void) {
        var totalReturned = 0
        
        // Fetch all members first
        db.collection("members").getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let documents = snapshot?.documents else {
                print("Error fetching members: \(error?.localizedDescription ?? "Unknown error")")
                completion(0)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            // For each member, check their history
            for memberDoc in documents {
                let userID = memberDoc.documentID
                
                dispatchGroup.enter()
                
                // Path: members/{userID}/userbooks/collection/history
                let historyPath = self.db.collection("members").document(userID)
                    .collection("userbooks").document("collection")
                    .collection("history")
                
                // Only count history items that are not rejected
                historyPath.whereField("status", isNotEqualTo: "rejected").getDocuments { (historySnapshot, error) in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error fetching history for \(userID): \(error.localizedDescription)")
                        return
                    }
                    
                    if let historyCount = historySnapshot?.documents.count {
                        totalReturned += historyCount
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(totalReturned)
            }
        }
    }
    
    // Method to fetch request count
    private func fetchRequestCount(completion: @escaping (Int) -> Void) {
        var totalRequests = 0
        
        // Fetch all members first
        db.collection("members").getDocuments { [weak self] (snapshot, error) in
            guard let self = self, let documents = snapshot?.documents else {
                print("Error fetching members: \(error?.localizedDescription ?? "Unknown error")")
                completion(0)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            
            // For each member, check their requested books
            for memberDoc in documents {
                let userID = memberDoc.documentID
                
                dispatchGroup.enter()
                
                // Path: members/{userID}/userbooks/collection/requested
                let requestedPath = self.db.collection("members").document(userID)
                    .collection("userbooks").document("collection")
                    .collection("requested")
                
                requestedPath.getDocuments { (requestedSnapshot, error) in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("Error fetching requested books for \(userID): \(error.localizedDescription)")
                        return
                    }
                    
                    if let requestedCount = requestedSnapshot?.documents.count {
                        totalRequests += requestedCount
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(totalRequests)
            }
        }
    }
    
    private func fetchMemberCount(completion: @escaping (Int) -> Void) {
        db.collection("members").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching members: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            let count = snapshot?.documents.count ?? 0
            completion(count)
        }
    }
    
    // New implementation to fetch real recent activities from Firestore
    private func fetchRecentActivities(completion: @escaping ([Activity]) -> Void) {
        // Create a reference to the activities collection
        let activitiesRef = db.collection("library_activities")
        
        // Get the most recent 20 activities, ordered by timestamp (most recent first)
        activitiesRef
            .order(by: "timestamp", descending: true)
            .limit(to: 20)
            .getDocuments { [weak self] (snapshot, error) in
                guard self != nil else { return }
                
                if let error = error {
                    print("Error fetching activities: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                var activities: [Activity] = []
                
                for document in snapshot?.documents ?? [] {
                    let data = document.data()
                    
                    // Extract data from Firestore document
                    guard let typeString = data["type"] as? String,
                          let bookTitle = data["bookTitle"] as? String,
                          let memberName = data["memberName"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else {
                        continue
                    }
                    
                    // Convert Firestore data to ActivityType
                    let type = LibraryActivityType(rawValue: typeString) ?? .issue
                    let dues = data["dues"] as? Double
                    
                    // Create Activity object
                    let activity = Activity(
                        id: UUID(),
                        name: memberName,
                        bookTitle: bookTitle,
                        date: timestamp.dateValue(),
                        status: type.displayText,
                        dues: dues,
                        iconName: type.iconName,
                        colorName: type.colorName
                    )
                    
                    activities.append(activity)
                }
                
                completion(activities)
            }
    }
    
    // MARK: - Fine related Functions

    // Record a fine payment activity
    func recordFinePayment(
        bookID: String,
        bookTitle: String,
        memberID: String,
        memberName: String,
        amount: Double
    ) {
        // Record activity in Firestore
        recordActivity(
            type: .finePaid,
            bookID: bookID,
            bookTitle: bookTitle,
            memberID: memberID,
            memberName: memberName,
            dues: amount
        )
        
        // Create local activity for UI
        let newActivity = Activity(
            id: UUID(),
            name: memberName,
            bookTitle: bookTitle,
            date: Date(),
            status: "Fine Paid",
            dues: amount,
            iconName: "indianrupeesign.circle.fill",
            colorName: "purple"
        )
        
        recentActivities.insert(newActivity, at: 0)
    }

    // Create a fine record when book is issued
    func createFineRecord(
        bookID: String,
        bookTitle: String,
        memberID: String,
        issuedTimestamp: Date
    ) {
        let finesRef = db.collection("members").document(memberID)
                         .collection("userbooks").document("collection")
                         .collection("fines").document(bookID)
        
        let fineData: [String: Any] = [
            "bookUUID": bookID,
            "bookTitle": bookTitle,
            "userId": memberID,
            "issuedTimestamp": Timestamp(date: issuedTimestamp),
            "daysOverdue": 0,
            "fineAmount": 0.0,
            "isPaid": false,
            "lastCalculated": Timestamp(date: Date())
        ]
        
        finesRef.setData(fineData) { error in
            if let error = error {
                print("Error creating fine record: \(error.localizedDescription)")
            } else {
                print("Fine record created successfully for book: \(bookID)")
            }
        }
    }

    // Get fine for a book
    func getFineForBook(
        memberID: String,
        bookID: String,
        completion: @escaping (Fine?) -> Void
    ) {
        let fineRef = db.collection("members").document(memberID)
                        .collection("userbooks").document("collection")
                        .collection("fines").document(bookID)
        
        fineRef.getDocument { document, error in
            if let error = error {
                print("Error fetching fine: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(nil)
                return
            }
            
            // Get the issued timestamp
            guard let issuedTimestamp = data["issuedTimestamp"] as? Timestamp else {
                completion(nil)
                return
            }
            
            // Calculate the current fine
            let (daysOverdue, fineAmount) = Fine.calculateFine(
                issuedDate: issuedTimestamp.dateValue()
            )
            
            // Create a fine object with updated calculations
            let fine = Fine(
                id: document.documentID,
                bookUUID: data["bookUUID"] as? String ?? bookID,
                bookTitle: data["bookTitle"] as? String ?? "Unknown Book",
                userId: data["userId"] as? String ?? memberID,
                issuedTimestamp: issuedTimestamp.dateValue(),
                daysOverdue: daysOverdue,
                fineAmount: fineAmount,
                isPaid: data["isPaid"] as? Bool ?? false,
                lastCalculated: Date()
            )
            
            // Update the fine in Firestore with latest calculation
            var updatedData = fine.toFirestoreData()
            fineRef.updateData(updatedData) { error in
                if let error = error {
                    print("Error updating fine calculation: \(error.localizedDescription)")
                }
            }
            
            completion(fine)
        }
    }

    // Mark fine as paid
    func markFineAsPaid(
        memberID: String,
        bookID: String,
        fine: Fine,
        completion: @escaping (Bool) -> Void
    ) {
        let fineRef = db.collection("members").document(memberID)
                        .collection("userbooks").document("collection")
                        .collection("fines").document(bookID)
        
        fineRef.updateData([
            "isPaid": true,
            "lastCalculated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("Error marking fine as paid: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            completion(true)
        }
    }
    
    // MARK: - Activity Recording Methods
    
    // Record a new activity in Firestore
    func recordActivity(type: LibraryActivityType,
                       bookID: String,
                       bookTitle: String,
                       memberID: String,
                       memberName: String,
                       dues: Double? = nil,
                       notes: String? = nil) {
        // Create a new document reference
        let activityRef = db.collection("library_activities").document()
        
        // Prepare data for the activity
        var activityData: [String: Any] = [
            "type": type.rawValue,
            "bookID": bookID,
            "bookTitle": bookTitle,
            "memberID": memberID,
            "memberName": memberName,
            "timestamp": Timestamp(date: Date())
        ]
        
        // Add optional fields if they exist
        if let dues = dues {
            activityData["dues"] = dues
        }
        
        if let notes = notes {
            activityData["notes"] = notes
        }
        
        // Save to Firestore
        activityRef.setData(activityData) { error in
            if let error = error {
                print("Error recording activity: \(error.localizedDescription)")
            } else {
                print("Activity recorded successfully with ID: \(activityRef.documentID)")
            }
        }
    }
    
    // MARK: - Book Issue/Return Methods
    
    func handleScannedBook(isbn: String, isReturn: Bool = false) {
        print("Handling scanned book with ISBN: \(isbn), isReturn: \(isReturn)")
        currentIssue = IssuedBook(isbn: isbn, isReturn: isReturn)
    }
    
    func resetCurrentIssue() {
        currentIssue = nil
    }
    
    func issueRequest() {
        print("Issue request action")
        // Logic for issuing a request
    }
    
    func returnRequest() {
        print("Return request action")
        // Logic for return request
    }
    
    func completeProcess(memberID: String) {
        guard var issue = currentIssue else {
            print("No current issue to complete")
            return
        }
        
        issue.memberID = memberID
        issue.status = .processing
        currentIssue = issue
        
        // Simulate API call to process the issue/return
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            
            // Update issue status
            var updatedIssue = self.currentIssue
            updatedIssue?.status = .completed
            self.currentIssue = updatedIssue
            
            // Update UI stats
            if self.currentIssue?.isReturn == true {
                self.returnedCount += 1
                // Refresh data
                self.loadData()
            } else {
                self.borrowedCount += 1
                // Refresh data
                self.loadData()
            }
            
            // Add to recent activities
            self.addRecentActivity(isbn: issue.isbn, memberID: memberID, isReturn: issue.isReturn)
        }
    }
    
    // Replace the duplicate addReturnActivity methods with a single version that handles fines
    func addReturnActivity(bookID: String, bookTitle: String, memberID: String, fineAmount: Double? = nil) {
        // Fetch member name
        db.collection("members").document(memberID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            var memberName = "Member ID: \(memberID)"
            
            if let data = snapshot?.data() {
                if let name = data["full_name"] as? String {
                    memberName = name
                }
            }
            
            // Record activity in Firestore
            self.recordActivity(
                type: .return,
                bookID: bookID,
                bookTitle: bookTitle,
                memberID: memberID,
                memberName: memberName,
                dues: fineAmount
            )
            
            // Create local activity for UI
            let newActivity = Activity(
                id: UUID(),
                name: memberName,
                bookTitle: bookTitle,
                date: Date(),
                status: "Returned",
                dues: fineAmount,
                iconName: "arrow.down.forward.circle.fill",
                colorName: "green"
            )
            
            self.recentActivities.insert(newActivity, at: 0)
        }
    }

    // Add the missing addRecentActivity method
    private func addRecentActivity(isbn: String, memberID: String, isReturn: Bool) {
        // First, get the book details
        db.collection("books")
            .whereField("isbn", isEqualTo: isbn)
            .getDocuments { [weak self] (snapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error finding book: \(error.localizedDescription)")
                    return
                }
                
                guard let bookDoc = snapshot?.documents.first else {
                    print("Book not found with ISBN: \(isbn)")
                    return
                }
                
                let bookData = bookDoc.data()
                let bookTitle = bookData["name"] as? String ?? "Unknown Book"
                let bookID = bookDoc.documentID
                
                // Then handle based on whether it's an issue or return
                if isReturn {
                    self.addReturnActivity(bookID: bookID, bookTitle: bookTitle, memberID: memberID)
                } else {
                    self.addIssueActivity(bookID: bookID, bookTitle: bookTitle, memberID: memberID)
                }
            }
    }
    
    // Issue a book
    func addIssueActivity(bookID: String, bookTitle: String, memberID: String) {
        // Fetch member name
        db.collection("members").document(memberID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            var memberName = "Member ID: \(memberID)"
            
            if let data = snapshot?.data() {
                if let name = data["full_name"] as? String {
                    memberName = name
                }
            }
            
            // Record activity in Firestore
            self.recordActivity(
                type: .issue,
                bookID: bookID,
                bookTitle: bookTitle,
                memberID: memberID,
                memberName: memberName
            )
            
            // Create local activity for UI
            let newActivity = Activity(
                id: UUID(),
                name: memberName,
                bookTitle: bookTitle,
                date: Date(),
                status: "Borrowed",
                dues: nil,
                iconName: "arrow.up.forward.circle.fill",
                colorName: "orange"
            )
            
            self.recentActivities.insert(newActivity, at: 0)
        }
    }

    
    
    // Record request approval
    func recordRequestApproved(bookID: String, bookTitle: String, memberID: String) {
        // Fetch member name
        db.collection("members").document(memberID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            var memberName = "Member ID: \(memberID)"
            
            if let data = snapshot?.data() {
                if let name = data["full_name"] as? String {
                    memberName = name
                }
            }
            
            // Record activity in Firestore
            self.recordActivity(
                type: .requestApproved,
                bookID: bookID,
                bookTitle: bookTitle,
                memberID: memberID,
                memberName: memberName
            )
            
            // Create local activity for UI
            let newActivity = Activity(
                id: UUID(),
                name: memberName,
                bookTitle: bookTitle,
                date: Date(),
                status: "Request Approved",
                dues: nil,
                iconName: "checkmark.circle.fill",
                colorName: "blue"
            )
            
            self.recentActivities.insert(newActivity, at: 0)
        }
    }
    
    // Record request rejection
    func recordRequestRejected(bookID: String, bookTitle: String, memberID: String) {
        // Fetch member name
        db.collection("members").document(memberID).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            var memberName = "Member ID: \(memberID)"
            
            if let data = snapshot?.data() {
                if let name = data["full_name"] as? String {
                    memberName = name
                }
            }
            
            // Record activity in Firestore
            self.recordActivity(
                type: .requestRejected,
                bookID: bookID,
                bookTitle: bookTitle,
                memberID: memberID,
                memberName: memberName
            )
            
            // Create local activity for UI
            let newActivity = Activity(
                id: UUID(),
                name: memberName,
                bookTitle: bookTitle,
                date: Date(),
                status: "Request Rejected",
                dues: nil,
                iconName: "xmark.circle.fill",
                colorName: "red"
            )
            
            self.recentActivities.insert(newActivity, at: 0)
        }
    }
}
