//
//  AddBookView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

// MARK: - Add Book View
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LibraryViewModel
    @State private var manualISBN = ""
    @State private var addingBookManually = false
    @State private var newBook = LibraryBook.empty
    @State private var isLoading = false
    @State private var isbnStatus = ""
    @State private var showingEditView = false
    @Binding var showFeedback: Bool
    @Binding var feedbackMessage: String
    @Binding var isSuccess: Bool
    @Binding var scannedCode: String
    @Binding var showingScanner: Bool
    @Binding var showingBookPreview: Bool
    @Binding var previewBook: LibraryBook?
    
    var body: some View {
        ZStack {
            backgroundGradient
            
            VStack(spacing: 0) {
                // Top Navigation Bar
                customNavigationBar
                
                // Main Content
                ScrollView {
                    VStack(spacing: 25) {
                        // Header
                        Text("Add a New Book")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "343A40"))
                            .padding(.top)
                        
                        if addingBookManually {
                            // Manual book entry form with enhanced UI
                            ManualBookEntryForm(book: $newBook, onSave: {
                                // Show preview instead of directly adding
                                previewBook = newBook
                                showingBookPreview = true
                                dismiss()
                            })
                        } else {
                            // Options to add book with enhanced UI
                            addBookOptionsSection
                        }
                    }
                    .padding(.bottom, 25)
                }
                .scrollDismissesKeyboard(.immediately)
            }
        }
        .sheet(isPresented: $showingEditView) {
            if let existingBook = viewModel.existingBook {
                EditBookView(book: existingBook, viewModel: viewModel)
            }
        }
        .alert(isPresented: $viewModel.showDuplicateAlert) {
            Alert(
                title: Text("Book Already Exists"),
                message: Text("A book with ISBN \(viewModel.existingBook?.isbn ?? "") already exists in the library. Would you like to edit it?"),
                primaryButton: .default(Text("Edit")) {
                    showingEditView = true
                },
                secondaryButton: .cancel(Text("Cancel")) {
                    // Reset state
                    manualISBN = ""
                    viewModel.existingBook = nil
                    dismiss()
                }
            )
        }
        .edgesIgnoringSafeArea(.all)
        .navigationBarHidden(true) // Hide the default navigation bar
        .onAppear {
            print("➕ AddBookView appeared")
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "F8F9FA"), Color(hex: "E9ECEF")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Custom Navigation Bar
    private var customNavigationBar: some View {
        ZStack {
            // Background
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            
            HStack {
                // Back/Cancel Button
                Button(action: {
                    print("❌ Add book cancelled")
                    dismiss()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Cancel")
                    }
                    .foregroundColor(Color(.systemIndigo))
                }
                .padding(.leading)
                
                Spacer()
                
                // Title
                Text("Add New Book")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Color(hex: "343A40"))
                
                Spacer()
                
                // Empty space to balance the layout
                Text("")
                    .frame(width: 60)
                    .padding(.trailing)
            }
            .padding(.vertical, 8)
            .padding(.top, safeAreaTop)
        }
        .frame(height: 44 + safeAreaTop)
    }
    
    // Safe area top padding helper
    private var safeAreaTop: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .map({$0 as? UIWindowScene})
            .compactMap({$0})
            .first?.windows
            .filter({$0.isKeyWindow}).first
        
        return keyWindow?.safeAreaInsets.top ?? 0
    }
    
    // MARK: - Add Book Options Section
    private var addBookOptionsSection: some View {
        VStack(spacing: 25) {
            // Scan ISBN Button
            Button(action: {
                print("📷 Scan ISBN button tapped")
                scannedCode = ""
                showingScanner = true
                dismiss()
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)
                    }
                    
                    Text("Scan ISBN Barcode")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "ADB5BD"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
            
            // OR divider
            HStack {
                Rectangle()
                    .fill(Color(hex: "DEE2E6"))
                    .frame(height: 1)
                
                Text("OR")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "6C757D"))
                    .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color(hex: "DEE2E6"))
                    .frame(height: 1)
            }
            .padding(.vertical, 10)
            
            // Manual ISBN Input Section
            FormCard {
                VStack(spacing: 16) {
                    HStack {
                        Text("Enter ISBN Manually")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "495057"))
                        
                        Spacer()
                    }
                    .padding(.top, 4)
                    
                    HStack {
                        TextField("ISBN Number", text: $manualISBN)
                            .padding()
                            .background(Color(hex: "F8F9FA"))
                            .cornerRadius(10)
                            .keyboardType(.numberPad)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "DEE2E6"), lineWidth: 1)
                            )
                            .onChange(of: manualISBN) { newValue in
                                print("📝 ISBN entered: \(newValue)")
                                isbnStatus = ""
                            }
                    }
                    
                    if !isbnStatus.isEmpty {
                        HStack {
                            Image(systemName: isbnStatus.contains("not found") ? "exclamationmark.triangle" : "info.circle")
                                .foregroundColor(isbnStatus.contains("not found") ? .orange : .blue)
                            Text(isbnStatus)
                                .font(.caption)
                                .foregroundColor(isbnStatus.contains("not found") ? .orange : .blue)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        lookUpISBN()
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            } else {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 16))
                                    .padding(.trailing, 5)
                            }
                            
                            Text("Look Up ISBN")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(manualISBN.isEmpty || isLoading ? Color.gray : Color.blue)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(manualISBN.isEmpty || isLoading)
                }
                .padding(16)
            }
            
            // Divider
            Rectangle()
                .fill(Color(hex: "DEE2E6"))
                .frame(height: 1)
                .padding(.vertical, 15)
            
            // Manual Entry Button
            Button(action: {
                print("📝 Add Book Manually button tapped")
                addingBookManually = true
            }) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 20))
                            .foregroundColor(.orange)
                    }
                    
                    Text("Add Book Manually")
                        .font(.system(size: 17, weight: .semibold))
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "ADB5BD"))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - ISBN Lookup Function
    private func lookUpISBN() {
        guard !manualISBN.isEmpty else { return }
        
        print("🔍 Looking up ISBN: \(manualISBN)")
        isLoading = true
        isbnStatus = "Checking ISBN..."
        
        viewModel.fetchBookByISBN(isbn: manualISBN) { success, book in
            isLoading = false
            
            if success, let bookInfo = book {
                print("✅ Found book in Google Books API: \(bookInfo.name)")
                
                // Show book preview instead of directly adding
                previewBook = bookInfo
                showingBookPreview = true
                dismiss()
            } else if let existingBook = viewModel.existingBook, viewModel.showDuplicateAlert {
                // The duplicate alert will be shown automatically via the viewModel
                print("⚠️ Book with ISBN \(manualISBN) already exists: \(existingBook.name)")
                // No need to do anything else here as the alert binding will trigger the alert
                isbnStatus = ""
            } else {
                print("❌ Failed to find book for ISBN: \(manualISBN)")
                isbnStatus = "ISBN not found. Try entering details manually."
                
                // Pre-fill the manual form with the ISBN
                addingBookManually = true
                newBook.isbn = manualISBN
            }
        }
    }
}

