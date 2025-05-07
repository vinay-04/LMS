//
//  explore.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

// MARK: - Explore Screen View

struct ExploreView: View {
    @StateObject private var bookService = BookService()
    @State private var searchText = ""
    @State private var selectedGenre: String? = nil
    @State private var showFilterSheet = false
    @State private var isGridView = false
    @State private var sortOption = SortOption.newest
    @State private var showSortMenu = false
    @State private var animateList = false

    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
    private let gridCardWidth: CGFloat = (UIScreen.main.bounds.width - 48) / 2

    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case titleAZ = "Title A-Z"
        case titleZA = "Title Z-A"

        var id: String { rawValue }
    }

    var filteredBooks: [LibraryBook] {
        var books = bookService.allBooks

        if !searchText.isEmpty {
            books = books.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.author.localizedCaseInsensitiveContains(searchText)
            }
        }

        if let genre = selectedGenre {
            books = books.filter { $0.genre == genre }
        }

        switch sortOption {
        case .newest:
            books.sort { $0.releaseYear > $1.releaseYear }
        case .oldest:
            books.sort { $0.releaseYear < $1.releaseYear }
        case .titleAZ:
            books.sort { $0.name < $1.name }
        case .titleZA:
            books.sort { $0.name > $1.name }
        }

        return books
    }

    var genres: [String] {
        Array(Set(bookService.allBooks.map { $0.genre }))
            .sorted()
    }

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray6),
                        Color(.systemBackground)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    searchAndFilterBar

                    if bookService.isLoading {
                        loadingView
                    } else if let errorMessage = bookService.errorMessage {
                        errorView(message: errorMessage)
                    } else if filteredBooks.isEmpty {
                        emptyStateView
                    } else {
                        if isGridView {
                            bookGridView
                        } else {
                            bookListView
                        }
                    }
                }
                .navigationTitle("Discover Books")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        viewToggleButton
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        sortButton
                    }
                }
                .onAppear {
                    if bookService.allBooks.isEmpty {
                        bookService.fetchAllBooks()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            animateList = true
                        }
                    }
                }
                .refreshable {
                    withAnimation { animateList = false }
                    bookService.fetchAllBooks()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            animateList = true
                        }
                    }
                }
                .sheet(isPresented: $showFilterSheet) {
                    filterView
                }

                if showSortMenu {
                    VStack {
                        sortMenuView
                            .offset(y: 45)
                        Spacer()
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
        .accentColor(.indigo)
    }

    // MARK: - Component Views

    private var searchAndFilterBar: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search books or authors", text: $searchText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 10)

            if !genres.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        GenreFilterButton(
                            title: "All",
                            isSelected: selectedGenre == nil
                        ) { selectedGenre = nil }

                        ForEach(genres, id: \.self) { genre in
                            GenreFilterButton(
                                title: genre,
                                isSelected: selectedGenre == genre
                            ) { selectedGenre = genre }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }

            if selectedGenre != nil || sortOption != .newest {
                HStack {
                    Text("Filters: ")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let genre = selectedGenre {
                        FilterChip(
                            label: genre,
                            onRemove: { selectedGenre = nil }
                        )
                    }
                    if sortOption != .newest {
                        FilterChip(
                            label: "Sort: \(sortOption.rawValue)",
                            onRemove: { sortOption = .newest }
                        )
                    }

                    Spacer()

                    Button("Clear All") {
                        selectedGenre = nil
                        sortOption = .newest
                    }
                    .font(.caption)
                    .foregroundColor(.indigo)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Discovering amazing books for you...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.8))
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding()

            Text("Oops! Something went wrong")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                withAnimation {
                    bookService.fetchAllBooks()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.indigo)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: Color.indigo.opacity(0.3), radius: 5)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "books.vertical")
                .font(.system(size: 70))
                .foregroundColor(.indigo.opacity(0.7))
                .padding()

            Text(searchText.isEmpty
                 ? "No books available"
                 : "No results for '\(searchText)'"
            )
            .font(.title2)
            .fontWeight(.medium)

            if !searchText.isEmpty {
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button {
                    searchText = ""
                    selectedGenre = nil
                } label: {
                    Text("Clear filters")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.systemIndigo))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 10)
            } else {
                Text("Check back later for new additions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    private var bookListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { idx, book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        EnhancedBookRowView(book: book)
                            .frame(width: cardWidth)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1),
                                    radius: 5, x: 0, y: 2)
                            .offset(y: animateList ? 0 : 50)
                            .opacity(animateList ? 1 : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(idx) * 0.05),
                                value: animateList
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 10)
            }
            .padding(.bottom, 20)
        }
    }

    private var bookGridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 16
            ) {
                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { idx, book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        BookGridItemView(book: book,
                                         cardWidth: gridCardWidth)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1),
                                    radius: 4, x: 0, y: 2)
                            .offset(y: animateList ? 0 : 50)
                            .opacity(animateList ? 1 : 0)
                            .animation(
                                .spring(response: 0.5,
                                        dampingFraction: 0.7)
                                .delay(Double(idx % 6) * 0.05),
                                value: animateList
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    private var filterView: some View {
        NavigationView {
            Form {
                Section(header: Text("Sort By")) {
                    ForEach(SortOption.allCases) { option in
                        Button {
                            sortOption = option
                            showFilterSheet = false
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                Spacer()
                                if sortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.indigo)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }

                Section(header: Text("Genre")) {
                    Button {
                        selectedGenre = nil
                        showFilterSheet = false
                    } label: {
                        HStack {
                            Text("All Genres")
                            Spacer()
                            if selectedGenre == nil {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.indigo)
                            }
                        }
                    }
                    .foregroundColor(.primary)

                    ForEach(genres, id: \.self) { genre in
                        Button {
                            selectedGenre = genre
                            showFilterSheet = false
                        } label: {
                            HStack {
                                Text(genre)
                                Spacer()
                                if selectedGenre == genre {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.indigo)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Filter Books")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        selectedGenre = nil
                        sortOption = .newest
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showFilterSheet = false
                    }
                }
            }
        }
    }

    private var viewToggleButton: some View {
        Button {
            withAnimation {
                isGridView.toggle()
                animateList = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation { animateList = true }
                }
            }
        } label: {
            Image(systemName: isGridView
                  ? "list.bullet"
                  : "square.grid.2x2")
                .foregroundColor(.indigo)
        }
    }

    private var sortButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showFilterSheet = false
                showSortMenu.toggle()
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(.indigo)
        }
    }

    private var sortMenuView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SortOption.allCases) { option in
                Button {
                    sortOption = option
                    withAnimation { showSortMenu = false }
                } label: {
                    HStack {
                        Text(option.rawValue)
                            .font(.subheadline)
                        Spacer()
                        if sortOption == option {
                            Image(systemName: "checkmark")
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        sortOption == option
                        ? Color.indigo.opacity(0.1)
                        : Color.clear
                    )
                }
                .foregroundColor(.primary)

                if option != SortOption.allCases.last {
                    Divider().padding(.leading, 16)
                }
            }
        }
        .frame(width: 220)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15),
                radius: 12, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.trailing, 8)
        .offset(x: 70)
    }
}

