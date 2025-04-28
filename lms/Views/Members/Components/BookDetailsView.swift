import SwiftUI

struct BookDetailsView: View {
    @Environment(\.dismiss) var dismiss

    // Replace individual properties with Book model
    var book: Book

    // Computed property to check if book is reserved
    private var isReserved: Bool {
        if case .reserved = book.status {
            return true
        }
        return false
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Blurred background image
            AsyncImage(url: URL(string: book.coverImage)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 400)  // Increased height to cover more area
                        .blur(radius: 15)
                        .overlay(Color.black.opacity(0.4))  // Slightly darker overlay for better contrast
                        .clipped()
                default:
                    Color.gray.opacity(0.4)
                        .frame(height: 300)  // Matched height here too
                }
            }
            .ignoresSafeArea(edges: .top)

            // Main content
            VStack(alignment: .leading, spacing: 0) {
                // Header with title
                ZStack {
                    Text("Book Details")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)

                    // Add back button if needed
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 60)  // Increased from 40 to 50
                .padding(.bottom, 8)  // Reduced to tighten up the layout

                // Book cover and main info
                HStack(alignment: .top, spacing: 16) {
                    // Book cover with discount badge
                    ZStack(alignment: .topLeading) {
                        // Replace the Image with AsyncImage
                        AsyncImage(url: URL(string: book.coverImage)) { phase in
                            switch phase {
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120)
                            case .failure:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 120)
                                    .overlay(
                                        Image(systemName: "book.closed")
                                            .foregroundColor(.gray)
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .cornerRadius(8)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)

                        // Discount badge (optional)
//                        ZStack {
//                            Circle()
//                                .fill(Color.yellow)
//                                .frame(width: 40, height: 40)
//
//                            Text("50%\nOFF")
//                                .font(.system(size: 10, weight: .bold))
//                                .multilineTextAlignment(.center)
//                                .foregroundColor(.black)
//                        }
//                        .offset(x: -10, y: -10)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(book.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text(book.author)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        HStack {
                            Image(systemName: "circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 8))

                            Text("Reserved")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(4)
                        .opacity(isReserved ? 1 : 0)

                        Spacer()
                    }

                    Spacer()

                    // Bookmark button
                    Button(action: {}) {
                        Image(systemName: "bookmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.trailing)
                }
                .padding()

                // Main content with white background
                VStack(spacing: 0) {
                    // Book metadata
//                    HStack(spacing: 0) {
//                        VStack(spacing: 4) {
//                            Image(systemName: "calendar")
//                                .foregroundColor(.gray)
//
//                            Text(book.releaseDate ?? "N/A")
//                                .font(.headline)
//
//                            Text("Year")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        .frame(maxWidth: .infinity)
//
//                        VStack(spacing: 4) {
//                            Image(systemName: "doc.text")
//                                .foregroundColor(.gray)
//
//                            Text(book.length)
//                                .font(.headline)
//
//                            Text("Pages")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        .frame(maxWidth: .infinity)
//
//                        VStack(spacing: 4) {
//                            Image(systemName: "globe")
//                                .foregroundColor(.gray)
//
//                            Text(book.language)
//                                .font(.headline)
//                                .lineLimit(1)
//
//                            Text("Language")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                        }
//                        .frame(maxWidth: .infinity)
//                    }
//                    .padding(.vertical, 16)
//                    .background(Color(.systemGray6))

                    // Reserve button
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Reserve Book")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                    }

                    // Book details sections
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            // Summary section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Summary")
                                    .font(.headline)

                                Text(book.summary)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Details section
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Details")
                                    .font(.headline)

                                DetailRow(label: "Genre", value: book.genre)
                                DetailRow(label: "Publisher", value: book.publisher)
                                DetailRow(label: "ISBN", value: book.isbn)
                            }
                        }
                        .padding()
                    }
                }
                .background(Color.white)
                .cornerRadius(16)
                .offset(y: -16)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .navigationBarBackButtonHidden(true)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .font(.subheadline)

            Spacer()
        }
    }
}

struct BookDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample book for preview
        let sampleData: [String: Any] = [
            "isbn": "9781234567890",
            "title": "Sample Book",
            "author": "John Doe",
            "genre": "Fiction",
            "releaseDate": "2023",
            "language": "English",
            "length": "320",
            "summary": "This is a sample book summary for preview purposes.",
            "publisher": "Sample Publisher",
            "availability": "Available",
            "bookLocation": "A-12",
            "coverColor": "blue",
            "coverImage": "https://example.com/cover.jpg",
            "status": ["type": "available"],
            "popularityScore": 85,
        ]

        let sampleBook = Book(id: "sample123", data: sampleData)

        return BookDetailsView(book: sampleBook)
            .previewLayout(.sizeThatFits)
            .background(Color.black.opacity(0.1))
            .edgesIgnoringSafeArea(.all)
    }
}
