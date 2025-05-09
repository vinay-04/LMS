//
//  MembersTabView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore

struct MembersTabView: View {
    @StateObject private var vm = MembersListViewModel()
    @State private var searchText = ""
    @State private var sortOption = SortOption.nameAscending
    
    enum SortOption: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
    }

    // MARK: – Filter and Sort logic
    private var filteredMembers: [Member] {
        let filtered = searchText.isEmpty ? vm.members : vm.members.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText)
        }
        
        return filtered.sorted { first, second in
            switch sortOption {
            case .nameAscending:
                return first.name < second.name
            case .nameDescending:
                return first.name > second.name
            case .dateNewest:
                return first.createdAt > second.createdAt
            case .dateOldest:
                return first.createdAt < second.createdAt
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Background color
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 0) {
                // Search bar with sort button
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search members", text: $searchText)
                    
                    Spacer()
                    
                    Menu {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(option.rawValue) {
                                sortOption = option
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Loading / error / empty / list
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error = vm.errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error loading members")
                            .font(.headline)
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") { vm.fetchMembers() }
                            .padding(.top, 8)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredMembers.isEmpty {
                    Spacer()
                    Text("No members found")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(filteredMembers) { member in
                            NavigationLink(
                                destination: MemberDetailView(member: member, viewModel: vm)
                            ) {
                                MemberRow(member: member)
                            }
                            .listRowBackground(Color(UIColor.secondarySystemBackground))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .scrollContentBackground(.hidden)
                }
            }
        }
        // fetch & refresh
        .onAppear { vm.fetchMembers() }
        .refreshable { vm.fetchMembers() }
        .navigationTitle("Members")
    }
}

struct MembersTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MembersTabView()
        }
    }
}

struct MemberRow: View {
    let member: Member
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.purple.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(member.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.purple)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Only show role badge if it's not "Member"
            if member.role != "Member" {
                Text(member.role)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 4)
    }
}
