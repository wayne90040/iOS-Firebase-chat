//
//  DatabaseManager.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/9.
//

import Foundation
import FirebaseDatabase

class DatabaseManager{
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func toSafeEmail(with email: String) -> String{
        var result = email.replacingOccurrences(of: ".", with: "-")
        result = result.replacingOccurrences(of: "@", with: "-")
        return result
    }
/*
     users = [
        [
            "name":
            "email":
        ],
        [
            "name":
            "email":
        ]
     ]
*/
    
    /// Insert New uesr to Database
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void){
        database.child(user.safeEmail).setValue(["first_name": user.firstName, "last_name": user.lastName], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to Insert New user to Database")
                completion(false)
                return
            }
            
            // 寫入 user array - > 搜尋使用者
            /// observeSingleEvent 只触发一次事件回调。这对于读取只需要加载一次且不希望之后更改的数据非常有用。
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]]{
                    // append user to user Array
                    
                    let newUser = ["name": user.firstName + " " + user.lastName, "email": user.safeEmail]
                    usersCollection.append(newUser)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                    
                }else{
                    // create user Array
                    let newCollection: [[String: String]] = [["name": user.firstName + " " + user.lastName, "email": user.safeEmail]]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        })
    }
    
    /// Check if user exist
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? [String: Any] != nil else{
                completion(false)
                return
            }
            
            completion(true)
        })
    }
    
    /// Get Firebase users array
    public func getAllUsers(completion: @escaping(Result<[[String: String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let result = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseManagerError.failedToFetch))
                return
            }
            completion(.success(result))
        })
    }
    
    /// Return Data by path
    public func getDataFor(path: String, completion: @escaping(Result<Any, Error>) -> Void){
        database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseManagerError.failedToFetch))
                return
            }
            completion(.success(value))
        })
    }
}


// MARK:- Sending Message / Conversation

extension DatabaseManager{
    
/*
    "testtest" {
         "messages": [
             {
                 "id": String,
                 "type": text, photo, video,
                 "content": String,
                 "date": Date(),
                 "sender_email": String,
                 "isRead": true/false,
             }
         ]
     }
     
     conversation => [
        [
            "conversation_id": "testtest"
            "other_user_email":
            "lastest_message": {
                "date": Date()
                "lastest_message": message
                "is_read": true/false
            }
        ]
     ]
*/
    
    /// Create new conversionation
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping(Bool) -> Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            print("Get UserDefault Error")
            return
        }
        
        let safeEmail = DatabaseManager.toSafeEmail(with: currentEmail)
        let ref = database.child(safeEmail)
        
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            
            guard var userNode = snapshot.value as? [String: Any] else {
                print("user not found")
                completion(false)
                return
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dataFormatter.string(from: messageDate)
            var message = ""
            
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message":[
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message":[
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            
            // MARK: Update Recipient(接收者) User Email conversation
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]]{
                    // conversation array exists for current user -> you should append
                    
                    // append
                    conversations.append(recipient_newConversationData)
                    
                    // return database
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }else{
                    // conversation array NOT exists -> create
                    
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            
            // MARK: Update current User Email conversation
            if var conversations = userNode["conversations"] as? [[String: Any]]{
                // conversation array exists for current user -> you should append
                
                // 1. append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                
                // 2. return to database
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name,conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }else{
                
                // conversation array NOT exists -> create
                // 1. create conversation
                userNode["conversations"] = [newConversationData]
                
                // 2. return to database
                ref.setValue(userNode, withCompletionBlock: { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation(name: String, conversationId: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        /*
            "id": String,
            "type": text, photo, video,
            "content": String,
            "date": Date(),
            "sender_email": String,
            "isRead": true/false,
         */
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        case .linkPreview(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.toSafeEmail(with: myEmail)
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dataFormatter.string(from: messageDate)
        
        let collectMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "name": name,
            "type": firstMessage.kind.messageKindtoString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "isRead": false
        ]
        
        let value: [String: Any] = [
            "messages": [ collectMessage ]
        ]
        
        print("adding conversation: \(conversationId)")
        
        database.child(conversationId).setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    
    /// Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>) -> Void){
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseManagerError.failedToFetch))
                return
            }
            
            let conversations: [Conversation] = value.compactMap({ dic in
                guard let id = dic["id"] as? String,
                    let name = dic["name"] as? String,
                    let otherUserEmail = dic["other_user_email"] as? String,
                    let latestMessage = dic["latest_message"] as? [String: Any],
                    let date = latestMessage["date"] as? String,
                    let message = latestMessage["message"] as? String,
                    let isRead = latestMessage["is_read"] as? Bool else{
                        return nil
                }
                
                let lastMessageObj = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: id, name: name, otherUserEmail: otherUserEmail, latestMessage: lastMessageObj)
            })
            
            completion(.success(conversations))
        })
    }
    
    /// Gets All messages for a Given Conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping(Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: { snapshpt in
            guard let value = snapshpt.value as? [[String: Any]] else{
                completion(.failure(DatabaseManagerError.failedToFetch))
                return
            }
            
            print("value: \(value)")
            
            let messages: [Message] = value.compactMap({ dic in
                guard let name = dic["name"] as? String,
                    let isRead = dic["isRead"] as? Bool,
                    let messageID = dic["id"] as? String,
                    let content = dic["content"] as? String,
                    let senderEmail = dic["sender_email"] as? String,
                    let type = dic["type"] as? String,
                    let dateString = dic["date"] as? String,
                    let date = ChatViewController.dataFormatter.date(from: dateString) else{
                        return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
            })
            
            completion(.success(messages))
        })
    }
    
    /// Sends a message with target conversation and message
    public func sendMessage(to conversation: String, name: String, newMessage: Message, completion: @escaping(Bool) -> Void){
        // 1. add new message to messages -> id
        // 2. update Sender latest message
        // 3. update Recipient latest message
        
        
        // MARK: 1. add new message to messages -> id
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            
            guard let strongSelf = self else{
                return
            }
            
            guard var currentMessage = snapshot.value as? [[String: Any]] else{
                completion(false)
                return
            }
            
            var message = ""
            switch newMessage.kind{
            case .text(let msgText):
                message = msgText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            // Date
            let msgDate = newMessage.sentDate
            let dateString = ChatViewController.dataFormatter.string(from: msgDate)
            
            // Email
            guard let userEmail = UserDefaults.standard.value(forKey: "email") as? String else{
                completion(false)
                return
            }
            
            // to safeEmail
            let userSafeEmail = DatabaseManager.toSafeEmail(with: userEmail)
            
            let newMessageModel: [String: Any] = [
                "id": newMessage.messageId,
                "name": name,
                "type": newMessage.kind.messageKindtoString,
                "content": message,
                "date": dateString,
                "sender_email": userSafeEmail,
                "isRead": false
            ]
            
            currentMessage.append(newMessageModel)
            
            // return to database
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessage, withCompletionBlock: { error, _ in
                guard error == nil else{
                    completion(false)
                    return
                }
                completion(true)
            })
            
            
        })
    }
}


// MARK: - Error

extension DatabaseManager{
    public enum DatabaseManagerError: Error{
        case failedToFetch
    }
}



