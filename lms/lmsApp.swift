//
//  lmsApp.swift
//  lms
//
//  Created by VR on 24/04/25.
//

import SwiftUI
import FirebaseCore

@main
struct lmsApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init(){
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
        }
    }
}
