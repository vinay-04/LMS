//
//  MemberFinesView.swift
//  lms
//
//  Created by user3 on 08/05/25.
//


import SwiftUI

struct MemberFinesView: View {
    let memberID: String
    @State private var fines: [Fine] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @ObservedObject var viewModel = LibrarianHomeViewModel()
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading fines...")
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            } else if fines.isEmpty {
                ContentUnavailableView(
                    "No Outstanding Fines",
                    systemImage: "indianrupeesign.circle",
                    description: Text("This member has no outstanding fines.")
                )
            } else {
                List {
                    ForEach(fines) { fine in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(fine.bookTitle)
                                .font(.headline)
                            
                            HStack {
                                Text("Issued on:")
                                Spacer()
                                Text(formatDate(fine.issuedTimestamp))
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Days overdue:")
                                Spacer()
                                Text("\(fine.daysOverdue)")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("Fine amount:")
                                Spacer()
                                Text("₹\(String(format: "%.2f", fine.fineAmount))")
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            }
                            
                            Button(action: {
                                markFineAsPaid(fine: fine)
                            }) {
                                Text("Mark as Paid")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.top, 5)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Member Fines")
        .onAppear {
            loadFines()
        }
    }
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Load all fines for this member
    private func loadFines() {
        isLoading = true
        fines = []
        
        let finesRef = viewModel.db.collection("members").document(memberID)
                                .collection("userbooks").document("collection")
                                .collection("fines")
                                .whereField("isPaid", isEqualTo: false)
        
        finesRef.getDocuments { snapshot, error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Error loading fines: \(error.localizedDescription)"
                return
            }
            
            var tempFines: [Fine] = []
            
            for document in snapshot?.documents ?? [] {
                if let fine = Fine.fromFirestore(document: document) {
                    // Recalculate the current fine amount
                    let (days, amount) = Fine.calculateFine(issuedDate: fine.issuedTimestamp)
                    
                    // Only add if there's actually a fine amount
                    if amount > 0 {
                        var updatedFine = fine
                        updatedFine.daysOverdue = days
                        updatedFine.fineAmount = amount
                        tempFines.append(updatedFine)
                    }
                }
            }
            
            fines = tempFines
        }
    }
    
    // Mark a fine as paid
    private func markFineAsPaid(fine: Fine) {
        isLoading = true
        
        viewModel.markFineAsPaid(memberID: memberID, bookID: fine.bookUUID, fine: fine) { success in
            isLoading = false
            
            if success {
                // Record the fine payment activity
                viewModel.recordFinePayment(
                    bookID: fine.bookUUID,
                    bookTitle: fine.bookTitle,
                    memberID: memberID,
                    memberName: "Member ID: \(memberID)", // You might want to fetch the actual name
                    amount: fine.fineAmount
                )
                
                // Refresh the list
                loadFines()
            } else {
                errorMessage = "Failed to mark fine as paid"
            }
        }
    }
}
