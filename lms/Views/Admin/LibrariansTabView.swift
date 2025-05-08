//
//  LibrariansTabView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import FirebaseFirestore

struct LibrariansTabView: View {
    @StateObject private var vm = LibrarianListViewModel()
    @State private var searchText = ""
    @State private var sortOption = SortOption.nameAscending
    @State private var selectedLibrarian: Librarian?
    @State private var showLibrarianDetail = false
    
    enum SortOption: String, CaseIterable {
        case nameAscending = "Name (A-Z)"
        case nameDescending = "Name (Z-A)"
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
    }

    // MARK: – Filter and Sort logic
    private var filteredLibrarians: [Librarian] {
        let filtered = searchText.isEmpty ? vm.librarians : vm.librarians.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.email.localizedCaseInsensitiveContains(searchText) ||
            $0.designation.localizedCaseInsensitiveContains(searchText)
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
        NavigationStack {
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
                        TextField("Search librarians", text: $searchText)
                        
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
                            Text("Error loading librarians")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Retry") { vm.fetchLibrarians() }
                                .padding(.top, 8)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if filteredLibrarians.isEmpty {
                        Spacer()
                        Text("No librarians found")
                            .foregroundColor(.secondary)
                        Spacer()
                    } else {
                        List {
                            ForEach(filteredLibrarians) { librarian in
                                Button {
                                    selectedLibrarian = librarian
                                    showLibrarianDetail = true
                                } label: {
                                    LibrarianRow(librarian: librarian)
                                }
                                .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                        }
                        .listStyle(PlainListStyle())
                        .scrollContentBackground(.hidden)
                    }
                }
                
                // Floating Add Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        NavigationLink(destination: AddLibrarianView()) {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().foregroundColor(.indigo))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 25)
                        .padding(.bottom, 25)
                    }
                }
            }
            // Navigation destination for librarian detail
            .navigationDestination(isPresented: $showLibrarianDetail) {
                if let librarian = selectedLibrarian {
                    LibrarianDetailView(librarian: librarian)
                }
            }
            // fetch & refresh
            .onAppear { vm.fetchLibrarians() }
            .refreshable { vm.fetchLibrarians() }
            .navigationTitle("Librarians")
        }
    }
}

struct LibrariansTabView_Previews: PreviewProvider {
    static var previews: some View {
        LibrariansTabView()
    }
}

struct LibrarianRow: View {
    let librarian: Librarian
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.indigo.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(librarian.name.prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.indigo)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(librarian.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(librarian.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Replaced designation badge with chevron icon
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.vertical, 4)
    }
}