// MARK: - Manual Book Entry Form
struct ManualBookEntryForm: View {
    @Binding var book: LibraryBook
    var onSave: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // Book Details Card
                FormCard {
                    VStack(spacing: 0) {
                        FormSectionHeader(title: "Essential Information")
                        
                        EnhancedBookDetailRow(
                            icon: "book.fill",
                            iconColor: Color(hex: "DC3545"),
                            label: "Title",
                            value: $book.name,
                            placeholder: "Book Title",
                            required: true
                        )
                        
                        EnhancedBookDetailRow(
                            icon: "person.fill",
                            iconColor: Color(hex: "FD7E14"),
                            label: "Author",
                            value: $book.author,
                            placeholder: "Author Name",
                            required: true
                        )
                        
                        EnhancedBookDetailRow(
                            icon: "barcode",
                            iconColor: Color(hex: "6610F2"),
                            label: "ISBN",
                            value: $book.isbn,
                            placeholder: "ISBN Number",
                            keyboardType: .numberPad,
                            required: true
                        )
                        
                        EnhancedBookDetailRow(
                            icon: "theatermasks.fill",
                            iconColor: Color(hex: "198754"),
                            label: "Genre",
                            value: $book.genre,
                            placeholder: "Book Genre"
                        )
                        
                        EnhancedIntegerInputRow(
                            icon: "calendar",
                            iconColor: Color(hex: "0D6EFD"),
                            label: "Release Year",
                            value: $book.releaseYear
                        )
                    }
                }
                
