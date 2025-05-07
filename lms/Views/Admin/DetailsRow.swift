//
//  DetailsRow.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI

struct DetailsRow: View {
    let icon: String
    let title: String
    @Binding var value: String
    var isEditing: Bool
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 30)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isEditing {
                TextField("", text: $value)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(keyboardType)
            } else {
                Text(value)
                    .foregroundColor(.primary)
            }
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 16)
    }
}
