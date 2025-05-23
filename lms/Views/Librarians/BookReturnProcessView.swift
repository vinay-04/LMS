//
//  BookReturnProcessView.swift
//  lms
//
//  Created by user@30 on 05/05/25.
//

import SwiftUI
import FirebaseFirestore

struct BookReturnProcessView: View {
    let isbn: String
    @ObservedObject var viewModel: LibrarianHomeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var bookDetails: BookDetails?
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showMemberScanner = false
    @State private var id: String? // Member ID from Firestore
    @State private var isBookIssued = false
    @State private var showConfirmation = false
    
    // New states for fine handling
    @State private var fine: Fine?
    @State private var showFineAlert = false
    @State private var processingFinePayment = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading book details...")
                } else if !errorMessage.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Go Back") {
                            dismiss()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                } else if let book = bookDetails {
                    ScrollView {
                        VStack(alignment: .center, spacing: 20) {
                            // Book Image
                            if let imageURL = book.imageURL, let url = URL(string: imageURL) {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 150, height: 200)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 200)
                                            .cornerRadius(8)
                                    case .failure:
                                        Image(systemName: "book.closed.fill")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 150, height: 200)
                                            .foregroundColor(.gray)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            } else {
                                Image(systemName: "book.closed.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 200)
                                    .foregroundColor(.gray)
                            }
                            
                            // Book Details
                            VStack(spacing: 5) {
                                Text(book.title)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                
                                Text("by \(book.author)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("ISBN: \(isbn)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Divider()
                            
                            // Book Stats
                            HStack(spacing: 15) {
                                VStack {
                                    Text("Total")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(book.totalCount)")
                                        .font(.title3)
                                }
                                
                                VStack {
                                    Text("Issued")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(book.issuedCount)")
                                        .font(.title3)
                                }
                                
                                VStack {
                                    Text("Available")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Text("\(book.unreservedCount)")
                                        .font(.title3)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            
                            Divider()
                            
                            if id == nil {
                                Button(action: {
                                    showMemberScanner = true
                                }) {
                                    HStack {
                                        Image(systemName: "qrcode.viewfinder")
                                        Text("Scan Member QR Code")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            } else {
                                if isBookIssued {
                                    VStack(spacing: 10) {
                                        Text("Member ID: \(id!)")
                                            .fontWeight(.medium)
                                        
                                        // Display fine info if present
                                        if let fine = fine, fine.fineAmount > 0 {
                                            VStack(alignment: .leading, spacing: 5) {
                                                Text("Fine Information:")
                                                    .font(.headline)
                                                
                                                HStack {
                                                    Text("Days overdue:")
                                                    Spacer()
                                                    Text("\(fine.daysOverdue)")
                                                }
                                                
                                                HStack {
                                                    Text("Fine amount:")
                                                    Spacer()
                                                    Text("₹\(String(format: "%.2f", fine.fineAmount))")
                                                        .foregroundColor(.red)
                                                        .fontWeight(.bold)
                                                }
                                                
                                                Button(action: {
                                                    processFinePayment()
                                                }) {
                                                    Text("Due Paid")
                                                        .frame(maxWidth: .infinity)
                                                        .padding()
                                                        .background(Color.purple)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(8)
                                                }
                                                .padding(.top, 5)
                                            }
                                            .padding()
                                            .background(Color.secondary.opacity(0.1))
                                            .cornerRadius(8)
                                            .padding(.vertical)
                                        } else {
                                            Button(action: {
                                                showConfirmation = true
                                            }) {
                                                Text("Confirm Return")
                                                    .frame(maxWidth: .infinity)
                                                    .padding()
                                                    .background(Color.green)
                                                    .foregroundColor(.white)
                                                    .cornerRadius(8)
                                            }
                                            .padding(.horizontal)
                                        }
                                    }
                                } else {
                                    VStack(spacing: 10) {
                                        Text("This book is not issued to this member")
                                            .foregroundColor(.red)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                        
                                        Button(action: {
                                            id = nil
                                        }) {
                                            Text("Scan Another Member")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.blue)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Return Book")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                // Fetch book details when view appears
                fetchBookDetails()
            }
            .sheet(isPresented: $showMemberScanner, onDismiss: {
                // Handle when member scanner is dismissed
                if let memberId = id {
                    checkIfBookIsIssuedToMember(isbn: isbn, memberId: memberId)
                }
            }) {
                // Member QR code scanner
                MemberQRScannerView(memberID: $id)
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Confirm Return"),
                    message: Text("Are you sure you want to process the return for this book?"),
                    primaryButton: .default(Text("Return")) {
                        processBookReturn()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .alert("Fine Due", isPresented: $showFineAlert) {
                Button("Pay Fine (₹\(String(format: "%.2f", fine?.fineAmount ?? 0.0)))") {
                    processFinePayment()
                }
                Button("Cancel", role: .cancel) {
                    // Reset states
                    fine = nil
                    id = nil
                }
            } message: {
                if let fine = fine {
                    Text("This book is \(fine.daysOverdue) days overdue. A fine of ₹\(String(format: "%.2f", fine.fineAmount)) is due. Would you like to mark it as paid?")
                } else {
                    Text("Unable to calculate fine amount.")
                }
            }
        }
    }
    
    // Fetch book details from Firestore using ISBN
    private func fetchBookDetails() {
        isLoading = true
        
        // Query Firestore for book with matching ISBN
        viewModel.db.collection("books")
            .whereField("isbn", isEqualTo: isbn)
            .getDocuments { snapshot, error in
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error fetching book details: \(error.localizedDescription)"
                    return
                }
                
                // Check if we found a book with this ISBN
                if let document = snapshot?.documents.first {
                    let data = document.data()
                    
                    // Create BookDetails object
                    bookDetails = BookDetails(
                        id: document.documentID,
                        title: data["name"] as? String ?? "Unknown Title",
                        author: data["author"] as? String ?? "Unknown Author",
                        imageURL: data["imageURL"] as? String,
                        totalCount: data["totalCount"] as? Int ?? 0,
                        reservedCount: data["reservedCount"] as? Int ?? 0,
                        issuedCount: data["issuedCount"] as? Int ?? 0,
                        unreservedCount: data["unreservedCount"] as? Int ?? 0
                    )
                } else {
                    errorMessage = "No book found with ISBN: \(isbn)"
                }
            }
    }
    
    // Check if the scanned book is issued to the scanned member
    private func checkIfBookIsIssuedToMember(isbn: String, memberId: String) {
        isLoading = true
        print("Starting check for ISBN: \(isbn) and Member ID: \(memberId)")
        
        // First, check if there's a document with the ID equal to memberId
        viewModel.db.collection("members").document(memberId).getDocument { (directSnapshot, directError) in
            if directSnapshot?.exists == true {
                // Document with memberId exists directly, proceed with normal flow
                print("Member found directly with ID: \(memberId)")
                self.continueBookCheck(isbn: isbn, memberId: memberId)
            } else {
                // Try to find a document where the 'id' field equals memberId
                print("Direct lookup failed, trying to find member by 'id' field")
                
                viewModel.db.collection("members")
                    .whereField("id", isEqualTo: memberId)
                    .getDocuments { (querySnapshot, queryError) in
                        if let error = queryError {
                            isLoading = false
                            errorMessage = "Error looking up member: \(error.localizedDescription)"
                            print("Query error: \(error.localizedDescription)")
                            return
                        }
                        
                        if let document = querySnapshot?.documents.first {
                            // Found a document with matching 'id' field, use its document ID
                            let actualMemberId = document.documentID
                            print("Found member with document ID: \(actualMemberId)")
                            self.continueBookCheck(isbn: isbn, memberId: actualMemberId)
                        } else {
                            isLoading = false
                            errorMessage = "Member not found"
                            print("Member not found by any method")
                        }
                    }
            }
        }
    }

    // Helper method to continue with book check after member is found
    private func continueBookCheck(isbn: String, memberId: String) {
        // Then get the book ID
        viewModel.db.collection("books")
            .whereField("isbn", isEqualTo: isbn)
            .getDocuments { snapshot, error in
                if let error = error {
                    isLoading = false
                    errorMessage = "Error checking book: \(error.localizedDescription)"
                    print("Book lookup error: \(error.localizedDescription)")
                    return
                }
                
                // Get book ID from ISBN
                guard let document = snapshot?.documents.first else {
                    isLoading = false
                    errorMessage = "Book not found with ISBN: \(isbn)"
                    print("No book found with ISBN: \(isbn)")
                    return
                }
                
                let bookID = document.documentID
                print("Found book with ID: \(bookID)")
                
                // Check issued books for this member
                let issuedRef = self.viewModel.db.collection("members")
                    .document(memberId)
                    .collection("userbooks")
                    .document("collection")
                    .collection("issued")
                
                print("Checking path: \(issuedRef.path)")
                
                issuedRef.getDocuments { (issuedSnapshot, error) in
                    if let error = error {
                        self.isLoading = false
                        self.errorMessage = "Error checking issued books: \(error.localizedDescription)"
                        print("Error fetching issued books: \(error.localizedDescription)")
                        return
                    }
                    
                    // Log all document IDs for debugging
                    print("Found \(issuedSnapshot?.documents.count ?? 0) issued books")
                    if let documents = issuedSnapshot?.documents {
                        for doc in documents {
                            print("Issued book ID: \(doc.documentID)")
                        }
                    }
                    
                    // Check if any of the issued books match the current book
                    let isBookIssued = issuedSnapshot?.documents.contains { document in
                        let matched = document.documentID == bookID
                        print("Comparing \(document.documentID) with \(bookID): \(matched)")
                        return matched
                    } ?? false
                    
                    print("Final result - Is Book Issued: \(isBookIssued)")
                    
                    // Update the state
                    self.isBookIssued = isBookIssued
                    
                    // If book is issued, check for fines before proceeding
                    if isBookIssued {
                        // Check for fines
                        self.viewModel.getFineForBook(memberID: memberId, bookID: bookID) { fine in
                            self.isLoading = false
                            
                            if let fine = fine, fine.fineAmount > 0 {
                                // There's a fine to be paid
                                self.fine = fine
                                // Update the UI to show fine information
                                // The fine info will be displayed in the UI
                            } else {
                                // No fine or zero amount, leave fine as nil
                                self.fine = nil
                            }
                        }
                    } else {
                        // If book is not issued, set an error message
                        self.isLoading = false
                        self.errorMessage = "This book is not currently issued to this member"
                    }
                }
            }
    }
    
    // Process fine payment
    private func processFinePayment() {
        guard let fine = fine, let memberId = id, let book = bookDetails else {
            return
        }
        
        processingFinePayment = true
        isLoading = true
        
        // Mark fine as paid in Firestore
        viewModel.markFineAsPaid(memberID: memberId, bookID: book.id, fine: fine) { success in
            if success {
                // Record the fine payment activity
                viewModel.recordFinePayment(
                    bookID: book.id,
                    bookTitle: book.title,
                    memberID: memberId,
                    memberName: "Member ID: \(memberId)", // You might want to fetch the actual name
                    amount: fine.fineAmount
                )
                
                // Update local state
                self.fine = nil
                self.processingFinePayment = false
                
                // Proceed with confirmation dialog
                self.showConfirmation = true
            } else {
                // Handle error
                                self.errorMessage = "Failed to process fine payment"
                                self.processingFinePayment = false
                                self.isLoading = false
                            }
                        }
                    }
                    
                    // Process the book return in Firestore
                    private func processBookReturn() {
                        guard let book = bookDetails, let scannedMemberId = id else { return }
                        
                        isLoading = true
                        
                        // First, find the actual member document ID
                        viewModel.db.collection("members")
                            .whereField("id", isEqualTo: scannedMemberId)
                            .getDocuments { (memberSnapshot, memberError) in
                                if let error = memberError {
                                    isLoading = false
                                    errorMessage = "Error finding member: \(error.localizedDescription)"
                                    return
                                }
                                
                                let actualMemberId: String
                                
                                if let memberDoc = memberSnapshot?.documents.first {
                                    // Use the actual document ID from Firestore
                                    actualMemberId = memberDoc.documentID
                                    print("Found member document ID: \(actualMemberId)")
                                } else {
                                    // Try direct lookup as fallback
                                    self.viewModel.db.collection("members").document(scannedMemberId).getDocument { (directSnapshot, directError) in
                                        if directSnapshot?.exists != true {
                                            self.isLoading = false
                                            self.errorMessage = "Member not found"
                                            print("Member not found by any method")
                                            return
                                        }
                                        
                                        // Continue with direct ID
                                        print("Using direct member ID: \(scannedMemberId)")
                                        self.continueBookReturn(scannedMemberId: scannedMemberId, actualMemberId: scannedMemberId, book: book)
                                    }
                                    return
                                }
                                
                                // Continue with found member ID
                                self.continueBookReturn(scannedMemberId: scannedMemberId, actualMemberId: actualMemberId, book: book)
                            }
                    }
                    
                    // Helper method to continue with book return after member is found
                    private func continueBookReturn(scannedMemberId: String, actualMemberId: String, book: BookDetails) {
                        let bookID = book.id
                        
                        // Get the issued document path
                        let issuedBookRef = viewModel.db.collection("members")
                            .document(actualMemberId)
                            .collection("userbooks")
                            .document("collection")
                            .collection("issued")
                            .document(bookID)
                        
                        // Get the issued timestamp from the issued document
                        issuedBookRef.getDocument { issuedDoc, error in
                            if let error = error {
                                self.isLoading = false
                                self.errorMessage = "Error getting issued data: \(error.localizedDescription)"
                                print("Error getting issued doc: \(error.localizedDescription)")
                                return
                            }
                            
                            guard let issuedData = issuedDoc?.data() else {
                                self.isLoading = false
                                self.errorMessage = "Book issue data not found"
                                print("No data in issued document")
                                return
                            }
                            
                            print("Found issued data: \(issuedData)")
                            
                            // Create a batch to ensure all operations succeed or fail together
                            let batch = self.viewModel.db.batch()
                            
                            let requestedTimestamp = issuedData["requestedTimestamp"] as? Timestamp ?? Timestamp(date: Date())
                            let issuedTimestamp = issuedData["issuedTimestamp"] as? Timestamp ?? Timestamp(date: Date())
                            let currentDate = Date()
                            
                            // Get fine information if it exists
                            let fineAmount = self.fine?.fineAmount
                            let finePaid = self.fine != nil && fineAmount != nil && fineAmount! > 0 ? true : false
                            
                            // Add history record with fine information
                            let historyRef = self.viewModel.db.collection("members")
                                .document(actualMemberId)
                                .collection("userbooks")
                                .document("collection")
                                .collection("history")
                                .document(bookID)
                            
                            let historyData = BookHistory.createReturnedWithFine(
                                bookID: bookID,
                                userID: scannedMemberId,
                                requestTimestamp: requestedTimestamp.dateValue(),
                                issuedTimestamp: issuedTimestamp.dateValue(),
                                returnedTimestamp: currentDate,
                                fineAmount: fineAmount,
                                finePaid: finePaid
                            )
                            
                            batch.setData(historyData, forDocument: historyRef)
                            
                            // Delete from issued collection
                            batch.deleteDocument(issuedBookRef)
                            
                            // Update book counts
                            let bookRef = self.viewModel.db.collection("books").document(bookID)
                            batch.updateData([
                                "issuedCount": FieldValue.increment(Int64(-1)),
                                "unreservedCount": FieldValue.increment(Int64(1))
                            ], forDocument: bookRef)
                            
                            // Update or delete the fine record
                            let fineRef = self.viewModel.db.collection("members")
                                .document(actualMemberId)
                                .collection("userbooks")
                                .document("collection")
                                .collection("fines")
                                .document(bookID)
                            
                            // If fine was paid (or no fine exists), delete the fine record
                            // Otherwise mark it as paid
                            if finePaid || self.fine == nil {
                                batch.deleteDocument(fineRef)
                            } else if let fine = self.fine {
                                batch.updateData([
                                    "isPaid": true,
                                    "lastCalculated": Timestamp(date: currentDate)
                                ], forDocument: fineRef)
                            }
                            
                            // Commit the batch
                            batch.commit { error in
                                self.isLoading = false
                                
                                if let error = error {
                                    self.errorMessage = "Failed to process return: \(error.localizedDescription)"
                                    print("Batch commit error: \(error.localizedDescription)")
                                    return
                                }
                                
                                // Success - update stats and record activity
                                self.viewModel.returnedCount += 1
                                self.viewModel.loadData() // Refresh all stats
                                
                                // Add to recent activities using the new method
                                self.viewModel.addReturnActivity(
                                    bookID: bookID,
                                    bookTitle: book.title,
                                    memberID: scannedMemberId,
                                    fineAmount: fineAmount
                                )
                                
                                // Dismiss the view
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.dismiss()
                                }
                            }
                        }
                    }
                }
