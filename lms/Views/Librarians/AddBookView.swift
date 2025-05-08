import SwiftUI

// MARK: - Add Book View
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    @State private var manualISBN = ""
    @State private var addingBookManually = false
    @State private var newBook = LibraryBook.empty
    @State private var isLoading = false
    @State private var isbnStatus = ""
    @State private var showingEditView = false
    @Binding var showFeedback: Bool
    @Binding var feedbackMessage: String
    @Binding var isSuccess: Bool
    @Binding var scannedCode: String
    @Binding var showingScanner: Bool
    @Binding var showingBookPreview: Bool
    @Binding var previewBook: LibraryBook?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Add a New Book")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                if addingBookManually {
                    // Manual book entry form
                    ManualBookEntryForm(book: $newBook, onSave: {
                        // Show preview instead of directly adding
                        previewBook = newBook
                        showingBookPreview = true
                        dismiss()
                    })
                } else {
                    // Options to add book
                    VStack(spacing: 20) {
                        Button(action: {
                            print("📷 Scan ISBN button tapped")
                            scannedCode = ""
                            showingScanner = true
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.title2)
                                Text("Scan ISBN Barcode")
                                    .font(.title3)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                        VStack(spacing: 15) {
                            Text("OR")
                                .fontWeight(.bold)
                                .foregroundColor(.gray)
                            
                            TextField("Enter ISBN Manually", text: $manualISBN)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .keyboardType(.numberPad)
                                .onChange(of: manualISBN) { newValue in
                                    print("📝 ISBN entered: \(newValue)")
                                    isbnStatus = ""
                                }
                            
                            if !isbnStatus.isEmpty {
                                HStack {
                                    Image(systemName: isbnStatus.contains("not found") ? "exclamationmark.triangle" : "info.circle")
                                        .foregroundColor(isbnStatus.contains("not found") ? .orange : .blue)
                                    Text(isbnStatus)
                                        .font(.caption)
                                        .foregroundColor(isbnStatus.contains("not found") ? .orange : .blue)
                                }
                                .padding(.horizontal)
                            }
                            
                            Button("Look Up ISBN") {
                                lookUpISBN()
                            }
                            .disabled(manualISBN.isEmpty || isLoading)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(manualISBN.isEmpty || isLoading ? Color.gray : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .overlay(
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                        }
                        
                        Divider()
                        
                        Button("Add Book Manually") {
                            print("📝 Add Book Manually button tapped")
                            addingBookManually = true
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                print("❌ Add book cancelled")
                dismiss()
            })
            .sheet(isPresented: $showingEditView) {
                if let existingBook = viewModel.existingBook {
                    EditBookView(book: existingBook, viewModel: viewModel)
                }
            }
            .alert(isPresented: $viewModel.showDuplicateAlert) {
                Alert(
                    title: Text("Book Already Exists"),
                    message: Text("A book with ISBN \(viewModel.existingBook?.isbn ?? "") already exists in the library. Would you like to edit it?"),
                    primaryButton: .default(Text("Edit")) {
                        showingEditView = true
                    },
                    secondaryButton: .cancel(Text("Cancel")) {
                        // Reset state
                        manualISBN = ""
                        viewModel.existingBook = nil
                        dismiss()
                    }
                )
            }
            .onAppear {
                print("➕ AddBookView appeared")
            }
        }
    }
    
    private func lookUpISBN() {
        guard !manualISBN.isEmpty else { return }
        
        print("🔍 Looking up ISBN: \(manualISBN)")
        isLoading = true
        isbnStatus = "Checking ISBN..."
        
        viewModel.fetchBookByISBN(isbn: manualISBN) { success, book in
            isLoading = false
            
            if success, let bookInfo = book {
                print("✅ Found book in Google Books API: \(bookInfo.name)")
                
                // Show book preview instead of directly adding
                previewBook = bookInfo
                showingBookPreview = true
                dismiss()
            } else if let existingBook = viewModel.existingBook, viewModel.showDuplicateAlert {
                // The duplicate alert will be shown automatically via the viewModel
                print("⚠️ Book with ISBN \(manualISBN) already exists: \(existingBook.name)")
                // No need to do anything else here as the alert binding will trigger the alert
                isbnStatus = ""
            } else {
                print("❌ Failed to find book for ISBN: \(manualISBN)")
                isbnStatus = "ISBN not found. Try entering details manually."
                
                // Pre-fill the manual form with the ISBN
                addingBookManually = true
                newBook.isbn = manualISBN
            }
        }
    }
}

// MARK: - Manual Book Entry Form
struct ManualBookEntryForm: View {
    @Binding var book: LibraryBook
    var onSave: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 15) {
                Group {
                    Text("Book Details").font(.headline)
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
                    TextField("Release Year", value: $book.releaseYear, format: .number)
                        .keyboardType(.numberPad)
                        .onChange(of: book.releaseYear) { newValue in
                            print("📝 Book release year changed: \(newValue)")
                        }
                    TextField("Description", text: $book.description)
                        .frame(height: 100)
                        .onChange(of: book.description) { newValue in
                            print("📝 Book description changed to \(newValue.count) characters")
                        }
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 5)
                
                Group {
                    Text("Library Details").font(.headline)
                    TextField("Total Count", value: $book.totalCount, format: .number)
                        .keyboardType(.numberPad)
                        .onChange(of: book.totalCount) { newValue in
                            print("📝 Book total count changed: \(newValue)")
                        }
                    TextField("Floor", value: $book.location.floor, format: .number)
                        .keyboardType(.numberPad)
                        .onChange(of: book.location.floor) { newValue in
                            print("📝 Book floor changed: \(newValue)")
                        }
                    TextField("Shelf", text: $book.location.shelf)
                        .onChange(of: book.location.shelf) { newValue in
                            print("📝 Book shelf changed: \(newValue)")
                        }
                    
                    ColorPicker("Cover Color", selection: Binding(
                        get: { Color(book.coverColor.lowercased()) },
                        set: {
                            book.coverColor = $0.description
                            print("📝 Book cover color changed: \(book.coverColor)")
                        }
                    ))
                }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.bottom, 5)
                
                Button("Save Book") {
                    print("💾 Save Book button tapped")
                    // Set initial availability counts
                    book.unreservedCount = book.totalCount
                    book.reservedCount = 0
                    book.issuedCount = 0
                    
                    // Set creation date
                    book.dateCreated = Date()
                    
                    print("📊 Book availability set - Total: \(book.totalCount), Unreserved: \(book.unreservedCount)")
                    print("📆 Book creation date set: \(book.dateCreated)")
                    
                    onSave()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.top)
            }
            .padding()
        }
        .onAppear {
            print("📝 ManualBookEntryForm appeared")
            print("🆔 New book UUID: \(book.id)")
        }
    }
}
