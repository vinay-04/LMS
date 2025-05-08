import SwiftUI
import Firebase
import FirebaseFirestore

// Toast notification component
struct ToastView: View {
    let message: String
    let type: ToastType
    
    enum ToastType {
        case success
        case error
        case info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "exclamationmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(type.color.opacity(0.9))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}

struct BookDetailView: View {
    @StateObject var bookService = BookService()
    @State private var isInWishlist = false
    @State private var showingReservationSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isReserving = false
    @State private var isWishlistLoading = false
    @State private var bookReservationStatus: ReservationStatus = .unknown
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .info
    
    @Environment(\.dismiss) private var dismiss
    
    // Enum to track the book's reservation status for the current user
    enum ReservationStatus {
        case unknown
        case available
        case alreadyReserved
        case alreadyIssued
        case unavailable
    }
    
    // Assume we have a book from somewhere
    var book: LibraryBook
    
    // MARK: - Computed Properties
    
    var isBookAvailable: Bool {
        return (book.issuedCount + book.reservedCount) < book.totalCount
    }
    
    var bookStatus: String {
        return isBookAvailable ? "Available" : "Not Available"
    }
    
    var statusColor: Color {
        return isBookAvailable ? .green : .red
    }
    
    var canReserve: Bool {
        return isBookAvailable &&
               bookReservationStatus != .alreadyReserved &&
               bookReservationStatus != .alreadyIssued
    }
    
    var buttonText: String {
        switch bookReservationStatus {
        case .alreadyReserved:
            return "Requested"
        case .alreadyIssued:
            return "Issued to You"
        case .unavailable:
            return "Not Available"
        default:
            return "Reserve Book"
        }
    }
    
    var buttonColor: Color {
        switch bookReservationStatus {
        case .alreadyReserved:
            return .orange
        case .alreadyIssued:
            return .green
        case .unavailable:
            return .gray
        default:
            return .cyan
        }
    }
    
    // MARK: - Methods
    
    private func checkWishlistStatus() {
        isWishlistLoading = true
        bookService.checkIfBookInWishlist(bookId: book.id) { result in
            isInWishlist = result
            isWishlistLoading = false
        }
    }
    
    private func checkReservationStatus() {
        // First check local storage for immediate UI update
        checkLocalReservationStatus()
        
        // Then verify with server for accuracy
        bookService.checkUserBookStatus(bookId: book.id) { status in
            switch status {
            case .reserved:
                self.bookReservationStatus = .alreadyReserved
                self.saveReservationState(bookId: self.book.id)
            case .issued:
                self.bookReservationStatus = .alreadyIssued
            case .none:
                // Only update to available if we didn't find it in local storage
                if self.bookReservationStatus != .alreadyReserved {
                    self.bookReservationStatus = self.isBookAvailable ? .available : .unavailable
                }
            }
        }
    }
    
    private func checkLocalReservationStatus() {
        // Check UserDefaults first for immediate UI response
        if let reservedBooks = UserDefaults.standard.array(forKey: "UserReservedBooks") as? [String],
           reservedBooks.contains(book.id) {
            bookReservationStatus = .alreadyReserved
        } else {
            bookReservationStatus = isBookAvailable ? .available : .unavailable
        }
    }
    
