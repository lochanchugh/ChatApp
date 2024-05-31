//
//  ChatMessage.swift
//  ChatApp
//
//  Created by Lochan on 06.04.2024.
//

import Foundation
import FirebaseFirestoreSwift

struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timeStamp: Date
}
