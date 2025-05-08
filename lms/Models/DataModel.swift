//
//  DataModel.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import Foundation
import FirebaseFirestore

struct Member: Identifiable, Codable {
    var id: String?
    let name: String
    let phone: String
    let email: String
    let role: String
    var createdAt: Date
}
struct MonthData: Identifiable {
    let id = UUID()
    let month: String
    var count: Int
}

// MARK: - Librarian

struct Librarian: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let email: String
    let phone: String
    let salary: Double
    let designation: String
    var createdAt: Date
    var status: String
    var profileImageURL: String?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
}

// MARK: - Admin

struct Admin {
    let id: String
    let email: String
}

// MARK: - OTP Code Entry

struct OTPCode {
    private(set) var digits: [String] = Array(repeating: "", count: 6)

    mutating func update(digit: String, at index: Int) {
        guard index < digits.count else { return }
        digits[index] = digit.prefix(1).description
    }
}

// MARK: - Simple Book Model

struct Book {
    var isbn: String
    var title: String
    var author: String
    var genre: String
    var releaseDate: Date
    var language: String
    var pages: Int
    var totalCopies: Int
    var reservedCount: Int
    var unreservedCount: Int
    var location: String
    var summary: String
    var coverImage: UIImage?

    init(isbn: String = "",
         title: String = "",
         author: String = "",
         genre: String = "",
         releaseDate: Date = Date(),
         language: String = "",
         pages: Int = 0,
         totalCopies: Int = 0,
         reservedCount: Int = 0,
         unreservedCount: Int = 0,
         location: String = "",
         summary: String = "",
         coverImage: UIImage? = nil) {
        self.isbn = isbn
        self.title = title
        self.author = author
        self.genre = genre
        self.releaseDate = releaseDate
        self.language = language
        self.pages = pages
        self.totalCopies = totalCopies
        self.reservedCount = reservedCount
        self.unreservedCount = unreservedCount
        self.location = location
        self.summary = summary
        self.coverImage = coverImage
    }
}

// MARK: - Book Details for Issue/Return

struct BookDetails {
    let id: String
    let title: String
    let author: String
    let imageURL: String?
    let totalCount: Int
    let reservedCount: Int
    let issuedCount: Int
    let unreservedCount: Int
}

// MARK: - Book Request Models

struct BookRequest: Identifiable {
    var id: String
    var bookID: String
    var userID: String
    var requestTimestamp: Date
    var bookName: String?
    var bookImageURL: String?
    var userName: String?

    var requestDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: requestTimestamp)
    }

    static func fromFirestore(document: QueryDocumentSnapshot, userID: String) -> BookRequest? {
        let data = document.data()
        let bookID = data["bookUUID"] as? String ?? document.documentID
        guard let ts = data["requestedTimestamp"] as? Timestamp else { return nil }
        return BookRequest(
            id: document.documentID,
            bookID: bookID,
            userID: userID,
            requestTimestamp: ts.dateValue(),
            bookName: nil,
            bookImageURL: nil,
            userName: nil
        )
    }
}

struct RequestBookDetail {
    var id: String
    var name: String?
    var author: String?
    var releaseYear: String?
    var imageURL: String?
    var totalCount: Int?
    var reservedCount: Int?
    var issuedCount: Int?
    var unreservedCount: Int?

    var availableCount: Int {
        (unreservedCount ?? (totalCount ?? 0)) - ((reservedCount ?? 0) + (issuedCount ?? 0))
    }

    static func fromFirestore(document: DocumentSnapshot) -> RequestBookDetail? {
        guard let data = document.data() else { return nil }
        return RequestBookDetail(
            id: document.documentID,
            name: data["name"] as? String,
            author: data["author"] as? String,
            releaseYear: data["releaseYear"] as? String,
            imageURL: data["imageURL"] as? String,
            totalCount: data["totalCount"] as? Int,
            reservedCount: data["reservedCount"] as? Int,
            issuedCount: data["issuedCount"] as? Int,
            unreservedCount: data["unreservedCount"] as? Int
        )
    }
}

enum RequestStatus {
    case approved
    case rejected
    case expired

    var description: String {
        switch self {
        case .approved: return "approved"
        case .rejected: return "rejected"
        case .expired:  return "expired"
        }
    }
}

struct BookHistory {
    let bookID: String
    let userID: String
    let requestedTimestamp: Timestamp
    let issuedTimestamp: Timestamp?
    let endTimestamp: Timestamp
    let status: RequestStatus