// MARK: - Supporting Components

struct GenreFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected
                    ? Color.indigo
                    : Color(.systemGray5)
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .shadow(
                    color: isSelected
                    ? Color.indigo.opacity(0.3)
                    : Color.clear,
                    radius: 3
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let label: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .lineLimit(1)
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .padding(4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.indigo.opacity(0.1))
        .foregroundColor(.indigo)
        .cornerRadius(12)
    }
}

struct EnhancedBookRowView: View {
    let book: LibraryBook

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            bookCoverView
                .frame(width: 100, height: 150)
                .padding(4)

            VStack(alignment: .leading, spacing: 8) {
                Text(book.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.indigo)
                    .lineLimit(1)

                StarRatingView(
                    rating: book.rating,
                    starSize: 12,
                    spacing: 2,
                    color: .orange
                )
                .padding(.vertical, 2)

                HStack(spacing: 8) {
                    BookInfoBadge(icon: "calendar", text: "\(book.releaseYear)")
                    BookInfoBadge(icon: "tag",      text: book.genre)
                }

                Text(book.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(12)
        }
        .frame(minHeight: 170)
    }

    private var bookCoverView: some View {
        Group {
            if let url = book.imageURL, !url.isEmpty {
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 100, height: 150)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 150)
                            .cornerRadius(8)
                            .clipped()
                            .shadow(radius: 3)
                    case .failure:
                        coverColorImage
                    @unknown default:
                        coverColorImage
                    }
                }
            } else {
                coverColorImage
            }
        }
    }

    private var coverColorImage: some View {
        ZStack {
            Rectangle()
                .fill(Color(book.coverColor))
                .frame(width: 100, height: 150)
                .cornerRadius(8)
                .shadow(radius: 3)

            VStack(spacing: 4) {
                Text(String(book.name.prefix(1)))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                Text(book.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
        }
    }
}

struct BookInfoBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct BookGridItemView: View {
    let book: LibraryBook
    let cardWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                if let url = book.imageURL, !url.isEmpty {
                    AsyncImage(url: URL(string: url)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 180)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth - 16, height: 180)
                                .cornerRadius(8)
                                .clipped()
                        case .failure:
                            coverColorImage
                        @unknown default:
                            coverColorImage
                        }
                    }
                } else {
                    coverColorImage
                }
            }
            .frame(width: cardWidth - 16, height: 180)
            .cornerRadius(8)
            .padding(8)
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.indigo)
                    .lineLimit(1)
                StarRatingView(
                    rating: book.rating,
                    starSize: 12,
                    spacing: 2,
                    color: .orange
                )
                .padding(.vertical, 4)
                Text(book.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 4)
                HStack {
                    Text(book.genre)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Text("\(book.releaseYear)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .frame(width: cardWidth)
    }

    private var coverColorImage: some View {
        ZStack {
            Rectangle()
                .fill(Color(book.coverColor))
                .frame(width: cardWidth - 16, height: 180)
            VStack(spacing: 8) {
                Text(String(book.name.prefix(2)))
                    .font(.system(size: 46, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                Text(book.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }
}

struct StarRatingView: View {
    let rating: Double
    let maxRating: Int = 5
    let starSize: CGFloat
    let spacing: CGFloat
    let color: Color

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { star in
                Image(systemName:
                    star <= Int(rating) ? "star.fill" :
                    (star == Int(rating) + 1 && rating.truncatingRemainder(dividingBy: 1) >= 0.5)
                    ? "star.leadinghalf.filled" : "star"
                )
                .font(.system(size: starSize))
                .foregroundColor(color)
            }
            Text(String(format: "%.1f", rating))
                .font(.system(size: starSize))
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
