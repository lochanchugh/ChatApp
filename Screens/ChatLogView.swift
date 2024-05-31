//
//  ChatLogView.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class ChatLogViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    
    var chatUser: ChatUser?
    var loginUser: ChatUser?
    var firestoreListener: ListenerRegistration?
    
    // MARK: - Initializers
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        Helpers.shared.getFirebaseUser(Auth.auth().currentUser?.uid ?? nil) { user in
            if let user {
                self.loginUser = user
            }
        }
    }
    
    // MARK: - Functions
    func handleSend() {
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        let messageData = [FirebaseConstants.fromId: fromId, FirebaseConstants.toId: toId, FirebaseConstants.text: chatText, FirebaseConstants.timeStamp: Timestamp()] as [String : Any]
        
        let document = Firestore.firestore().collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .document()
        
        document.setData(messageData) { error in
            if let error {
                self.errorMessage = "Failed to save message to firestore: \(error)"
                print("Failed to save message to firestore: \(error)")
                return
            }
            
            self.persistRecentMessage()
            
            print("Successfully saved current user sending message")
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = Firestore.firestore().collection(FirebaseConstants.messages)
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error {
                self.errorMessage = "Failed to save message to firestore: \(error)"
                print("Failed to save message to firestore: \(error)")
                return
            }
            
            print("Recipient saved message as well")
        }
    }
    
    func fetchMessages() {
        guard let fromId = Auth.auth().currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        self.chatMessages.removeAll()
        firestoreListener?.remove()
        firestoreListener = Firestore.firestore().collection(FirebaseConstants.messages)
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timeStamp)
            .addSnapshotListener { querySnapshot, error in
                if let error {
                    print("Failed to fetch messages: \(error)")
                    self.errorMessage = "Failed to fetch messages: \(error)"
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        do {
                            let message = try change.document.data(as: ChatMessage.self)
                            self.chatMessages.append(message)
                            print("Appending chat messages in chat log view")
                        } catch {
                            print("Error:", error)
                        }
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
    }
    
    private func persistRecentMessage() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        guard let chatUser else { return }
        
        // TODO: For current user recent messages
        let data: [String: Any] = [
            FirebaseConstants.timeStamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ]
        
        let document = Firestore.firestore().collection(FirebaseConstants.recentMessages)
            .document(uid)
            .collection(FirebaseConstants.messages)
            .document(toId)
        
        document.setData(data) { error in
            if let error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent message: \(error)")
                return
            }
        }
        
        // TODO: For the user to which message is sent
        let toIdData: [String: Any] = [
            FirebaseConstants.timeStamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: toId,
            FirebaseConstants.toId: uid,
            FirebaseConstants.profileImageUrl: loginUser?.profileImageUrl ?? "",
            FirebaseConstants.email: loginUser?.email ?? ""
        ]
        let toIdDocument = Firestore.firestore().collection(FirebaseConstants.recentMessages)
            .document(toId)
            .collection(FirebaseConstants.messages)
            .document(uid)
        
        toIdDocument.setData(toIdData) { error in
            if let error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent message: \(error)")
                return
            }
        }
    }
}

struct ChatLogView: View {
    
    // MARK: - Properties
    @ObservedObject var vm: ChatLogViewModel

    static let emptyScrollString = "emptyScrollString"
    
    // MARK: - Body
    var body: some View {
        VStack {
            ZStack {
                // TODO: MessagesView
                ScrollView {
                    ScrollViewReader { scrollViewProxy in
                        VStack {
                            ForEach(vm.chatMessages) { message in
                                MessageView(message: message)
                            } //: Loop
                            HStack{ Spacer()}
                                .id(Self.emptyScrollString)
                        } //: VStack
                        .onReceive(vm.$count) { _ in
                            withAnimation(.easeOut(duration: 0.5)) {
                                scrollViewProxy.scrollTo(Self.emptyScrollString, anchor: .bottom)
                            }
                        }
                        .padding(.vertical, 12)
                    } //: ScrollViewReader
                } //: Scroll
                .background(Color(.init(white: 0.95, alpha: 1)))
                .clipped()
                Text(vm.errorMessage)
            } //: ZStack
            NewMessageBottomBar(chatUser: vm.chatUser)
        } //: VStack
        .navigationTitle(vm.chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            vm.firestoreListener?.remove()
        }
    }
}

struct MessageView: View {
    
    let message: ChatMessage
    
    var body: some View {
        VStack {
            if message.fromId == Auth.auth().currentUser?.uid {
                HStack {
                    Spacer(minLength: 20)
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    } //: HStack
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                } //: HStack
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    } //: HStack
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer(minLength: 20)
                } //: HStack
            } //: Condition
        } //: VStack
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        //        NavigationView{
        //            ChatLogView(chatUser: .init(data: ["uid": "0lxz3wrKt9WgYeHgSHeSfhFrGSs2", "email": "Basit@gmail.com"]))
        //        }
        MainMessagesView()
    }
}
