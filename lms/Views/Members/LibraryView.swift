//
//  LibraryView.swift
//  lms
//
//  Created by VR on 28/04/25.
//

import SwiftUI

struct LibraryView: View {
    @State private var selectedSegment = 0
    let segments = ["Current", "History", "Reserved"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Segmented Control
                HStack(spacing: 0) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Button {
                            selectedSegment = index
                        } label: {
                            Text(segments[index])
                                .font(.subheadline)
                                .fontWeight(selectedSegment == index ? .semibold : .regular)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .foregroundColor(selectedSegment == index ? .primary : .secondary)
                        }
                        .background(
                            selectedSegment == index
                                ? Color(.systemBackground) : Color(.systemGray6))
                    }
                }
                .background(Color(.systemGray6))

                // Indicator
                HStack {
                    Rectangle()
                        .fill(Color.blue)
                        .frame(height: 3)
                        .frame(width: UIScreen.main.bounds.width / CGFloat(segments.count))
                        .offset(
                            x: UIScreen.main.bounds.width / CGFloat(segments.count)
                                * CGFloat(selectedSegment) - UIScreen.main.bounds.width / 2
                                + UIScreen.main.bounds.width / CGFloat(segments.count) / 2
                        )
                        .animation(.spring(), value: selectedSegment)

                    Spacer()
                }

                // Content based on selected segment
                TabView(selection: $selectedSegment) {
                    CurrentBooksView()
                        .tag(0)

                    HistoryBooksView()
                        .tag(1)

                    ReservedBooksView()
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.default, value: selectedSegment)
            }
            .navigationTitle("My Library")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Filter action
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.title3)
                    }
                }
            }
        }
    }
}

struct CurrentBooksView: View {
    var body: some View {
        if true {  // Replace with actual condition
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(1...3, id: \.self) { i in
                        LibraryBookRow(
                            title: "Current Book \(i)",
                            author: "Author Name",
                            dueDate: Date().addingTimeInterval(Double(i) * 60 * 60 * 24 * 3),
                            coverImage: "book-\(i)"
                        )
                    }
                }
                .padding()
            }
        } else {
            VStack(spacing: 24) {
                Image(systemName: "books.vertical.circle")
                    .font(.system(size: 72))
                    .foregroundColor(.gray.opacity(0.7))

                Text("No books currently borrowed")
                    .font(.title3)
                    .fontWeight(.medium)

                Button {
                    // Navigate to explore
                } label: {
                    Text("Explore Books")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct HistoryBooksView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(1...5, id: \.self) { i in
                    HistoryBookRow(
                        title: "History Book \(i)",
                        author: "Author Name",
                        returnedDate: Date().addingTimeInterval(-Double(i) * 60 * 60 * 24 * 10),
                        coverImage: "book-\(i % 3 + 1)"
                    )
                }
            }
            .padding()
        }
    }
}

struct ReservedBooksView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(1...2, id: \.self) { i in
                    ReservedBookRow(
                        title: "Reserved Book \(i)",
                        author: "Author Name",
                        availableDate: Date().addingTimeInterval(Double(i) * 60 * 60 * 24 * 5),
                        position: i,
                        coverImage: "book-\(i + 1)"
                    )
                }
            }
            .padding()
        }
    }
}

struct LibraryBookRow: View {
    let title: String
    let author: String
    let dueDate: Date
    let coverImage: String

    var body: some View {
        HStack(spacing: 16) {
            Image(coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(dueDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Button {
                    // Renew action
                } label: {
                    Text("Renew")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct HistoryBookRow: View {
    let title: String
    let author: String
    let returnedDate: Date
    let coverImage: String

    var body: some View {
        HStack(spacing: 16) {
            Image(coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Returned")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(returnedDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ReservedBookRow: View {
    let title: String
    let author: String
    let availableDate: Date
    let position: Int
    let coverImage: String

    var body: some View {
        HStack(spacing: 16) {
            Image(coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)

                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Expected Available")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(availableDate, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Text("You are #\(position) in queue")
                    .font(.caption)
                    .foregroundColor(.orange)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        LibraryView()
    }
}
