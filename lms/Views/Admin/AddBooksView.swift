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

// MARK: – Main AddBooksView

struct AddBooksView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var book = Book()
    @State private var pagesText: String = ""
    @State private var totalCopiesText: String = ""
    
    @State private var showingImageOptions = false
    @State private var activeSheet: ActiveSheet?
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Firestore & Storage refs
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
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 25) {
                    bookCoverSection
                    detailsSection
                    metadataSection
                    locationSection
                    saveButton
                }
                .padding(.bottom, 25)
            }
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Add New Book")
            .navigationBarTitleDisplayMode(.inline)
        }
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
            Alert(
                title: Text("Book Status"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: – Book Cover Section
    private var bookCoverSection: some View {
        VStack(spacing: 15) {
            ZStack {
                if let image = book.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white, lineWidth: 2)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(hex: "E9ECEF"), Color(hex: "CED4DA")]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 150, height: 200)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .overlay(
                            VStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 30))
                                    .foregroundColor(Color(hex: "6C757D"))
                                Text("Add Cover")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "6C757D"))
                            }
                        )
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { showingImageOptions = true }) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: book.coverImage == nil ? "plus" : "pencil")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
                        }
                        .offset(x: 10, y: 10)
                    }
                }
                .frame(width: 150, height: 200)
            }
            .padding(.top, 20)
            .actionSheet(isPresented: $showingImageOptions) {
                ActionSheet(
                    title: Text("Add Book Cover"),
                    message: Text("Select a source"),
                    buttons: [
                        .default(Text("Camera")) { activeSheet = .camera },
                        .default(Text("Photo Library")) { activeSheet = .photoLibrary },
                        .cancel()
                    ]
                )
            }
        }
    }
    
    // MARK: – Form Sections
    
    private var detailsSection: some View {
        FormCard {
            VStack(spacing: 0) {
                FormSectionHeader(title: "Essential Information")
                EnhancedBookDetailRow(
                    icon: "barcode", iconColor: Color(hex: "6610F2"),
                    label: "ISBN Number",
                    value: $book.isbn,
                    keyboardType: .numberPad,
                    required: true
                )
                EnhancedBookDetailRow(
                    icon: "book.fill", iconColor: Color(hex: "DC3545"),
                    label: "Book Title",
                    value: $book.title,
                    required: true
                )
                EnhancedBookDetailRow(
                    icon: "person.fill", iconColor: Color(hex: "FD7E14"),
                    label: "Author Name",
                    value: $book.author,
                    required: true
                )
                EnhancedBookDetailRow(
                    icon: "theatermasks.fill", iconColor: Color(hex: "198754"),
                    label: "Genre",
                    value: $book.genre
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var metadataSection: some View {
        FormCard {
            VStack(spacing: 0) {
                FormSectionHeader(title: "Publication Information")
                DateSelectionRow(
                    icon: "calendar", iconColor: Color(hex: "0D6EFD"),
                    label: "Release Date",
                    dateFormatter: dateFormatter,
                    date: $book.releaseDate,
                    action: { activeSheet = .datePicker }
                )
                EnhancedBookDetailRow(
                    icon: "globe", iconColor: Color(hex: "6F42C1"),
                    label: "Language",
                    value: $book.language
                )
                EnhancedIntegerInputRow(
                    icon: "doc.text.fill", iconColor: Color(hex: "20C997"),
                    label: "Pages",
                    text: $pagesText,
                    value: $book.pages
                )
                EnhancedIntegerInputRow(
                    icon: "books.vertical.fill", iconColor: Color(hex: "0DCAF0"),
                    label: "Total Copies",
                    text: $totalCopiesText,
                    value: $book.totalCopies
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var locationSection: some View {
        FormCard {
            VStack(spacing: 0) {
                FormSectionHeader(title: "Location & Description")
                EnhancedBookDetailRow(
                    icon: "mappin.and.ellipse", iconColor: Color(hex: "DC3545"),
                    label: "Book Location",
                    value: $book.location,
                    placeholder: "e.g., Shelf A-12"
                )
                EnhancedBookDetailRow(
                    icon: "text.alignleft", iconColor: Color(hex: "6C757D"),
                    label: "Book Summary",
                    value: $book.summary,
                    placeholder: "Add a brief description...",
                    isMultiline: true
                )
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var saveButton: some View {
        Button(action: saveBookToFirebase) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 5)
                } else {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 16))
                        .padding(.trailing, 5)
                }
                Text("Save Book to Library")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemIndigo))
                    .shadow(color: Color(.systemIndigo).opacity(0.4), radius: 5, x: 0, y: 3)
            )
            .foregroundColor(.white)
        }
        .disabled(isLoading)
        .padding(.horizontal, 16)
        .padding(.top, 15)
    }
    
    // MARK: – Firebase Logic
    
    private func saveBookToFirebase() {
        // validate required
        guard !book.title.isEmpty, !book.author.isEmpty, !book.isbn.isEmpty else {
            alertMessage = "Please fill in at least the title, author, and ISBN fields."
            showAlert = true
            return
        }
        isLoading = true
        let bookRef = db.collection("books").document(book.isbn)
        bookRef.getDocument { snapshot, error in
            if let err = error {
                finishWithError("Unable to check ISBN: \(err.localizedDescription)"); return
            }
            if snapshot?.exists == true {
                finishWithError("A book with this ISBN already exists."); return
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
                if let err = err { finishWithError("Image upload failed: \(err.localizedDescription)"); return }
                imgRef.downloadURL { url, err in
                    if let err = err { finishWithError("URL fetch failed: \(err.localizedDescription)"); }
                    else { saveBookData(to: ref, imageURL: url?.absoluteString) }
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
                finishWithError("Error saving book: \(err.localizedDescription)")
            } else {
                alertMessage = "Book successfully added!"
                showAlert = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isLoading = false
                    book = Book()
                    pagesText = ""
                    totalCopiesText = ""
                    dismiss()
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
}

// MARK: – Supporting UI Components

struct FormCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

struct FormSectionHeader: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "6C757D"))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Spacer()
        }
        .background(Color(hex: "F8F9FA"))
    }
}

struct EnhancedBookDetailRow: View {
    let icon: String; var iconColor: Color = .gray
    let label: String; @Binding var value: String
    var placeholder: String = "Value"
    var isMultiline: Bool = false
    var keyboardType: UIKeyboardType = .default
    var required: Bool = false
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.1)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(iconColor)
                }
                HStack(spacing: 4) {
                    Text(label).font(.system(size: 16)).foregroundColor(Color(hex: "495057"))
                    if required {
                        Text("*").font(.system(size: 16, weight: .bold)).foregroundColor(Color(hex: "DC3545"))
                    }
                }
                Spacer()
                if isMultiline && isEditing {
                    EmptyView()
                } else if isEditing {
                    TextField("", text: $value)
                        .keyboardType(keyboardType)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: UIScreen.main.bounds.width / 2.5)
                        .placeholder(when: value.isEmpty) {
                            Text(placeholder).foregroundColor(Color(hex: "ADB5BD"))
                        }
                } else {
                    Text(value.isEmpty ? placeholder : value)
                        .foregroundColor(value.isEmpty ? Color(hex: "ADB5BD") : Color(hex: "212529"))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(isMultiline ? nil : 1)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            .onTapGesture { withAnimation { isEditing = true } }
            
            if isMultiline && isEditing {
                VStack(spacing: 0) {
                    TextEditor(text: $value)
                        .frame(minHeight: 120)
                        .padding(12)
                        .background(Color(hex: "F8F9FA"))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "DEE2E6"), lineWidth: 1)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                        )
                    Button("Done") {
                        withAnimation { isEditing = false }
                    }
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            
            if !isMultiline || !isEditing {
                Divider().padding(.leading, 60)
            }
        }
    }
}

