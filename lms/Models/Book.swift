import Firebase
import FirebaseFirestore
////
////  Book.swift
////  LMS-INFY
////
////  Created by palak seth on 27/04/25.
////
import Foundation

struct Book: Identifiable {
    let id: String
    let isbn: String
    let title: String
    let author: String
    let genre: String
    let releaseDate: String?
    let language: String
    let length: String
    let summary: String
    let publisher: String
    let availability: String
    let bookLocation: String
    let coverColor: String
    let coverImage: String
    let status: BookStatus
    let popularityScore: Int?  // Optional field for sorting popular books

    init(id: String, data: [String: Any]) {
        self.id = id
        self.isbn = data["isbn"] as? String ?? ""
        self.title = data["title"] as? String ?? ""
        self.author = data["author"] as? String ?? ""
        self.genre = data["genre"] as? String ?? ""
        self.releaseDate = data["releaseDate"] as? String ?? ""
        self.language = data["language"] as? String ?? ""
        self.length = data["length"] as? String ?? ""
        self.summary = data["summary"] as? String ?? ""
        self.publisher = data["publisher"] as? String ?? ""
        self.availability = data["availability"] as? String ?? ""
        self.bookLocation = data["bookLocation"] as? String ?? ""
        self.coverColor = data["coverColor"] as? String ?? "gray"
        self.coverImage = data["coverImage"] as? String ?? "defaultCover"
        self.status = (data["status"] as? [String: Any]).map { BookStatus(data: $0) } ?? .available
        self.popularityScore = data["popularityScore"] as? Int
    }
}

enum BookStatus {
    case available
    case issued(issuedTo: String, issuedDate: Date, dueDate: Date, overdueFine: Double)
    case reserved(reservedBy: String, reservedDate: Date, timeLeft: String)
    case notAvailable

    init(data: [String: Any]) {
        switch data["type"] as? String ?? "" {
        case "issued":
            let issuedTo = data["issuedTo"] as? String ?? ""
            let issuedDate = (data["issuedDate"] as? Timestamp)?.dateValue() ?? Date()
            let dueDate = (data["dueDate"] as? Timestamp)?.dateValue() ?? Date()
            let overdueFine = data["overdueFine"] as? Double ?? 0.0
            self = .issued(
                issuedTo: issuedTo, issuedDate: issuedDate, dueDate: dueDate,
                overdueFine: overdueFine)
        case "reserved":
            let reservedBy = data["reservedBy"] as? String ?? ""
            let reservedDate = (data["reservedDate"] as? Timestamp)?.dateValue() ?? Date()
            let timeLeft = data["timeLeft"] as? String ?? ""
            self = .reserved(reservedBy: reservedBy, reservedDate: reservedDate, timeLeft: timeLeft)
        case "notAvailable":
            self = .notAvailable
        default:
            self = .available
        }
    }
}

struct LibraryStats {
    let booksRead: Int
    let totalBooks: Int
}

struct LibraryUser {
    let name: String
    let issuedBooks: [Book]
    let reservedBooks: [Book]
    let stats: LibraryStats
}