    private func showToastMessage(message: String, type: ToastView.ToastType) {
        toastMessage = message
        toastType = type
        showToast = true
        
        // Automatically hide toast after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showToast = false
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero section with cover and basic info
                    ZStack(alignment: .bottom) {
                        if let imageURL = book.imageURL {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .empty:
                                    Color(.systemGray5)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 280)
                                        .blur(radius: 15)
                                case .failure:
                                    Color(.systemGray5)
                                @unknown default:
                                    Color(.systemGray5)
                                }
                            }
                            .overlay(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black.opacity(0), Color.black.opacity(0)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        
                        HStack(alignment: .bottom, spacing: 20) {
                            // Book cover
                            if let imageURL = book.imageURL {
                                AsyncImage(url: URL(string: imageURL)) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .frame(width: 140, height: 210)
                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 140, height: 210)
                                            .cornerRadius(12)
                                            .shadow(radius: 8)
                                    case .failure:
                                        Image(systemName: "book.closed")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 140, height: 210)
                                            .cornerRadius(12)
                                            .shadow(radius: 8)
                                    @unknown default:
                                        Image(systemName: "book.closed")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 140, height: 210)
                                            .cornerRadius(12)
                                            .shadow(radius: 8)
                                    }
                                }
                                .offset(y: 40)
                            }
                            
                            // Book info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                    .lineLimit(2)
                                
                                Text(book.author)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    StatusBadge(status: bookStatus, color: statusColor)
                                    Spacer()
                                    wishlistButton
                                }
                                .padding(.top, 8)
                            }
                            .padding(.trailing)
                            .padding(.bottom, 40)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 60)
                    
                    // Quick stats
                    HStack(spacing: 0) {
                        StatItem(icon: "calendar", value: String(book.releaseYear), label: "Year")
                        Divider().frame(height: 40)
                        StatItem(icon: "doc.text", value: "\(book.pageCount ?? 0)", label: "Pages")
                        Divider().frame(height: 40)
                        StatItem(icon: "globe", value: book.language.first ?? "", label: "Language")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        if isReserving {
                            // Use a fixed height container to maintain consistent sizing
                            HStack {
                                Spacer()
                                ProgressView("Reserving...")
                                Spacer()
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.cyan.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        } else {
                            Button(action: {
                                if canReserve {
                                    handleReservation()
                                }
                            }) {
                                HStack {
                                    if bookReservationStatus == .alreadyReserved {
                                        Image(systemName: "clock.fill")
                                    } else if bookReservationStatus == .alreadyIssued {
                                        Image(systemName: "book.fill")
                                    } else {
                                        Image(systemName: "plus.circle.fill")
                                    }
                                    
                                    Text(buttonText)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 52) // Fixed height button
                                .background(canReserve ? buttonColor : buttonColor.opacity(0.5))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(!canReserve)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 18)
                    
                    // Info sections
                    VStack(spacing: 28) {
                        // Summary section
                        InfoSection(title: "Summary") {
                            Text(book.description)
                                .font(.body)
                                .lineSpacing(6)
                                .foregroundColor(.primary)
                        }
                        
                        // Details section
                        InfoSection(title: "Details") {
                            DetailRow(title: "Genre", value: book.genre)
                            DetailRow(title: "Languages", value: book.language.joined(separator: ", "))
                            DetailRow(title: "Rating", value: "\(String(format: "%.1f", book.rating))/5")
                            DetailRow(title: "Location", value: "Floor \(book.location.floor), Shelf \(book.location.shelf)")
                        }
                        
                        // Availability section
                        InfoSection(title: "Availability") {
                            VStack(alignment: .leading, spacing: 12) {
                                availabilityInfo
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGray6))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color(.systemGray3))
                            .font(.title2)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Book Details")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                checkWishlistStatus()
                checkReservationStatus()
            }
            
            // Toast message overlay
            if showToast {
                ToastView(message: toastMessage, type: toastType)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
                    .animation(.easeInOut, value: showToast)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var wishlistButton: some View {
        Button(action: {
            if isWishlistLoading { return }
            
            isWishlistLoading = true
            if isInWishlist {
                bookService.removeFromWishlist(bookId: book.id) { success, errorMessage in
                    isWishlistLoading = false
                    
                    if success {
                        isInWishlist = false
                        showToastMessage(message: "\"\(book.name)\" removed from wishlist", type: .info)
                    } else {
                        showToastMessage(message: errorMessage ?? "Failed to remove from wishlist", type: .error)
                    }
                }
            } else {
                bookService.addToWishlist(bookId: book.id) { success, errorMessage in
                    isWishlistLoading = false
                    
                    if success {
                        isInWishlist = true
                        showToastMessage(message: "\"\(book.name)\" added to your wishlist", type: .success)
                    } else {
                        showToastMessage(message: errorMessage ?? "Failed to add to wishlist", type: .error)
                    }
                }
            }
        }) {
            Group {
                if isWishlistLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: isInWishlist ? "bookmark.fill" : "bookmark")
                        .font(.title3)
                        .foregroundColor(isInWishlist ? .cyan : .black)
                }
            }
        }
    }
    
    private var availabilityInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            if isBookAvailable {
                Text("Currently Available")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(book.unreservedCount) of \(book.totalCount) copies available.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if bookReservationStatus == .alreadyReserved {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("You have already requested this book")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                } else if bookReservationStatus == .alreadyIssued {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.green)
                        Text("This book is already issued to you")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("You can reserve this book")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Not Available")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("All \(book.totalCount) copies are currently unavailable.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if bookReservationStatus == .alreadyReserved {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("You have already requested this book")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                } else if bookReservationStatus == .alreadyIssued {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.green)
                        Text("This book is already issued to you")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 4)
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.red)
                        Text("You can add to your wishlist")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    // Handle reservation action
    func handleReservation() {
        if !canReserve {
            return
        }
        
        isReserving = true
        
        bookService.reserveBook(bookId: book.id) { success, errorMessage in
            isReserving = false
            
            if success {
                // Update local state
                bookReservationStatus = .alreadyReserved
                
                // Update the user defaults to persist the reservation state
                saveReservationState(bookId: book.id)
                
                showToastMessage(message: "Book Requested", type: .success)
            } else {
                showToastMessage(message: errorMessage ?? "Failed to reserve book", type: .error)
            }
        }
    }
    
    // Helper method to persist reservation state in UserDefaults
    private func saveReservationState(bookId: String) {
        // Get existing reserved books array or create new one
        let userDefaults = UserDefaults.standard
        var reservedBooks = userDefaults.array(forKey: "UserReservedBooks") as? [String] ?? []
        
        // Add this book if not already in the array
        if !reservedBooks.contains(bookId) {
            reservedBooks.append(bookId)
            userDefaults.set(reservedBooks, forKey: "UserReservedBooks")
        }
    }
}

