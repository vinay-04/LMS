//
//  BooksStatsView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore

struct BooksStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    
    // Book status counts
    @State private var issuedCount = 0
    @State private var missingCount = 0
    @State private var reservedCount = 0
    @State private var newCount = 0
    @State private var totalBooks = 0
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemIndigo).opacity(0.1), Color(.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // List View only (no segmented control since chart is removed)
                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        Text("BOOK STATUS")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                        
                        // Book Status List
                        VStack(spacing: 0) {
                            // Container for all list items
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                
                                VStack(spacing: 0) {
                                    // Issued Books
                                    StatusListItem(
                                        icon: "book.closed",
                                        iconColor: .red,
                                        title: "Issued Books",
                                        count: issuedCount
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 48)
                                    
                                    // Reserved Books
                                    StatusListItem(
                                        icon: "book.closed.fill",
                                        iconColor: .purple,
                                        title: "Reserved Books",
                                        count: reservedCount
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 48)
                                    
                                    // Missing Books
                                    StatusListItem(
                                        icon: "questionmark.circle",
                                        iconColor: .green,
                                        title: "Missing Books",
                                        count: missingCount
                                    )
                                    
                                    Divider()
                                        .padding(.leading, 48)
                                    
                                    // New Books
                                    StatusListItem(
                                        icon: "star.fill",
                                        iconColor: .yellow,
                                        title: "New Books",
                                        count: newCount
                                    )
                                }
                            }
                            
                            Spacer()
                                .frame(height: 16)
                            
                            // Total Books (separated with its own container)
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                                
                                StatusListItem(
                                    icon: "books.vertical.fill",
                                    iconColor: .blue,
                                    title: "Total Books",
                                    count: totalBooks
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .overlay(
                    Group {
                        if isLoading {
                            ProgressView()
                        }
                    }
                )
            }
            .navigationTitle("Book Status Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(Color(.systemBlue))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        fetchData()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color(.systemBlue))
                    }
                }
            }
            .onAppear {
                fetchData()
            }
        }
    }
    
    private func fetchData() {
        isLoading = true
        
        let db = Firestore.firestore()
        
        db.collection("books").getDocuments { snapshot, error in
            defer { isLoading = false }
            
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching books: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Reset counters
            self.issuedCount = 0
            self.missingCount = 0
            self.reservedCount = 0
            self.newCount = 0
            
            // Count total books
            self.totalBooks = documents.count
            
            // Process documents
            for document in documents {
                let data = document.data()
                
                // Count issued books
                if let issued = data["issuedCount"] as? Int {
                    self.issuedCount += issued
                }
                
                // Count missing books
                if let missing = data["missingCount"] as? Int {
                    self.missingCount += missing
                }
                
                // Count reserved books
                if let reserved = data["reservedCount"] as? Int {
                    self.reservedCount += reserved
                }
                
                // Count new books (added in the last month)
                if let timestamp = data["createdAt"] as? Timestamp {
                    let creationDate = timestamp.dateValue()
                    let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                    
                    if creationDate > oneMonthAgo {
                        self.newCount += 1
                    }
                }
            }
        }
    }
}

// Component for individual status list items
struct StatusListItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
                .padding(.leading, 12)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.headline)
                .bold()
                .padding(.trailing, 16)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    BooksStatsView()
}
