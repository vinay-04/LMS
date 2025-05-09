import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showQRFullScreen = false
    @State private var showLogoutConfirmation = false // Added for confirmation dialog
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if authViewModel.currentUser == nil {
                    VStack {
                        Text("Please log in to view your profile")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding()
                        Button("Log In") {
                            // Navigate to login screen (implement as needed)
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                } else if viewModel.isLoading {
                    ProgressView("Loading profile...")
                        .padding()
                } else if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    profileHeader
                    membershipCard
                    optionsList
                    logoutButton
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
        .navigationBarTitle("Profile", displayMode: .large)
        .sheet(isPresented: $showEditProfile) {
            Text("Edit Profile View")
                .font(.title)
                .padding()
        }
        .sheet(isPresented: $showQRFullScreen) {
            qrCodeFullScreenView
        }
        .confirmationDialog("Are you sure you want to log out?", isPresented: $showLogoutConfirmation, titleVisibility: .visible) {
            Button("Log Out", role: .destructive) {
                Task { await authViewModel.logout() }
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            if let userId = authViewModel.currentUser?.id {
                viewModel.fetchProfile(userId: userId)
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                Image("libraryBackground")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.4, blue: 0.6).opacity(0.7),
                                Color(red: 0.1, green: 0.2, blue: 0.4).opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipped()
                    .onAppear {
                        if UIImage(named: "libraryBackground") == nil {
                            print("Image not found, using gradient fallback")
                        }
                    }
                
                VStack {
                    HStack {
                        Spacer()
                        Text("Member since 2023")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(12)
                            .padding([.top, .trailing], 10)
                    }
                    Spacer()
                }
                
                ZStack {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.8, green: 0.7, blue: 0.5),
                                    Color(red: 0.6, green: 0.4, blue: 0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .background(Circle().fill(Color.white))
                        .frame(width: 104, height: 104)
                        .shadow(color: Color.black.opacity(0.2), radius: 5)
                    
                    if let uiImage = UIImage(named: "userProfilePic") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 94, height: 94)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.3, green: 0.5, blue: 0.7),
                                        Color(red: 0.2, green: 0.3, blue: 0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 94, height: 94)
                        
                        Text(String(viewModel.userName.prefix(1)))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .offset(y: 50)
            }
            
            VStack(spacing: 5) {
                Spacer().frame(height: 55)
                
                HStack(alignment: .center, spacing: 8) {
                    Text(viewModel.userName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Image(systemName: "book.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 14))
                        .padding(4)
                        .background(Color.yellow.opacity(0.2))
                        .clipShape(Circle())
                }
                
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue.opacity(0.7))
                            .frame(width: 20)
                        
                        Text(viewModel.userEmail)
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = viewModel.userEmail
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.horizontal, 5)
                    
                    Divider()
                        .padding(.horizontal, 5)
                    
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundColor(.green.opacity(0.7))
                            .frame(width: 20)
                        
                        Text(viewModel.userPhone)
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: {
                            UIPasteboard.general.string = viewModel.userPhone
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                    .padding(.horizontal, 5)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 10)
                
                HStack(spacing: 15) {
                    Button(action: {
                        showEditProfile = true
                    }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Edit")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                    
                    NavigationLink(destination: Text("Reading History")) {
                        HStack {
                            Image(systemName: "book")
                            Text("History")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    NavigationLink(destination: Text("Wishlist")) {
                        HStack {
                            Image(systemName: "bookmark.fill")
                            Text("Saved")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 5)
                
                HStack(spacing: 0) {
                    Spacer()
                    statView(value: "12", label: "Books Read")
                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 15)
                    statView(value: "3", label: "Currently")
                    Divider()
                        .frame(height: 30)
                        .padding(.horizontal, 15)
                    statView(value: "85%", label: "On Time")
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .padding(.top, 20)
            .padding(.bottom, 15)
            .padding(.horizontal, 5)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 5)
        .padding(.horizontal)
    }
    
    private func statView(value: String, label: String) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var membershipCard: some View {
           VStack(spacing: 20) {
               HStack {
                   Text("Library Membership")
                       .font(.headline)
                       .foregroundColor(.primary)
                   
                   Spacer()
                   
                   Text("ACTIVE")
                       .font(.caption)
                       .fontWeight(.bold)
                       .foregroundColor(.white)
                       .padding(.horizontal, 12)
                       .padding(.vertical, 4)
                       .background(Color.green)
                       .cornerRadius(12)
               }
               
               Divider()
               
               VStack(spacing: 16) {
                   Button(action: {
                       showQRFullScreen = true
                   }) {
                       ZStack {
                           if let qrImage = viewModel.qrCodeImage {
                               Image(uiImage: qrImage)
                                   .resizable()
                                   .interpolation(.none)
                                   .aspectRatio(contentMode: .fit)
                                   .frame(width: 150, height: 150)
                           } else {
                               Image(systemName: "qrcode")
                                   .resizable()
                                   .aspectRatio(contentMode: .fit)
                                   .frame(width: 150, height: 150)
                                   .foregroundColor(.black)
                           }
                           
                           Image(systemName: "plus.magnifyingglass")
                               .resizable()
                               .frame(width: 20, height: 20)
                               .foregroundColor(.blue)
                               .offset(x: 60, y: 60)
                       }
                       .padding(8)
                       .background(Color.white)
                       .cornerRadius(10)
                       .shadow(color: Color.black.opacity(0.05), radius: 5)
                   }
                   
                   Text("Member ID: \(viewModel.memberId)")
                       .font(.subheadline)
                       .foregroundColor(.secondary)
                   
                   HStack {
                       Image(systemName: "info.circle")
                           .foregroundColor(.blue.opacity(0.8))
                       Text("Show this QR code when borrowing books")
                           .font(.caption)
                           .foregroundColor(.secondary)
                           .multilineTextAlignment(.center)
                   }
                   .padding(.top, 5)
               }
           }
           .padding()
           .background(Color.white)
           .cornerRadius(15)
           .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
           .padding(.horizontal)
       }
       
    
    private var optionsList: some View {
        VStack(spacing: 0) {
            Text("Settings & Preferences")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .foregroundColor(.secondary)
            
            
            NavigationLink(destination: Text("Overdues & Fines")) {
                OptionRow(icon: "dollarsign.circle.fill", title: "Overdues & Fines", iconColor: .red)
            }
            
            Divider().padding(.leading, 56)
            
            NavigationLink(destination: FAQView()) {
                OptionRow(icon: "questionmark.circle.fill", title: "FAQs", iconColor: .purple)
            }
        }
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    private var logoutButton: some View {
        Button(action: {
            showLogoutConfirmation = true // Trigger confirmation dialog
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
                    .fontWeight(.medium)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var qrCodeFullScreenView: some View {
        VStack(spacing: 30) {
            HStack {
                Spacer()
                Button(action: {
                    showQRFullScreen = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.gray)
                }
                .padding()
            }
            
            Spacer()
            
            Text("Scan to verify membership")
                .font(.headline)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.blue, lineWidth: 3)
                    .frame(width: 280, height: 280)
                
                if let qrImage = viewModel.qrCodeImage {
                    Image(uiImage: qrImage)
                        .resizable()
                        .interpolation(.none)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 250)
                } else {
                    Image(systemName: "qrcode")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: 250)
                        .foregroundColor(.black)
                }
            }
            
            Text("Member ID: \(viewModel.memberId)")
                .font(.title3)
                .fontWeight(.medium)
            
            Text(viewModel.userName)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            HStack {
                Image(systemName: "info.circle")
                Text("Valid until Dec 31, 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 30)
        }
        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
    }
}

struct OptionRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var hasValue: Bool = true
    var iconColor: Color = .blue
    var badgeCount: Int? = nil
    var toggleOption: Bool = false
    @State private var isToggled = true
    
    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
            .padding(.leading)
            
            Text(title)
                .font(.system(size: 16))
            
            Spacer()
            
            if let value = value {
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.trailing, 8)
            }
            
            if let badgeCount = badgeCount {
                Text("\(badgeCount)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.red)
                    .clipShape(Circle())
                    .padding(.trailing, 8)
            }
            
            if toggleOption {
                Toggle("", isOn: $isToggled)
                    .labelsHidden()
                    .padding(.trailing)
            } else if hasValue {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.trailing)
            }
        }
        .padding(.vertical, 12)
        .background(Color.white)
    }
}
//import SwiftUI
//import Firebase
//import CoreImage.CIFilterBuiltins
//
//// First, update the ProfileViewModel to fetch user_id from Firestore
//
//// Now, update the ProfileView to use the generated QR code
//struct ProfileView: View {
//
//    @EnvironmentObject var authViewModel: AuthViewModel
//    @StateObject private var viewModel = ProfileViewModel()
//    @State private var showEditProfile = false
//    @State private var showQRFullScreen = false
//    @State private var showLogoutConfirmation = false
//    
//    // Rest of your ProfileView remains the same, just update the QR code parts
//    
//    // Replace the membershipCard view
//    private var membershipCard: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Text("Library Membership")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                Text("ACTIVE")
//                    .font(.caption)
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//                    .padding(.horizontal, 12)
//                    .padding(.vertical, 4)
//                    .background(Color.green)
//                    .cornerRadius(12)
//            }
//            
//            Divider()
//            
//            VStack(spacing: 16) {
//                Button(action: {
//                    showQRFullScreen = true
//                }) {
//                    if let qrImage = viewModel.qrCodeImage {
//                        Image(uiImage: qrImage)
//                            .interpolation(.none)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 150, height: 150)
//                            .padding(8)
//                            .background(Color.white)
//                            .cornerRadius(10)
//                            .shadow(color: Color.black.opacity(0.05), radius: 5)
//                            .overlay(
//                                Image(systemName: "plus.magnifyingglass")
//                                    .resizable()
//                                    .frame(width: 20, height: 20)
//                                    .foregroundColor(.blue)
//                                    .offset(x: 60, y: 60)
//                            )
//                    } else {
//                        // Fallback to placeholder if QR code is not generated yet
//                        ZStack {
//                            Image(systemName: "qrcode")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 150, height: 150)
//                                .foregroundColor(.black)
//                            
//                            Image(systemName: "plus.magnifyingglass")
//                                .resizable()
//                                .frame(width: 20, height: 20)
//                                .foregroundColor(.blue)
//                                .offset(x: 60, y: 60)
//                        }
//                        .padding(8)
//                        .background(Color.white)
//                        .cornerRadius(10)
//                        .shadow(color: Color.black.opacity(0.05), radius: 5)
//                    }
//                }
//                
//                Text("Member ID: \(viewModel.memberId)")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                HStack {
//                    Image(systemName: "info.circle")
//                        .foregroundColor(.blue.opacity(0.8))
//                    Text("Show this QR code when borrowing books")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//                .padding(.top, 5)
//            }
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(15)
//        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
//        .padding(.horizontal)
//    }
//    
//    // Replace the qrCodeFullScreenView
//    private var qrCodeFullScreenView: some View {
//        VStack(spacing: 30) {
//            HStack {
//                Spacer()
//                Button(action: {
//                    showQRFullScreen = false
//                }) {
//                    Image(systemName: "xmark.circle.fill")
//                        .resizable()
//                        .frame(width: 30, height: 30)
//                        .foregroundColor(.gray)
//                }
//                .padding()
//            }
//            
//            Spacer()
//            
//            Text("Scan to verify membership")
//                .font(.headline)
//            
//            if let qrImage = viewModel.qrCodeImage {
//                Image(uiImage: qrImage)
//                    .interpolation(.none)
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 250, height: 250)
//                    .padding(15)
//                    .background(Color.white)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 20)
//                            .stroke(Color.blue, lineWidth: 3)
//                            .frame(width: 280, height: 280)
//                    )
//            } else {
//                ZStack {
//                    RoundedRectangle(cornerRadius: 20)
//                        .stroke(Color.blue, lineWidth: 3)
//                        .frame(width: 280, height: 280)
//                    
//                    Image(systemName: "qrcode")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 250, height: 250)
//                        .foregroundColor(.black)
//                }
//            }
//            
//            Text("User ID: \(viewModel.userId)")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//                .padding(.top, 5)
//            
//            Text("Member ID: \(viewModel.memberId)")
//                .font(.title3)
//                .fontWeight(.medium)
//            
//            Text(viewModel.userName)
//                .font(.headline)
//                .foregroundColor(.secondary)
//            
//            Spacer()
//            
//            HStack {
//                Image(systemName: "info.circle")
//                Text("Valid until Dec 31, 2025")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//            }
//            .padding(.bottom, 30)
//        }
//        .background(Color(.systemGray6).edgesIgnoringSafeArea(.all))
//    }
//}
//
//// Optional: A simple extension to make QR code generation reusable elsewhere in your app
//extension UIImage {
//    static func generateQRCode(from string: String) -> UIImage? {
//        let context = CIContext()
//        let filter = CIFilter.qrCodeGenerator()
//        
//        guard let data = string.data(using: .utf8) else { return nil }
//        filter.setValue(data, forKey: "inputMessage")
//        filter.setValue("M", forKey: "inputCorrectionLevel")
//        
//        guard let ciImage = filter.outputImage else { return nil }
//        
//        // Scale up the image for better visibility
//        let transform = CGAffineTransform(scaleX: 10, y: 10)
//        let scaledCIImage = ciImage.transformed(by: transform)
//        
//        guard let cgImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else { return nil }
//        return UIImage(cgImage: cgImage)
//    }
//}
