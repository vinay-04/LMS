//
//  AddBooksView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore
import FirebaseStorage

struct AddBooksView: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var book = Book()
    @State private var pagesText: String = ""
    @State private var totalCopiesText: String = ""
    
    @State private var showingImageOptions = false
    @State private var activeSheet: ActiveSheet?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Firestore & Storage references
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    enum ActiveSheet: Identifiable {
        case camera, photoLibrary, datePicker
        var id: Int {
            switch self {
            case .camera:        return 0
            case .photoLibrary:  return 1
            case .datePicker:    return 2
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // MARK: — Cover Picker —
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 150, height: 200)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        
                        if let img = book.coverImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 150, height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Image(systemName: "camera")
                                .font(.system(size: 30))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 20)
                    .onTapGesture { showingImageOptions = true }
                    .actionSheet(isPresented: $showingImageOptions) {
                        ActionSheet(
                            title: Text("Add Book Cover"),
                            message: Text("Select a source"),
                            buttons: [
                                .default(Text("Camera"))       { activeSheet = .camera },
                                .default(Text("Photo Library")){ activeSheet = .photoLibrary },
                                .cancel()
                            ]
                        )
                    }
                    
                    // MARK: — Details Section —
                    VStack(spacing: 8) {
                        // Section header
                        Text("ENTER BOOK DETAILS")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // White “table” container
                        VStack(spacing: 0) {
                            BookDetailRow(icon: "barcode",       label: "ISBN Number",    value: $book.isbn)
                            Divider()
                            BookDetailRow(icon: "book",          label: "Book Title",     value: $book.title)
                            Divider()
                            BookDetailRow(icon: "person",        label: "Author Name",    value: $book.author)
                            Divider()
                            BookDetailRow(icon: "theatermasks",  label: "Genre",          value: $book.genre)
                            Divider()
                            
                            // Release Date
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .frame(width: 24)
                                        .foregroundColor(.gray)
                                    Text("Release Date")
                                        .font(.body)
                                    Spacer()
                                    Button {
                                        activeSheet = .datePicker
                                    } label: {
                                        Text(dateFormatter.string(from: book.releaseDate))
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 16)
                                .background(Color.white)
                                .contentShape(Rectangle())
                                
                                Divider()
                                    .padding(.leading, 52)
                            }
                            
                            Divider()
                            BookDetailRow(icon: "globe",         label: "Language",       value: $book.language)
                            Divider()
                            IntegerInputRow(icon: "doc.text",    label: "Pages",          text: $pagesText,       value: $book.pages)
                            Divider()
                            IntegerInputRow(icon: "books.vertical", label: "Total Copies", text: $totalCopiesText, value: $book.totalCopies)
                            Divider()
                            BookDetailRow(icon: "location",      label: "Book Location",  value: $book.location)
                            Divider()
                            BookDetailRow(icon: "doc.plaintext", label: "Book Summary",   value: $book.summary,   isMultiline: true)
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 16)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitle("Add a New Book", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Back") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(action: saveBookToFirebase) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save").fontWeight(.semibold)
                    }
                }
                .disabled(isLoading)
            )
            .sheet(item: $activeSheet) { item in
                switch item {
                case .camera:
                    ImagePicker(selectedImage: $book.coverImage, sourceType: .camera)
                case .photoLibrary:
                    ImagePicker(selectedImage: $book.coverImage, sourceType: .photoLibrary)
                case .datePicker:
                    DatePickerView(selectedDate: $book.releaseDate)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Book Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: — Firestore Upload Logic —
    private func saveBookToFirebase() {
        guard !book.title.isEmpty, !book.author.isEmpty, !book.isbn.isEmpty else {
            alertMessage = "Please fill in title, author, and ISBN."
            showAlert = true
            return
        }
        isLoading = true
        
        let bookRef = db.collection("books").document(book.isbn)
        bookRef.getDocument { snapshot, error in
            if let error = error {
                finishWithError("ISBN check failed: \(error.localizedDescription)")
                return
            }
            if snapshot?.exists == true {
                finishWithError("A book with this ISBN already exists.")
                return
            }
            uploadCover(to: bookRef)
        }
    }
    
    private func uploadCover(to ref: DocumentReference) {
        if let img = book.coverImage,
           let data = img.jpegData(compressionQuality: 0.7) {
            
            let imgRef = storage.reference().child("bookCovers/\(book.isbn).jpg")
            let meta = StorageMetadata(); meta.contentType = "image/jpeg"
            imgRef.putData(data, metadata: meta) { _, err in
                if let err = err {
                    finishWithError("Image upload failed: \(err.localizedDescription)")
                    return
                }
                imgRef.downloadURL { url, err in
                    if let err = err {
                        finishWithError("URL fetch failed: \(err.localizedDescription)")
                    } else {
                        saveBookData(to: ref, imageURL: url?.absoluteString)
                    }
                }
            }
        } else {
            saveBookData(to: ref, imageURL: nil)
        }
    }
    
    private func saveBookData(to ref: DocumentReference, imageURL: String?) {
        var data: [String: Any] = [
            "isbn": book.isbn,
            "title": book.title,
            "author": book.author,
            "genre": book.genre,
            "releaseDate": Timestamp(date: book.releaseDate),
            "language": book.language,
            "pages": book.pages,
            "totalCopies": book.totalCopies,
            "availableCopies": book.totalCopies,
            "location": book.location,
            "summary": book.summary,
            "createdAt": FieldValue.serverTimestamp()
        ]
        if let url = imageURL { data["coverImageURL"] = url }
        
        ref.setData(data) { err in
            if let err = err {
                finishWithError("Save failed: \(err.localizedDescription)")
            } else {
                alertMessage = "Book added successfully!"
                showAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isLoading = false
                    resetForm()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func finishWithError(_ msg: String) {
        DispatchQueue.main.async {
            isLoading = false
            alertMessage = msg
            showAlert = true
        }
    }
    
    private func resetForm() {
        book = Book()
        pagesText = ""
        totalCopiesText = ""
    }
}

// MARK: — Supporting Views & Extensions —

struct BookDetailRow: View {
    let icon: String, label: String
    @Binding var value: String
    var isMultiline = false
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.gray)
                Text(label).font(.body)
                Spacer()
                if isEditing {
                    TextField("", text: $value)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: UIScreen.main.bounds.width / 2.5)
                        .placeholder(when: value.isEmpty) {
                            Text("Value").foregroundColor(.gray)
                        }
                } else {
                    Text(value.isEmpty ? "Value" : value)
                        .foregroundColor(value.isEmpty ? .gray : .primary)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(isMultiline ? nil : 1)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { isEditing = true } }
        }
    }
}

struct IntegerInputRow: View {
    let icon: String, label: String
    @Binding var text: String
    @Binding var value: Int
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 24)
                    .foregroundColor(.gray)
                Text(label).font(.body)
                Spacer()
                if isEditing {
                    TextField("", text: $text)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: UIScreen.main.bounds.width / 2.5)
                        .placeholder(when: text.isEmpty) {
                            Text("0").foregroundColor(.gray)
                        }
                        .onChange(of: text) { new in value = Int(new) ?? 0 }
                } else {
                    Text("\(value)")
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isEditing = true
                    if value > 0 && text.isEmpty {
                        text = "\(value)"
                    }
                }
            }
        }
    }
}

struct DatePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDate: Date
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Select a date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(GraphicalDatePickerStyle())
                .padding()
                Spacer()
            }
            .navigationBarTitle("Book Release Date", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") { presentationMode.wrappedValue.dismiss() },
                trailing: Button("Done")   { presentationMode.wrappedValue.dismiss() }
            )
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .trailing,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct AddBookView_Previews: PreviewProvider {
    static var previews: some View {
        AddBooksView()
    }
}
