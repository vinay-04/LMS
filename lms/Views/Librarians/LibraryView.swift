//
//  LibraryView.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//

import SwiftUI
import AVFoundation

// MARK: - Main Library View
struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showingAddBookSheet = false
    @State private var searchText = ""
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isSuccess = true
    @State private var showingScanner = false
    @State private var scannedCode = ""
    @State private var showingBookPreview = false
    @State private var previewBook: LibraryBook?
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText, onSearchButtonClicked: {
                    viewModel.searchBooks(query: searchText)
                })
                .padding(.horizontal)
                
                // Add Book Button
                Button(action: {
                    print("➕ Add New Book button tapped")
                    showingAddBookSheet = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Book")
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .padding(.bottom)
                
                // Books List
                if viewModel.isSearching {
                    // Display search results
                    SearchResultsView(books: viewModel.searchResults, viewModel: viewModel)
                } else {
                    // Display regular book list
                    BookListView(books: viewModel.books, viewModel: viewModel)
                }
            }
            .navigationTitle("Library")
            .sheet(isPresented: $showingAddBookSheet) {
                AddBookView(
                    viewModel: viewModel,
                    showFeedback: $showFeedback,
                    feedbackMessage: $feedbackMessage,
                    isSuccess: $isSuccess,
                    scannedCode: $scannedCode,
                    showingScanner: $showingScanner,
                    showingBookPreview: $showingBookPreview,
                    previewBook: $previewBook
                )
            }
            .sheet(isPresented: $showingScanner) {
                LibraryBarcodeScannerView(scannedCode: $scannedCode)
                    .onDisappear {
                        if !scannedCode.isEmpty {
                            print("📷 Processing scanned ISBN: \(scannedCode)")
                            processScannedISBN()
                        }
                    }
            }
            .sheet(isPresented: $showingBookPreview) {
                if let book = previewBook {
                    BookPreviewView(book: book, viewModel: viewModel)
                }
            }
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
                        scannedCode = ""
                        viewModel.existingBook = nil
                    }
                )
            }
            .overlay(
                ZStack {
                    if showFeedback {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(isSuccess ? .green : .red)
                                Text(feedbackMessage)
                            }
                            .padding()
                            .background(isSuccess ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .cornerRadius(10)
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal)
                    }
                }
            )
            .onChange(of: viewModel.errorMessage) { newValue in
                if let errorMessage = newValue {
                    feedbackMessage = errorMessage
                    isSuccess = false
                    showFeedback = true
                    
                    // Auto dismiss after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showFeedback = false
                        viewModel.errorMessage = nil
                    }
                }
            }
            .onAppear {
                print("📚 LibraryView appeared")
            }
        }
    }
    
    private func processScannedISBN() {
        print("🔍 Looking up scanned ISBN: \(scannedCode)")
        
        viewModel.fetchBookByISBN(isbn: scannedCode) { success, book in
            if success, let bookInfo = book {
                print("✅ Found book in Google Books API: \(bookInfo.name)")
                
                // Show book preview instead of directly adding
                previewBook = bookInfo
                showingBookPreview = true
            } else if let existingBook = viewModel.existingBook, viewModel.showDuplicateAlert {
                // The duplicate alert will be shown automatically via the viewModel
                print("⚠️ Book with ISBN \(scannedCode) already exists: \(existingBook.name)")
                // No need to do anything else here as the alert binding will trigger the alert
            } else {
                print("❌ Failed to find book for ISBN: \(scannedCode)")
                
                // Show feedback
                feedbackMessage = "Could not find book with ISBN: \(scannedCode)"
                isSuccess = false
                showFeedback = true
                
                // Auto dismiss after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showFeedback = false
                }
            }
        }
    }
}

// MARK: - Preview Provider
struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