// MARK: - Supporting Components

struct InfoSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            content()
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatusBadge: View {
    let status: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(status)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.3))
        .cornerRadius(8)
    }
}

// Extension to BookService to add necessary methods

extension BookService {
    enum BookUserStatus {
        case reserved
        case issued
        case none
    }
    
    
    func checkUserBookStatus(bookId: String, completion: @escaping (BookUserStatus) -> Void) {
        // Get the current user ID from Firebase Service
        guard let userId = FirebaseService.shared.getCurrentUserId() else {
            print("Error: User not logged in")
            completion(.none)
            return
        }
        let db = Firestore.firestore()
        let reservedBookRef = db.collection("members").document(userId)
            .collection("userbooks").document("collection")
            .collection("requested").document(bookId)
        
        reservedBookRef.getDocument { (document, error) in
            if let error = error {
                print("Error checking reservation status: \(error.localizedDescription)")
                completion(.none)
                return
            }
            
            if document?.exists ?? false {
                completion(.reserved)
                return
            }
            
            // Check if the book is in the user's issued collection
            let issuedBookRef = db.collection("members").document(userId)
                .collection("userbooks").document("collection")
                .collection("issued").document(bookId)
            
            issuedBookRef.getDocument { (document, error) in
                if let error = error {
                    print("Error checking issued status: \(error.localizedDescription)")
                    completion(.none)
                    return
                }
                
                if document?.exists ?? false {
                    completion(.issued)
                } else {
                    completion(.none)
                }
            }
        }
    }
}
