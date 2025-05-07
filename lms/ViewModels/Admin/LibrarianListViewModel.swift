//
//  LibrarianListViewModel.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import Foundation
import FirebaseFirestore

class LibrarianListViewModel: ObservableObject {
    // MARK: - Published properties for the UI
    @Published var librarians: [Librarian] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // MARK: - Private
    private var listener: ListenerRegistration?
    private let db = FirebaseService.shared.db

    // MARK: - Lifecycle
    func fetch() {
        fetchLibrarians()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Public API
    func fetchLibrarians() {
        isLoading = true
        errorMessage = nil

        listener = db.collection("librarians")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }

                guard let documents = snapshot?.documents else {
                    self.librarians = []
                    return
                }

                self.librarians = documents.compactMap { doc in
                    do {
                        return try doc.data(as: Librarian.self)
                    } catch {
                        print("⚠️ Decoding Librarian failed:", error)
                        return nil
                    }
                }
            }
    }
}
