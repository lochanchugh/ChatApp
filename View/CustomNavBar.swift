//
//  CustomNavBar.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import SwiftUI
import SDWebImageSwiftUI

struct CustomNavBar: View {
    
    // MARK: - Properties
    @State private var shouldShowLogoutOptions = false
//    @ObservedObject private var mainMessagesViewModel = MainMessagesViewModel()
    @ObservedObject var vm: MainMessagesViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
            
            VStack(alignment:.leading, spacing: 5) {
                Text(vm.chatUser?.email ?? "")
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 12, height: 12)
                    Text("Online")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                } //: HStack
            } //: VStack
            Spacer()
            Button {
                shouldShowLogoutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        } //: HStack
        .actionSheet(isPresented: $shouldShowLogoutOptions, content: {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    vm.handleSignOut()
                }),
                .cancel()
            ])
        })
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, content: {
            RegisterView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
                self.vm.fetchRecentMessages()
            })
        })
        .padding()
    }
}

struct CustomNavBar_Previews: PreviewProvider {
    static var previews: some View {
        CustomNavBar(vm: MainMessagesViewModel())
            .previewLayout(.sizeThatFits)
    }
}
