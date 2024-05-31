//
//  Helpers.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import Foundation
import FirebaseFirestore

class Helpers {
    static let shared: Helpers = Helpers()
    
    func getFirebaseUser(_ uid: String?, completion: @escaping(ChatUser?) -> ()) {
        var chatUser: ChatUser?
        if let uid {
            Firestore.firestore().collection(FirebaseConstants.users).document(uid).getDocument { documentSnapshot, error in
                if let error {
                    print("Failed to fetch user: \(error)")
                    completion(nil)
                }
                
                guard let documentSnapshot else { return }
                do {
                    chatUser = try documentSnapshot.data(as: ChatUser.self)
                    completion(chatUser)
                } catch {
                    print("Error: ", error)
                    completion(nil)
                }
            }
        }
    }
}
