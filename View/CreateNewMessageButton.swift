//
//  NewMessageButton.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import SwiftUI

struct CreateNewMessageButton: View {
    
    // MARK: - Properties
    @State private var shouldShowNewMessageScreen = false
    
    let didSelectNewUser: (ChatUser) -> ()
    
    // MARK: - Body
    var body: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                 Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            } //: HStack
            .foregroundColor(.white)
            .padding(.vertical)
            .background(.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        } //: Button
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView { user in
                self.didSelectNewUser(user)
                print(user.email)
            }
        }
    }
}

struct CreateNewMessageButton_Preview: PreviewProvider {
    static var previews: some View {
        CreateNewMessageButton(didSelectNewUser: { user in
            
        })
            .previewLayout(.sizeThatFits)
    }
}
