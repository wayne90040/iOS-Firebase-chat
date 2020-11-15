//
//  ChatViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/15.
//

import UIKit
import MessageKit

final class ChatViewController: MessagesViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Delegate

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
}


// MARK: - MessageCellDelegate, MessagesLayoutDelegate, MessagesDisplayDelegate

extension ChatViewController: MessagesDataSource ,MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        
    }
}

