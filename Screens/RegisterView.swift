//
//  ContentView.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct RegisterView: View {
    
    // MARK: - Properties
    @State private var isLoginMode: Bool = false
    @State private var email = ""
    @State private var password = ""
    @State private var shouldShowImagePicker = false
    @State private var image: UIImage?
    @State private var loginStatusMessage = ""
    
    let auth: Auth = Auth.auth()
    let storage: Storage = Storage.storage()
    let firestore: Firestore = Firestore.firestore()
    let didCompleteLoginProcess: () -> ()
    
    // MARK: - Functions
    
    private func handleAuthentication() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    private func loginUser() {
        auth.signIn(withEmail: email, password: password) { authResult, error in
            if let error {
                print("Failed to login user: \(error)")
                self.loginStatusMessage = "Failed to login user: \(error)"
                return
            }
            
            print("Successfully login user: \(authResult?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully login user: \(authResult?.user.uid ?? "")"
            self.didCompleteLoginProcess()
        }
    }
    
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        auth.createUser(withEmail: email, password: password) { authResult, error in
            if let error {
                print("Failed to create user: \(error)")
                self.loginStatusMessage = "Failed to create user: \(error)"
                return
            }
            
            print("Successfully create user: \(authResult?.user.uid ?? "")")
            self.loginStatusMessage = "Successfully create user: \(authResult?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = Auth.auth().currentUser?.uid else {return}
        let ref = storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {return}
        ref.putData(imageData) { data, error in
            if let error {
                print("Failed to push image data to storage: \(error)")
                self.loginStatusMessage = "Failed to push image data to storage: \(error)"
                return
            }
            
            ref.downloadURL { url, error in
                if let error {
                    print("Failed to retrieve downloadURL: \(error)")
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(error)"
                    return
                }
                
                print("Successfully stored image with url: \(url?.absoluteString ?? "")")
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
                self.storeUserInformation(imageProfileUrl: url!)
            }
        }
    }
    
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userData = ["uid": uid, "email": email, "profileImageUrl": imageProfileUrl.absoluteString]
        
        firestore.collection("users").document(uid).setData(userData) { error in
            if let error {
                print("Failed to store user information to database:", error)
                self.loginStatusMessage = "Failed to store user information to database: \(error)"
                return
            }
            print("Success")
            self.loginStatusMessage = "Successfully stored user data to storage"
            self.didCompleteLoginProcess()
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Segmented Control
                    Picker(selection: $isLoginMode, content: {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }, label: {
                        Text("Picker here")
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // MARK: - Image Button
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack {
                                if let image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128, alignment: .center)
                                        .cornerRadius(64)
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(.black)
                                }
                            } //: VStack
                            .overlay(
                                RoundedRectangle(cornerRadius: 64)
                                    .stroke(Color.black, lineWidth: 3)
                            )
                        }
                    }
                    
                    // MARK: - TextFields
                    Group {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.none)
                    SecureField("Password", text: $password)
                    }
                    .padding(12)
                    .background(.white)
                    .cornerRadius(5)
                    
                    // MARK: - Authentication Button
                    Button {
                        handleAuthentication()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Login" : "Create Account")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding()
                            Spacer()
                        }
                    }
                    .background(Color.blue)
                    .cornerRadius(5)
                    
                    Text(loginStatusMessage)
                        .foregroundColor(.red)
                    
                } //: VStack
                .padding()
            } //: Scroll
            .background(Color(.init(white: 0, alpha: 0.05)))
            .navigationTitle(isLoginMode ? "Login" : "Create Account")
            .fullScreenCover(isPresented: $shouldShowImagePicker) {
                ImagePicker(image: $image)
            }
        } //: Navigation
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(didCompleteLoginProcess: {})
    }
}
