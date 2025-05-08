//import SwiftUI
//
//// MARK: - Explore Screen View
//struct ExploreView: View {
//    @StateObject private var bookService = BookService()
//    @State private var searchText = ""
//    @State private var selectedGenre: String? = nil
//    @State private var showFilterSheet = false
//    @State private var isGridView = false
//    @State private var sortOption = SortOption.newest
//    @State private var showSortMenu = false
//    
//    // Animation properties
//    @State private var animateList = false
//    @State private var showSearchBar = false
//    
//    // Card sizing
//    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
//    private let gridCardWidth: CGFloat = (UIScreen.main.bounds.width - 48) / 2
//    
//    enum SortOption: String, CaseIterable, Identifiable {
//        case newest = "Newest First"
//        case oldest = "Oldest First"
//        case titleAZ = "Title A-Z"
//        case titleZA = "Title Z-A"
//        
//        var id: String { self.rawValue }
//    }
//    
//    var filteredBooks: [LibraryBook] {
//        var books = bookService.allBooks
//        
//        // Filter by search text
//        if !searchText.isEmpty {
//            books = books.filter { book in
//                book.name.localizedCaseInsensitiveContains(searchText) ||
//                book.author.localizedCaseInsensitiveContains(searchText)
//            }
//        }
//        
//        // Filter by genre
//        if let genre = selectedGenre {
//            books = books.filter { $0.genre == genre }
//        }
//        
//        // Sort books
//        switch sortOption {
//        case .newest:
//            books.sort { $0.releaseYear > $1.releaseYear }
//        case .oldest:
//            books.sort { $0.releaseYear < $1.releaseYear }
//        case .titleAZ:
//            books.sort { $0.name < $1.name }
//        case .titleZA:
//            books.sort { $0.name > $1.name }
//        }
//        
//        return books
//    }
//    
//    var genres: [String] {
//        Array(Set(bookService.allBooks.map { $0.genre })).sorted()
//    }
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                // Background gradient
//                LinearGradient(
//                    gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray6)]),
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .ignoresSafeArea()
//                
//                VStack(spacing: 0) {
//                    // Custom navigation header
//                    headerView
//                    
//                    // Expandable search bar
//                    if showSearchBar {
//                        searchBarView
//                            .transition(.move(edge: .top).combined(with: .opacity))
//                    }
//                    
//                    // Genre filters
//                    if !genres.isEmpty {
//                        genreFilterView
//                    }
//                    
//                    // Active filters display
//                    if selectedGenre != nil || sortOption != .newest {
//                        activeFiltersView
//                    }
//                    
//                    // Content based on loading state
////                    ZStack {
////                        if bookService.isLoading {
////                            loadingView
////                        } else if let errorMessage = bookService.errorMessage {
////                            errorView(message: errorMessage)
////                        } else if filteredBooks.isEmpty {
////                            emptyStateView
////                        } else {
////                            // Toggle between list and grid view
////                            if isGridView {
////                                bookGridView
////                            } else {
////                                bookListView
////                            }
////                        }
////                    }
//                    ZStack {
//                        if bookService.isLoading && bookService.allBooks.isEmpty {
//                            loadingView
//                        } else if let errorMessage = bookService.errorMessage {
//                            errorView(message: errorMessage)
//                        } else if filteredBooks.isEmpty {
//                            emptyStateView
//                        } else {
//                            if isGridView {
//                                bookGridView
//                            } else {
//                                bookListView
//                            }
//                        }
//                    }
//                    .animation(.easeInOut, value: bookService.isLoading)
//                }
//                .navigationBarHidden(true)
//                .onAppear {
//                    if bookService.allBooks.isEmpty {
//                        bookService.fetchAllBooks()
//                    }
//                    
//                    // Make sure animation is only triggered if not already animated
//                    if !animateList {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
//                                animateList = true
//                            }
//                        }
//                    }
//                }
////                .refreshable {
////                    withAnimation {
////                        animateList = false
////                    }
////                    bookService.fetchAllBooks()
////
////                    // Reset animation on refresh
////                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
////                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
////                            animateList = true
////                        }
////                    }
////                }
//                .refreshable {
//                    // Don't immediately set animateList to false
//                    // This prevents the UI from collapsing during refresh
//                    bookService.fetchAllBooks()
//                    
//                    // Only reset animation if needed, with a smoother transition
//                    if !animateList {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
//                                animateList = true
//                            }
//                        }
//                    }
//                }
//                .sheet(isPresented: $showFilterSheet) {
//                    filterView
//                        .presentationDetents([.medium, .large])
//                        .presentationDragIndicator(.visible)
//                }
//                
//                // Sort menu dropdown
//                if showSortMenu {
//                    Color.black.opacity(0.1)
//                        .ignoresSafeArea()
//                        .onTapGesture {
//                            withAnimation(.easeInOut(duration: 0.2)) {
//                                showSortMenu = false
//                            }
//                        }
//                    
//                    VStack {
//                        sortMenuView
//                            .offset(y: 100)
//                        Spacer()
//                    }
//                    .transition(.opacity)
//                    .zIndex(1)
//                }
//            }
//        }
//        .accentColor(.indigo)
//    }
//    
//    // MARK: - Component Views
//    
//    private var headerView: some View {
//        HStack {
//            // Logo/Title area
//            VStack(alignment: .leading, spacing: 2) {
//                Text("Bookshelf")
//                    .font(.system(size: 32, weight: .heavy))
//                    .foregroundColor(.primary)
//                
//                Text("Discover your next read")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            // Action buttons
//            HStack(spacing: 16) {
//                // Search button
//                Button(action: {
//                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                        showSearchBar.toggle()
//                    }
//                }) {
//                    Image(systemName: "magnifyingglass")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(showSearchBar ? .indigo : .primary)
//                        .frame(width: 38, height: 38)
//                        .background(
//                            Circle()
//                                .fill(Color.primary.opacity(showSearchBar ? 0.1 : 0.05))
//                        )
//                }
//                
//                // View toggle button
//                Button(action: {
//                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                        isGridView.toggle()
//                        // Reset and re-trigger animation
//                        animateList = false
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                            withAnimation {
//                                animateList = true
//                            }
//                        }
//                    }
//                }) {
//                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(.primary)
//                        .frame(width: 38, height: 38)
//                        .background(
//                            Circle()
//                                .fill(Color.primary.opacity(0.05))
//                        )
//                }
//                
//                // Filter button
//                Button(action: {
//                    showFilterSheet = true
//                }) {
//                    Image(systemName: "slider.horizontal.3")
//                        .font(.system(size: 18, weight: .medium))
//                        .foregroundColor(selectedGenre != nil || sortOption != .newest ? .indigo : .primary)
//                        .frame(width: 38, height: 38)
//                        .background(
//                            Circle()
//                                .fill(Color.primary.opacity(selectedGenre != nil || sortOption != .newest ? 0.1 : 0.05))
//                        )
//                        .overlay(
//                            // Show indicator dot if filters are active
//                            Group {
//                                if selectedGenre != nil || sortOption != .newest {
//                                    Circle()
//                                        .fill(Color.indigo)
//                                        .frame(width: 8, height: 8)
//                                        .offset(x: 12, y: -12)
//                                }
//                            }
//                        )
//                }
//            }
//        }
//        .padding(.horizontal)
//        .padding(.top, 16)
//        .padding(.bottom, 12)
//    }
//    
//    private var searchBarView: some View {
//        HStack {
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.secondary)
//                    .font(.system(size: 16))
//                
//                TextField("Search books or authors", text: $searchText)
//                    .font(.system(size: 16))
//                    .autocapitalization(.none)
//                    .disableAutocorrection(true)
//                
//                if !searchText.isEmpty {
//                    Button(action: {
//                        searchText = ""
//                    }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.secondary)
//                            .font(.system(size: 16))
//                    }
//                }
//            }
//            .padding(12)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(Color(.systemGray6))
//            )
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 8)
//    }
//    
//    private var genreFilterView: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 10) {
//                // "All" filter
//                GenreFilterButton(
//                    title: "All",
//                    isSelected: selectedGenre == nil,
//                    action: { selectedGenre = nil }
//                )
//                
//                // Genre filters
//                ForEach(genres, id: \.self) { genre in
//                    GenreFilterButton(
//                        title: genre,
//                        isSelected: selectedGenre == genre,
//                        action: { selectedGenre = genre }
//                    )
//                }
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 8)
//        }
//    }
//    
//    private var activeFiltersView: some View {
//        HStack {
//            if let genre = selectedGenre {
//                FilterChip(
//                    label: genre,
//                    onRemove: { selectedGenre = nil }
//                )
//            }
//            
//            if sortOption != .newest {
//                FilterChip(
//                    label: "Sort: \(sortOption.rawValue)",
//                    onRemove: { sortOption = .newest }
//                )
//            }
//            
//            Spacer()
//            
//            Button(action: {
//                selectedGenre = nil
//                sortOption = .newest
//            }) {
//                Text("Clear All")
//                    .font(.caption)
//                    .fontWeight(.medium)
//                    .foregroundColor(.indigo)
//            }
//        }
//        .padding(.horizontal)
//        .padding(.bottom, 8)
//    }
//    
//    private var loadingView: some View {
//        VStack(spacing: 24) {
//            BookshelfLoadingView()
//                .frame(width: 120, height: 120)
//            
//            Text("Discovering amazing books for you...")
//                .font(.headline)
//                .foregroundColor(.secondary)
//        }
//    }
//    
//    private func errorView(message: String) -> some View {
//        VStack(spacing: 22) {
//            Image(systemName: "exclamationmark.triangle")
//                .font(.system(size: 60))
//                .foregroundColor(.orange)
//                .padding()
//            
//            Text("Oops! Something went wrong")
//                .font(.title2)
//                .fontWeight(.bold)
//            
//            Text(message)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//            
//            Button(action: {
//                withAnimation {
//                    bookService.fetchAllBooks()
//                }
//            }) {
//                HStack {
//                    Image(systemName: "arrow.clockwise")
//                    Text("Try Again")
//                }
//                .padding(.horizontal, 24)
//                .padding(.vertical, 12)
//                .background(
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(Color.indigo)
//                )
//                .foregroundColor(.white)
//            }
//            .padding(.top, 8)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//    
//    private var emptyStateView: some View {
//        VStack(spacing: 20) {
//            Image(systemName: "books.vertical")
//                .font(.system(size: 70))
//                .foregroundColor(.indigo.opacity(0.7))
//                .padding()
//            
//            Text(searchText.isEmpty ? "No books available" : "No results for '\(searchText)'")
//                .font(.title2)
//                .fontWeight(.medium)
//            
//            if !searchText.isEmpty {
//                Text("Try adjusting your search or filters")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                Button(action: {
//                    searchText = ""
//                    selectedGenre = nil
//                }) {
//                    Text("Clear filters")
//                        .font(.headline)
//                        .padding(.horizontal, 24)
//                        .padding(.vertical, 12)
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color.indigo)
//                        )
//                        .foregroundColor(.white)
//                }
//                .padding(.top, 10)
//            } else {
//                Text("Check back later for new additions")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//    
//    private var bookListView: some View {
//        ScrollView {
//            LazyVStack(spacing: 20) {
//                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
//                    NavigationLink(destination: BookDetailView(book: book)) {
//                        EnhancedBookRowView(book: book)
//                            .frame(width: cardWidth)
//                            .background(
//                                RoundedRectangle(cornerRadius: 16)
//                                    .fill(Color(.systemBackground))
//                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
//                            )
//                            .offset(y: animateList ? 0 : 50)
//                            .opacity(animateList ? 1.0 : 0.0)
//                            .animation(
//                                .spring(response: 0.5, dampingFraction: 0.7)
//                                .delay(Double(index) * 0.05),
//                                value: animateList
//                            )
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//                .padding(.vertical, 10)
//            }
//            .padding(.horizontal)
//            .padding(.bottom, 20)
//        }
//    }
//
//    private var bookGridView: some View {
//        ScrollView {
//            LazyVGrid(columns: [
//                GridItem(.flexible(), spacing: 16),
//                GridItem(.flexible(), spacing: 16)
//            ], spacing: 16) {
//                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
//                    NavigationLink(destination: BookDetailView(book: book)) {
//                        BookGridItemView(book: book, cardWidth: gridCardWidth)
//                            .background(
//                                RoundedRectangle(cornerRadius: 16)
//                                    .fill(Color(.systemBackground))
//                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
//                            )
//                            .offset(y: animateList ? 0 : 50)
//                            .opacity(animateList ? 1.0 : 0.0)
//                            .animation(
//                                .spring(response: 0.5, dampingFraction: 0.7)
//                                .delay(Double(index % 6) * 0.05),
//                                value: animateList
//                            )
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                }
//            }
//            .padding(.horizontal)
//            .padding(.vertical, 10)
//        }
//    }
//    
//    private var filterView: some View {
//        VStack(spacing: 0) {
//            // Handle bar
//            Capsule()
//                .fill(Color(.systemGray3))
//                .frame(width: 40, height: 4)
//                .padding(.top, 8)
//                .padding(.bottom, 20)
//            
//            Text("Filter & Sort")
//                .font(.title2)
//                .fontWeight(.bold)
//                .padding(.bottom, 16)
//            
//            ScrollView {
//                VStack(alignment: .leading, spacing: 24) {
//                    // Sort section
//                    VStack(alignment: .leading, spacing: 14) {
//                        Text("SORT BY")
//                            .font(.caption)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.secondary)
//                            .padding(.leading, 16)
//                        
//                        VStack(spacing: 2) {
//                            ForEach(SortOption.allCases) { option in
//                                Button(action: {
//                                    sortOption = option
//                                }) {
//                                    HStack {
//                                        Text(option.rawValue)
//                                            .foregroundColor(.primary)
//                                        
//                                        Spacer()
//                                        
//                                        if sortOption == option {
//                                            Image(systemName: "checkmark.circle.fill")
//                                                .foregroundColor(.indigo)
//                                        } else {
//                                            Circle()
//                                                .stroke(Color(.systemGray3), lineWidth: 1)
//                                                .frame(width: 20, height: 20)
//                                        }
//                                    }
//                                    .padding()
//                                    .background(
//                                        RoundedRectangle(cornerRadius: 12)
//                                            .fill(sortOption == option ? Color.indigo.opacity(0.1) : Color.clear)
//                                    )
//                                }
//                            }
//                        }
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color(.systemGray6))
//                        )
//                        .padding(.horizontal)
//                    }
//                    
//                    // Genre section
//                    VStack(alignment: .leading, spacing: 14) {
//                        Text("GENRE")
//                            .font(.caption)
//                            .fontWeight(.semibold)
//                            .foregroundColor(.secondary)
//                            .padding(.leading, 16)
//                        
//                        VStack(spacing: 2) {
//                            // All genres option
//                            Button(action: {
//                                selectedGenre = nil
//                            }) {
//                                HStack {
//                                    Text("All Genres")
//                                        .foregroundColor(.primary)
//                                    
//                                    Spacer()
//                                    
//                                    if selectedGenre == nil {
//                                        Image(systemName: "checkmark.circle.fill")
//                                            .foregroundColor(.indigo)
//                                    } else {
//                                        Circle()
//                                            .stroke(Color(.systemGray3), lineWidth: 1)
//                                            .frame(width: 20, height: 20)
//                                    }
//                                }
//                                .padding()
//                                .background(
//                                    RoundedRectangle(cornerRadius: 12)
//                                        .fill(selectedGenre == nil ? Color.indigo.opacity(0.1) : Color.clear)
//                                )
//                            }
//                            
//                            // Genre options
//                            ForEach(genres, id: \.self) { genre in
//                                Button(action: {
//                                    selectedGenre = genre
//                                }) {
//                                    HStack {
//                                        Text(genre)
//                                            .foregroundColor(.primary)
//                                        
//                                        Spacer()
//                                        
//                                        if selectedGenre == genre {
//                                            Image(systemName: "checkmark.circle.fill")
//                                                .foregroundColor(.indigo)
//                                        } else {
//                                            Circle()
//                                                .stroke(Color(.systemGray3), lineWidth: 1)
//                                                .frame(width: 20, height: 20)
//                                        }
//                                    }
//                                    .padding()
//                                    .background(
//                                        RoundedRectangle(cornerRadius: 12)
//                                            .fill(selectedGenre == genre ? Color.indigo.opacity(0.1) : Color.clear)
//                                    )
//                                }
//                            }
//                        }
//                        .background(
//                            RoundedRectangle(cornerRadius: 16)
//                                .fill(Color(.systemGray6))
//                        )
//                        .padding(.horizontal)
//                    }
//                }
//                .padding(.bottom, 20)
//            }
//            
//            // Action buttons
//            HStack(spacing: 16) {
//                // Reset button
//                Button(action: {
//                    selectedGenre = nil
//                    sortOption = .newest
//                }) {
//                    Text("Reset")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 16)
//                        .background(
//                            RoundedRectangle(cornerRadius: 14)
//                                .stroke(Color.indigo, lineWidth: 1)
//                        )
//                        .foregroundColor(.indigo)
//                }
//                
//                // Apply button
//                Button(action: {
//                    showFilterSheet = false
//                }) {
//                    Text("Apply")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                        .padding(.vertical, 16)
//                        .background(
//                            RoundedRectangle(cornerRadius: 14)
//                                .fill(Color.indigo)
//                        )
//                        .foregroundColor(.white)
//                }
//            }
//            .padding()
//            .background(Color(.systemBackground))
//        }
//    }
//    
//    private var sortMenuView: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            VStack(alignment: .leading, spacing: 10) {
//                Text("Sort by")
//                    .font(.headline)
//                    .padding(.horizontal, 16)
//                    .padding(.top, 16)
//                    .padding(.bottom, 8)
//                
//                ForEach(SortOption.allCases) { option in
//                    Button(action: {
//                        sortOption = option
//                        withAnimation {
//                            showSortMenu = false
//                        }
//                    }) {
//                        HStack {
//                            Text(option.rawValue)
//                                .font(.subheadline)
//                            
//                            Spacer()
//                            
//                            if sortOption == option {
//                                Image(systemName: "checkmark")
//                                    .foregroundColor(.indigo)
//                            }
//                        }
//                        .padding(.vertical, 12)
//                        .padding(.horizontal, 16)
//                    }
//                    .foregroundColor(.primary)
//                    
//                    if option != SortOption.allCases.last {
//                        Divider()
//                            .padding(.leading, 16)
//                    }
//                }
//            }
//        }
//        .frame(width: 250)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
//        )
//        .padding(.horizontal)
//        .offset(x: 50)
//    }
//}
//
//struct GenreFilterButton: View {
//    let title: String
//    let isSelected: Bool
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            Text(title)
//                .font(.system(size: 15, weight: isSelected ? .medium : .regular))
//                .padding(.horizontal, 16)
//                .padding(.vertical, 8)
//                .background(
//                    Capsule()
//                        .fill(isSelected ? Color.indigo : Color(.systemGray6))
//                )
//                .foregroundColor(isSelected ? .white : .primary)
//                .shadow(color: isSelected ? Color.indigo.opacity(0.3) : Color.clear, radius: 4)
//        }
//        .buttonStyle(PlainButtonStyle())
//    }
//}
import SwiftUI

