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

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        currentAuth()
    }
    
    
    // MARK: - Action
    
    /// 確認有無登入紀錄
    private func currentAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        }
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
