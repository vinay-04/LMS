
//
//  SectionHeader.swift
//  LMS_USER
//
//  Created by user@79 on 25/04/25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .padding(.vertical, 4)
                .foregroundColor(AppTheme.primaryTextColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppTheme.secondaryTextColor)
        }
    }
}
