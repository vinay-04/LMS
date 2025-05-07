//
//  AppState.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

enum AppScreen : Equatable {
    case onboarding
    case memberLogin
    case adminLogin
    case register
    case verifyOTP(verificationID: String)
    case memberHome
    case librarianHome
    case adminHome
    case AddLibrarianView
    case AdminHomeView
}

final class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .onboarding
}
