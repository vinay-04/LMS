//
//  LibrariansTabView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

struct LibrariansTabView: View {
    @StateObject private var vm = LibrarianListViewModel()
    @State private var searchText = ""
    @State private var showAdd = false
    @State private var selectedLibrarian: Librarian?
    @State private var showLibrarianDetail = false

    // filter on name or designation
    private var filtered: [Librarian] {
        if searchText.isEmpty { return vm.librarians }
        return vm.librarians.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.designation.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(UIColor.secondarySystemBackground)
                    .ignoresSafeArea()

                LinearGradient(
                    colors: [Color.purple.opacity(0.3), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                .ignoresSafeArea(edges: .top)

                VStack(spacing: 25) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        TextField("Search", text: $searchText)
                        Image(systemName: "mic.fill")
                    }
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                    Button {
                        showAdd = true
                    } label: {
                        HStack {
                            Text("Add a New Librarian")
                            Spacer()
                            Image(systemName: "plus.circle")
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 60)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 16)

                    List {
                        ForEach(filtered) { librarian in
                            Button(action: {
                                selectedLibrarian = librarian
                                showLibrarianDetail = true
                            }) {
                                HStack {
                                    Circle()
                                        .foregroundColor(.blue.opacity(0.3))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(librarian.name.prefix(1)))
                                                .foregroundColor(.blue)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(librarian.name).bold()
                                        Text(librarian.designation)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(librarian.status)
                                        .font(.subheadline)
                                        .foregroundColor(librarian.status == "Active" ? .green : .red)
                                }
                            }
                            .listRowBackground(Color(UIColor.secondarySystemBackground))
                        }
                    }
                    .listStyle(.plain)
                }
                .navigationDestination(isPresented: $showLibrarianDetail) {
                    if let librarian = selectedLibrarian {
                        LibrarianDetailView(librarian: librarian)
                    }
                }
            }
            .navigationTitle("Librarians")
            .sheet(isPresented: $showAdd) {
                NavigationStack {
                    AddLibrarianView()
                }
            }
            .onAppear {
                vm.fetchLibrarians()
            }
        }
    }
}
