

import Foundation
import FirebaseFirestore
import FirebaseStorage

class LibrarianViewModel: ObservableObject {
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    func updateLibrarian(_ librarian: Librarian, with updatedData: [String: Any]) {
        guard let id = librarian.id else { return }
        
        db.collection("librarians").document(id).updateData(updatedData) { error in
            if let error = error {
                print("Error updating librarian: \(error.localizedDescription)")
            } else {
                print("Librarian successfully updated")
            }
        }
    }
    
    func deleteLibrarian(_ librarian: Librarian) {
        guard let id = librarian.id else { return }
        
        // Delete the librarian document
        db.collection("librarians").document(id).delete { error in
            if let error = error {
                print("Error deleting librarian: \(error.localizedDescription)")
            } else {
                print("Librarian successfully deleted")
                
                // Delete the profile image if it exists
                let imageRef = self.storage.reference().child("librarian_images/\(id).jpg")
                imageRef.delete { error in
                    if let error = error {
                        print("Error deleting librarian image: \(error.localizedDescription)")
                    } else {
                        print("Librarian image successfully deleted")
                    }
                }
            }
        }
    }
}