struct ExploreView: View {
    @StateObject private var bookService = BookService()
    @StateObject private var speechRecognizer = SpeechRecognizer() // Added for speech recognition
    @State private var searchText = ""
    @State private var selectedGenre: String? = nil
    @State private var showFilterSheet = false
    @State private var isGridView = false
    @State private var sortOption = SortOption.newest
    @State private var showSortMenu = false
    @State private var animateList = false
    @State private var showSearchBar = false
    
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 32
    private let gridCardWidth: CGFloat = (UIScreen.main.bounds.width - 48) / 2
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case titleAZ = "Title A-Z"
        case titleZA = "Title Z-A"
        var id: String { self.rawValue }
    }
    
    var filteredBooks: [LibraryBook] {
        var books = bookService.allBooks
        if !searchText.isEmpty {
            books = books.filter { book in
                book.name.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText)
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
        Array(Set(bookService.allBooks.map { $0.genre })).sorted()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    if showSearchBar {
                        searchBarView
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    if !genres.isEmpty {
                        genreFilterView
                    }
                    if selectedGenre != nil || sortOption != .newest {
                        activeFiltersView
                    }
                    ZStack {
                        if bookService.isLoading && bookService.allBooks.isEmpty {
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
                    .animation(.easeInOut, value: bookService.isLoading)
                }
                .navigationBarHidden(true)
                .onAppear {
                    if bookService.allBooks.isEmpty {
                        bookService.fetchAllBooks()
                    }
                    speechRecognizer.requestPermission { granted in
                        if !granted {
                            print("Speech recognition permission not granted")
                        }
                    }
                    if !animateList {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                animateList = true
                            }
                        }
                    }
                }
                .refreshable {
                    bookService.fetchAllBooks()
                    if !animateList {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                animateList = true
                            }
                        }
                    }
                }
                .sheet(isPresented: $showFilterSheet) {
                    filterView
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
                .onChange(of: speechRecognizer.recognizedText) { newValue in
                    searchText = newValue
                }
                .onChange(of: showSearchBar) { newValue in
                    if !newValue && speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    }
                }
                if showSortMenu {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showSortMenu = false
                            }
                        }
                    VStack {
                        sortMenuView
                            .offset(y: 100)
                        Spacer()
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
        .accentColor(.indigo)
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Bookshelf")
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(.primary)
                Text("Discover your next read")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            HStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSearchBar.toggle()
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(showSearchBar ? .indigo : .primary)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(showSearchBar ? 0.1 : 0.05))
                        )
                }
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isGridView.toggle()
                        animateList = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation {
                                animateList = true
                            }
                        }
                    }
                }) {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(0.05))
                        )
                }
                Button(action: {
                    showFilterSheet = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(selectedGenre != nil || sortOption != .newest ? .indigo : .primary)
                        .frame(width: 38, height: 38)
                        .background(
                            Circle()
                                .fill(Color.primary.opacity(selectedGenre != nil || sortOption != .newest ? 0.1 : 0.05))
                        )
                        .overlay(
                            Group {
                                if selectedGenre != nil || sortOption != .newest {
                                    Circle()
                                        .fill(Color.indigo)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 12, y: -12)
                                }
                            }
                        )
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var searchBarView: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                TextField("Search books or authors", text: $searchText)
                    .font(.system(size: 16))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                    }
                }
                Button(action: {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                    } else {
                        speechRecognizer.startRecording()
                    }
                }) {
                    Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                        .foregroundColor(speechRecognizer.isRecording ? .red : .secondary)
                        .font(.system(size: 16))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var genreFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                GenreFilterButton(
                    title: "All",
                    isSelected: selectedGenre == nil,
                    action: { selectedGenre = nil }
                )
                ForEach(genres, id: \.self) { genre in
                    GenreFilterButton(
                        title: genre,
                        isSelected: selectedGenre == genre,
                        action: { selectedGenre = genre }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var activeFiltersView: some View {
        HStack {
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
            Button(action: {
                selectedGenre = nil
                sortOption = .newest
            }) {
                Text("Clear All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.indigo)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            BookshelfLoadingView()
                .frame(width: 120, height: 120)
            Text("Discovering amazing books for you...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 22) {
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
            Button(action: {
                withAnimation {
                    bookService.fetchAllBooks()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.indigo)
                )
                .foregroundColor(.white)
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
            Text(searchText.isEmpty ? "No books available" : "No results for '\(searchText)'")
                .font(.title2)
                .fontWeight(.medium)
            if !searchText.isEmpty {
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button(action: {
                    searchText = ""
                    selectedGenre = nil
                }) {
                    Text("Clear filters")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.indigo)
                        )
                        .foregroundColor(.white)
                }
                .padding(.top, 10)
            } else {
                Text("Check back later for new additions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var bookListView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        EnhancedBookRowView(book: book)
                            .frame(width: cardWidth)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .offset(y: animateList ? 0 : 50)
                            .opacity(animateList ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(index) * 0.05),
                                value: animateList
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.vertical, 10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    private var bookGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ], spacing: 16) {
                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        BookGridItemView(book: book, cardWidth: gridCardWidth)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            )
                            .offset(y: animateList ? 0 : 50)
                            .opacity(animateList ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                .delay(Double(index % 6) * 0.05),
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
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 20)
            Text("Filter & Sort")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("SORT BY")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                        VStack(spacing: 2) {
                            ForEach(SortOption.allCases) { option in
                                Button(action: {
                                    sortOption = option
                                }) {
                                    HStack {
                                        Text(option.rawValue)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if sortOption == option {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.indigo)
                                        } else {
                                            Circle()
                                                .stroke(Color(.systemGray3), lineWidth: 1)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(sortOption == option ? Color.indigo.opacity(0.1) : Color.clear)
                                    )
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("GENRE")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                            .padding(.leading, 16)
                        VStack(spacing: 2) {
                            Button(action: {
                                selectedGenre = nil
                            }) {
                                HStack {
                                    Text("All Genres")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedGenre == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.indigo)
                                    } else {
                                        Circle()
                                            .stroke(Color(.systemGray3), lineWidth: 1)
                                            .frame(width: 20, height: 20)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedGenre == nil ? Color.indigo.opacity(0.1) : Color.clear)
                                )
                            }
                            ForEach(genres, id: \.self) { genre in
                                Button(action: {
                                    selectedGenre = genre
                                }) {
                                    HStack {
                                        Text(genre)
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if selectedGenre == genre {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.indigo)
                                        } else {
                                            Circle()
                                                .stroke(Color(.systemGray3), lineWidth: 1)
                                                .frame(width: 20, height: 20)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedGenre == genre ? Color.indigo.opacity(0.1) : Color.clear)
                                    )
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            HStack(spacing: 16) {
                Button(action: {
                    selectedGenre = nil
                    sortOption = .newest
                }) {
                    Text("Reset")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.indigo, lineWidth: 1)
                        )
                        .foregroundColor(.indigo)
                }
                Button(action: {
                    showFilterSheet = false
                }) {
                    Text("Apply")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.indigo)
                        )
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
    
    private var sortMenuView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sort by")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                ForEach(SortOption.allCases) { option in
                    Button(action: {
                        sortOption = option
                        withAnimation {
                            showSortMenu = false
                        }
                    }) {
                        HStack {
                            Text(option.rawValue)
                                .font(.subheadline)
                            Spacer()
                            if sortOption == option {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.indigo)
                            }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    .foregroundColor(.primary)
                    if option != SortOption.allCases.last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .frame(width: 250)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal)
        .offset(x: 50)
    }
    
    struct GenreFilterButton: View {
        let title: String
        let isSelected: Bool
        let action: () -> Void
    
        var body: some View {
            Button(action: action) {
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .medium : .regular))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.indigo : Color(.systemGray6))
                    )
                    .foregroundColor(isSelected ? .white : .primary)
                    .shadow(color: isSelected ? Color.indigo.opacity(0.3) : Color.clear, radius: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
struct FilterChip: View {
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .padding(4)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.indigo.opacity(0.1))
        )
        .foregroundColor(.indigo)
    }
}
struct BookshelfLoadingView: View {
    @State private var currentBookIndex = 0
    @State private var opacity = false
    private let bookColors: [Color] = [.indigo, .blue, .purple, .teal, .green]
    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<5) { index in
                RoundedRectangle(cornerRadius: 4)
                    .fill(bookColors[index])
                    .frame(width: 14, height: index == currentBookIndex ? 60 : 40)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: currentBookIndex)
                    .shadow(color: bookColors[index].opacity(0.3), radius: index == currentBookIndex ? 8 : 0, x: 0, y: 2)
            }
        }
        .overlay(
            Text("Loading books...")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 80)
                .opacity(opacity ? 1 : 0)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: opacity)
        )
        .onReceive(timer) { _ in
            currentBookIndex = (currentBookIndex + 1) % 5
        }
        .onAppear {
            opacity = true
        }
    }
}
struct EnhancedBookRowView: View {
    let book: LibraryBook
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Cover image with improved design
            bookCoverView
                .frame(width: 100, height: 150)
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(book.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                // Author
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.indigo)
                    .lineLimit(1)
                