                // Book Description Card
                FormCard {
                    VStack(spacing: 0) {
                        FormSectionHeader(title: "Description")
                        
                        EnhancedBookDetailRow(
                            icon: "text.alignleft",
                            iconColor: Color(hex: "6C757D"),
                            label: "Book Summary",
                            value: $book.description,
                            placeholder: "Add a brief description...",
                            isMultiline: true
                        )
                    }
                }
                
                // Library Details Card
                FormCard {
                    VStack(spacing: 0) {
                        FormSectionHeader(title: "Library Information")
                        
                        EnhancedIntegerInputRow(
                            icon: "books.vertical.fill",
                            iconColor: Color(hex: "0DCAF0"),
                            label: "Total Count",
                            value: $book.totalCount
                        )
                        
                        EnhancedIntegerInputRow(
                            icon: "building.2.fill",
                            iconColor: Color(hex: "6F42C1"),
                            label: "Floor",
                            value: $book.location.floor
                        )
                        
                        EnhancedBookDetailRow(
                            icon: "rectangle.stack.fill",
                            iconColor: Color(hex: "20C997"),
                            label: "Shelf",
                            value: $book.location.shelf,
                            placeholder: "e.g., A-12"
                        )
                        
                        ColorPickerRow(
                            icon: "paintpalette.fill",
                            iconColor: Color(hex: "FF5733"),
                            label: "Cover Color",
                            selection: Binding(
                                get: { Color(book.coverColor.lowercased()) },
                                set: {
                                    book.coverColor = $0.description
                                    print("📝 Book cover color changed: \(book.coverColor)")
                                }
                            )
                        )
                    }
                }
                
                // Save Button
                Button(action: {
                    print("💾 Save Book button tapped")
                    // Set initial availability counts
                    book.unreservedCount = book.totalCount
                    book.reservedCount = 0
                    book.issuedCount = 0
                    
                    // Set creation date
                    book.dateCreated = Date()
                    
                    print("📊 Book availability set - Total: \(book.totalCount), Unreserved: \(book.unreservedCount)")
                    print("📆 Book creation date set: \(book.dateCreated)")
                    
                    onSave()
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: 16))
                            .padding(.trailing, 5)
                        
                        Text("Save Book to Library")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGreen))
                            .shadow(color: Color(.systemGreen).opacity(0.4), radius: 5, x: 0, y: 3)
                    )
                    .foregroundColor(.white)
                }
                .padding(.top, 10)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .onAppear {
            print("📝 ManualBookEntryForm appeared")
            print("🆔 New book UUID: \(book.id)")
        }
    }
}

// MARK: - Form Card Container
struct FormCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Form Section Header
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

// MARK: - Enhanced Book Detail Row
struct EnhancedBookDetailRow: View {
    let icon: String
    var iconColor: Color = .gray
    let label: String
    @Binding var value: String
    var placeholder: String = "Value"
    var isMultiline: Bool = false
    var keyboardType: UIKeyboardType = .default
    var required: Bool = false
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main row
            HStack(spacing: 12) {
                // Icon with colorful background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                
                // Label with required indicator if needed
                HStack(spacing: 4) {
                    Text(label)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "495057"))
                    
