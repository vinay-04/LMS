//
//  LibrarianHomeView.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import SwiftUI
import ActivityKit

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
            VStack(spacing: 20) {
                // Stats Section
                HStack(spacing: 20) {
                    StatCardView(title: "Borrowed", value: "\(viewModel.borrowedCount)", percentage: viewModel.borrowedPercentage, isIncrease: false)
                    StatCardView(title: "Returned", value: "\(viewModel.returnedCount)", percentage: viewModel.returnedPercentage, isIncrease: true)
                }
                .padding(.horizontal)
                
                HStack(spacing: 20) {
                    StatCardView(title: "Overdue", value: "$\(String(format: "%.1f", viewModel.overdueAmount))", percentage: viewModel.overduePercentage, isIncrease: true)
                    StatCardView(title: "Members", value: "\(viewModel.memberCount)", percentage: viewModel.memberPercentage, isIncrease: false)
                }
                .padding(.horizontal)

                // Issue/Return Buttons with updated colors
                HStack(spacing: 20) {
                    Button(action: {
                        if !isProcessingSheet {
                            isReturningBook = false
                            viewModel.issueRequest()
                            showScanner = true
                        }
                    }) {
                        Text("Issue")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green) // Changed to green
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        if !isProcessingSheet {
                            isReturningBook = true
                            viewModel.returnRequest()
                            showScanner = true
                        }
                    }) {
                        Text("Return")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.yellow) // Changed to yellow
                            .foregroundColor(.black) // Changed text to black for better visibility on yellow
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)

                // Recent Activity
                VStack(alignment: .leading) {
                    Text("Recent Activity")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.horizontal)
                    
                    if viewModel.recentActivities.isEmpty {
                        Text("No recent activities")
                            .foregroundColor(.gray)
                            .padding(.vertical)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(viewModel.recentActivities) { activity in
                                    ActivityRow(activity: activity)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)

                Spacer()
            }
            .navigationTitle("Librarian")
            .navigationBarTitleDisplayMode(.large)
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
}

// MARK: - Supporting Views
struct StatCardView: View {
    let title: String
    let value: String
    let percentage: String
    let isIncrease: Bool

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.title2)
                .foregroundColor(.black)
            Text(percentage)
                .font(.caption)
                .foregroundColor(isIncrease ? .green : .red)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
    }
}

struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(activity.name)
                        .font(.headline)
                    
                    Text(activity.bookTitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(activity.date, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(activity.status)
                        .foregroundColor(activity.status == "Borrowed" ? .orange : .green)
                    
                    if let dues = activity.dues {
                        Text("Dues Paid: $\(String(format: "%.2f", dues))")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            
            Divider()
        }
    }
}
