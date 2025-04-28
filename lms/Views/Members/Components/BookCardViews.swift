//
//  BookCardViews.swift
//  lms
//
//  Created by VR on 27/04/25.
//

import SwiftUI

struct CurrentReadingCardView: View {
    let book: Book

    private var dueDate: String {
        if case let .issued(_, _, dueDate, _) = book.status {
            let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
            return "Due in \(days) days"
        }
        return "Due date unknown"
    }

    private var overdueFine: String {
        if case let .issued(_, _, _, fine) = book.status {
            return String(format: "$%.2f", fine)
        }
        return "$0.00"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(book.coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 80, height: 120)
                .cornerRadius(8)
                .clipped()
                .background(Color(book.coverColor))

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(1)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack {
                    Text(book.releaseDate ?? "")
                    Text("•")
                    Text(book.genre)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Text(dueDate)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.yellow)
                        .cornerRadius(4)

                    Text("Fine: \(overdueFine)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ReservedBookCardView: View {
    let book: Book

    private var timeLeft: String {
        if case let .reserved(_, _, timeLeft) = book.status {
            return timeLeft
        }
        return "Time unknown"
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.title3)
                    .fontWeight(.bold)

                Text(book.author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    Text(book.releaseDate ?? "")
                    Text("•")
                    Text(book.genre)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Text(timeLeft)
                .font(.headline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct PopularBookView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(book.coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .clipped()
                .background(Color(book.coverColor))

            Text(book.title)
                .font(.headline)
                .lineLimit(1)

            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}

struct NewReleaseBookView: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(book.coverImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 120, height: 180)
                .cornerRadius(8)
                .clipped()
                .background(Color(book.coverColor))

            Text(book.title)
                .font(.headline)
                .lineLimit(1)

            Text(book.author)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(width: 120)
    }
}
