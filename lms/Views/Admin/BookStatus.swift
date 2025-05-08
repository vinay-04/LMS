//
//  BookStatus.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore
import Charts

// Book status data model for chart
struct BookStatus: Identifiable {
    var id = UUID()
    var status: String
    var count: Int
    
    // Color for each status
    var color: Color {
        switch status {
        case "Issued": return .red
        case "Missing": return .green
        case "Reserved": return .purple
        case "New": return .yellow
        default: return .gray
        }
    }
    
    // Icon for each status
    var icon: String {
        switch status {
        case "Issued": return "book.closed"
        case "Missing": return "questionmark.circle"
        case "Reserved": return "book.closed.fill"
        case "New": return "star.fill"
        default: return "circle"
        }
    }
}

struct BookStatsChart: View {
    @State private var bookStats: [BookStatus] = []
    @State private var isLoading = true
    @State private var totalBooks = 0
    @State private var selectedPeriod = "Monthly"
    @State private var animateChart = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with time period selector
            HStack {
                Text("Books Status")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Menu {
                    Button("Monthly") {
                        selectedPeriod = "Monthly"
                        fetchData(period: "monthly")
                    }
                    Button("Quarterly") {
                        selectedPeriod = "Quarterly"
                        fetchData(period: "quarterly")
                    }
                    Button("Yearly") {
                        selectedPeriod = "Yearly"
                        fetchData(period: "yearly")
                    }
                } label: {
                    HStack {
                        Text(selectedPeriod)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Spacer()
                }
                .frame(height: 250)
            } else {
                // Chart container
                VStack(spacing: 20) {
                    // Donut Chart
                    ZStack {
                        Chart {
                            ForEach(bookStats) { item in
                                SectorMark(
                                    angle: .value("Count", animateChart ? item.count : 0),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(item.color)
                                .cornerRadius(5)
                                .annotation(position: .overlay) {
                                    Text("\(item.count)")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(height: 220)
                        .padding(.horizontal)
                        
                        // Center info for total books
                        VStack(spacing: 4) {
                            Text("TOTAL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(totalBooks)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("books")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Legend with improved design
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(bookStats) { item in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 12, height: 12)
                                
                                Image(systemName: item.icon)
                                    .foregroundColor(item.color)
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(item.status)
                                    .font(.system(size: 15, weight: .medium))
                                
                                Spacer()
                                
                                Text("\(item.count)")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                }
            }
        }
        .onAppear {
            fetchData(period: "monthly")
        }
    }
    
    private func fetchData(period: String) {
        // Reset state
        isLoading = true
        bookStats = []
        animateChart = false
        
        let db = Firestore.firestore()
        
        // Get books collection
        db.collection("books").getDocuments { snapshot, error in
            defer {
                isLoading = false
                
                // Animate the chart after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        animateChart = true
                    }
                }
            }
            
            guard let documents = snapshot?.documents, error == nil else {
                print("Error fetching books: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Process documents
            var issuedCount = 0
            var missingCount = 0
            var reservedCount = 0
            var newCount = 0
            
            let timeFrame: TimeInterval
            switch period {
                case "quarterly":
                    // 3 months ago
                    timeFrame = 60 * 60 * 24 * 90
                case "yearly":
                    // 12 months ago
                    timeFrame = 60 * 60 * 24 * 365
                default:
                    // 1 month ago (default)
                    timeFrame = 60 * 60 * 24 * 30
            }
            
            let cutoffDate = Date().addingTimeInterval(-timeFrame)
            
            for document in documents {
                let data = document.data()
                
                // Count issued books
                if let issued = data["issuedCount"] as? Int {
                    issuedCount += issued
                }
                
                // Count missing books (if tracked)
                if let missing = data["missingCount"] as? Int {
                    missingCount += missing
                }
                
                // Count reserved books
                if let reserved = data["reservedCount"] as? Int {
                    reservedCount += reserved
                }
                
                // Count new books based on the selected period
                if let timestamp = data["createdAt"] as? Timestamp {
                    let creationDate = timestamp.dateValue()
                    
                    if creationDate > cutoffDate {
                        if let count = data["totalCount"] as? Int {
                            newCount += count
                        } else {
                            newCount += 1 // Assume at least one if totalCount not specified
                        }
                    }
                }
            }
            
            // Calculate total
            self.totalBooks = documents.count
            
            // Create BookStatus objects (even with zero counts for consistency)
            self.bookStats = [
                BookStatus(status: "Issued", count: issuedCount),
                BookStatus(status: "Missing", count: missingCount),
                BookStatus(status: "Reserved", count: reservedCount),
                BookStatus(status: "New", count: newCount)
            ].filter { $0.count > 0 }  // Only display non-zero values
            
            // If no data, show placeholder
            if self.bookStats.isEmpty {
                self.bookStats = [BookStatus(status: "No Data", count: 1)]
            }
        }
    }
}

// Preview
#Preview {
    BookStatsChart()
}
