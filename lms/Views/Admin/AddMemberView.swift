//
//  AddMemberView.swift
//  lms
//
//  Created by admin19 on 06/05/25.
//

import SwiftUI
import PhotosUI

struct AddMemberView: View {
    @StateObject private var vm = AddMemberViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Photo") {
                    HStack {
                        Spacer()
                        ZStack {
                            if let image = vm.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                            }
                            
                            Circle()
                                .stroke(Color.blue, lineWidth: 2)
                                .frame(width: 120, height: 120)
                        }
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                vm.showPhotoPicker = true
                            } label: {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(Circle().fill(Color.blue))
                            }
                            .offset(x: -5, y: -5)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .padding(.vertical, 10)
                }
                
                Section("Member Information") {
                    TextField("Name", text: $vm.name)
                    TextField("Role", text: $vm.role)
                        .autocapitalization(.words)
                    TextField("Phone", text: $vm.phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Login Credentials") {
                    TextField("Email", text: $vm.email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                    SecureField("Password", text: $vm.password)
                }
            }
            .navigationTitle("Add New Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        vm.save {
                            dismiss()
                        }
                    }
                    .disabled(!vm.canSave)
                }
            }
            .photosPicker(
                isPresented: $vm.showPhotoPicker,
                selection: $vm.photoItem,
                matching: .images
            )
            .onChange(of: vm.photoItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run {
                            vm.image = image
                        }
                    }
                }
            }
        }
    }
}

struct AddMemberView_Previews: PreviewProvider {
    static var previews: some View {
        AddMemberView()
    }
}
