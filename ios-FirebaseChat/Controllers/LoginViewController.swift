//
//  LoginViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/1.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
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
    
    private let fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        /// permissions -  取得 Facebook 資訊 email,
        button.permissions = ["email,public_profile"]
        return button
    }()
    
    /// 按下會觸發 GIDSignInDelegate - didSignInFor
    private let googleLoginButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 註冊為觀察者
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else{
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        title = "Log In"
        view.backgroundColor = .white
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(registerAction))
        
        loginButton.addTarget(self, action: #selector(loginAction), for: .touchUpInside)
        
        GIDSignIn.sharedInstance()?.presentingViewController = self
        
        // MARK: Delegate
        emailText.delegate = self
        passwordText.delegate = self
        fbLoginButton.delegate = self
        
        // MARK: Add SubViews
        view.addSubview(scrollView)
        scrollView.addSubview(logoImageView)
        scrollView.addSubview(emailText)
        scrollView.addSubview(passwordText)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(fbLoginButton)
        scrollView.addSubview(googleLoginButton)
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
        
        fbLoginButton.frame = CGRect(x: 30,
                                     y: loginButton.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        googleLoginButton.frame = CGRect(x: 30,
                                     y: fbLoginButton.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
    }
    
    deinit{
        if let observer = loginObserver{
            NotificationCenter.default.removeObserver(observer)
        }
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
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard result != nil, error == nil else {
                print("Fail to login with email: \(email)")
                return
            }
            
            // Get firstName & lastName From Database
            let safeEmail = DatabaseManager.toSafeEmail(with: email)
            
            // Fetch
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result{
                case .success(let date):
                    guard let userData = date as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else{
                        return
                    }
                    
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                    
                case .failure(let error):
                    print("Failed to Get Data with error: \(error)")
                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")
            
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
}


// MARK: - UITextFieldDelegater

extension LoginViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


// MARK: - Facebook Login LoginButtonDelegate

extension LoginViewController: LoginButtonDelegate{
    
    /// loginButtonDidLogOut 為登出後會呼叫之函式
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        
        guard let token = result?.token?.tokenString else {
            print("Failed Log in with Facebook")
            return
        }
        
        // MARK: 取得帳號資訊
        let request = GraphRequest(graphPath: "me",
                                   parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                   tokenString: token,
                                   version: nil,
                                   httpMethod: .get)
        
        request.start(completionHandler: { (respone, result, error) in
            guard let result = result as? [String: Any], error == nil else{
                print("Failed to make facebook GraphRequest")
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let pic = result["picture"] as? [String: Any],
                  let data = pic["data"] as? [String: Any],
                  let pictureURL = data["url"] as? String else{
                print("Failed to get facebook result")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
            
            // MARK: 比對 Firebase Database 有無重複資料
            DatabaseManager.shared.userExists(with: email, completion: { exist in
                /// 不存在 就寫入資料庫
                if !exist{
                    let newUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: email)
                        
                    DatabaseManager.shared.insertUser(with: newUser, completion: { success in
                        if success{
                            
                            // Get URL
                            guard let url = URL(string: pictureURL) else{
                                print("Failed with String to Url ")
                                return
                            }
                            
                            print("Downloading data from facebook image")
                            
                            // Get Data
                            URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
                                guard let data = data else{
                                    print("Failed to Get Data From Facebook")
                                    return
                                }
                                
                                print("Got data from Facebook")
                                
                                // Upload Image to Firebase
                                let fileName = newUser.profilePicFileName
                                StorageManager.shared.uploadProfilePic(with: data, fileName: fileName, completion: { result in
                                    switch result{
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                        
                                    case .failure(let error):
                                        print("Storage maanger error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
            })
            
            // MARK: Firebase Login
            
            // 用 AccessToken.current!.tokenString 產生 Firebase 登入需要的 credential
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential){ [weak self] (resultAuth, error) in
                guard let strongSelf = self else{
                    return
                }
                
                guard resultAuth != nil, error == nil else{
                    print("Facebook credential login failed")
                    return
                }
                print("Successful Log in with Facebook")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        })
    }
}