    static func createRejected(bookID: String, userID: String, requestTimestamp: Date) -> [String: Any] {
        return [
            "bookUUID": bookID,
            "userId": userID,
            "requestedTimestamp": Timestamp(date: requestTimestamp),
            "endTimestamp": Timestamp(date: Date()),
            "status": RequestStatus.rejected.description
        ]
    }

    static func createApproved(bookID: String, userID: String, requestTimestamp: Date) -> [String: Any] {
        let now = Date()
        return [
            "bookUUID": bookID,
            "userId": userID,
            "requestedTimestamp": Timestamp(date: requestTimestamp),
            "issuedTimestamp": Timestamp(date: now),
            "endTimestamp": Timestamp(date: now),
            "status": RequestStatus.approved.description
        ]
    }
}

// MARK: - Library Presentation Models

struct LibraryStats {
    let booksRead: Int
    let totalBooks: Int
}

struct LibraryUser {
    let name: String
    let issuedBooks: [LibraryBook]
    let reservedBooks: [LibraryBook]
    let stats: LibraryStats
}

class LibraryData {
    static let placeholderUser = LibraryUser(
        name: "Vansh",
        issuedBooks: [],
        reservedBooks: [],
        stats: LibraryStats(booksRead: 0, totalBooks: 3546)
    )

    static let books: [LibraryBook] = [
        LibraryBook(
            id: UUID().uuidString,
            name: "Harry Potter and the Order of the Phoenix",
            isbn: "978-0-7475-8108-5",
            genre: "Fantasy",
            author: "J. K. Rowling",
            releaseYear: 2003,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "FiveFeetApart",
            rating: 4.8,
            location: BookLocation(floor: 2, shelf: "Fiction C4"),
            totalCount: 2,
            unreservedCount: 0,
            reservedCount: 0,
            issuedCount: 2,
            description: "Harry's fifth year at Hogwarts School of Witchcraft and Wizardry.",
            coverColor: "blue",
            pageCount: 870
        ),
        LibraryBook(
            id: UUID().uuidString,
            name: "Crazy Rich Asians",
            isbn: "978-0-385-53707-0",
            genre: "Romantic Comedy",
            author: "Kevin Kwan",
            releaseYear: 2013,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "Godfather",
            rating: 4.3,
            location: BookLocation(floor: 1, shelf: "Romance A2"),
            totalCount: 1,
            unreservedCount: 0,
            reservedCount: 1,
            issuedCount: 0,
            description: "Asian-American woman gets a peek into the ultra-rich lives in Singapore.",
            coverColor: "pink",
            pageCount: 403
        ),
        LibraryBook(
            id: UUID().uuidString,
            name: "Inferno",
            isbn: "978-0-385-53785-8",
            genre: "Thriller",
            author: "Dan Brown",
            releaseYear: 2013,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "dune",
            rating: 4.2,
            location: BookLocation(floor: 3, shelf: "Thriller B1"),
            totalCount: 4,
            unreservedCount: 4,
            reservedCount: 0,
            issuedCount: 0,
            description: "Robert Langdon must solve a puzzle to prevent a plague.",
            coverColor: "red",
            pageCount: 480
        ),
        LibraryBook(
            id: UUID().uuidString,
            name: "Origin",
            isbn: "978-0-385-50422-5",
            genre: "Thriller",
            author: "Dan Brown",
            releaseYear: 2017,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "hpss",
            rating: 4.1,
            location: BookLocation(floor: 3, shelf: "Thriller B2"),
            totalCount: 5,
            unreservedCount: 5,
            reservedCount: 0,
            issuedCount: 0,
            description: "Langdon attends a revelation that turns into a dangerous quest.",
            coverColor: "yellow",
            pageCount: 461
        ),
        LibraryBook(
            id: UUID().uuidString,
            name: "The Da Vinci Code",
            isbn: "978-0-385-50420-1",
            genre: "Thriller",
            author: "Dan Brown",
            releaseYear: 2003,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "oneOfUsIsLying",
            rating: 4.5,
            location: BookLocation(floor: 3, shelf: "Thriller B3"),
            totalCount: 2,
            unreservedCount: 2,
            reservedCount: 0,
            issuedCount: 0,
            description: "A murder in the Louvre leads to clues hidden in Da Vinci's paintings.",
            coverColor: "brown",
            pageCount: 454
        ),
        LibraryBook(
            id: UUID().uuidString,
            name: "The Quiet Part Out Loud",
            isbn: "978-1-9821-4985-4",
            genre: "Fiction",
            author: "Deborah Crossland",
            releaseYear: 2023,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "orientExpress",
            rating: 4.0,
            location: BookLocation(floor: 2, shelf: "Fiction D1"),
            totalCount: 5,
            unreservedCount: 5,
            reservedCount: 0,
            issuedCount: 0,
            description: "A compelling contemporary fiction novel.",
            coverColor: "teal",
            pageCount: 320
        ),
        LibraryBook(
            id: UUID().uuidString,
            name: "Normal People",
            isbn: "978-0-571-32523-6",
            genre: "Fiction",
            author: "Sally Rooney",
            releaseYear: 2018,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "prettyLittleLiars",
            rating: 4.4,
            location: BookLocation(floor: 2, shelf: "Fiction D2"),
            totalCount: 2,
            unreservedCount: 2,
            reservedCount: 0,
            issuedCount: 0,
            description: "Relationship between Marianne and Connell from school to college.",
            coverColor: "green",
            pageCount: 273
        ),
        LibraryBook(
            id: UUID().uuidString,
            name: "Gone Girl",
            isbn: "978-0-307-58836-4",
            genre: "Thriller",
            author: "Gillian Flynn",
            releaseYear: 2012,
            language: ["English", "Hindi", "Tamil"],
            dateCreated: Date(),
            imageURL: "thirteenReasons",
            rating: 4.6,
            location: BookLocation(floor: 3, shelf: "Thriller B4"),
            totalCount: 3,
            unreservedCount: 3,
            reservedCount: 0,
            issuedCount: 0,
            description: "Psychological thriller about a woman who disappears on her wedding anniversary.",
            coverColor: "purple",
            pageCount: 432
        )
    ]

