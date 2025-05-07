//
//  BarcodeScannerView.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUI
import CodeScanner

struct BarcodeScannerView: View {
    @Binding var scannedISBN: String?
    @Environment(\.dismiss) var dismiss
    @State private var showManualEntry = false
    @State private var manualISBN = ""
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
                            Text("Enter ISBN Manually")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()

                            TextField("Enter ISBN", text: $manualISBN)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .padding(.horizontal)

                            Button(action: {
                                if !manualISBN.isEmpty {
                                    if isValidISBN(manualISBN) {
                                        scannedISBN = manualISBN
                                        print("Manual ISBN entry successful: \(manualISBN)")
                                        dismiss()
                                    } else {
                                        alertMessage = "Please enter a valid ISBN"
                                        showAlert = true
                                    }
                                }
                            }) {
                                Text("Submit")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(manualISBN.isEmpty ? Color.gray : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            .disabled(manualISBN.isEmpty)
                            .padding(.horizontal)

                            Button(action: {
                                showManualEntry = false
                                manualISBN = ""
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
                        // Scanner View
                        VStack {
                            Text("Scan Book's ISBN")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()

                            CodeScannerView(
                                codeTypes: [.ean13, .ean8],
                                simulatedData: "9780141326696", // Update with a real ISBN for testing
                                completion: { result in
                                    switch result {
                                    case .success(let code):
                                        let scannedCode = code.string.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if isValidISBN(scannedCode) {
                                            scannedISBN = scannedCode
                                            print("Scanned ISBN: \(scannedCode)")
                                            dismiss()
                                        } else {
                                            alertMessage = "Invalid ISBN code scanned. Please try again."
                                            showAlert = true
                                        }
                                    case .failure(let error):
                                        print("Scanning failed: \(error.localizedDescription)")
                                        alertMessage = "Scanning failed: \(error.localizedDescription)"
                                        showAlert = true
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity, maxHeight: 300)

                            Button(action: {
                                showManualEntry = true
                            }) {
                                Text("Enter Code Manually")
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
                    title: Text("Scanning Error"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                            Text("Back")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onDisappear {
            // Ensure ISBN is passed correctly when dismissing
            if scannedISBN != nil {
                print("BarcodeScannerView disappeared with ISBN: \(scannedISBN!)")
            }
        }
    }
    
    // Function to validate ISBN format
    private func isValidISBN(_ isbn: String) -> Bool {
        // Basic validation - can be enhanced based on your requirements
        let trimmedISBN = isbn.replacingOccurrences(of: "-", with: "")
                              .replacingOccurrences(of: " ", with: "")
        
        // Check if ISBN is 10 or 13 digits
        return (trimmedISBN.count == 10 || trimmedISBN.count == 13) &&
               trimmedISBN.allSatisfy { $0.isNumber }
    }
}

struct BarcodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BarcodeScannerView(scannedISBN: .constant(nil))
    }
}
