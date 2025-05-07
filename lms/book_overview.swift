//
//  MemberView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct BookDetailView: View {
    @StateObject var bookService = BookService()
    @State private var isInWishlist = false
    @State private var showingReservationSheet = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @State private var isReserving = false
    @Environment(\.dismiss) private var dismiss
    
    var book: LibraryBook
    
    // MARK: - Computed Properties
    
    var bookStatus: String {
        if book.issuedCount >= book.totalCount {
            return "Issued"
        } else if book.reservedCount > 0 {
            return "Reserved"
        } else if book.unreservedCount > 0 {
            return "Available"
        } else {
            return "Not Available"
        }
    }
    
    var statusColor: Color {
        switch bookStatus {
        case "Available":
            return .green
        case "Reserved":
            return .blue
        case "Issued":
            return .orange
        default:
            return .red
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
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
                        ProgressView("Reserving...")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.cyan.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    } else {
                        actionButton(
                            title: "Reserve Book",
                            icon: "plus.circle.fill",
                            color: Color.cyan,
                            isPrimary: true,
                            action: {
                                handleReservation()
                            }
                        )
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
                        DetailRow(icon: "book.fill", title: "Genre", value: book.genre)
                        DetailRow(icon: "globe", title: "Languages", value: book.language.joined(separator: ", "))
                        DetailRow(icon: "star.fill", title: "Rating", value: "\(String(format: "%.1f", book.rating))/5")
                        DetailRow(icon: "map.fill", title: "Location", value: "Floor \(book.location.floor), Shelf \(book.location.shelf)")
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
    }
    
    // MARK: - Helper Views
    
    private var wishlistButton: some View {
        Button(action: {
            isInWishlist.toggle()
        }) {
            Image(systemName: isInWishlist ? "bookmark.fill" : "bookmark")
                .font(.title3)
                .foregroundColor(isInWishlist ? .cyan : .black)
        }
    }
    
    private func actionButton(title: String, icon: String, color: Color, isPrimary: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPrimary ? color : Color.clear)
            .foregroundColor(isPrimary ? .white : color)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isPrimary ? Color.clear : color, lineWidth: 1)
            )
        }
        .disabled(book.unreservedCount <= 0)
    }
    
    private var availabilityInfo: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch bookStatus {
            case "Available":
                Text("Currently Available")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("You can reserve this book right away.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Ready for pickup")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
                
            case "Reserved":
                Text("Currently Reserved")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("This book has \(book.reservedCount) active reservations.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.blue)
                    Text("Join the reservation queue")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.top, 4)
                
            case "Issued":
                Text("Currently Checked Out")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("All \(book.totalCount) copies are currently issued.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    Text("You can add to your wishlist")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.top, 4)
                
            default:
                Text("Not Available")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("This book is currently not available for reservation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "exclamationmark.circle")
                        .foregroundColor(.red)
                    Text("Contact librarian for more information")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
            }
        }
    }
    
    // Handle reservation action
    func handleReservation() {
        if book.unreservedCount <= 0 {
            alertTitle = "Not Available"
            alertMessage = "This book is currently not available for reservation"
            showAlert = true
            return
        }
        
        isReserving = true
        
        bookService.reserveBook(bookId: book.id) { success, errorMessage in
            isReserving = false
            
            if success {
                alertTitle = "Success"
                alertMessage = "Book has been reserved successfully!"
            } else {
                alertTitle = "Error"
                alertMessage = errorMessage ?? "Failed to reserve book"
            }
            
            showAlert = true
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
