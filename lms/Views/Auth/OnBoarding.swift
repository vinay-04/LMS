//
//  OnBoarding.swift
//  lms
//
//  Created by VR on 24/04/25.
//

import SwiftUI

struct onboardingView: View {
    @State private var showCarousel = false

    var body: some View {
        NavigationStack {
            if showCarousel {
                OnboardingCarousel()
            } else {
                ZStack {

                    Image("onboarding_books")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()

                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.2), Color.white.opacity(0.95), Color.white,
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    VStack(spacing: -10) {
                        Spacer()

                        VStack(spacing: 16) {
                            Image(systemName: "books.vertical")
                                .resizable()
                                .frame(width: 50, height: 50)
                                .foregroundColor(.black)

                            Text("Welcome to InfyReads")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                        }

                        Spacer().frame(height: 120)

                        VStack(alignment: .leading, spacing: 37) {
                            FeatureItem(
                                icon: "book.closed",
                                text: "Your gateway to a world of books & information."
                            )
                            FeatureItem(
                                icon: "arrow.left.arrow.right",
                                text: "Explore, Borrow and Return books from libraries.")
                            FeatureItem(
                                icon: "rectangle.stack.badge.person.crop",
                                text: "Seamlessly manage your library experience.")
                        }
                        .padding(.horizontal, 130)

                        Spacer()

                        Button(action: {
                            showCarousel = true
                        }) {
                            HStack {
                                Text("Get Started")
                                    .fontWeight(.semibold)
                                Image(systemName: "arrow.right")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                            .padding(.horizontal, 135)
                        }
                    }
                }
            }
        }
    }
}

// Modify the OnboardingCarousel struct to include a dismiss binding
struct OnboardingCarousel: View {
    @State private var currentPage = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                CarouselPage(
                    image: "book",
                    title: "Discover Books",
                    description: "Browse through thousands of books across various genres."
                )
                .tag(0)

                CarouselPage(
                    image: "bookmark",
                    title: "Track Your Reading",
                    description: "Keep track of your borrowed books and reading progress."
                )
                .tag(1)

                CarouselPage(
                    image: "person.2",
                    title: "Join the Community",
                    description: "Connect with other readers and share recommendations."
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))

            if currentPage == 2 {
                VStack(spacing: 16) {
                    NavigationLink(destination: SignInView()) {
                        Text("Login")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .simultaneousGesture(
                        TapGesture().onEnded {
                            dismiss()
                        })

//                    NavigationLink(destination: RegisterView()) {
//                        Text("Register")
//                            .fontWeight(.semibold)
//                            .foregroundColor(.black)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(Color.white)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .stroke(Color.black, lineWidth: 1)
//                            )
//                    }
//                    .simultaneousGesture(
//                        TapGesture().onEnded {
//                            dismiss()
//                        })
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
        .padding(.bottom, 40)
    }
}

struct CarouselPage: View {
    let image: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: image)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.black)

            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.black)

            Text(description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 100)
    }
}

struct FeatureItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.black)

            Text(text)
                .foregroundColor(.black)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    onboardingView()
}
