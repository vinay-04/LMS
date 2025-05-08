//
//  BookRequestViews.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//

import SwiftUI

// Main view for displaying book requests
struct BookRequestsView: View {
    @StateObject private var viewModel = BookRequestViewModel()
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                Text("Reservation Requests")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                // Content
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                        
                        Text("Loading requests...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.requestedBooks.isEmpty {
                    ContentUnavailableView(
                        "No Book Requests",
                        systemImage: "book.closed",
                        description: Text("There are no pending book reservation requests.")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(viewModel.requestedBooks) { request in
                                BookRequestRow(request: request)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewModel.selectedRequest = request
                                        viewModel.getBookDetails(for: request.bookID)
                                    }
                            }
                        }
                        .padding(.vertical)
                    }
                    .refreshable {
                        viewModel.fetchRequestedBooks()
                    }
                }
                
                if !viewModel.errorMessage.isEmpty {
                    Text(viewModel.errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.showDetailView) {
            if let request = viewModel.selectedRequest, let book = viewModel.selectedBook {
                BookRequestDetailView(
                    viewModel: viewModel,
                    request: request,
                    book: book
                )
            }
        }
        .onAppear {
            viewModel.fetchRequestedBooks()
        }
    }
}

// Row view for each book request
struct BookRequestRow: View {
    let request: BookRequest
    
    var body: some View {
        HStack(spacing: 15) {
            // Book Image with AsyncImage
            if let imageURL = request.bookImageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        Image(systemName: "book.closed.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 110)
                            .foregroundColor(.gray)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 110)
                            .cornerRadius(5)
                    case .failure:
                        Image(systemName: "book.closed.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 110)
                            .foregroundColor(.gray)
                    @unknown default:
                        Image(systemName: "book.closed.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 110)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Image(systemName: "book.closed.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 110)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                // Book Title
                Text(request.bookName ?? "Unknown Book")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.bottom, 5)
                
                // Requested Info
                Group {
                    HStack(alignment: .top, spacing: 5) {
                        Text("Requested by:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(width: 100, alignment: .leading)
                        
                        Text(request.userName ?? "Unknown User")
                            .font(.subheadline)
                    }
                    
                    HStack(alignment: .top, spacing: 5) {
                        Text("Requested on:")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(width: 100, alignment: .leading)
                        
                        Text(request.requestDateFormatted)
                            .font(.subheadline)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        )
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}

// Detail view for a book request
struct BookRequestDetailView: View {
    @ObservedObject var viewModel: BookRequestViewModel
    let request: BookRequest
    let book: RequestBookDetail
    @Environment(\.presentationMode) var presentationMode
    @State private var isProcessing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // Book Image with AsyncImage
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
                                    .shadow(radius: 3)
                            case .failure:
                                Image(systemName: "book.closed.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 200)
                                    .foregroundColor(.gray)
                            @unknown default:
                                Image(systemName: "book.closed.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 150, height: 200)
                                    .foregroundColor(.gray)
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
                        Text(book.name ?? "Unknown Book")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        if let author = book.author {
                            Text("by \(author)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let releaseYear = book.releaseYear {
                            Text("Published: \(releaseYear)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Divider()
                    
                    // Book Counts
                    VStack(spacing: 12) {
                        BookCountRow(title: "Total Count", value: book.totalCount ?? 0)
                        BookCountRow(title: "Reserved Count", value: book.reservedCount ?? 0)
                        BookCountRow(title: "Issued Count", value: book.issuedCount ?? 0)
                        BookCountRow(title: "Available Count", value: book.availableCount)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    // User Information
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Request Information")
                            .font(.headline)
                            .padding(.top)
                        
                        HStack {
                            Text("Requested by:")
                            Spacer()
                            Text(request.userName ?? "Unknown User")
                                .fontWeight(.medium)
                        }
                        
                        HStack {
                            Text("Request Date:")
                            Spacer()
                            Text(request.requestDateFormatted)
                                .fontWeight(.medium)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    Divider()
                    
                    // Action Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            isProcessing = true
                            viewModel.cancelRequest(request: request)
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Cancel")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isProcessing)
                        
                        Button(action: {
                            isProcessing = true
                            viewModel.issueBook(request: request)
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Issue")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(book.availableCount > 0 ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isProcessing || book.availableCount <= 0)
                    }
                    .padding(.vertical)
                    
                    if isProcessing {
                        ProgressView("Processing request...")
                            .padding()
                    }
                }
                .padding()
                .onChange(of: viewModel.showDetailView) { newValue in
                    if !newValue {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Request Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// Helper view for displaying book counts
struct BookCountRow: View {
    var title: String
    var value: Int
    
    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.medium)
            Spacer()
            Text("\(value)")
                .font(.system(.body, design: .monospaced))
        }
    }
}
