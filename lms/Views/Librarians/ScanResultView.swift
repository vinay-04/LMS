//
//  ScanResultView.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUI
import FirebaseFirestore

// Simplified model class - separate from the view
class BookDataModel: ObservableObject {
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var bookData: [String: Any]?
    
    func fetchBook(isbn: String) {
        isLoading = true
        errorMessage = nil
        bookData = nil
        
        let db = Firestore.firestore()
        
        db.collection("books")
            .whereField("isbn", isEqualTo: isbn)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    if let error = error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    if let document = snapshot?.documents.first {
                        self.bookData = document.data()
                    } else {
                        self.errorMessage = "Book not found"
                    }
                }
            }
    }
}

// Main view - keeping the original name
struct ScanResultView: View {
    let isbn: String
    @Environment(\.dismiss) var dismiss
    @StateObject private var dataModel = BookDataModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Content
                VStack {
                    if dataModel.isLoading {
                        ProgressView("Loading book details...")
                            .foregroundColor(.white)
                    } else if let error = dataModel.errorMessage {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.yellow)
                            
                            Text("Error: \(error)")
                                .foregroundColor(.white)
                            
                            Button("Try Again") {
                                dataModel.fetchBook(isbn: isbn)
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .padding()
                    } else if let bookData = dataModel.bookData {
                        // Book details display
                        bookDetailsView(bookData: bookData)
                    } else {
                        Text("No data available")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                            Text("Back")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .onAppear {
                dataModel.fetchBook(isbn: isbn)
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // Extract the book details view to a separate function
    // to simplify the main body and reduce type-checking complexity
    private func bookDetailsView(bookData: [String: Any]) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Book image
                if let imageURL = bookData["imageURL"] as? String,
                   !imageURL.isEmpty,
                   let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .foregroundColor(.white)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 150, height: 200)
                                .cornerRadius(8)
                        case .failure:
                            bookPlaceholder
                        @unknown default:
                            bookPlaceholder
                        }
                    }
                    .padding(.top, 20)
                } else {
                    bookPlaceholder
                        .padding(.top, 20)
                }
                
                // Book title
                Text(bookData["name"] as? String ?? "Unknown Title")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                
                // Basic info rows
                Group {
                    infoRow(label: "Author", value: bookData["author"] as? String ?? "Unknown")
                    
                    infoRow(label: "Copies Available",
                           value: String(bookData["unreservedCount"] as? Int ?? 0))
                    
                    infoRow(label: "Currently Borrowed",
                           value: String(bookData["issuedCount"] as? Int ?? 0))
                    
                    // Location info
                    if let location = bookData["location"] as? [String: Any],
                       let floor = location["floor"],
                       let shelf = location["shelf"] {
                        infoRow(label: "Book Location", value: "Floor \(floor), Shelf \(shelf)")
                    } else {
                        infoRow(label: "Book Location", value: "Not Available")
                    }
                }
                
                Spacer(minLength: 30)
                
                // Scan Member QR Button
                Button(action: {
                    print("Scan Member QR tapped")
                }) {
                    Text("Scan Member QR")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .padding(.horizontal)
        }
    }
    
    // Helper function to create info rows
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
    
    // Book placeholder image
    private var bookPlaceholder: some View {
        Image(systemName: "book.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 200)
            .foregroundColor(.gray)
    }
}

struct ScanResultView_Previews: PreviewProvider {
    static var previews: some View {
        ScanResultView(isbn: "9781234567890")
    }
}
