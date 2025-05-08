//
//  BookRequestViewModel.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import Foundation
import FirebaseFirestore

// Define the Activity struct properly with conformance to Identifiable
struct Activity: Identifiable {
    var id = UUID()
    var name: String
    var bookTitle: String
    var date: Date
    var status: String
    var dues: Double?
}

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

class LibrarianHomeViewModel: ObservableObject {
    @Published var borrowedCount: Int = 233
    @Published var returnedCount: Int = 176
    @Published var overdueAmount: Double = 43.0
    @Published var missingCount: Int = 54
    @Published var memberCount: Int = 345 // Added this property
    @Published var borrowedPercentage: String = "-26%"
    @Published var returnedPercentage: String = "+04%"
    @Published var overduePercentage: String = "+43%"
    @Published var missingPercentage: String = "-96%"
    @Published var memberPercentage: String = "+12%" // Added this property
    @Published var recentActivities: [Activity] = []
    
    // Add the current issue being processed
    @Published var currentIssue: IssuedBook?
    
    // Reference to Firestore database
    let db = Firestore.firestore()
    
    init() {
        loadData()
    }
    
    func loadData() {
        // Create sample activity data
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yy 'at' HH:mm a"
        let date1 = dateFormatter.date(from: "12 Jun 24 at 01:23 PM") ?? Date()
        let date2 = dateFormatter.date(from: "12 Jun 24 at 01:23 PM") ?? Date()
        
        recentActivities = [
            Activity(name: "Radikha", bookTitle: "The Count of Monte Cristo", date: date1, status: "Borrowed", dues: nil),
            Activity(name: "Radikha", bookTitle: "The Count of Monte Cristo", date: date2, status: "Returned", dues: 5.0)
        ]
    }
    
    // Handle a scanned book ISBN
    func handleScannedBook(isbn: String, isReturn: Bool = false) {
        print("Handling scanned book with ISBN: \(isbn), isReturn: \(isReturn)")
        currentIssue = IssuedBook(isbn: isbn, isReturn: isReturn)
    }
    
    // Reset the current issue
    func resetCurrentIssue() {
        currentIssue = nil
    }
    
    // Issue request action
    func issueRequest() {
        print("Issue request action")
        // Logic for issuing a request
    }
    
    // Return request action
    func returnRequest() {
        print("Return request action")
        // Logic for return request
    }
    
    // Complete the issue/return process with member ID
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
                // Update other stats as needed
            } else {
                self.borrowedCount += 1
                // Update other stats as needed
            }
            
            // Add to recent activities
            self.addRecentActivity(isbn: issue.isbn, memberID: memberID, isReturn: issue.isReturn)
        }
    }
    
    // Add a new activity to recent activities
    func addRecentActivity(isbn: String, memberID: String, isReturn: Bool) {
        // In a real app, you would fetch book and member details from your database
        // For now, we'll create dummy data
        let newActivity = Activity(
            name: "Member ID: \(memberID)",
            bookTitle: "Book ISBN: \(isbn)",
            date: Date(),
            status: isReturn ? "Returned" : "Borrowed",
            dues: isReturn ? 0.0 : nil
        )
        
        recentActivities.insert(newActivity, at: 0)
    }
    
    // Add issue activity
    func addIssueActivity(bookID: String, bookTitle: String, memberID: String) {
        let newActivity = Activity(
            name: "Member ID: \(memberID)",
            bookTitle: bookTitle,
            date: Date(),
            status: "Borrowed",
            dues: nil
        )
        
        recentActivities.insert(newActivity, at: 0)
    }
    
    // Add return activity
    func addReturnActivity(bookID: String, bookTitle: String, memberID: String) {
        let newActivity = Activity(
            name: "Member ID: \(memberID)",
            bookTitle: bookTitle,
            date: Date(),
            status: "Returned",
            dues: 0.0
        )
        
        recentActivities.insert(newActivity, at: 0)
    }
}
