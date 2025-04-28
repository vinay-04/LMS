//
//  MemberHomeView.swift
//  lms
//
//  Created by VR on 27/04/25.
//

import SwiftUI

struct MemberHomeView: View {
    @StateObject private var viewModel: MemberViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showProfileView = false

    private let user: User
    let genres = ["Classics", "Thriller", "Fiction", "Romance"]

    init(user: User) {
        self.user = user
        _viewModel = StateObject(wrappedValue: MemberViewModel(user: user))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            homeTab
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(1)

            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical.fill")
                }
                .tag(2)
        }
        .tint(.blue)
        .sheet(isPresented: $showProfileView) {
            MemberProfileView(user: user)
        }
    }

    // Home Tab Content
    private var homeTab: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView("Loading your books...")
                    .navigationTitle("Welcome")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Currently Reading Section
                        if let currentBook = viewModel.currentlyReading {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Currently Reading")
                                    .font(.title2)
                                    .foregroundColor(.secondary)

                                CurrentReadingCardView(book: currentBook)
                            }
                        }

                        // Reserved Book Section
                        if let reservedBook = viewModel.reservedBook {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Book Reserved")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("Time Left")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                ReservedBookCardView(book: reservedBook)
                            }
                        }

                        // Popular Books Section
                        if !viewModel.popularBooks.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Popular Books")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.popularBooks) { book in
                                            PopularBookView(book: book)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                        }

                        // Collection Stats
                        CollectionStatsView(
                            booksRead: viewModel.booksReadCount,
                            totalBooks: viewModel.totalBooksCount,
                            onAddToCollection: {
                                // Handle add to collection
                            }
                        )

                        // New Releases
                        if !viewModel.newReleases.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("New Releases")
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.newReleases) { book in
                                            NewReleaseBookView(book: book)
                                        }
                                    }
                                    .padding(.bottom, 8)
                                }
                            }
                        }

                        // Explore Genres
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Explore Genres")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16
                            ) {
                                ForEach(genres, id: \.self) { genre in
                                    GenreCardView(
                                        title: genre,
                                        onTapped: {
                                            // Navigate to genre search
                                            selectedTab = 1  // Switch to Explore tab
                                        })
                                }
                            }
                        }
                    }
                    .padding()
                }
                .navigationTitle("Welcome, \(viewModel.username)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showProfileView = true
                        } label: {
                            Image(systemName: "person.circle.fill")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .refreshable {
                    viewModel.fetchBooks()
                }
            }
        }
    }
}

struct MemberHomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock user for preview
        let mockUser = User(
            id: "preview-id",
            fullName: "Preview User",
            email: "preview@example.com",
            profileImageUrl: nil,
            role: .member,
            isVerified: true,
            mfaEnabled: false,
            preferences: nil,
            createdAt: Date()
        )

        MemberHomeView(user: mockUser)
            .environmentObject(AuthViewModel())
    }
}
