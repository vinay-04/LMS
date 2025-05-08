//
//  MemberHomeView.swift
//  lms
//
//  Created by VR on 25/04/25.
//
import SwiftUI

struct MemberHomeView: View {
    let userData = LibraryData.sampleUser
    @StateObject private var bookService = BookService()
    @State private var isWishlistLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    // MARK: — Welcome Header
                    HStack {
//                        Text("Welcome, \(userData.name)")
                        Text("Welcome")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(.primary)
                        Spacer()
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundColor(AppTheme.secondaryTextColor)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Currently Reading Section
                    CurrentlyReadingSection(bookService: bookService)
                    
                    // Reserved Books Section - Using our new component
                    // This will only show up if the user has reserved books
                    ReservedBooksSection(bookService: bookService)
//                    
//                    // Popular Books Section
                    PopularBooksSection(bookService: bookService)
                    
                    // Library Progress View
                    LibraryProgressView(bookService: bookService, booksRead: userData.stats.booksRead)
                    
                    // New Releases Section
                    NewReleasesSection(bookService: bookService)
                    
                    // Explore Genres Section
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: "Explore Genres")
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(LibraryData.genreList, id: \.self) { genre in
                                GenreButton(genre: genre)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .background(AppTheme.backgroundColor)
            .navigationBarTitleDisplayMode(.inline)
        }
        .accentColor(AppTheme.accentColor)
        .onAppear {
            // Fetch all necessary data when the view appears
            bookService.fetchPopularBooks()
            bookService.fetchNewReleases()
            bookService.fetchTotalBookCount()
            bookService.fetchCurrentlyReadingBooks()
            // The ReservedBooksSection will fetch its own data when it appears
        }
    }
    
}


//import SwiftUI
//
//struct MemberHomeView: View {
//    // your sample or injected user data
//    let userData = LibraryData.sampleUser
//    @StateObject private var bookService = BookService()
//    
//    // State variables for popular books
//    @State private var popularBooks: [LibraryBook] = []
//    @State private var isLoadingPopularBooks = false
//    @State private var popularBooksError: String?
//    
//    // Add state for logout confirmation
//    @State private var showLogoutConfirmation = false
//    // Add environment object for authentication
//    @EnvironmentObject var authViewModel: AuthViewModel
//    
//    private let cardCornerRadius: CGFloat = 8
//    private let sectionSpacing: CGFloat = 24
//    private let horizontalPadding: CGFloat = 20
//    private let genreCardHeight: CGFloat = 120
//    private let shadowRadius: CGFloat = 4
//    private let gridSpacing: CGFloat = 16
//    private let popularBookWidth: CGFloat = 120
//    private let popularBookHeight: CGFloat = 180
//    
//    private var genreCardWidth: CGFloat {
//        (UIScreen.main.bounds.width - (horizontalPadding * 2) - gridSpacing) / 2
//    }
//    
//    // Computed property for popular books section
//    private var popularBooksSection: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            HStack {
//                Text("Popular Books")
//                    .font(.title3)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppTheme.primaryTextColor)
//                
//                Spacer()
//                
//                NavigationLink(destination: PopularBooksView()) {
//                    Text("See All")
//                        .font(.subheadline)
//                        .foregroundColor(AppTheme.accentColor)
//                }
//            }
//            
//            if isLoadingPopularBooks {
//                ProgressView()
//                    .frame(height: 210)
//            } else if let error = popularBooksError {
//                Text("Error: \(error)")
//                    .foregroundColor(.red)
//                    .frame(height: 210)
//            } else {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 16) {
//                        ForEach(popularBooks) { book in
//                            PopularBookView(book: book)
//                        }
//                    }
//                    .padding(.vertical, 8)
//                    .padding(.trailing, 20)
//                }
//            }
//        }
//    }
//    
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 10) {
//                    // MARK: — Welcome Header
//                    HStack {
//                        Text("Welcome, \(userData.name)")
//                            .font(.title)
//                            .fontWeight(.bold)
//                            .foregroundColor(Color(hex: "242526"))
//                        Spacer()
//                        
////                        // Profile button with logout functionality
////                        Button(action: {
////                            showLogoutConfirmation = true
////                        }) {
////                            Image(systemName: "person.circle.fill")
////                                .font(.title)
////                                .foregroundColor(Color(hex: "242526"))
////                        }
////                    }
//                        NavigationLink(destination: ProfileView()) {
//                            Image(systemName: "person.circle.fill")
//                                .font(.title)
//                                .foregroundColor(Color(hex: "242526"))
//                        }
//                    }
//                    .padding(.top, 20)
//                    
//                    // MARK: — Currently Reading & Reserved
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text("Currently Reading")
//                            .font(.title3)
//                            .fontWeight(.semibold)
//                            .foregroundColor(Color(.darkGray))
//                        
//                        if let book = userData.issuedBooks.first {
//                            CurrentlyReadingView(book: book)
//                        }
//                        
//                        if let book = userData.reservedBooks.first {
//                            ReservedBookView(book: book)
//                        }
//                    }
//                    
//                    // MARK: — Popular Books
//                    popularBooksSection
//                    
//                    // MARK: — Library Progress
//                    LibraryProgressView(bookService: bookService, booksRead: userData.stats.booksRead)
//                    
//                    // MARK: — New Releases
//                    NewReleasesSection(bookService: bookService)
//                    
//                    // MARK: — Explore Genres
//                    VStack(alignment: .leading, spacing: 8) {
//                        SectionHeader(title: "Explore Genres")
//                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
//                            ForEach(LibraryData.genreList, id: \.self) { genre in
//                                GenreButton(genre: genre)
//                            }
//                        }
//                    }
//                }
//                .padding(.horizontal, 16)
//            }
//            .background(AppTheme.backgroundColor)
//            .navigationBarTitleDisplayMode(.inline)
//            // Add alert for logout confirmation
//            .alert(isPresented: $showLogoutConfirmation) {
//                Alert(
//                    title: Text("Logout"),
//                    message: Text("Are you sure you want to logout?"),
//                    primaryButton: .destructive(Text("Logout")) {
//                        // Call logout function from AuthViewModel
//                        Task {
//                            await authViewModel.logout()
//                        }
//                    },
//                    secondaryButton: .cancel()
//                )
//            }
//        }
//        .accentColor(AppTheme.accentColor)
//        .onAppear {
//            // Load popular books when view appears
//            isLoadingPopularBooks = true
//            bookService.fetchPopularBooks { [self] result in
//                isLoadingPopularBooks = false
//                switch result {
//                case .success(let books):
//                    self.popularBooks = books
//                case .failure(let error):
//                    self.popularBooksError = error.localizedDescription
//                }
//            }
//        }
//    }
//}


//struct MemberHomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        MemberHomeView()
//            .environmentObject(AuthViewModel()) // Add the AuthViewModel for previews
//    }
//}