    static let popularBooks = Array(books.prefix(3))
    static let newReleases = Array(books.suffix(3))
    static let genreList = ["Fantasy", "Mystery", "Fiction", "Romance"]

    static let sampleUser = LibraryUser(
        name: "User",
        issuedBooks: Array(books.prefix(1)),
        reservedBooks: Array(books.dropFirst().prefix(1)),
        stats: LibraryStats(booksRead: 0, totalBooks: 3546)
    )
}

// MARK: - Library Book & Location

struct LibraryBook: Identifiable, Codable {
    var id: String
    var name: String
    var isbn: String
    var genre: String
    var author: String
    var releaseYear: Int
    var language: [String]
    var dateCreated: Date
    var imageURL: String?
    var rating: Double
    var location: BookLocation
    var totalCount: Int
    var unreservedCount: Int
    var reservedCount: Int
    var issuedCount: Int
    var description: String
    var coverColor: String
    var pageCount: Int?

    var copiesAvailable: Int { unreservedCount }
        var currentlyBorrowed: Int { issuedCount }

        enum CodingKeys: String, CodingKey {
            case id, name, isbn, genre, author
            case releaseYear = "releaseYear"
            case language, dateCreated, imageURL, rating, location
            case totalCount, unreservedCount, reservedCount, issuedCount
            case description, coverColor = "coverColor", pageCount
        }
    
    static var empty: LibraryBook {
        let bookId = UUID().uuidString
        return LibraryBook(
            id: bookId,
            name: "",
            isbn: "",
            genre: "",
            author: "",
            releaseYear: Calendar.current.component(.year, from: Date()),
            language: ["en"],
            dateCreated: Date(),
            imageURL: nil,
            rating: 0.0,
            location: BookLocation(floor: 1, shelf: "A1"),
            totalCount: 1,
            unreservedCount: 1,
            reservedCount: 0,
            issuedCount: 0,
            description: "",
            coverColor: "blue",
            pageCount: nil
        )
    }
}


struct BookLocation: Codable {
    var floor: Int
    var shelf: String
}

// MARK: - Fine Model

// Model to represent a fine in the system
struct Fine: Identifiable {
    let id: String // This will be the book UUID
    let bookUUID: String
    let bookTitle: String
    let userId: String
    let issuedTimestamp: Date
    var daysOverdue: Int
    var fineAmount: Double
    var isPaid: Bool
    var lastCalculated: Date
    
