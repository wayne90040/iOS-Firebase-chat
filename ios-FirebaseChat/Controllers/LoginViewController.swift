//
//  LoginViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/1.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

// final class 防止被覆寫

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailText: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue // 鍵盤上 Return 樣式
        textField.keyboardType = .emailAddress
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Email ..."
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        return textField
    }()
    
    private let passwordText: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Password"
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.leftViewMode = .always
        textField.backgroundColor = .secondarySystemBackground
        textField.isSecureTextEntry = true
        return textField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = "Log In"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(registerAction))
        
        loginButton.addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        
        // delegate
        emailText.delegate = self
        passwordText.delegate = self
        
        // Add SubViews
        view.addSubview(scrollView)
        scrollView.addSubview(logoImageView)
        scrollView.addSubview(emailText)
        scrollView.addSubview(passwordText)
        scrollView.addSubview(loginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size = scrollView.frame.width / 3
        
        logoImageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                     y: 20,
                                     width: size,
                                     height: size)
        
        emailText.frame = CGRect(x: 30,
                                 y: logoImageView.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        passwordText.frame = CGRect(x: 30,
                                    y: emailText.bottom + 10, width: scrollView.width - 60, height: 52)
        
        loginButton.frame = CGRect(x: 30,
                                   y: passwordText.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
    }
    
    // MARK: - Action
    
    @objc private func registerAction(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func loginAction(){
        emailText.resignFirstResponder()
        passwordText.resignFirstResponder()
        
        guard let email = emailText.text, let password = passwordText.text, !email.isEmpty, !password.isEmpty else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // Firebase Log In
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
            guard let strongSelf = self else{
                return
            }
            
            guard let userResult = result, error == nil else {
                print("Fail to login with email: \(email)")
                return
            }
            
            
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
        
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Error",
                                      message: "Please Enter all Information",
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
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


// MARK: - UITextFieldDelegater

extension LoginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
