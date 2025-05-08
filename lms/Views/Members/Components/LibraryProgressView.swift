//
//  LibraryProgressView.swift
//  LMS_USER
//
//  Created by user@79 on 25/04/25.
//
import SwiftUI

struct LibraryProgressView: View {
    @ObservedObject var bookService: BookService
    let booksRead: Int
    
    // This computed property will use either the history count from Firestore or the provided booksRead
    private var displayBooksRead: Int {
        return bookService.historyBookCount > 0 ? bookService.historyBookCount : booksRead
    }
    
    // Calculate progress as a percentage (between 0.0 and 1.0)
    private var progressPercentage: Double {
        let total = Double(bookService.totalBookCount)
        if total > 0 {
            return min(Double(displayBooksRead) / total, 1.0)
        }
        return 0.0
    }

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text("Complete your Collection")
                .font(.headline)
                .foregroundColor(AppTheme.primaryTextColor)
            
            if bookService.isLoading || bookService.isLoadingHistory {
                ProgressView()
            } else if let errorMessage = bookService.errorMessage ?? bookService.historyErrorMessage {
                Text("Error: \(errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                // Progress stat display
                Text("\(displayBooksRead)/\(bookService.totalBookCount)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primaryTextColor)
                
                Text("Books Read")
                    .font(.caption)
                    .foregroundColor(AppTheme.secondaryTextColor)
                
                // Custom progress bar
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(progressGradient)
                        .frame(width: max(CGFloat(progressPercentage) * UIScreen.main.bounds.width * 0.7, 4), height: 12)
                        .animation(.spring(), value: progressPercentage)
                }
                .frame(height: 12)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                
                // Percentage text
            }
            
            Button(action: {
                // Add to collection action
            }) {
                Text("Add to Collection")
                    .font(.caption)
                    .foregroundColor(Color(.systemBackground))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemGray5))
        .cornerRadius(12)
        .onAppear {
            bookService.fetchTotalBookCount()
            bookService.fetchUserHistoryBookCount()
        }
    }
    
    // Gradient for the progress bar
    private var progressGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color(.systemIndigo)]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}


//import SwiftUI
//
//struct LibraryProgressView: View {
//    @ObservedObject var bookService: BookService
//    let booksRead: Int
//
//    var body: some View {
//        VStack(alignment: .center, spacing: 8) {
//            Text("Complete your Collection")
//                .font(.headline)
//                .foregroundColor(AppTheme.primaryTextColor)
//            
//            if bookService.isLoading {
//                ProgressView()
//            } else if let errorMessage = bookService.errorMessage {
//                Text("Error: \(errorMessage)")
//                    .font(.caption)
//                    .foregroundColor(.red)
//            } else {
//                Text("\(booksRead)/\(bookService.totalBookCount)")
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .foregroundColor(AppTheme.primaryTextColor)
//                
//                Text("Books Read")
//                    .font(.caption)
//                    .foregroundColor(AppTheme.secondaryTextColor)
//            }
//            
//            Button(action: {
//                // Add to collection action
//            }) {
//                Text("Add to Collection")
//                    .font(.caption)
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 16)
//                    .padding(.vertical, 8)
//                    .background(Color.accentColor)
//                    .cornerRadius(16)
//            }
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 20)
//        .background(AppTheme.cardBackgroundColor)
//        .cornerRadius(12)
//        .onAppear {
//            bookService.fetchTotalBookCount()
//        }
//    }
//}
