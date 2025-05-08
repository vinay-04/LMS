//
//  MemberStatsView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore
import Charts

struct MemberStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var members: [Member] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    @State private var selectedTimeRange = TimeRange.month
    
    // For animation
    @State private var appear = false
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    statsView
                }
            }
            .navigationTitle("Member Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .fontWeight(.medium)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { fetchMembers() }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .rotationEffect(isLoading ? .degrees(360) : .degrees(0))
                            .animation(isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                }
            }
            .onAppear {
                fetchMembers()
                withAnimation(.easeOut(duration: 0.5)) {
                    appear = true
                }
            }
        }
    }
    
    // MARK: - Background Gradient
    var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(UIColor.systemBackground),
                Color(UIColor.systemBackground).opacity(0.95)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Loading View
    var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading member data...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .padding(.bottom, 10)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { fetchMembers() }) {
                Text("Try Again")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Stats View
    var statsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Time range selector
                timeRangeSelector
                    .padding(.horizontal)
                    .padding(.top, 4)
                
                // Summary cards
                summaryCardsView
                    .padding(.horizontal)
                
                // Growth Chart
                growthChartView
                    .padding(.horizontal)
                
                // Recent activity
                recentMembersView
                    .padding(.horizontal)
                
                // Reference row
                Text("Showing data for \(members.count) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
            }
            .padding(.top, 12)
            .opacity(appear ? 1 : 0)
            .offset(y: appear ? 0 : 30)
        }
        .refreshable {
            await refreshData()
        }
    }
    
    // MARK: - Time Range Selector
    var timeRangeSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases) { range in
                Button(action: {
                    withAnimation {
                        selectedTimeRange = range
                    }
                }) {
                    Text(range.rawValue)
                        .fontWeight(selectedTimeRange == range ? .semibold : .regular)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            ZStack {
                                if selectedTimeRange == range {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.blue.opacity(0.1))
                                }
                            }
                        )
                        .foregroundColor(selectedTimeRange == range ? .blue : .secondary)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Summary Cards
    var summaryCardsView: some View {
        HStack(spacing: 12) {
            // Total Members Card
            StatCard(
                title: "Total Members",
                value: "\(members.count)",
                trend: "+\(countNewMembersInPeriod())",
                trendLabel: timeRangeTrendLabel(),
                icon: "person.3.fill",
                iconColor: .blue
            )
            
            // Active Members Card
            StatCard(
                title: "Active Members",
                value: "\(members.count)",
                trend: "+\(countNewMembersInPeriod())",
                trendLabel: timeRangeTrendLabel(),
                icon: "person.fill.checkmark",
                iconColor: .green
            )
        }
    }
    
    // MARK: - Growth Chart
    var growthChartView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Member Growth")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(membersAddedInTimeRange()) new")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            if members.count > 1 {
                Chart {
                    ForEach(membersByPeriod()) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Members", point.count)
                        )
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .foregroundStyle(Color.blue.gradient)
                        
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Members", point.count)
                        )
                        .foregroundStyle(Color.blue.opacity(0.1).gradient)
                        
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("Members", point.count)
                        )
                        .symbolSize(50)
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(position: .bottom) { value in
                        AxisValueLabel() {
                            if let date = value.as(Date.self) {
                                let format = selectedTimeRange == .week ? "EEE" :
                                            (selectedTimeRange == .month ? "d MMM" : "MMM")
                                Text(date.formatted(.dateTime.day().month().weekday()))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            } else {
                Text("Not enough data to display growth chart")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Role Distribution
    var roleDistributionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Member Roles")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 16) {
                ForEach(roleDistribution(), id: \.role) { item in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(colorForRole(item.role))
                            .frame(width: 12, height: 12)
                        
                        Text(item.role)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("(\(Int(item.percentage))%)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                            .overlay(
                                HStack {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(colorForRole(item.role))
                                        .frame(width: CGFloat(item.percentage) / 100 * geometry.size.width)
                                    
                                    Spacer(minLength: 0)
                                }
                            )
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Recent Members
    var recentMembersView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Members")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if members.isEmpty {
                Text("No members to display")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(members.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5))) { member in
                        MemberRow(member: member)
                        
                        if member.id != members.sorted(by: { $0.createdAt > $1.createdAt }).prefix(5).last?.id {
                            Divider()
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
        .padding()
        .background(cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Views
    var cardBackground: some View {
        Group {
            if colorScheme == .dark {
                Color(UIColor.secondarySystemBackground)
            } else {
                Color.white
            }
        }
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Data Fetching
    private func fetchMembers() {
        let db = Firestore.firestore()
        isLoading = true
        errorMessage = nil
        
        db.collection("members").getDocuments { snapshot, error in
            if let error = error {
                isLoading = false
                errorMessage = "Error fetching members: \(error.localizedDescription)"
                print(errorMessage!)
                return
            }
            
            guard let documents = snapshot?.documents else {
                isLoading = false
                errorMessage = "No member documents found"
                print(errorMessage!)
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
            isLoading = false
        }
    }
    
    // MARK: - Async refresh
    private func refreshData() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Call fetch on main thread
        await MainActor.run {
            fetchMembers()
        }
    }
    
    // MARK: - Data Analysis Helpers
    private func countNewMembersInPeriod() -> Int {
        let calendar = Calendar.current
        let startDate: Date
        
        switch selectedTimeRange {
        case .week:
            guard let date = calendar.date(byAdding: .day, value: -7, to: Date()) else { return 0 }
            startDate = date
        case .month:
            guard let date = calendar.date(byAdding: .month, value: -1, to: Date()) else { return 0 }
            startDate = date
        case .year:
            guard let date = calendar.date(byAdding: .year, value: -1, to: Date()) else { return 0 }
            startDate = date
        }
        
        return members.filter { $0.createdAt >= startDate }.count
    }
    
    private func timeRangeTrendLabel() -> String {
        switch selectedTimeRange {
        case .week: return "this week"
        case .month: return "this month"
        case .year: return "this year"
        }
    }
    
    private func membersAddedInTimeRange() -> Int {
        switch selectedTimeRange {
        case .week:
            return countMembersAddedInLastDays(7)
        case .month:
            return countMembersAddedInLastDays(30)
        case .year:
            return countMembersAddedInLastDays(365)
        }
    }
    
    private func countMembersAddedInLastDays(_ days: Int) -> Int {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return 0 }
        return members.filter { $0.createdAt >= startDate }.count
    }
    
    // MARK: - Role Analysis
    private func roleDistribution() -> [(role: String, count: Int, percentage: Double)] {
        let roleCounts = Dictionary(grouping: members, by: { $0.role })
            .map { (role, members) in (role: role, count: members.count) }
            .sorted { $0.count > $1.count }
        
        let totalCount = members.count
        
        return roleCounts.map { role, count in
            let percentage = totalCount > 0 ? Double(count) / Double(totalCount) * 100 : 0
            return (role: role, count: count, percentage: percentage)
        }
    }
    
    private func topRole() -> String {
        let distribution = roleDistribution()
        return distribution.first?.role ?? "Member"
    }
    
    private func roleCount(_ role: String) -> Int {
        return members.filter { $0.role == role }.count
    }
    
    private func colorForRole(_ role: String) -> Color {
        switch role.lowercased() {
        case "admin": return .red
        case "moderator": return .orange
        case "editor": return .green
        case "premium": return .purple
        default: return .blue
        }
    }
    
    // MARK: - Chart Data
    struct DateCount: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }
    
    private func membersByPeriod() -> [DateCount] {
        let calendar = Calendar.current
        var datePoints: [DateCount] = []
        
        switch selectedTimeRange {
        case .week:
            // Daily for the last week
            for day in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
                let startOfDay = calendar.startOfDay(for: date)
                let count = members.filter { $0.createdAt <= startOfDay }.count
                datePoints.append(DateCount(date: startOfDay, count: count))
            }
            
        case .month:
            // Weekly for the last month
            for week in 0..<4 {
                guard let date = calendar.date(byAdding: .weekOfYear, value: -week, to: Date()) else { continue }
                let startOfWeek = calendar.startOfDay(for: date)
                let count = members.filter { $0.createdAt <= startOfWeek }.count
                datePoints.append(DateCount(date: startOfWeek, count: count))
            }
            
        case .year:
            // Monthly for the last year
            for month in 0..<12 {
                guard let date = calendar.date(byAdding: .month, value: -month, to: Date()) else { continue }
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                let count = members.filter { $0.createdAt <= startOfMonth }.count
                datePoints.append(DateCount(date: startOfMonth, count: count))
            }
        }
        
        return datePoints.sorted(by: { $0.date < $1.date })
    }
}

// MARK: - UI Components
struct StatCard: View {
    let title: String
    let value: String
    let trend: String
    let trendLabel: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(iconColor)
                    )
                
                Spacer()
            }
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
                .padding(.top, 4)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                Text(trend)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(trend.contains("+") ? .green : .primary)
                
                Text(trendLabel)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

// MARK: - Preview
struct MemberStatsView_Previews: PreviewProvider {
    static var previews: some View {
        MemberStatsView()
            .preferredColorScheme(.light)
        
        MemberStatsView()
            .preferredColorScheme(.dark)
    }
}
