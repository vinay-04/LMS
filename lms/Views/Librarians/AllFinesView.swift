//
//  AllFinesView.swift
//  lms
//
//  Created by user3 on 08/05/25.
//

import SwiftUI
import FirebaseFirestore

struct AllFinesView: View {
    @State private var fines: [Fine] = []
    @State private var isLoading = true
    @State private var errorMessage = ""
    @ObservedObject var viewModel = LibrarianHomeViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading all fines...")
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                } else if fines.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "indianrupeesign.circle")
                            .font(.system(size: 70))
                            .foregroundColor(.green)
                        
                        Text("No Outstanding Fines")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("There are no outstanding fines in the system.")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    VStack {
                        Text("Total Outstanding: ₹\(String(format: "%.2f", totalFinesAmount))")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                        
                        List {
                            ForEach(finesByMember.keys.sorted(), id: \.self) { memberId in
                                Section(header: Text("Member ID: \(memberId)")) {
                                    ForEach(finesByMember[memberId] ?? []) { fine in
                                        VStack(alignment: .leading) {
                                            Text(fine.bookTitle)
                                                .font(.headline)
                                            
                                            HStack {
                                                Text("Days overdue:")
                                                Spacer()
                                                Text("\(fine.daysOverdue)")
                                            }
                                            .font(.subheadline)
                                            
                                            HStack {
                                                Text("Fine amount:")
                                                Spacer()
                                                Text("₹\(String(format: "%.2f", fine.fineAmount))")
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.red)
                                            }
                                            .font(.subheadline)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("All Outstanding Fines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadAllFines()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                loadAllFines()
            }
        }
    }
    
    // Calculate total fines amount
    var totalFinesAmount: Double {
        fines.reduce(0) { $0 + $1.fineAmount }
    }
    
    // Group fines by member ID
    var finesByMember: [String: [Fine]] {
        Dictionary(grouping: fines, by: { $0.userId })
    }
    
    // Load all fines across all members
    private func loadAllFines() {
        isLoading = true
        fines = []
        
        // First, get all members
        viewModel.db.collection("members").getDocuments { snapshot, error in
            if let error = error {
                self.isLoading = false
                self.errorMessage = "Error loading members: \(error.localizedDescription)"
                return
            }
            
            let memberDocuments = snapshot?.documents ?? []
            let dispatchGroup = DispatchGroup()
            var allFines: [Fine] = []
            
            // For each member, check their fines
            for memberDoc in memberDocuments {
                let memberID = memberDoc.documentID
                
                dispatchGroup.enter()
                
                self.viewModel.db.collection("members").document(memberID)
                    .collection("userbooks").document("collection")
                    .collection("fines")
                    .whereField("isPaid", isEqualTo: false)
                    .getDocuments { finesSnapshot, finesError in
                        defer { dispatchGroup.leave() }
                        
                        if let error = finesError {
                            print("Error fetching fines for member \(memberID): \(error.localizedDescription)")
                            return
                        }
                        
                        for document in finesSnapshot?.documents ?? [] {
                            if let fine = Fine.fromFirestore(document: document) {
                                // Recalculate the current fine amount
                                let (days, amount) = Fine.calculateFine(issuedDate: fine.issuedTimestamp)
                                
                                // Only add if there's actually a fine amount
                                if amount > 0 {
                                    var updatedFine = fine
                                    updatedFine.daysOverdue = days
                                    updatedFine.fineAmount = amount
                                    allFines.append(updatedFine)
                                }
                            }
                        }
                    }
            }
            
            // When all operations are complete
            dispatchGroup.notify(queue: .main) {
                self.fines = allFines.sorted(by: { $0.fineAmount > $1.fineAmount })
                self.isLoading = false
            }
        }
    }
}
