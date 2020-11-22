//
//  ProfileViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/13.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import SDWebImage

final class ProfileViewController: UIViewController {
    
    @IBOutlet var mainTableView: UITableView!
    
    let items = ["Log Out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // delegate
        mainTableView.delegate = self
        mainTableView.dataSource = self
        
        mainTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        mainTableView.tableHeaderView = createTableHeaderView()

    }
    
    func createTableHeaderView() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            print("Failed to Get Email by Userdefault")
            return nil
        }
        
        let safeEmail = DatabaseManager.toSafeEmail(with: email)
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/" + fileName
        
        print(path)
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        
        headerView.backgroundColor = .link
        
        let imageView = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2, y: 75, width: 150, height: 150))
        
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width / 2
        
        headerView.addSubview(imageView)
        
        // Download Image
        StorageManager.shared.downloadURL(for: path, completion: { result in
            switch result{
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)
            
            case .failure(let error):
                print("Failed to get download url: \(error)")
            }
        })
        
        return headerView
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    
        let actionSheet  = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive){ [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            
            // Facebook LogOut
            FBSDKLoginKit.LoginManager().logOut()
            
            // Firebase Log Out
            do{
                try FirebaseAuth.Auth.auth().signOut()
                let vc = LoginViewController()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                
                strongSelf.present(nav, animated: true, completion: nil)
            }catch{
                print("Log Out Error")
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        actionSheet.addAction(logoutAction)
        actionSheet.addAction(cancelAction)
        present(actionSheet, animated: true)
    }
}
