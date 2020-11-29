//
//  ChatViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/15.
//
// https://github.com/MessageKit/MessageKit

import UIKit
import MessageKit
import InputBarAccessoryView

final class ChatViewController: MessagesViewController {
    
    public static let dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    
    public let otherUserEmail: String
    
    private var messages = [Message]()
    
    // private let selfSender = Sender(photoURL: "", senderId: "1", displayName: "Wayne")
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        return Sender(photoURL: "", senderId: email, displayName: "Me")
    }
    
    init(with email: String){
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Delegate
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
}


// MARK:- MessageCellDelegate, MessagesLayoutDelegate, MessagesDisplayDelegate

extension ChatViewController: MessagesDataSource ,MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("Self Sender is nil, Email should be catched")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}


// MARK:- InputBarAccessoryViewDelegate
extension ChatViewController: InputBarAccessoryViewDelegate{
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageID = createMessageID() else {
            return
        }
        
        print("Sending: \(text)")
        
        // Send Message
        if isNewConversation{
            // Create New Conversation in Database
            let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { success in
                if success{
                    print("success")
                }else{
                    print("failed")
                }
            })
            
        }else{
            // Append to Existing Conversation
        }
    }
    
    private func createMessageID() -> String?{
        // date, otherUserEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.toSafeEmail(with: currentUserEmail)
        let dataString = Self.dataFormatter.string(from: Date())
        let result = "\(otherUserEmail)_\(safeEmail)_\(dataString)"
        
        return result
    }
}