    // Calculate fine amount based on days overdue (₹10 per day after 15 days)
    static func calculateFine(issuedDate: Date, currentDate: Date = Date()) -> (days: Int, amount: Double) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: issuedDate, to: currentDate)
        let totalDays = components.day ?? 0
        
        // Free for first 15 days
        let daysOverdue = max(0, totalDays - 15)
        let fineAmount = Double(daysOverdue) * 10.0 // ₹10 per day
        
        return (daysOverdue, fineAmount)
    }
    
    // Create a fine from Firestore document
    static func fromFirestore(document: QueryDocumentSnapshot) -> Fine? {
        let data = document.data()
        
        guard
            let bookUUID = data["bookUUID"] as? String,
            let bookTitle = data["bookTitle"] as? String,
            let userId = data["userId"] as? String,
            let issuedTimestamp = data["issuedTimestamp"] as? Timestamp,
            let daysOverdue = data["daysOverdue"] as? Int,
            let fineAmount = data["fineAmount"] as? Double,
            let isPaid = data["isPaid"] as? Bool,
            let lastCalculated = data["lastCalculated"] as? Timestamp
        else {
            return nil
        }
        
        return Fine(
            id: document.documentID,
            bookUUID: bookUUID,
            bookTitle: bookTitle,
            userId: userId,
            issuedTimestamp: issuedTimestamp.dateValue(),
            daysOverdue: daysOverdue,
            fineAmount: fineAmount,
            isPaid: isPaid,
            lastCalculated: lastCalculated.dateValue()
        )
    }
    
    // Convert to Firestore data
    func toFirestoreData() -> [String: Any] {
        return [
            "bookUUID": bookUUID,
            "bookTitle": bookTitle,
            "userId": userId,
            "issuedTimestamp": Timestamp(date: issuedTimestamp),
            "daysOverdue": daysOverdue,
            "fineAmount": fineAmount,
            "isPaid": isPaid,
            "lastCalculated": Timestamp(date: lastCalculated)
        ]
    }
}

// Extension for BookHistory to include fine information
extension BookHistory {
    static func createReturnedWithFine(
        bookID: String,
        userID: String,
        requestTimestamp: Date,
        issuedTimestamp: Date,
        returnedTimestamp: Date,
        fineAmount: Double?,
        finePaid: Bool
    ) -> [String: Any] {
        var historyData: [String: Any] = [
            "bookUUID": bookID,
            "userId": userID,
            "requestedTimestamp": Timestamp(date: requestTimestamp),
            "issuedTimestamp": Timestamp(date: issuedTimestamp),
            "returnedTimestamp": Timestamp(date: returnedTimestamp),
            "endTimestamp": Timestamp(date: returnedTimestamp),
            "status": "returned"
        ]
        
        // Add fine information if there was a fine
        if let fineAmount = fineAmount, fineAmount > 0 {
            historyData["fineAmount"] = fineAmount
            historyData["finePaid"] = finePaid
        }
        
        return historyData
    }
}

// Activity model for the database
struct LibraryActivity: Identifiable, Codable {
    var id: String // Document ID in Firestore
    var type: ActivityType
    var bookID: String
    var bookTitle: String
    var memberID: String
    var memberName: String?
    var timestamp: Date
    var notes: String?
    
    enum ActivityType: String, Codable {
        case issue = "issue"
        case `return` = "return"
        case requestApproved = "request_approved"
        case requestRejected = "request_rejected"
        
        var displayText: String {
            switch self {
            case .issue: return "Borrowed"
            case .return: return "Returned"
            case .requestApproved: return "Request Approved"
            case .requestRejected: return "Request Rejected"
            }
        }
        
        var iconName: String {
            switch self {
            case .issue: return "arrow.up.forward.circle.fill"
            case .return: return "arrow.down.forward.circle.fill"
            case .requestApproved: return "checkmark.circle.fill"
            case .requestRejected: return "xmark.circle.fill"
            }
        }
        
        var colorName: String {
            switch self {
            case .issue: return "orange"
            case .return: return "green"
            case .requestApproved: return "blue"
            case .requestRejected: return "red"
            }
        }
    }
}
// MARK: - Color Helper

extension Color {
    init(_ colorName: String) {
        switch colorName.lowercased() {
        case "red":    self = .red
        case "blue":   self = .blue
        case "green":  self = .green
        case "yellow": self = .yellow
        case "purple": self = .purple
        case "black":  self = .black
        case "white":  self = .white
        case "orange": self = .orange
        case "brown":  self = .brown
        case "gray":   self = .gray
        default:       self = .blue
        }
    }
}
