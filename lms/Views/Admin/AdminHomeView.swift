//
//  AdminHomeView.swift
//  lms
//
//  Created by VR on 25/04/25.
//

import SwiftUI
import FirebaseFirestore

struct AdminHomeView: View {
    let user: User
    @State private var showAddLibrarian = false
    @State private var showAddBook = false
    @State private var bookCount = "..."
    @State private var librarianCount = "..."
    @State private var memberCount = "..."
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()

            LinearGradient(
                colors: [Color.purple.opacity(0.3), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)
            .ignoresSafeArea(edges: .top)

            ScrollView {
                // 20‐point gaps everywhere, left‐aligned
                VStack(alignment: .leading, spacing: 30) {

                    Text("Welcome, \(user.fullName)!")
                        .font(.title3)
                        .fontWeight(.semibold)

                    // 2×2 summary cards
                    LazyVGrid(
                        columns: [
                            GridItem(.fixed(166.5), spacing: 20),
                            GridItem(.fixed(166.5))
                        ],
                        spacing: 20
                    ) {
                        SummaryCard(title: "BOOKS", value: bookCount)
                            .overlay(isLoading ? ProgressView() : nil)
                        SummaryCard(title: "LIBRARIANS", value: librarianCount)
                            .overlay(isLoading ? ProgressView() : nil)
                        SummaryCard(title: "REVENUE", value: "$4,134")
                        SummaryCard(title: "MEMBERS", value: memberCount)
                            .overlay(isLoading ? ProgressView() : nil)
                    }

                    // Add Librarian
                    Button {
                        showAddLibrarian = true
                    } label: {
                        HStack {
                            Text("Add Librarian")
                            Spacer()
                            Image(systemName: "person")
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    // Add Book
                    Button {
                        showAddBook = true
                    } label: {
                        HStack {
                            Text("Add Book")
                            Spacer()
                            Image(systemName: "book")
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }

                    // Ensure 20 pt gap above the tab bar
                    Spacer(minLength: 20)
                }
                .padding(.top, 20)       // 20 pts from top of scroll view
                .padding(.horizontal, 16)
            }
        }
        // MARK: — Modals —
        .fullScreenCover(isPresented: $showAddLibrarian) {
            NavigationStack {
                AddLibrarianView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back") {
                                showAddLibrarian = false
                            }
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showAddBook) {
            AddBooksView()
        }
        // MARK: — Data Fetching —
        .onAppear {
            fetchSummaryData()
        }
    }

    private func fetchSummaryData() {
        let db = Firestore.firestore()
        isLoading = true

        db.collection("books").getDocuments { snapshot, error in
            if let _ = error {
                bookCount = "Error"
            } else {
                bookCount = "\(snapshot?.documents.count ?? 0)"
            }
        }

        db.collection("librarians").getDocuments { snapshot, error in
            if let _ = error {
                librarianCount = "Error"
            } else {
                librarianCount = "\(snapshot?.documents.count ?? 0)"
            }
        }

        db.collection("members").getDocuments { snapshot, error in
            if let _ = error {
                memberCount = "Error"
            } else {
                memberCount = "\(snapshot?.documents.count ?? 0)"
            }
            isLoading = false
        }
    }
}

// MARK: — SummaryCard —

struct SummaryCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title3).bold()
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .frame(width: 166.5, height: 83, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: — Preview —

struct AdminHomeView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleUser = User(
            id: "admin123",
            fullName: "Jane Doe",
            email: "jane@example.com",
            profileImageUrl: nil,
            role: .admin,
            isVerified: true,
            mfaEnabled: false,
            preferences: nil,
            createdAt: Date()
        )

        NavigationStack {
            AdminHomeView(user: sampleUser)
        }
    }
}
