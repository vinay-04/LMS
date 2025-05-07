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

    // MARK: – Filter logic
    private var filtered: [Member] {
        if searchText.isEmpty { return vm.members }
        return vm.members.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Background color
            Color(UIColor.secondarySystemBackground)
                .ignoresSafeArea()

            // Decorative gradient at top
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [Color.purple.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .ignoresSafeArea(edges: .top)
                Spacer()
            }

            // Main content
            VStack(spacing: 25) {
                // Search bar with exactly 30pt under the nav-title
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search", text: $searchText)
                    Image(systemName: "mic.fill")
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.top, 30)

                // Loading / error / empty / list
                if vm.isLoading {
                    VStack {
                        ProgressView().padding()
                        Text("Loading members...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

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

                } else if filtered.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                        Text(searchText.isEmpty
                             ? "No members found"
                             : "No matching members")
                            .font(.headline)
                        Text(searchText.isEmpty
                             ? "Members will appear here once added"
                             : "Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    List {
                        ForEach(filtered) { member in
                            NavigationLink(
                                destination: MemberDetailView(member: member, viewModel: vm)
                            ) {
                                HStack {
                                    Circle()
                                        .foregroundColor(.indigo.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.name).bold()
                                        Text(member.role)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("Active")
                                        .font(.subheadline)
                                        .foregroundColor(.green)
                                }
                            }
                            // make each row blend with the screen
                            .listRowBackground(Color(UIColor.secondarySystemBackground))
                        }
                    }
                    .listStyle(.plain)
                    // hide default white behind empty areas (iOS 16+)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        // fetch & refresh
        .onAppear { vm.fetchMembers() }
        .refreshable { vm.fetchMembers() }
    }
}
