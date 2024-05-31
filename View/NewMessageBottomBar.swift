//
//  NewMessageBottomBar.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import SwiftUI

struct NewMessageBottomBar: View {
    
    // MARK: - Properties
    let chatUser: ChatUser?
    @ObservedObject var vm: ChatLogViewModel
    
    // MARK: - Initializers
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    // MARK: - Body
    var body: some View {
        // TODO: New Message Bottom Bar
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5 : 1)
            } //: ZStack
            .frame(height: 40)
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(4)
        } //: HStack
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
//                .padding(.top, -4)
            Spacer()
        }
    }
}

struct NewMessageBottomBar_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageBottomBar(chatUser: nil)
    }
}
