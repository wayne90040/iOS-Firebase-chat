//
//  Message.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/15.
//

import Foundation
import MessageKit

struct Message: MessageType{
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}
