//
//  BookPreviewView.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//

import SwiftUI

// MARK: - Book Preview View
struct BookPreviewView: View {
    let book: LibraryBook
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var editedBook: LibraryBook
    @State private var isEditing = false
    @State private var isLoading = false
    
    init(book: LibraryBook, viewModel: LibraryViewModel) {
        self.book = book
        self.viewModel = viewModel
        _editedBook = State(initialValue: book)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Book Cover
                    if let imageURL = editedBook.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 250)
                                    .cornerRadius(15)
                            case .failure:
                                Image(systemName: "book.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    } else {
                        // Placeholder if no image
                        ZStack {
                            Rectangle()
                                .fill(Color(editedBook.coverColor.lowercased()))
                                .frame(height: 250)
                                .cornerRadius(15)
                            
                            Text(String(editedBook.name.prefix(1)))
                                .font(.system(size: 80))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    
                    if isEditing {
                        // Editable fields
                        VStack(spacing: 15) {
                            Group {
                                TextField("Title", text: $editedBook.name)
                                TextField("Author", text: $editedBook.author)
                                TextField("ISBN", text: $editedBook.isbn)
                                TextField("Genre", text: $editedBook.genre)
                                
                                HStack {
                                    Text("Release Year:")
                                    Picker("", selection: $editedBook.releaseYear) {
                                        ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                                            Text(String(year)).tag(year)
                                        }
                                    }
                                    .pickerStyle(WheelPickerStyle())
                                    .frame(height: 100)
                                    .clipped()
                                }
                            }
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Group {
                                HStack {
                                    Text("Location:")
                                    Picker("Floor", selection: $editedBook.location.floor) {
                                        ForEach(1...5, id: \.self) { floor in
                                            Text("Floor \(floor)").tag(floor)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                    
                                    TextField("Shelf", text: $editedBook.location.shelf)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 80)
                                }
                                
                                HStack {
                                    Text("Count:")
                                    Stepper("\(editedBook.totalCount)", value: $editedBook.totalCount, in: 1...100)
                                }
                                
                                TextEditor(text: $editedBook.description)
                                    .frame(height: 100)
                                    .border(Color.gray.opacity(0.3))
                                    .cornerRadius(4)
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Display-only fields
                        VStack(alignment: .leading, spacing: 10) {
                            Text(editedBook.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text("by \(editedBook.author)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Text(editedBook.genre)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(6)
                                
                                Spacer()
                                
                                Text("ISBN: \(editedBook.isbn)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                            
                            Divider()
                            
                            HStack {
                                DetailColumn(title: "Published", value: "\(editedBook.releaseYear)")
                                Spacer()
                                DetailColumn(title: "Location", value: "Floor \(editedBook.location.floor), \(editedBook.location.shelf)")
                                Spacer()
                                DetailColumn(title: "Copies", value: "\(editedBook.totalCount)")
                            }
                            
                            Divider()
                            
                            Text("Description")
                                .font(.headline)
                                .padding(.top, 4)
                            
                            Text(editedBook.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            if isEditing {
                                // Save changes locally only
                                isEditing.toggle()
                                print("📝 Preview edits saved locally")
                            } else {
                                // Toggle edit mode
                                isEditing.toggle()
                                print("✏️ Entered edit mode in preview")
                            }
                        }) {
                            HStack {
                                Image(systemName: isEditing ? "checkmark" : "pencil")
                                Text(isEditing ? "Done" : "Edit")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        Button(action: {
                            addBookToLibrary()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("Add to Library")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isLoading)
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                }
                .padding(.vertical)
            }
            .navigationTitle("Book Preview")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") {
                print("❌ Book preview cancelled")
                presentationMode.wrappedValue.dismiss()
            })
            .overlay(
                Group {
                    if isLoading {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("Adding to library...")
                                    .foregroundColor(.white)
                                    .padding(.top)
                            }
                        }
                    }
                }
            )
        }
        .onAppear {
            print("👁️ BookPreviewView appeared for: \(book.name)")
        }
    }
    
    private func addBookToLibrary() {
        print("📚 Adding previewed book to library: \(editedBook.name) (ID: \(editedBook.id))")
        isLoading = true
        
        viewModel.addBook(editedBook) { success, id in
            isLoading = false
            
            if success {
                print("✅ Book successfully added to library with ID: \(id)")
                presentationMode.wrappedValue.dismiss()
            } else {
                print("❌ Failed to add book to library")
                // Show error
            }
        }
    }
}

// MARK: - Preview Provider
struct BookPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        BookPreviewView(
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
