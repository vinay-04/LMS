//
//  GenreButton.swift
//  lms
//
//  Created by palak seth on 04/05/25.
//

import SwiftUICore
import SwiftUI
struct GenreButton: View {
    let genre: String
    @Environment(\.colorScheme) var colorScheme
    
    // UI Constants
    private let cardHeight: CGFloat = 100  // Reduced from 110
    private let cornerRadius: CGFloat = 10
    
    var body: some View {
        NavigationLink(destination: GenreDetailView(genre: genre)) {
            ZStack(alignment: .bottomLeading) {
                // Genre Image with subtle gradient
                Image(genre.lowercased() + "_genre")
                    .resizable()
                    .scaledToFill()
                    .frame(height: cardHeight)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.3)]),  // Reduced opacity
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Genre Name
                Text(genre)
                    .font(.system(size: 16, weight: .bold))  // Slightly smaller font
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
            }
            .frame(width: 160, height: cardHeight)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
            .background(colorScheme == .dark ? Color(hex: "2E2E2E") : Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
