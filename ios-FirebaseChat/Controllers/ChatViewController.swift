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
import AVKit
import CoreLocation

final class ChatViewController: MessagesViewController {
    
    public static let dataFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    private var userPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
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

        setupInputButton()
        
        // Delegate
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
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

    // MARK:- Action
    
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
        
        sheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoActionSheet()
        }))
        
        sheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        
        sheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
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
    
    private func presentVideoActionSheet(){
        let sheet = UIAlertController(title: "Attach Video", message: "", preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true, completion: nil)
        }))
        
        sheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true, completion: nil)
        }))
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(sheet, animated: true, completion: nil)
    }
    
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
        vc.navigationItem.largeTitleDisplayMode = .never
        
        // sendButtonTapped
        vc.completion = { [weak self] selectedCoorindates in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let messageId = strongSelf.createMessageID(), let conversationID = strongSelf.conversationID,
                  let name = strongSelf.title, let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude = selectedCoorindates.longitude
            let latitude = selectedCoorindates.latitude
        
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                if success{
                    print("success")
                }else{
                    print("failed")
                }
            })
        }
        
        navigationController?.pushViewController(vc, animated: true)
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
    
    // change message background
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId{
            return .link
        }
        
        return .secondarySystemBackground
    }
    
    // 頭像
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId{
            // show user image
            if let userPhotoURL = userPhotoURL{
                // set Image
                avatarView.sd_setImage(with: userPhotoURL, completed: nil)
            }else{
                // Path: images/safeemail_profile_picture.png
                
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                
                let safeEmail = DatabaseManager.toSafeEmail(with: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                // fetch Url
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result{
                    case .success(let url):
                        self?.userPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }else{
            // show other user image
            if let otherUserPhotoURL = otherUserPhotoURL{
                avatarView.sd_setImage(with: otherUserPhotoURL, completed: nil)
            }else{
                let safeEmail = DatabaseManager.toSafeEmail(with: otherUserEmail)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                // fetch Url
                StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                    switch result{
                    case .success(let url):
                        self?.userPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                })
            }
        }
    }
}


// MARK:- InputBarAccessoryViewDelegate

extension ChatViewController: MessageCellDelegate{
    /// You can get a reference to the `MessageType` for the cell by using `UICollectionView`'s
    /// `indexPath(for: cell)` method. Then using the returned `IndexPath` with the `MessagesDataSource`
    /// method `messageForItem(at:indexPath:messagesCollectionView)`
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationItem):
            let coordinates = locationItem.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    // Photo & Video Tap
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
            navigationController?.pushViewController(vc, animated: true)
        
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            
            present(vc, animated: true, completion: nil)
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
        
        guard let messageId = createMessageID(),
              let conversationID = conversationID,
              let name = title,
              let selfSender = selfSender else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData(){
            // Photo Message
            
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            // 1. Upload Image to Firebase Storage
            StorageManager.shared.uploadMessagePhote(with: imageData, fileName: fileName, completion: { [weak self] result in
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
            
        }else if let videoUrl = info[.mediaURL] as? URL {
            // Video Message
            
            let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            // 1. Upload Video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                
                guard let strongSelf = self else {
                    return
                }
                
                switch result{
                case .success(let urlString):
                    // 2. Send message
                    print("Uploaded Message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString), let placeholderImage = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholderImage, size: .zero)
                    let newMessage = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: newMessage, completion: { success in
                        if success{
                            print("Send Video Success")
                        }else{
                            print("Send Video Failed")
                        }
                    })
                    
                case .failure(let error):
                    print("message video upload error: \(error)")
                }
            })
        }
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
            
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success{
                    // Create NewConversation Success
                    let newConversationId = "conversation_\(message.messageId)"
                    
                    self?.conversationID = newConversationId
                    self?.listenForMessages(id: newConversationId)
                    self?.isNewConversation = false
                    self?.messageInputBar.inputTextView.text = nil
                }else{
                    
                    print("Create NewConversation Failed")
                }
            })
            
        }else{
            // Append to Existing Conversation
            
            guard let conversationID = conversationID, let name = title else {
                return
            }
            
            DatabaseManager.shared.sendMessage(to: conversationID, otherUserEmail: otherUserEmail, name: name, newMessage: message, completion: { [weak self] success in
                if success{
                    // Send Message Success
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

