//
//  lmsApp.swift
//  lms
//
//  Created by VR on 24/04/25.
//

import SwiftUI

@main
struct lmsApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
