

//
//  EditBookView.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//


import SwiftUI

// MARK: - Edit Book View
struct EditBookView: View {
    @State var book: LibraryBook
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isSuccess = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Information")) {
                    TextField("Title", text: $book.name)
                        .onChange(of: book.name) { newValue in
                            print("📝 Book title changed: \(newValue)")
                        }
                    
                    TextField("Author", text: $book.author)
                        .onChange(of: book.author) { newValue in
                            print("📝 Book author changed: \(newValue)")
                        }
                    
                    TextField("ISBN", text: $book.isbn)
                        .onChange(of: book.isbn) { newValue in
                            print("📝 Book ISBN changed: \(newValue)")
                        }
                    
                    TextField("Genre", text: $book.genre)
                        .onChange(of: book.genre) { newValue in
                            print("📝 Book genre changed: \(newValue)")
                        }
                    
                    Picker("Release Year", selection: $book.releaseYear) {
                        ForEach((1900...Calendar.current.component(.year, from: Date())).reversed(), id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .onChange(of: book.releaseYear) { newValue in
                        print("📝 Book release year changed: \(newValue)")
                    }
                }
                
                Section(header: Text("Library Details")) {
                    TextField("Total Count", value: $book.totalCount, format: .number)
                        .keyboardType(.numberPad)
                        .onChange(of: book.totalCount) { newValue in
                            print("📝 Book total count changed: \(newValue)")
                        }
                    
                    TextField("Unreserved Count", value: $book.unreservedCount, format: .number)
                        .keyboardType(.numberPad)
                        .onChange(of: book.unreservedCount) { newValue in
                            print("📝 Book unreserved count changed: \(newValue)")
                        }
                    
                    Picker("Floor", selection: $book.location.floor) {
                        ForEach(1...5, id: \.self) { floor in
                            Text("Floor \(floor)").tag(floor)
                        }
                    }
                    .onChange(of: book.location.floor) { newValue in
                        print("📝 Book floor changed: \(newValue)")
                    }
                    
                    TextField("Shelf", text: $book.location.shelf)
                        .onChange(of: book.location.shelf) { newValue in
                            print("📝 Book shelf changed: \(newValue)")
                        }
                }
                
                Section(header: Text("Book Image")) {
                    TextField("Image URL", text: Binding(
                        get: { book.imageURL ?? "" },
                        set: {
                            book.imageURL = $0.isEmpty ? nil : $0
                            print("📝 Book image URL changed: \(book.imageURL ?? "nil")")
                        }
                    ))
                    
                    if let imageURL = book.imageURL, let url = URL(string: imageURL) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 150)
                                    .cornerRadius(8)
                            case .failure:
                                Text("Failed to load image")
                                    .foregroundColor(.red)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                
                Section(header: Text("Description")) {
                    TextEditor(text: $book.description)
                        .frame(height: 100)
                        .onChange(of: book.description) { newValue in
                            print("📝 Book description changed to \(newValue.count) characters")
                        }
                }
            }
            .navigationTitle("Edit Book")
            .navigationBarItems(
                leading: Button("Cancel") {
                    print("❌ Edit cancelled")
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    saveBook()
                }
                .disabled(isLoading)
            )
            .overlay(
                Group {
                    if isLoading {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                            .overlay(
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("Saving...")
                                        .foregroundColor(.white)
                                        .padding(.top)
                                }
                            )
                    }
                }
            )
        }
        .onAppear {
            print("✏️ EditBookView appeared for: \(book.name) (ID: \(book.id))")
        }
    }
    
    private func saveBook() {
        print("💾 Saving book changes: \(book.id)")
        isLoading = true
        
        viewModel.updateBook(book) { success in
            isLoading = false
            
            if success {
                print("✅ Book successfully updated: \(book.id)")
                presentationMode.wrappedValue.dismiss()
            } else {
                print("❌ Failed to update book: \(book.id)")
                // Show error
            }
        }
    }
}

// MARK: - Preview Provider
struct EditBookView_Previews: PreviewProvider {
    static var previews: some View {
        EditBookView(
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
