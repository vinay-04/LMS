//import SwiftUI
//
//struct LibrariansTabView: View {
//    @StateObject private var vm = LibrarianListViewModel()
//    @State private var searchText = ""
//    @State private var showAdd = false
//    @State private var selectedLibrarian: Librarian?
//    @State private var showLibrarianDetail = false
//
//    // filter on name or designation
//    private var filtered: [Librarian] {
//        if searchText.isEmpty { return vm.librarians }
//        return vm.librarians.filter {
//            $0.name.localizedCaseInsensitiveContains(searchText) ||
//            $0.designation.localizedCaseInsensitiveContains(searchText)
//        }
//    }
//
//    var body: some View {
//        NavigationStack {
//            ZStack(alignment: .top) {
//                Color(UIColor.secondarySystemBackground)
//                    .ignoresSafeArea()
//
//                LinearGradient(
//                    colors: [Color.purple.opacity(0.3), .clear],
//                    startPoint: .top,
//                    endPoint: .bottom
//                )
//                .frame(height: 150)
//                .ignoresSafeArea(edges: .top)
//
//                VStack(spacing: 25) {
//                    HStack {
//                        Image(systemName: "magnifyingglass")
//                        TextField("Search", text: $searchText)
//                        Image(systemName: "mic.fill")
//                    }
//                    .padding(12)
//                    .background(Color.white)
//                    .cornerRadius(10)
//                    .padding(.horizontal, 16)
//                    .padding(.top, 20)
//
//                    List {
//                        ForEach(filtered) { librarian in
//                            Button(action: {
//                                selectedLibrarian = librarian
//                                showLibrarianDetail = true
//                            }) {
//                                HStack {
//                                    Circle()
//                                        .foregroundColor(.blue.opacity(0.3))
//                                        .frame(width: 40, height: 40)
//                                        .overlay(
//                                            Text(String(librarian.name.prefix(1)))
//                                                .foregroundColor(.blue)
//                                        )
//
//                                    VStack(alignment: .leading, spacing: 2) {
//                                        Text(librarian.name).bold()
//                                        Text(librarian.designation)
//                                            .font(.subheadline)
//                                            .foregroundColor(.secondary)
//                                    }
//
//                                    Spacer()
//
//                                    Text(librarian.status)
//                                        .font(.subheadline)
//                                        .foregroundColor(librarian.status == "Active" ? .green : .red)
//                                }
//                            }
//                            .listRowBackground(Color(UIColor.secondarySystemBackground))
//                        }
//                    }
//                    .listStyle(.plain)
//                }
//                .navigationDestination(isPresented: $showLibrarianDetail) {
//                    if let librarian = selectedLibrarian {
//                        LibrarianDetailView(librarian: librarian)
//                    }
//                }
//                
//                VStack {
//                    Spacer()
//                    HStack {
//                        Spacer()
//                        Button {
//                            showAdd = true
//                        } label: {
//                            Image(systemName: "plus")
//                                .font(.title)
//                                .foregroundColor(.white)
//                                .frame(width: 60, height: 60)
//                                .background(Circle().foregroundColor(.blue))
//                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
//                        }
//                        .padding(.trailing, 25)
//                        .padding(.bottom, 25)
//                    }
//                }
//            }
//            .navigationTitle("Librarians")
//            .sheet(isPresented: $showAdd) {
//                NavigationStack {
//                    AddLibrarianView()
//                }
//            }
//            .onAppear {
//                vm.fetchLibrarians()
//            }
//        }
//    }
//}






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
                                        // Designation line removed
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
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showAdd = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().foregroundColor(.blue))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 25)
                        .padding(.bottom, 25)
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
