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
    
    private var conversationID: String?
    
    private var messages = [Message]()
    
    // private let selfSender = Sender(photoURL: "", senderId: "1", displayName: "Wayne")
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        /// 應該會根據 senderId 來決定左右
        let safeEmail = DatabaseManager.toSafeEmail(with: email)
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Me")
    }
    
    init(with email: String, id: String?){
        self.otherUserEmail = email
        self.conversationID = id
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let conversationID = conversationID{
            listenForMessages(id: conversationID)
        }
    }
    
    
    
    // MARK: Action
    
    private func listenForMessages(id: String){
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result{
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("Message is Empty")
                    return
                }
            
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                }
               
            case .failure(let error):
                print("failed to get message: \(error)")
            }
        })
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
        
        let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        
        print("isNewConversation: \(isNewConversation.description)")
        
        // Send Message
        if isNewConversation{
            
            // Create New Conversation in Database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success{
                    print("Create NewConversation Success")
                    self?.isNewConversation = false
                }else{
                    print("Create NewConversation Failed")
                }
            })
            
        }else{
            
            guard let conversationID = conversationID, let name = self.title else {
                return
            }
            
            // Append to Existing Conversation
            DatabaseManager.shared.sendMessage(to: conversationID, name: name, newMessage: message, completion: { success in
                if success{
                    print("Send Message Success")
                }else{
                    print("Send Message Failed")
                }
            })
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

