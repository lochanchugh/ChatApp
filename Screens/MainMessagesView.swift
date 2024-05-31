//
//  MainMessagesView.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import SwiftUI
import SDWebImageSwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseFirestoreSwift

class MainMessagesViewModel: ObservableObject {
    
    @Published var message = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var errorMessage = ""
    @Published var recentMessages = [RecentMessage]()
    
    private var firestoreListener: ListenerRegistration?
    
    init() {
        
        self.isUserCurrentlyLoggedOut = Auth.auth().currentUser?.uid == nil
        
        fetchCurrentUser()
        fetchRecentMessages()
    }
    
    func fetchRecentMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        firestoreListener?.remove()
        self.recentMessages.removeAll()
        
        firestoreListener = Firestore.firestore().collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .order(by: FirebaseConstants.timeStamp)
            .addSnapshotListener { querySnapShot, error in
                if let error {
                    self.errorMessage = "Failed to listen for recent message: \(error)"
                    print("Failed to listen for recent message: \(error)")
                    return
                }
                querySnapShot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: { rm in
                        docId == rm.id
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    
                    do {
                        let rm = try change.document.data(as: RecentMessage.self)
                        DispatchQueue.main.async {
                            self.recentMessages.insert(rm, at: 0)
                            print("RECENT MESSAGES: \(self.recentMessages)")
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                })
            }
    }
    
    func fetchCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else{
            message = "Failed to get current user uid"
            return
        }
        
        Firestore.firestore().collection("users").document(uid).getDocument { snapShot, error in
            if let error {
                self.message = "Failed to get user data: \(error)"
                print("Failed to get user data: \(error)")
                return
            }
            
            do {
                self.chatUser = try snapShot?.data(as: ChatUser.self)
            } catch {
                self.message = "Failed to decode snapshot data: \(error)"
                print("Failed to decode snapshot data: ", error)
            }
        }
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? Auth.auth().signOut()
    }
}

struct MainMessagesView: View {
    
    // MARK: - Properties
    @State private var shouldNavigateToChatLogView = false
    @State var chatUser: ChatUser?
    @ObservedObject var vm = MainMessagesViewModel()
    private let chatLogViewModel = ChatLogViewModel(chatUser: nil)
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack {
                CustomNavBar(vm: vm)
                ScrollView {
                    ForEach(vm.recentMessages) { recentMessage in
                        Button {
                            let uid = Auth.auth().currentUser?.uid == recentMessage.fromId ? recentMessage.toId : recentMessage.fromId
                            self.chatUser = .init(data: [FirebaseConstants.email: recentMessage.email, FirebaseConstants.profileImageUrl: recentMessage.profileImageUrl, FirebaseConstants.uid: uid])
                            self.chatLogViewModel.chatUser = self.chatUser
                            self.chatLogViewModel.fetchMessages()
                            self.shouldNavigateToChatLogView.toggle()
                        } label: {
                            HStack(spacing: 16) {
                                WebImage(url: URL(string: recentMessage.profileImageUrl))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipped()
                                    .cornerRadius(64)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 64)
                                            .stroke(Color(.label), lineWidth: 1)
                                    )
                                    .shadow(radius: 5)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(recentMessage.username)
                                        .font(.system(size: 16, weight: .heavy))
                                        .foregroundColor(Color(.label))
                                        .multilineTextAlignment(.leading)
                                    Text(recentMessage.text)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(.darkGray))
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                } //: VStack
                                
                                Spacer()
                                
                                Text(recentMessage.timeago)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(.label))
                            } //: HStack
                            .padding(.horizontal)
                        } //: Navigation
                        Divider()
                            .padding(.vertical, 8)
                    } //: Loop
                    .padding(.bottom, 50)
                } //: Scroll
                
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(vm: chatLogViewModel)
                }
            } //: VStack
            .overlay(
                CreateNewMessageButton(didSelectNewUser: { user in
                    self.shouldNavigateToChatLogView.toggle()
                    self.chatUser = user
                    self.chatLogViewModel.chatUser = user
                    self.chatLogViewModel.fetchMessages()
                })
                , alignment: .bottom
            )
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Preview
struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
            .preferredColorScheme(.dark)
    }
}
