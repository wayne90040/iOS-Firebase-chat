//
//  ConversationsViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/7.
//

import UIKit
import FirebaseAuth
import JGProgressHUD


final class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private var loginObserver: NSObjectProtocol?
    
    private let mainTableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        
        return tableView
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add RightBarButtom
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                            target: self,
                                                            action: #selector(didTapComposeButton))
        
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.startListeningForConversations()
        })
        
        // MARK: Delegate
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.isHidden = false
        
        // MARK: Add SubViews
        view.addSubview(mainTableView)
        view.addSubview(noConversationsLabel)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        mainTableView.frame = view.bounds
        noConversationsLabel.frame = CGRect(x: 10, y: (view.height - 100) / 2, width: view.width - 20, height: 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentAuth()
    }
    
    
    // MARK: - Action
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeEmail = DatabaseManager.toSafeEmail(with: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self] result in
            
            switch result{
            case .success(let conversations):
                print("success get conversation")
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.mainTableView.reloadData()
                }
            
            case .failure(let error):
                print("failed to get Conversation: \(error)")
            }
        })
    }
    
    /// 確認有無登入紀錄
    private func currentAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
    }
    
    /// ComposeButton Action
    
    @objc private func didTapComposeButton(){
        let vc = NewConversationViewController()
        
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: {
                // 現在有的 Conversation otherUserEmail == 搜尋結果的 email
                $0.otherUserEmail == DatabaseManager.toSafeEmail(with: result.email)
            }){
                // Exist
                let vc = ChatViewController(with: targetConversation.otherUserEmail, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }else{
                // Not Exist
                strongSelf.createNewConversation(result: result)
            }
        }
        
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func createNewConversation(result: SearchResult){
        let name = result.name
        let safeEmail = DatabaseManager.toSafeEmail(with: result.email)
        
        // check database if conversation with these two users exists
        // if it does, reuse conversation id
        // otherwise use existing code
        
        DatabaseManager.shared.conversationExists(with: safeEmail, completion: { [weak self] result in
            guard let strongSelf = self else{
                return
            }
            
            switch result{
            case .success(let conversationId):
                let vc = ChatViewController(with: safeEmail, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
                
            case .failure(_):
                let vc = ChatViewController(with: safeEmail, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier,
                                                 for: indexPath) as! ConversationTableViewCell
        let conversation = conversations[indexPath.row]
        cell.configure(with: conversation)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        
        let vc = ChatViewController(with: conversation.otherUserEmail, id: conversation.id)
        vc.title = conversation.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete{
            let id = conversations[indexPath.row].id
            
            tableView.beginUpdates()
            
            // 有 bugs
            // 1. 會有 out of range
            // 2. 資料庫需要改規格 -> 紀錄刪不乾淨
            
            self.conversations.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.shared.deleteConversation(conversationId: id, completion: { success in
                if !success{
                    // add alert
                }
            })
    
            tableView.endUpdates()
        }
    }
}

