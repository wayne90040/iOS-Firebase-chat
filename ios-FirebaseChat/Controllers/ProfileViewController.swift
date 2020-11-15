//
//  ProfileViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/13.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit

class ProfileViewController: UIViewController {
    
    @IBOutlet var mainTableView: UITableView!
    
    let items = ["Log Out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        mainTableView.delegate = self
        mainTableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

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
