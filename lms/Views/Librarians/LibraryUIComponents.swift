//
//  LibraryUIComponents.swift
//  lms
//
//  Created by user@30 on 03/05/25.
//


import SwiftUI

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search books...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                text = ""
                                print("🧹 Search text cleared")
                                onSearchButtonClicked()
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .onChange(of: text) { newValue in
                    print("🔍 Search text changed: \(newValue)")
                    onSearchButtonClicked()
                }
                .onSubmit {
                    print("⌨️ Search submitted: \(text)")
                    onSearchButtonClicked()
                }
            
            if !text.isEmpty {
                Button("Search") {
                    print("🔎 Search button tapped: \(text)")
                    onSearchButtonClicked()
                }
                .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Book List View
struct BookListView: View {
    let books: [LibraryBook]
    @ObservedObject var viewModel: LibraryViewModel
    @State private var scrolledToBottom = false
    
    var body: some View {
        if books.isEmpty {
            VStack {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
                
                Text("Loading books...")
                    .foregroundColor(.secondary)
            }
            .onAppear {
                print("⏳ Book list loading indicator shown")
            }
        } else {
            List {
                ForEach(books) { book in
                    NavigationLink(destination: BookDetailsView(book: book, viewModel: viewModel)) {
                        // Wrap LibraryBook into BookWithStatus for compatibility
                        BookRow(book: BookWithStatus(
                            book: book,
                            status: .borrowed, // Default status; adjust as needed
                            borrowedDate: Date(),
                            dueDate: nil,
                            returnedDate: nil
                        ))
                    }
                    .onAppear {
                        if book.id == books.last?.id && !scrolledToBottom {
                            print("📜 Reached end of list, loading more books")
                            scrolledToBottom = true
                            viewModel.loadMoreBooks()
                        }
                    }
                }
                
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
            }
            .listStyle(PlainListStyle())
            .onAppear {
                print("📋 Book list populated with \(books.count) books")
                scrolledToBottom = false
            }
        }
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let books: [LibraryBook]
    @ObservedObject var viewModel: LibraryViewModel
    
    var body: some View {
        if books.isEmpty {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .padding()
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No books found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .onAppear {
                    print("🔍 Search returned no results")
                }
            }
        } else {
            List {
                ForEach(books) { book in
                    NavigationLink(destination: BookDetailsView(book: book, viewModel: viewModel)) {
                        // Wrap LibraryBook into BookWithStatus for compatibility
                        BookRow(book: BookWithStatus(
                            book: book,
                            status: .borrowed, // Default status; adjust as needed
                            borrowedDate: Date(),
                            dueDate: nil,
                            returnedDate: nil
                        ))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .onAppear {
                print("🔍 Search returned \(books.count) results")
            }
        }
    }
}

// MARK: - Detail Row Helper
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail Column Helper
struct DetailColumn: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .center) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
    }
}
