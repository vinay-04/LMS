//
//  PopularBooksView.swift
//  LMS_USER
//
//  Created by admin3 on 03/05/25.
//

import SwiftUI

struct PopularBooksView: View {
    @StateObject private var viewModel = PopularBooksViewModel()
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 160), spacing: 16)],
                spacing: 16
            ) {
                ForEach(viewModel.books) { book in
                    PopularBookView(book: book)
                }
            }
            .padding()
        }
        .navigationTitle("Popular Books")
        .onAppear {
            viewModel.fetchAllPopularBooks()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

class PopularBooksViewModel: ObservableObject {
    @Published var books: [LibraryBook] = []
    @Published var isLoading = false
    private let bookService = BookService()
    
    func fetchAllPopularBooks() {
        isLoading = true
        bookService.fetchAllPopularBooks { [weak self] (result: Result<[LibraryBook], Error>) in // Added type annotation
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let books):
                    self?.books = books
                case .failure(let error):
                    print("Error fetching popular books: \(error.localizedDescription)")
                }
            }
        }
    }
}
