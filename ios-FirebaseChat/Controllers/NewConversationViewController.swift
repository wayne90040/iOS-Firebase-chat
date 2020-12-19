//
//  NewConversationViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/20.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var hasFetched = false
    
    private var users = [[String: String]]()
    
    private var results = [SearchResult]()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search For User"
        return searchBar
    }()
    
    // result
    private let tableView: UITableView = {
        let tableview = UITableView()
        tableview.isHidden = true
        tableview.register(NewConversationTableViewCell.self,
                           forCellReuseIdentifier: NewConversationTableViewCell.identifier)
        return tableview
    }()
    
    // no result
    private let noResultLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Result"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        view.backgroundColor = .systemBackground

        // Delegate
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        // 自動彈出鍵盤, 省去點擊 search bar 才會跳出鍵盤
        searchBar.becomeFirstResponder()
        
        // AddSubview
        view.addSubview(noResultLabel)
        view.addSubview(tableView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultLabel.frame = CGRect(x: view.width / 4, y: (view.height-200)/2, width: view.width / 2, height: 200)
    }
    
    // MARK: - Action
    
    @objc private func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationTableViewCell.identifier,
                                                for: indexPath) as! NewConversationTableViewCell
        let result = results[indexPath.row]
        
        cell.configure(with: result)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Start Converation - 點擊搜尋結果
        let didSelectUser = results[indexPath.row]
        
        // Dismiss and Push
        dismiss(animated: true, completion: { [weak self] in
            self?.completion?(didSelectUser)
        })
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}


// MARK: - UISearchBarDelegate

extension NewConversationViewController: UISearchBarDelegate{
    
    /// 搜尋觸發事件, 點選虛擬鍵盤上的search按鈕時觸發此方法
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard  let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        
        results.removeAll()
        spinner.show(in: view)
        searchUsers(query: text)
    }
    
    func searchUsers(query: String){
        // 1. Check if array has firebase results
        if hasFetched{
            // 2. if it does: filter
            filterUsers(with: query)
            
        }else{
            // 2. if not, fetch then filter
            // fetch
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result{
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                    
                case .failure(let error):
                    print("Failed to get users: \(error)")
                }
            })
        }
    }
    
    func filterUsers(with term: String){
        // 3. update the UI: eitehr show results or show no results label
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.toSafeEmail(with: currentEmail)

        let results: [SearchResult] = self.users.filter({
            // 新增功能: 透過 Email 搜尋時過濾自己
            guard let email = $0["email"], email != safeEmail else{
                return false
            }
            
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            
            // 返回前輟相同 -> results
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"], let name = $0["name"] else{
                return nil
            }
            
            return SearchResult(name: name, email: email)
        })
        
        self.results = results
        self.spinner.dismiss()
        
        // Update UI
        updateUI()
    }
    
    func updateUI(){
        if results.isEmpty{
            noResultLabel.isHidden = false
            tableView.isHidden = true
        }else{
            noResultLabel.isHidden = true
            tableView.isHidden = false
            tableView.reloadData()
        }
    }
}
