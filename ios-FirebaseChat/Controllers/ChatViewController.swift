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
import SDWebImage

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
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        setupInputButton()
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
    
    private func setupInputButton(){
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({ [weak self] _ in
            self?.presentInputActionSheet()
        })
        
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet(){
        let sheet = UIAlertController(title: "Attach Media", message: "", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionsheet()
        }))
        
        sheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { _ in
            
        }))
        
        sheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        
        sheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { _ in
            
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            
        present(sheet, animated: true)
    }
    
    private func presentPhotoInputActionsheet(){
        let sheet = UIAlertController(title: "Attach Photo", message: "", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        
        sheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true, completion: nil)
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(sheet, animated: true)
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
    
    // Image Message
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        switch message.kind {
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            
            imageView.sd_setImage(with: url, completed: nil)
            
        default:
            break
        }
    }
}


// MARK:- InputBarAccessoryViewDelegate

extension ChatViewController: MessageCellDelegate{
    /// You can get a reference to the `MessageType` for the cell by using `UICollectionView`'s
    /// `indexPath(for: cell)` method. Then using the returned `IndexPath` with the `MessagesDataSource`
    /// method `messageForItem(at:indexPath:messagesCollectionView)`
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind{
        
        case .photo(let media):
            guard let url = media.url else {
                return
            }
            
            let vc = PhotoMessageViewController(with: url)
            self.navigationController?.pushViewController(vc, animated: true)
        
        default:
            break
        }
    }
}

// MARK:- UIImagePickerControllerDelegate & UINavigationControllerDelegate

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    /// 當使用者拍照或選照片後，將呼叫此 Function
    /// 從參數 info 取得圖片相關資料 info 的型別是 dictionary，傳入 key .originalImage 可得到圖片 -> info[.originalImage]
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[.editedImage] as? UIImage,
              let imageDate = image.pngData(),
              let messageId = createMessageID(),
              let conversationID = conversationID,
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        
        let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
        
        // 1. Upload Image to Firebase Storage
        
        StorageManager.shared.uploadMessagePhote(with: imageDate, fileName: fileName, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            switch result{
            
            case .success(let urlString):
                // 2. Send Message
                print("Upload Message Photo: \(urlString)")
                
                guard let url = URL(string: urlString), let placeholderImage = UIImage(systemName: "plus") else {
                    return
                }
                
                let media = Media(url: url, image: nil, placeholderImage: placeholderImage, size: .zero)
                
                let newMessage = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .photo(media))
                
                DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: newMessage, completion: { success in
                    if success{
                        print("Send Photo Success")
                    }else{
                        print("Send Photo Failed")
                    }
                })
                    
            case .failure(let error):
                print("message photo upload error: \(error)")
            }
        })
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
                    self?.messageInputBar.inputTextView.text = nil
                }else{
                    print("Create NewConversation Failed")
                }
            })
            
        }else{
            // Append to Existing Conversation
            
            guard let conversationID = conversationID, let name = self.title else {
                return
            }
            
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { [weak self] success in
                if success{
                    print("Send Message Success")
                    self?.messageInputBar.inputTextView.text = nil
                }else{
                    print("Send Message Failed")
                }
            })
        }
    }
    
    // make unique id
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

