//
//  BookDetailsView.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//

import SwiftUI

// MARK: - Book Details View
struct BookDetailsView: View {
    let book: LibraryBook
    @ObservedObject var viewModel: LibraryViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingEditView = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                // Book Cover
                if let imageURL = book.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 300)
                                .cornerRadius(15)
                        case .failure:
                            Image(systemName: "book.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 300)
                                .foregroundColor(.gray)
                                .onAppear {
                                    print("❌ Failed to load detail image for book: \(book.name)")
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    // Placeholder if no image
                    ZStack {
                        Rectangle()
                            .fill(Color(book.coverColor.lowercased()))
                            .frame(height: 300)
                            .cornerRadius(15)
                        
                        Text(String(book.name.prefix(1)))
                            .font(.system(size: 100))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .onAppear {
                        print("📕 Using placeholder for book detail: \(book.name)")
                    }
                }
                
                // Book Details
                VStack(alignment: .leading, spacing: 10) {
                    Text(book.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("by \(book.author)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    DetailRow(icon: "tag", title: "ISBN", value: book.isbn)
                    DetailRow(icon: "list.bullet", title: "Genre", value: book.genre)
                    DetailRow(icon: "calendar", title: "Release Year", value: "\(book.releaseYear)")
                    DetailRow(icon: "building", title: "Location", value: "Floor \(book.location.floor), Shelf \(book.location.shelf)")
                    
                    Divider()
                    
                    Text("Description")
                        .font(.headline)
                    Text(book.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack {
                        Text("Availability")
                            .font(.headline)
                        Spacer()
                        Text("Total: \(book.totalCount)")
                        Text("Unreserved: \(book.unreservedCount)")
                            .foregroundColor(book.unreservedCount > 0 ? .green : .red)
                    }
                    
                    // Action Buttons
                    HStack(spacing: 15) {
                        // Edit Button
                        Button(action: {
                            print("✏️ Edit button tapped for: \(book.id)")
                            showingEditView = true
                        }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Edit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        // Delete Button
                        Button(action: {
                            print("🗑️ Delete button tapped for: \(book.id)")
                            showingDeleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingDeleteConfirmation) {
            Alert(
                title: Text("Delete Book"),
                message: Text("Are you sure you want to delete '\(book.name)'? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteBook()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingEditView) {
            EditBookView(book: book, viewModel: viewModel)
        }
        .onAppear {
            print("📖 BookDetailsView appeared for: \(book.name) (ID: \(book.id))")
        }
    }
    
    private func deleteBook() {
        viewModel.deleteBook(book) { success in
            if success {
                print("✅ Book successfully deleted: \(book.id)")
                presentationMode.wrappedValue.dismiss()
            } else {
                print("❌ Failed to delete book: \(book.id)")
            }
        }
    }
}

// MARK: - Preview Provider
struct BookDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        BookDetailsView(
            book: LibraryBook(
                id: "preview-id",
                name: "Sample Book",
                isbn: "9781234567890",
                genre: "Fiction",
                author: "Author Name",
                releaseYear: 2023,
                language: ["en"],
                dateCreated: Date(),
                imageURL: nil,
                rating: 4.5,
                location: BookLocation(floor: 1, shelf: "A1"),
                totalCount: 5,
                unreservedCount: 3,
                reservedCount: 1,
                issuedCount: 1,
                description: "This is a sample book description for preview purposes.",
                coverColor: "blue",
                pageCount: 300
            ),
            viewModel: LibraryViewModel()
        )
    }
}
