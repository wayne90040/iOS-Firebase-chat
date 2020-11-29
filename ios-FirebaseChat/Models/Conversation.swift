//
//  Conversation.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/29.
//

import Foundation

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}