                // Rating
                HStack(spacing: 4) {
                    StarRatingView(rating: book.rating, starSize: 12, spacing: 2, color: .orange)
                }
                .padding(.vertical, 2)
                
                // Book details in pill-shaped badges
                FlowLayout(spacing: 8) {
                    BookInfoBadge(icon: "calendar", text: "\(book.releaseYear)")
                    BookInfoBadge(icon: "tag", text: book.genre)
                }
                
                Spacer(minLength: 4)
                
                // Description
                Text(book.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(4)

            }
            .padding(12)
        }
        .padding(8)
        .frame(minHeight: 170)
    }
    
    private var bookCoverView: some View {
        Group {
            if let imageURL = book.imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .empty:
                        bookPlaceholder
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
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
    
    private var bookPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
            
            ProgressView()
                .scaleEffect(1.2)
        }
        .frame(width: 100, height: 150)
    }
    
    private var coverColorImage: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(book.coverColor), Color(book.coverColor).opacity(0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 100, height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(spacing: 6) {
                Text(String(book.name.prefix(1)))
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                
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
        .background(
            Capsule()
                .fill(Color(.systemGray6))
        )
    }
}

struct BookGridItemView: View {
    let book: LibraryBook
    let cardWidth: CGFloat // Use a fixed width passed from parent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cover image with padding
            ZStack {
                if let imageURL = book.imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 180)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: cardWidth - 16, height: 180) // Use consistent width - padding
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
            .frame(width: cardWidth - 16, height: 180) // Fixed width based on parent
            .cornerRadius(8)
            .padding(8) // Even padding around image
            .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
            
            // Book details
            VStack(alignment: .leading, spacing: 4) {
                Text(book.name)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true) // Allow title to expand
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.indigo)
                    .lineLimit(1)
                
                // Star rating
                StarRatingView(rating: book.rating, starSize: 12, spacing: 2, color: .orange)
                    .padding(.vertical, 4)
                
                // Description - exactly 3 lines
                Text(book.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true) // Ensure 3 lines
                
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
        .frame(width: cardWidth) // Consistent width
    }
    
    // Update coverColorImage to use cardWidth
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
                    .fixedSize(horizontal: false, vertical: true) // Allow multiple lines
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
                Image(systemName: star <= Int(rating) ? "star.fill" :
                                  (star == Int(rating) + 1 && rating.truncatingRemainder(dividingBy: 1) >= 0.5) ?
                                  "star.leadinghalf.filled" : "star")
                    .font(.system(size: starSize))
                    .foregroundColor(color)
            }
            
            Text(String(format: "%.1f", rating))
                .font(.system(size: starSize))
                .foregroundColor(color)
        }
    }
}

// MARK: - FlowLayout Component

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > width && x > 0 {
                // Move to next row
                y += rowHeight + spacing
                x = 0
                rowHeight = size.height
            } else {
                // Stay on same row
                rowHeight = max(rowHeight, size.height)
            }
            
            x += size.width + spacing
        }
        
        height = y + rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            
            if x + size.width > bounds.maxX && x > bounds.minX {
                // Move to next row
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = size.height
            } else {
                // Stay on same row
                rowHeight = max(rowHeight, size.height)
            }
            
            view.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + spacing
        }
    }
}
