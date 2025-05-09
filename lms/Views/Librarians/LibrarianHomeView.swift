//
//  LibrarianHomeView.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import SwiftUI

struct LibrarianHomeView: View {
    let user: User
    @StateObject private var viewModel = LibrarianHomeViewModel()
    @State private var showScanner = false
    @State private var scannedISBN: String?
    @State private var showScanResult = false
    @State private var isProcessingSheet = false
    @State private var isReturningBook = false
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Stats Overview
                    Text("Statistics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Stats Cards
                    statsCards
                    
                    
                    Text("Library Actions")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    
                    // Issue and Return buttons side by side below stats
                    HStack(spacing: 10) {
                        // Issue Button
                        Button(action: {
                            isReturningBook = false
                            viewModel.issueRequest()
                            showScanner = true
                        }) {
                            VStack(spacing: 8) { // Reduced spacing
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 40, height: 40) // Smaller circle
                                    
                                    Image(systemName: "book.fill")
                                        .font(.system(size: 18)) // Smaller icon
                                        .foregroundColor(.green)
                                }
                                
                                Text("Issue Book")
                                    .font(.system(size: 15, weight: .medium)) // Smaller text
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12) // Reduced vertical padding
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                        
                        // Return Button
                        Button(action: {
                            isReturningBook = true
                            viewModel.returnRequest()
                            showScanner = true
                        }) {
                            VStack(spacing: 8) { // Reduced spacing
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.15))
                                        .frame(width: 40, height: 40) // Smaller circle
                                    
                                    Image(systemName: "arrow.triangle.swap")
                                        .font(.system(size: 18)) // Smaller icon
                                        .foregroundColor(.yellow)
                                }
                                
                                Text("Return Book")
                                    .font(.system(size: 15, weight: .medium)) // Smaller text
                                    .foregroundColor(.primary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12) // Reduced vertical padding
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity Section - Immediately after Issue/Return buttons
                    recentActivitySection
                    
                    // Extra space at bottom for scrolling
                    Spacer(minLength: 30)
                }
                .padding(.vertical)
            }
            .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Librarian")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showScanner, onDismiss: {
                if scannedISBN != nil && !isProcessingSheet {
                    isProcessingSheet = true
                    viewModel.handleScannedBook(isbn: scannedISBN!, isReturn: isReturningBook)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showScanResult = true
                        isProcessingSheet = false
                    }
                } else {
                    isProcessingSheet = false
                }
            }) {
                BarcodeScannerView(scannedISBN: $scannedISBN)
            }
            .sheet(isPresented: $showScanResult, onDismiss: {
                scannedISBN = nil
                isProcessingSheet = false
                if case .failed(let message) = viewModel.currentIssue?.status {
                    alertMessage = message
                    showAlert = true
                }
                viewModel.resetCurrentIssue()
            }) {
                if let issue = viewModel.currentIssue {
                    if isReturningBook {
                        BookReturnProcessView(isbn: issue.isbn, viewModel: viewModel)
                    } else {
                        BookIssueProcessView(isbn: issue.isbn, viewModel: viewModel)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Process Failed"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onReceive(viewModel.$currentIssue) { newIssue in
                if let issue = newIssue, case .failed(let message) = issue.status {
                    alertMessage = message
                    showAlert = true
                }
            }
            .onAppear {
                viewModel.loadData()
            }
        }
    }
    
    private var statsCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(
                title: "ISSUED", // Changed from BORROWED to ISSUED
                value: "\(viewModel.borrowedCount)",
                icon: "arrow.up.doc.fill",
                color: .blue
            )
            .transition(.scale)
            
            StatCard(
                title: "RETURNED",
                value: "\(viewModel.returnedCount)",
                icon: "arrow.down.doc.fill",
                color: .green
            )
            .transition(.scale)
            
            StatCard(
                title: "REQUESTS",
                value: "\(viewModel.requestCount)",
                icon: "clock.fill",
                color: .purple
            )
            .transition(.scale)
            
            StatCard(
                title: "MEMBERS",
                value: "\(viewModel.memberCount)",
                icon: "person.3.fill",
                color: .orange
            )
            .transition(.scale)
        }
        .padding(.horizontal)
        .animation(.spring(), value: viewModel.borrowedCount)
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
                .padding(.top, 16)
            
            if viewModel.recentActivities.isEmpty {
                Text("No recent activities")
                    .foregroundColor(.gray)
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                // Limited to 5 rows and increased size
                ForEach(Array(viewModel.recentActivities.prefix(5).enumerated()), id: \.element.id) { _, activity in
                    EnhancedActivityRowLarge(activity: activity)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var suffix: String = ""
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: icon)
                    .foregroundColor(color)
                    .imageScale(.small)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// Enlarged activity row for more visibility
struct EnhancedActivityRowLarge: View {
    let activity: Activity
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(colorFromName(activity.colorName).opacity(0.2))
                    .frame(width: 50, height: 50) // Increased size
                
                Image(systemName: activity.iconName)
                    .font(.system(size: 22)) // Larger icon
                    .foregroundColor(colorFromName(activity.colorName))
            }
            
            VStack(alignment: .leading, spacing: 6) { // Increased spacing
                Text(activity.status)
                    .font(.system(size: 16, weight: .semibold)) // Larger font
                
                HStack {
                    Text(activity.bookTitle)
                        .font(.system(size: 14)) // Larger font
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Text("by \(activity.name)")
                        .font(.system(size: 14)) // Larger font
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let dues = activity.dues {
                    Text("Dues Paid: ₹\(String(format: "%.2f", dues))")
                        .font(.system(size: 14)) // Larger font
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Text(formattedDate(activity.date))
                .font(.system(size: 13)) // Larger font
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 14) // Increased padding
        .padding(.horizontal)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Helper function to convert string color names to SwiftUI Color
    private func colorFromName(_ name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .primary
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        // Get the time between now and the date
        let timeInterval = Date().timeIntervalSince(date)
        
        // Less than a minute
        if timeInterval < 60 {
            return "Just now"
        }
        // Less than an hour
        else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        }
        // Less than a day
        else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        }
        // Less than a week
        else if timeInterval < 604800 {
            let days = Int(timeInterval / 86400)
            return "\(days)d ago"
        }
        // Default to a standard date format
        else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: date)
        }
    }
}
