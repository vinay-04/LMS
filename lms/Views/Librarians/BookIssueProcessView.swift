//
//  BookIssueProcessView.swift
//  lms
//
//  Created by user@30 on 05/05/25.
//

import SwiftUI
import FirebaseFirestore

struct BookIssueProcessView: View {
    let isbn: String
    @ObservedObject var viewModel: LibrarianHomeViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var bookDetails: BookDetails?
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var showMemberScanner = false
    @State private var id: String? // Changed from memberID to id
    @State private var showConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.edgesIgnoringSafeArea(.all)
                
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
                            
                            // Availability message
                            if book.unreservedCount <= 0 {
                                Text("No copies available for issue")
                                    .foregroundColor(.red)
                                    .padding()
                            } else {
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
                                    VStack(spacing: 10) {
                                        Text("Member ID: \(id!)")
                                            .fontWeight(.medium)
                                        
                                        Button(action: {
                                            showConfirmation = true
                                        }) {
                                            Text("Confirm Issue")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.green)
                                                .foregroundColor(.white)
                                                .cornerRadius(8)
                                        }
                                        .padding(.horizontal)
                                        
                                        Button(action: {
                                            id = nil
                                        }) {
                                            Text("Scan Different Member")
                                                .frame(maxWidth: .infinity)
                                                .padding()
                                                .background(Color.gray)
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
            .navigationTitle("Issue Book")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                dismiss()
            })
            .onAppear {
                // Fetch book details when view appears
                fetchBookDetails()
            }
            .sheet(isPresented: $showMemberScanner) {
                // Member QR code scanner
                MemberQRScannerView(memberID: $id)
            }
            .alert(isPresented: $showConfirmation) {
                Alert(
                    title: Text("Confirm Issue"),
                    message: Text("Are you sure you want to issue this book to the member?"),
                    primaryButton: .default(Text("Issue")) {
                        processBookIssue()
                    },
                    secondaryButton: .cancel(Text("Cancel"))
                )
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
                    let unreservedCount = data["unreservedCount"] as? Int ?? 0
                    
                    if unreservedCount <= 0 {
                        errorMessage = "No copies available for issue"
                    }
                    
                    bookDetails = BookDetails(
                        id: document.documentID,
                        title: data["name"] as? String ?? "Unknown Title",
                        author: data["author"] as? String ?? "Unknown Author",
                        imageURL: data["imageURL"] as? String,
                        totalCount: data["totalCount"] as? Int ?? 0,
                        reservedCount: data["reservedCount"] as? Int ?? 0,
                        issuedCount: data["issuedCount"] as? Int ?? 0,
                        unreservedCount: unreservedCount
                    )
                } else {
                    errorMessage = "No book found with ISBN: \(isbn)"
                }
            }
    }
    
    // Process the book issue in Firestore
    private func processBookIssue() {
        guard let book = bookDetails, let scannedMemberId = id else { return }
        
        // Check if there are available copies
        if book.unreservedCount <= 0 {
            errorMessage = "No copies available for issue"
            return
        }
        
        isLoading = true
        
        let bookID = book.id
        
        // First, find the actual member document ID
        viewModel.db.collection("members")
            .whereField("id", isEqualTo: scannedMemberId)
            .getDocuments { (memberSnapshot, memberError) in
                if let error = memberError {
                    isLoading = false
                    errorMessage = "Error finding member: \(error.localizedDescription)"
                    print("Member query error: \(error.localizedDescription)")
                    return
                }
                
                let actualMemberId: String
                
                if let memberDoc = memberSnapshot?.documents.first {
                    // Use the actual document ID from Firestore
                    actualMemberId = memberDoc.documentID
                    print("Found member document ID: \(actualMemberId) by 'id' field")
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
                        self.continueBookIssue(bookID: bookID, book: book, scannedMemberId: scannedMemberId, actualMemberId: scannedMemberId)
                    }
                    return
                }
                
                // Continue with found member ID
                self.continueBookIssue(bookID: bookID, book: book, scannedMemberId: scannedMemberId, actualMemberId: actualMemberId)
            }
    }

    // Helper method to continue with book issue after member is found
    // Update the continueBookIssue method in BookIssueProcessView.swift
    private func continueBookIssue(bookID: String, book: BookDetails, scannedMemberId: String, actualMemberId: String) {
        // Create a batch to ensure all operations succeed or fail together
        let batch = viewModel.db.batch()
        
        // 1. Add to issued collection
        // Path: members -> actualMemberId -> userbooks -> collection -> issued
        let issuedRef = viewModel.db.collection("members")
            .document(actualMemberId)
            .collection("userbooks")
            .document("collection")
            .collection("issued")
            .document(bookID)
        
        print("Adding issued book at path: \(issuedRef.path)")
        
        let currentDate = Date()
        let issuedData: [String: Any] = [
            "bookUUID": bookID,
            "userId": scannedMemberId, // Use the scanned ID for data consistency
            "issuedTimestamp": Timestamp(date: currentDate),
            "requestedTimestamp": Timestamp(date: currentDate)
        ]
        
        batch.setData(issuedData, forDocument: issuedRef)
        
        // 2. Update book counts
        let bookRef = viewModel.db.collection("books").document(bookID)
        batch.updateData([
            "issuedCount": FieldValue.increment(Int64(1)),
            "unreservedCount": FieldValue.increment(Int64(-1))
        ], forDocument: bookRef)
        
        // Commit the batch
        batch.commit { error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to issue book: \(error.localizedDescription)"
                print("Batch commit error: \(error.localizedDescription)")
                return
            }
            
            // Success - update stats and record activity
            viewModel.borrowedCount += 1
            viewModel.loadData() // Refresh all stats
            
            // Add to recent activities using the new method
            viewModel.addIssueActivity(bookID: bookID, bookTitle: book.title, memberID: scannedMemberId)
            
            // Create a fine record (initially with zero amount)
            viewModel.createFineRecord(
                bookID: bookID,
                bookTitle: book.title,
                memberID: scannedMemberId,
                issuedTimestamp: currentDate
            )
            
            // Dismiss the view
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                dismiss()
            }
        }
    }
}
