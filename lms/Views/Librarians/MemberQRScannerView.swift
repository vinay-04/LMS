//
//  MemberQRScannerView.swift
//  lms
//
//  Created by user@30 on 05/05/25.
//


import SwiftUI

struct MemberQRScannerView: View {
    @Binding var memberID: String?
    @Environment(\.dismiss) var dismiss
    @State private var showManualEntry = false
    @State private var manualID = ""
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Content
                VStack {
                    if showManualEntry {
                        // Manual Entry View
                        VStack(spacing: 20) {
                            Text("Enter Member ID Manually")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()

                            TextField("Enter Member ID", text: $manualID)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .padding(.horizontal)

                            Button(action: {
                                if !manualID.isEmpty {
                                    memberID = manualID
                                    dismiss()
                                } else {
                                    alertMessage = "Please enter a valid Member ID"
                                    showAlert = true
                                }
                            }) {
                                Text("Submit")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(manualID.isEmpty ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(manualID.isEmpty)
                            .padding(.horizontal)

                            Button(action: {
                                showManualEntry = false
                                manualID = ""
                            }) {
                                Text("Back to Scanner")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // Simulated scanner for now
                        VStack {
                            Text("Scan Member QR Code")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                            
                            // Placeholder for scanner
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.yellow, lineWidth: 3)
                                    .frame(width: 250, height: 250)
                                
                                // Simulated scanning animation
                                Rectangle()
                                    .fill(Color.green.opacity(0.3))
                                    .frame(height: 2)
                                    .offset(y: -50)
                            }
                            .frame(height: 250)
                            .padding(.vertical, 30)
                            
                            // Simulation buttons for testing
                            Button(action: {
                                memberID = "MEMBER_001"
                                dismiss()
                            }) {
                                Text("Simulate Member Scan")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)

                            Button(action: {
                                showManualEntry = true
                            }) {
                                Text("Enter ID Manually")
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    .foregroundColor(.white)
                            }
                            .padding()
                        }
                    }
                }
                .padding()
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Scanner Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle("Scan Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
