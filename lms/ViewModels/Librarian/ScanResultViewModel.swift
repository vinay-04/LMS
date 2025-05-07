//
//  ScanResultViewModel.swift
//  lms
//
//  Created by palak seth on 01/05/25.
//

import SwiftUI
import FirebaseFirestore

class ScanResultViewModel: ObservableObject {
    @Published var book: LibraryBook?
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let db = Firestore.firestore()

    func fetchBookDetails(isbn: String) {
        isLoading = true
        error = nil
        book = nil
        
        print("Starting fetch for ISBN: \(isbn)")
        
        // Trim the ISBN to ensure no extra whitespace
        let trimmedISBN = isbn.trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("books")
            .whereField("isbn", isEqualTo: trimmedISBN)
            .getDocuments(source: .default) { [weak self] snapshot, error in // Changed nil to .default
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    print("Fetch completed, isLoading set to false")
                    
                    if let error = error {
                        self.error = "Failed to fetch book: \(error.localizedDescription)"
                        print("Fetch error: \(error.localizedDescription)")
                        return
                    }

                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        self.error = "Book not found with ISBN: \(trimmedISBN)"
                        print("No documents found for ISBN: \(trimmedISBN)")
                        return
                    }

                    print("Documents found: \(documents.count)")
                    var documentData = documents.first?.data()
                    print("Raw document data: \(String(describing: documentData))")

                    // Preprocess the document data to handle FIRTimestamp and language
                    if var docData = documentData {
                        // Convert FIRTimestamp to Date
                        if let timestamp = docData["dateCreated"] as? Timestamp {
                            docData["dateCreated"] = timestamp.dateValue()
                        }

                        // Ensure language is an array
                        if let languageDict = docData["language"] as? [String: String] {
                            docData["language"] = Array(languageDict.values)
                        } else if let languageArray = docData["language"] as? [String] {
                            docData["language"] = languageArray
                        } else {
                            docData["language"] = ["en"] // Fallback
                        }

                        documentData = docData
                    }

                    do {
                        // Manually decode the document data
                        let jsonData = try JSONSerialization.data(withJSONObject: documentData as Any)
                        let decoder = JSONDecoder()
                        var book = try decoder.decode(LibraryBook.self, from: jsonData)
                        book.id = documents[0].documentID  // Manually set the document ID
                        self.book = book
                        print("Book fetched successfully: \(String(describing: self.book?.name))")
                        print("Book details - ISBN: \(String(describing: self.book?.isbn)), Copies Available: \(self.book?.copiesAvailable ?? 0)")
                    } catch {
                        self.error = "Failed to decode book data: \(error.localizedDescription)"
                        print("Decoding error: \(error.localizedDescription)")
                    }
                }
            }
    }
}
