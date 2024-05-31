//
//  ChatUser.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatUser: Codable, Identifiable {
    
    @DocumentID var id: String?
    
    let uid, email, profileImageUrl : String
    
    init(data: [String: Any]) {
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    }
}
