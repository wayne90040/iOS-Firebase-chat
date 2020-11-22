//
//  NewConversationViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/20.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var hasFetched = false
    
    private var users = [[String: String]]()
    private var results = [[String: String]]()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search For User"
        return searchBar
    }()
    
    // result
    private let tableView: UITableView = {
        let tableview = UITableView()
        tableview.isHidden = true
        tableview.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        
        return cell
    }
}


// MARK: - UISearchBarDelegate

extension NewConversationViewController: UISearchBarDelegate{
    
    /// 搜尋觸發事件,點選虛擬鍵盤上的search按鈕時觸發此方法
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        print("searchBarSearchButtonClicked")
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
        guard hasFetched else { return }
        
        var results: [[String: String]] = self.users.filter({
            guard let name = $0["name"]?.lowercased() else{
                return false
            }
            
            // 返回前輟相同 -> results
            return name.hasPrefix(term.lowercased())
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
