//
//  NewMessageScreen.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import SDWebImageSwiftUI

class CreateNewMessageViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var users = [ChatUser]()
    @Published var errorMessage = ""
    
    // MARK: - Initialization
    init() {
        fetchAllUsers()
    }
    
    // MARK: - Functions
    private func fetchAllUsers() {
        Firestore.firestore().collection("users").getDocuments { documentsSnapShot, error in
            if let error {
                self.errorMessage = "Failed to fetch users: \(error)"
                print("Failed to fetch users: \(error)")
                return
            }
            
            documentsSnapShot?.documents.forEach({ snapShot in
                do {
                    let user = try snapShot.data(as: ChatUser.self)
                    if user.uid != Auth.auth().currentUser?.uid {
                        self.users.append(user)
                    }
                } catch {
                    print("Error", error)
                }
                
//                let data = snapShot.data()
//                let user = ChatUser(data: data)
//                if user.uid != Auth.auth().currentUser?.uid {
//                    self.users.append(ChatUser(data: data))
//                }
            })
        }
    }
}

struct CreateNewMessageView: View {
    
    // MARK: - Properties
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    let didSelectNewUser: (ChatUser) -> ()
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(vm.users) { user in
                    Button {
                        self.didSelectNewUser(user)
                        dismiss()
                    } label: {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(Color(.label), lineWidth: 1)
                                )
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            Spacer()
                        } //: HStack
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    } //: Button
                    Divider()
                } //: Loop
            } //: Scroll
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                      dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
        } //: Navigation
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
//        CreateNewMessageView()
        MainMessagesView()
    }
}
