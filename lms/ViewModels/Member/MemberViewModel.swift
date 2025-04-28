//
//  MemberViewModel.swift
//  lms
//
//  Created by VR on 27/04/25.
//

import FirebaseFirestore
import Foundation
import SwiftUI

class MemberViewModel: ObservableObject {
    @Published var currentlyReading: Book?
    @Published var reservedBook: Book?
    @Published var popularBooks: [Book] = []
    @Published var newReleases: [Book] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var username: String = "Guest"
    @Published var booksReadCount: Int = 0
    @Published var totalBooksCount: Int = 0

    private let user: User
    private let db = Firestore.firestore()

    init(user: User) {
        self.user = user
        self.username = user.fullName
        fetchBooks()
        loadUserStats()
    }

    private func loadUserStats() {
        // Placeholder data - in a real app, this would fetch from Firestore
        self.booksReadCount = 23
        self.totalBooksCount = 3546

        // TODO: Fetch stats from Firestore based on user ID
        // Example:
        /*
        db.collection("users")
            .document(user.id)
            .collection("stats")
            .document("reading")
            .getDocument { [weak self] snapshot, error in
                if let data = snapshot?.data() {
                    self?.booksReadCount = data["booksRead"] as? Int ?? 0
                    self?.totalBooksCount = data["totalBooks"] as? Int ?? 0
                }
            }
        */
    }

    func fetchBooks() {
        isLoading = true
        error = nil

        // Simulate fetch for demo purposes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.loadMockData()
            self.isLoading = false
        }

        // TODO: Replace with actual Firestore fetch using user.id
        // Example:
        /*
        db.collection("books")
            .whereField("status.type", isEqualTo: "issued")
            .whereField("status.issuedTo", isEqualTo: user.id)
            .getDocuments { [weak self] snapshot, error in
                // Handle results
            }
        */
    }

    // The loadMockData method remains the same
    private func loadMockData() {
        // Sample data for demo
        let mockData: [String: Any] = [
            "title": "Harry Potter and the Order of the Phoenix",
            "author": "J. K. Rowling",
            "releaseDate": "2016",
            "genre": "Fantasy",
            "coverImage": "",
            "status": [
                "type": "issued",
                "issuedTo": "user123",
                "issuedDate": Timestamp(date: Date()),
                "dueDate": Timestamp(date: Date().addingTimeInterval(9 * 24 * 60 * 60)),
                "overdueFine": 10.0,
            ],
        ]

        let reservedData: [String: Any] = [
            "title": "Crazy Rich Asians",
            "author": "Kevin Kwan",
            "releaseDate": "2013",
            "genre": "Romantic Comedy",
            "coverImage": "crazy-rich-asians",
            "status": [
                "type": "reserved",
                "reservedBy": "user123",
                "reservedDate": Timestamp(date: Date()),
                "timeLeft": "10 days",
            ],
        ]

        self.currentlyReading = Book(id: "book1", data: mockData)
        self.reservedBook = Book(id: "book2", data: reservedData)

        // Load popular books
        self.popularBooks = [
            Book(
                id: "book3",
                data: ["title": "Inferno", "author": "Dan Brown", "coverImage": "dune"]),
            Book(
                id: "book4",
                data: ["title": "Origin", "author": "Dan Brown", "coverImage": "harry-potter"]),
            Book(
                id: "book5",
                data: [
                    "title": "The Da Vinci Code", "author": "Dan Brown", "coverImage": "one-of-us",
                ]),
        ]

        // Load new releases
        self.newReleases = [
            Book(
                id: "book6",
                data: [
                    "title": "The Quiet Part Out...", "author": "Deborah Crossland",
                    "coverImage": "murder-orient-express",
                ]),
            Book(
                id: "book7",
                data: [
                    "title": "Normal People", "author": "Sally Rooney",
                    "coverImage": "pretty-little-liars",
                ]),
            Book(
                id: "book8",
                data: [
                    "title": "Gone Girl", "author": "Gillian Flynn",
                    "coverImage": "thirteen-reasons",
                ]),
        ]
    }
}
