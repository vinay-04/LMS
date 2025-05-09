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
            ZStack(alignment: .bottomTrailing) {
                // Main content with fixed top spacer
                VStack(spacing: 0) {
                    // Fixed spacer to prevent jumping
                    Color.clear
                        .frame(height: 1)
                        .background(Color(.systemBackground))
                    
                    // Search Bar
                    SearchBar(text: $searchText, onSearchButtonClicked: {
                        viewModel.searchBooks(query: searchText)
                    })
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Books List
                    if viewModel.isSearching {
                        SearchResultsView(books: viewModel.searchResults, viewModel: viewModel)
                    } else {
                        BookListView(books: viewModel.books, viewModel: viewModel)
                    }
                    
                    Spacer() // Push content up
                }
                
                // Floating Action Button
                Button(action: {
                    showingAddBookSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.indigo)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 4)
                        .padding(24)
                }
                .accessibilityLabel("Add new book")
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.inline)
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
                        scannedCode = ""
                        viewModel.existingBook = nil
                    }
                )
            }
            .overlay(
                Group {
                    if showFeedback {
                        VStack {
                            Spacer()
                            
                            HStack {
                                Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundColor(isSuccess ? .green : .red)
                                Text(feedbackMessage)
                                    .font(.subheadline)
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .shadow(radius: 2)
                            .padding(.bottom, 24)
                            .transition(.move(edge: .bottom))
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    withAnimation {
                                        showFeedback = false
                                    }
                                }
                            }
                        }
                        .animation(.easeInOut, value: showFeedback)
                    }
                }
            )
            .onChange(of: viewModel.errorMessage) { newValue in
                if let errorMessage = newValue {
                    feedbackMessage = errorMessage
                    isSuccess = false
                    showFeedback = true
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    private func processScannedISBN() {
        viewModel.fetchBookByISBN(isbn: scannedCode) { success, book in
            if success, let bookInfo = book {
                previewBook = bookInfo
                showingBookPreview = true
            } else if viewModel.existingBook == nil {
                feedbackMessage = "Could not find book with ISBN: \(scannedCode)"
                isSuccess = false
                showFeedback = true
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
