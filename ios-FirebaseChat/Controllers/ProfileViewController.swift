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
import GoogleSignIn

final class ProfileViewController: UIViewController {
    
    @IBOutlet var mainTableView: UITableView!
    
    var profileViewModels = [ProfileViewModel]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        profileViewModels = createProfileViewModels()
        
        // delegate
        mainTableView.delegate = self
        mainTableView.dataSource = self
        
        mainTableView.register(ProfileTableViewCell.self, forCellReuseIdentifier: ProfileTableViewCell.identifier)
        mainTableView.tableHeaderView = createTableHeaderView()
    }
    
    func createProfileViewModels() ->  [ProfileViewModel]{
        var result = [ProfileViewModel]()
        
        result.append(ProfileViewModel(title: "Name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Name")",
                                     profileModelType: .info, handler: nil))
        
        result.append(ProfileViewModel(title: "Email: \(UserDefaults.standard.value(forKey: "email") as? String ?? "No Email")",
                                     profileModelType: .info, handler: nil))
        
        result.append(ProfileViewModel(title: "Log out", profileModelType: .logout, handler: { [weak self] in
            guard let strongSelf = self else{
                return
            }
            
            let sheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
            
            sheet.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                // remove userdefaults
                UserDefaults.standard.setValue(nil, forKey: "email")
                UserDefaults.standard.setValue(nil, forKey: "name")
                
                // Facebook Logout
                FBSDKLoginKit.LoginManager().logOut()
                
                // Google Logout
                GIDSignIn.sharedInstance()?.signOut()
                
                // Firebase Logout
                do{
                    try FirebaseAuth.Auth.auth().signOut()
                    
                    // 回到登入頁面
                    let vc = LoginViewController()
                    let nav = UINavigationController(rootViewController: vc)
                    nav.modalPresentationStyle = .fullScreen
                    strongSelf.present(nav, animated: true, completion: nil)
                    
                }catch{
                    print("Failed to log out")
                }
            }))
            
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            strongSelf.present(sheet, animated: true, completion: nil)
        }))
        
        return result
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
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.width, height: 300))
        
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
        return profileViewModels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        let profileViewModel = profileViewModels[indexPath.row]
        
        cell.configure(with: profileViewModel)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        profileViewModels[indexPath.row].handler?()
    }
}
