//
//  AdminHomeView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore
import Charts

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding(.vertical, 8)
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var suffix: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: icon)
                    .imageScale(.small)
                    .foregroundColor(color)
            }
            .padding(.top, 8)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .frame(width: 166.5, height: 83)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ChartContainer<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: – AdminHomeView

struct AdminHomeView: View {
    let user: User

    @State private var showAddLibrarian = false
    @State private var showAddBook = false
    @State private var showBookStats = false
    @State private var showLibrarianStats = false
    @State private var showMemberStats = false

    @State private var bookCount = "..."
    @State private var librarianCount = "..."
    @State private var memberCount = "..."
    @State private var isLoading = true
    @State private var members: [Member] = []

    var membersByMonth: [MonthData] {
        var monthsData: [MonthData] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM yyyy"
        
        // Get last 6 months
        let calendar = Calendar.current
        
        for i in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                let monthStr = dateFormatter.string(from: date)
                monthsData.append(MonthData(month: monthStr, count: 0))
            }
        }
        
        // Count members by join month
        for member in members {
            let monthStr = dateFormatter.string(from: member.createdAt)
            if let index = monthsData.firstIndex(where: { $0.month == monthStr }) {
                monthsData[index].count += 1
            }
        }
        
        return monthsData.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Welcome, \(user.fullName)!")
                    .font(.title3)
                    .fontWeight(.semibold)

                // Quick Actions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        Button { showAddBook = true } label: {
                            ActionButton(
                                title: "Add Book",
                                icon: "book.fill",
                                color: Color(.systemIndigo)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button { showAddLibrarian = true } label: {
                            ActionButton(
                                title: "Add Librarian",
                                icon: "person.fill.badge.plus",
                                color: .green
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Book Stats Chart
                VStack(alignment: .leading) {
                    Text("Book Status Overview")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                    
                    BookStatsChart()
                        .padding(.top, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                }

                // Statistics Header
                Text("Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top, 8)

                // Summary Cards
                LazyVGrid(
                    columns: [
                        GridItem(.fixed(166.5), spacing: 20),
                        GridItem(.fixed(166.5))
                    ],
                    spacing: 20
                ) {
                    Button { showBookStats = true } label: {
                        SummaryCard(
                            title: "BOOKS",
                            value: bookCount,
                            icon: "books.vertical.fill",
                            color: .blue
                        )
                        .overlay(isLoading ? ProgressView() : nil)
                    }
                    .buttonStyle(PlainButtonStyle())

                    SummaryCard(
                        title: "LIBRARIANS",
                        value: librarianCount,
                        icon: "person.2.fill",
                        color: .green
                    )
                    .overlay(isLoading ? ProgressView() : nil)

                    SummaryCard(
                        title: "REVENUE",
                        value: "$4,134",
                        icon: "dollarsign.square.fill",
                        color: .purple
                    )

                    Button { showMemberStats = true } label: {
                        SummaryCard(
                            title: "MEMBERS",
                            value: memberCount,
                            icon: "person.3.fill",
                            color: .orange
                        )
                        .overlay(isLoading ? ProgressView() : nil)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Member Growth Chart - Moved to be below Statistics as requested
                VStack(alignment: .leading) {
                    Text("Growth Analytics")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.top, 12)
                    
                    ChartContainer(title: "Member Growth") {
                        if isLoading {
                            ProgressView()
                                .frame(height: 200)
                        } else {
                            Chart(membersByMonth) { item in
                                BarMark(
                                    x: .value("Month", item.month),
                                    y: .value("New Members", item.count)
                                )
                                .foregroundStyle(Color.purple.gradient)
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 200)
                        }
                    }
                    .padding(.top, 4)
                }

                .onAppear {
                    fetchSummaryData()
                    fetchMembers()
                }

                Spacer(minLength: 20)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)
        }
        .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea())
        
        // MARK: Modals
        .fullScreenCover(isPresented: $showAddLibrarian) {
            NavigationStack {
                AddLibrarianView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showAddLibrarian = false }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            }
                            .tint(.indigo)
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showAddBook) {
            NavigationStack {
                AddBooksView()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { showAddBook = false }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                    Text("Back")
                                }
                            }
                            .tint(.indigo)
                        }
                    }
            }
        }
        .fullScreenCover(isPresented: $showBookStats) {
            BooksStatsView()
        }
        .fullScreenCover(isPresented: $showMemberStats) {
            MemberStatsView()
        }
    }

    // MARK: Data Fetching
    private func fetchSummaryData() {
        let db = Firestore.firestore()
        isLoading = true

        db.collection("books").getDocuments { snap, _ in
            bookCount = "\(snap?.documents.count ?? 0)"
        }
        db.collection("librarians").getDocuments { snap, _ in
            librarianCount = "\(snap?.documents.count ?? 0)"
        }
        db.collection("members").getDocuments { snap, _ in
            memberCount = "\(snap?.documents.count ?? 0)"
            isLoading = false
        }
    }
    
    private func fetchMembers() {
        let db = Firestore.firestore()
        
        db.collection("members").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching members: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No member documents found")
                return
            }
            
            print("Found \(documents.count) member documents")
            
            var loadedMembers: [Member] = []
            
            for document in documents {
                do {
                    let data = document.data()
                    
                    // Extract fields with better handling of field names based on Firestore structure
                    let name = data["name"] as? String ??
                             data["full_name"] as? String ??
                             data["fullName"] as? String ??
                             "Unknown"
                    
                    let email = data["email"] as? String ?? "No email"
                    let phone = data["phone"] as? String ?? "No phone"
                    
                    // Normalize role case for consistency
                    let roleValue = data["role"] as? String ?? "Member"
                    let role = roleValue.capitalized
                    
                    // Better timestamp handling with more field name options
                    let createdAt: Date
                    if let timestamp = data["createdAt"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    } else if let timestamp = data["created_at"] as? Timestamp {
                        createdAt = timestamp.dateValue()
                    } else if let timestampDouble = data["createdAt"] as? Double {
                        createdAt = Date(timeIntervalSince1970: timestampDouble)
                    } else if let timestampDouble = data["created_at"] as? Double {
                        createdAt = Date(timeIntervalSince1970: timestampDouble)
                    } else {
                        createdAt = Date()
                        print("Missing or invalid createdAt timestamp in document: \(document.documentID)")
                    }
                    
                    let member = Member(
                        id: document.documentID,
                        name: name,
                        phone: phone,
                        email: email,
                        role: role,
                        createdAt: createdAt
                    )
                    
                    loadedMembers.append(member)
                } catch {
                    print("Error processing member document \(document.documentID): \(error)")
                }
            }
            
            print("Successfully loaded \(loadedMembers.count) members")
            self.members = loadedMembers
        }
    }
}

// Preview
#Preview {
    AdminHomeView(user: User(
        id: "1",
        fullName: "Admin User",
        email: "admin@example.com",
        role: .admin,
        isVerified: true,
        mfaEnabled: false,
        createdAt: Date()
    ))
}
