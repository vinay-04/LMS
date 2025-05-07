//
//  TabBarManager.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

class TabBarManager {
    static let shared = TabBarManager()
    
    private init() {}
    
    // Notification names
    static let showTabBarNotification = Notification.Name("ShowTabBar")
    static let hideTabBarNotification = Notification.Name("HideTabBar")
    
    func showTabBar() {
        NotificationCenter.default.post(name: TabBarManager.showTabBarNotification, object: nil)
    }
    
    func hideTabBar() {
        NotificationCenter.default.post(name: TabBarManager.hideTabBarNotification, object: nil)
    }
}

// Extension for View to add convenience methods
extension View {
    func hideTabBar() -> some View {
        return self.onAppear {
            TabBarManager.shared.hideTabBar()
        }
    }
    
    func showTabBar() -> some View {
        return self.onAppear {
            TabBarManager.shared.showTabBar()
        }
    }
}
