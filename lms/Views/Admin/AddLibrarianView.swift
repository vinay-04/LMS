//
//  AddLibrarianView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import PhotosUI

struct AddLibrarianView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = AddLibrarianViewModel()

    var body: some View {
        VStack(spacing: 0) {
            Button {
                vm.showPhotoPicker = true
            } label: {
                if let img = vm.image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "camera")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 120, height: 120)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(color: Color.gray.opacity(0.5), radius: 5)
            .padding(.top, 30)

            Spacer().frame(height: 60)

            Text("ADD LIBRARIAN DETAILS")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .foregroundColor(.gray)

            VStack(spacing: 0) {
                RowField(icon: "person", title: "Name", text: $vm.name)
                Divider()
                RowField(icon: "briefcase", title: "Designation", text: $vm.designation)
                Divider()
                RowField(icon: "dollarsign.circle", title: "Salary", text: $vm.salary)
                Divider()
                RowField(icon: "phone", title: "Contact", text: $vm.phone)
                Divider()
                RowField(icon: "at", title: "Email", text: $vm.email)
                Divider()
                RowField(icon: "key", title: "Password", text: $vm.password, isSecure: true)
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()
        }
        .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("Add Librarian")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    vm.save { dismiss() }
                }
                .disabled(!vm.canSave)
            }
            // Back button is now handled by the parent view
        }
        .photosPicker(isPresented: $vm.showPhotoPicker, selection: $vm.photoItem)
        .onChange(of: vm.photoItem) { newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    vm.image = ui
                }
            }
        }
    }
}

fileprivate struct RowField: View {
    let icon: String, title: String
    @Binding var text: String
    var isSecure = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(title)
            Spacer()
            if isSecure {
                SecureField("Value", text: $text)
                    .multilineTextAlignment(.trailing)
            } else {
                TextField("Value", text: $text)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        AddLibrarianView()
    }
}