                    if required {
                        Text("*")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(hex: "DC3545"))
                    }
                }
                
                Spacer()
                
                // Value display or editor
                if isMultiline && isEditing {
                    // Don't show anything here when multiline editing is active
                } else if isEditing {
                    TextField("", text: $value)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(keyboardType)
                        .frame(maxWidth: UIScreen.main.bounds.width / 2.5)
                        .modifier(PlaceholderModifier(showPlaceholder: value.isEmpty, placeholder: placeholder))
                        .onChange(of: value) { newValue in
                            print("📝 \(label) changed: \(newValue)")
                        }
                } else {
                    // Display value or placeholder
                    Text(value.isEmpty ? placeholder : value)
                        .foregroundColor(value.isEmpty ? Color(hex: "ADB5BD") : Color(hex: "212529"))
                        .multilineTextAlignment(.trailing)
                        .lineLimit(isMultiline ? 1 : nil)
                        .truncationMode(.tail)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    isEditing = true
                }
            }
            
            // Multiline editor
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
                        .onChange(of: value) { newValue in
                            print("📝 \(label) changed to \(newValue.count) characters")
                        }
                    
                    // Done button
                    Button(action: {
                        withAnimation {
                            isEditing = false
                        }
                    }) {
                        Text("Done")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemIndigo))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            
            // Divider
            if !isMultiline || !isEditing {
                Divider()
                    .padding(.leading, 60)
            }
        }
        .background(Color.white)
    }
}

// MARK: - Enhanced Integer Input Row
struct EnhancedIntegerInputRow: View {
    let icon: String
    var iconColor: Color = .gray
    let label: String
    @Binding var value: Int
    @State private var text: String = ""
    
    @State private var isEditing = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon with colorful background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "495057"))
                
                Spacer()
                
                if isEditing {
                    // Stepper with text field
                    HStack(spacing: 0) {
                        // Decrease button
                        Button(action: {
                            if value > 0 {
                                value -= 1
                                text = "\(value)"
                                print("📝 \(label) decreased to: \(value)")
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(hex: "6C757D"))
                                .cornerRadius(6)
                        }
                        .disabled(value <= 0)
                        
                        // Text Field
                        TextField("", text: $text)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                            .padding(.horizontal, 8)
                            .onChange(of: text) { newValue in
                                // Convert to integer and ensure it's valid
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    text = filtered
                                }
                                value = Int(filtered) ?? 0
                                print("📝 \(label) changed to: \(value)")
                            }
                        
                        // Increase button
                        Button(action: {
                            value += 1
                            text = "\(value)"
                            print("📝 \(label) increased to: \(value)")
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Color(.systemIndigo))
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
                    // Display value
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
                    // Initialize text field with current value when editing starts
                    if text.isEmpty {
                        text = "\(value)"
                    }
                }
            }
            
            Divider()
                .padding(.leading, 60)
        }
        .background(Color.white)
        .onAppear {
            // Initialize text field with current value
            text = "\(value)"
        }
    }
}

// MARK: - Color Picker Row
struct ColorPickerRow: View {
    let icon: String
    var iconColor: Color = .gray
    let label: String
    @Binding var selection: Color
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon with colorful background
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(iconColor)
                }
                
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "495057"))
                
                Spacer()
                
                // Color Picker
                ColorPicker("", selection: $selection)
                    .labelsHidden()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            
            Divider()
                .padding(.leading, 60)
        }
        .background(Color.white)
    }
}

// MARK: - Custom Placeholder Modifier (instead of extension)
struct PlaceholderModifier: ViewModifier {
    var showPlaceholder: Bool
    var placeholder: String

    func body(content: Content) -> some View {
        ZStack(alignment: .trailing) {
            if showPlaceholder {
                Text(placeholder)
                    .foregroundColor(Color(hex: "ADB5BD"))
                    .multilineTextAlignment(.trailing)
            }
            content
        }
    }
}