struct EnhancedIntegerInputRow: View {
    let icon: String; var iconColor: Color = .gray
    let label: String; @Binding var text: String; @Binding var value: Int
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.1)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(iconColor)
                }
                Text(label).font(.system(size: 16)).foregroundColor(Color(hex: "495057"))
                Spacer()
                if isEditing {
                    HStack(spacing: 0) {
                        Button {
                            if value > 0 { value -= 1; text = "\(value)" }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "6C757D"))
                                .cornerRadius(6)
                        }
                        .disabled(value <= 0)
                        TextField("", text: $text)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .padding(.horizontal, 8)
                            .onChange(of: text) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue { text = filtered }
                                value = Int(filtered) ?? 0
                            }
                        Button {
                            value += 1; text = "\(value)"
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color.accentColor)
                                .cornerRadius(6)
                        }
                    }
                    .padding(4)
                    .background(Color(hex: "F8F9FA"))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "DEE2E6"), lineWidth: 1)
                    )
                } else {
                    Text("\(value)")
                        .foregroundColor(Color(hex: "212529"))
                        .font(.system(size: 16, weight: .medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color(hex: "F8F9FA"))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isEditing = true
                    if value > 0 && text.isEmpty { text = "\(value)" }
                }
            }
            Divider().padding(.leading, 60)
        }
    }
}

struct DateSelectionRow: View {
    let icon: String; var iconColor: Color = .gray
    let label: String; let dateFormatter: DateFormatter
    @Binding var date: Date; var action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(iconColor.opacity(0.1)).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(iconColor)
                }
                Text(label).font(.system(size: 16)).foregroundColor(Color(hex: "495057"))
                Spacer()
                Button(action: action) {
                    HStack(spacing: 6) {
                        Text(dateFormatter.string(from: date))
                            .foregroundColor(Color(hex: "212529"))
                            .font(.system(size: 16))
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemIndigo))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "F8F9FA")))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .contentShape(Rectangle())
            Divider().padding(.leading, 60)
        }
    }
}

struct DatePickerView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDate: Date

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select a date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                Spacer()
            }
            .navigationBarTitle("Book Release Date", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                }
            }
            .accentColor(Color(.systemIndigo))
        }
    }
}

// MARK: – View Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: – Preview

struct AddBooksView_Previews: PreviewProvider {
    static var previews: some View {
        AddBooksView()
    }
}
