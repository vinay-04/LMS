//import SwiftUI
//import PhotosUI
//
//struct AddLibrarianView: View {
//    @Environment(\.dismiss) private var dismiss
//    @StateObject private var vm = AddLibrarianViewModel()
//
//    var body: some View {
//        VStack(spacing: 0) {
//            Button {
//                vm.showPhotoPicker = true
//            } label: {
//                if let img = vm.image {
//                    Image(uiImage: img)
//                        .resizable()
//                        .scaledToFill()
//                } else {
//                    Image(systemName: "camera")
//                        .font(.largeTitle)
//                        .foregroundColor(.gray)
//                }
//            }
//            .frame(width: 120, height: 120)
//            .background(Color.white)
//            .clipShape(Circle())
//            .shadow(color: Color.gray.opacity(0.5), radius: 5)
//            .padding(.top, 30)
//
//            Spacer().frame(height: 60)
//
//            Text("ADD LIBRARIAN DETAILS")
//                .font(.subheadline)
//                .fontWeight(.medium)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal, 16)
//                .foregroundColor(.gray)
//
//            VStack(spacing: 0) {
//                RowField(icon: "person", title: "Name", text: $vm.name)
//                Divider()
//                RowField(icon: "briefcase", title: "Designation", text: $vm.designation)
//                Divider()
//                RowField(icon: "dollarsign.circle", title: "Salary", text: $vm.salary)
//                Divider()
//                RowField(icon: "phone", title: "Contact", text: $vm.phone)
//                Divider()
//                RowField(icon: "at", title: "Email", text: $vm.email)
//                Divider()
//                RowField(icon: "key", title: "Password", text: $vm.password, isSecure: true)
//            }
//            .background(Color.white)
//            .cornerRadius(12)
//            .padding(.horizontal, 16)
//            .padding(.top, 8)
//
//            Spacer()
//        }
//        .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea())
//        .navigationTitle("Add Librarian")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button("Save") {
//                    vm.save { dismiss() }
//                }
//                .disabled(!vm.canSave)
//            }
//            // Back button is now handled by the parent view
//        }
//        .photosPicker(isPresented: $vm.showPhotoPicker, selection: $vm.photoItem)
//        .onChange(of: vm.photoItem) { newItem in
//            guard let item = newItem else { return }
//            Task {
//                if let data = try? await item.loadTransferable(type: Data.self),
//                   let ui = UIImage(data: data) {
//                    vm.image = ui
//                }
//            }
//        }
//    }
//}
//
//fileprivate struct RowField: View {
//    let icon: String, title: String
//    @Binding var text: String
//    var isSecure = false
//
//    var body: some View {
//        HStack {
//            Image(systemName: icon)
//                .foregroundColor(.gray)
//            Text(title)
//            Spacer()
//            if isSecure {
//                SecureField("Value", text: $text)
//                    .multilineTextAlignment(.trailing)
//            } else {
//                TextField("Value", text: $text)
//                    .multilineTextAlignment(.trailing)
//            }
//        }
//        .padding(.vertical, 12)
//        .padding(.horizontal, 16)
//    }
//}
//
//#Preview {
//    NavigationStack {
//        AddLibrarianView()
//    }
//}
//
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

            ScrollView {
                VStack(spacing: 0) {
                    // Name Field
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.gray)
                            Text("Name")
                            Spacer()
                            TextField("Enter Name", text: $vm.name)
                                .multilineTextAlignment(.trailing)
                                .onSubmit { vm.validateName() }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if !vm.nameError.isEmpty {
                            Text(vm.nameError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    Divider()
                    
                    // Designation Field
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "briefcase")
                                .foregroundColor(.gray)
                            Text("Designation")
                            Spacer()
                            TextField("Enter Designation", text: $vm.designation)
                                .multilineTextAlignment(.trailing)
                                .onSubmit { vm.validateDesignation() }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if !vm.designationError.isEmpty {
                            Text(vm.designationError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    Divider()
                    
                    // Salary Field
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.gray)
                            Text("Salary")
                            Spacer()
                            TextField("Enter Salary", text: $vm.salary)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.numberPad)
                                .onSubmit { vm.validateSalary() }
                                .onChange(of: vm.salary) { _ in vm.validateSalary() }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if !vm.salaryError.isEmpty {
                            Text(vm.salaryError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    Divider()
                    
                    // Phone Field
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "phone")
                                .foregroundColor(.gray)
                            Text("Contact")
                            Spacer()
                            TextField("Enter Phone", text: $vm.phone)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.phonePad)
                                .onSubmit { vm.validatePhone() }
                                .onChange(of: vm.phone) { _ in vm.validatePhone() }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if !vm.phoneError.isEmpty {
                            Text(vm.phoneError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    Divider()
                    
                    // Email Field
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "at")
                                .foregroundColor(.gray)
                            Text("Email")
                            Spacer()
                            TextField("Enter Email", text: $vm.email)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                                .onSubmit { vm.validateEmail() }
                                .onChange(of: vm.email) { _ in vm.validateEmail() }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if !vm.emailError.isEmpty {
                            Text(vm.emailError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                    Divider()
                    
                    // Password Field
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: "key")
                                .foregroundColor(.gray)
                            Text("Password")
                            Spacer()
                            SecureField("Enter Password", text: $vm.password)
                                .multilineTextAlignment(.trailing)
                                .onSubmit { vm.validatePassword() }
                                .onChange(of: vm.password) { _ in vm.validatePassword() }
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        
                        if !vm.passwordError.isEmpty {
                            Text(vm.passwordError)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }

            Button {
                vm.save { dismiss() }
            } label: {
                Text("Save Librarian")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(vm.canSave ? Color.blue : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(!vm.canSave)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
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

#Preview {
    NavigationStack {
        AddLibrarianView()
    }
}
