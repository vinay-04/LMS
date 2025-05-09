//
//  BookCoverView.swift
//  LMS_USER
//
//  Created by user@79 on 25/04/25.
//

import SwiftUI

struct BookCoverView: View {
    let imageURL: String?
    let title: String
    let width: CGFloat
    let height: CGFloat
    
    private var validURL: URL? {
        guard let urlString = imageURL, !urlString.isEmpty else { return nil }
        return URL(string: urlString)
    }
    
    var body: some View {
        Group {
            if let url = validURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: width, height: height)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                    case .failure(let error):
                        placeholderView
                            .onAppear {
                                print("Failed to load image: \(error)")
                            }
                    @unknown default:
                        placeholderView
                    }
                }
                .cornerRadius(6)
            } else {
                placeholderView
            }
        }
    }
    
    var placeholderView: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: width, height: height)
            
            Text(String(title.prefix(2)).uppercased())
                .font(.system(size: width * 0.3, weight: .bold))
                .foregroundColor(.white)
        }
        .cornerRadius(6)
    }
}

