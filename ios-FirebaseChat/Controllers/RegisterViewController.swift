//
//  RegisterViewController.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/1.
//

import UIKit
import JGProgressHUD
import FirebaseAuth

class RegisterViewController: UIViewController {
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let firstNameText: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "First Name ..."
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.backgroundColor = .secondarySystemBackground
        return textField
    }()
    
    private let lastNameText: UITextField = {
        let textField = UITextField()
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.layer.cornerRadius = 12
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        textField.placeholder = "Last Name ..."
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        textField.backgroundColor = .secondarySystemBackground
        return textField
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
        textField.placeholder = "Email"
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
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "Register"
        view.backgroundColor = .systemBackground
        registerButton.addTarget(self, action: #selector(registerAction), for: .touchUpInside)
        
        // Add Delegate
        firstNameText.delegate = self
        lastNameText.delegate = self
        emailText.delegate = self
        passwordText.delegate = self
        
        // Add Subview
        view.addSubview(scrollView)
        scrollView.addSubview(profileImageView)
        scrollView.addSubview(firstNameText)
        scrollView.addSubview(lastNameText)
        scrollView.addSubview(emailText)
        scrollView.addSubview(passwordText)
        scrollView.addSubview(registerButton)
        
        profileImageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        // Add Tap
        let tap = UITapGestureRecognizer(target: self, action: #selector(changeImageAction))
        profileImageView.addGestureRecognizer(tap)
        
    }
    
    override func viewDidLayoutSubviews() {
        scrollView.frame = view.bounds
        
        let size = scrollView.frame.width / 3
        
        profileImageView.layer.cornerRadius = profileImageView.width / 2
        
        profileImageView.frame = CGRect(x: (scrollView.width - size) / 2,
                                     y: 20,
                                     width: size,
                                     height: size)
        
        firstNameText.frame = CGRect(x: 30,
                                     y: profileImageView.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        
        lastNameText.frame = CGRect(x: 30,
                                    y: firstNameText.bottom + 10,
                                    width: scrollView.width - 60,
                                    height: 52)
        
        emailText.frame = CGRect(x: 30,
                                 y: lastNameText.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        passwordText.frame = CGRect(x: 30,
                                    y: emailText.bottom + 10, width: scrollView.width - 60, height: 52)
        
        registerButton.frame = CGRect(x: 30,
                                   y: passwordText.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
    }
    
    // MARK: - Action
    
    @objc private func changeImageAction(){
        presentProfileSheet()
    }
    
    @objc private func registerAction(){

        guard let firstName = firstNameText.text,
              let lastName = lastNameText.text,
              let email = emailText.text,
              let password = passwordText.text,
              !firstName.isEmpty, !lastName.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertUserError(meg: "Please Enter all Information")
            return
        }
        
        spinner.show(in: view)
        
        DatabaseManager.shared.userExists(with: email, completion: { [weak self] exist in
            guard let strongSelf = self else{
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.dismiss(animated: true, completion: nil)
            }
            
            guard !exist else{
                // Email Exist
                strongSelf.alertUserError(meg: "Email Exists")
                return
            }
            
            // Email not Exist
            Auth.auth().createUser(withEmail: email, password: password) { (result, error) in
                guard result != nil, error == nil else{
                    print("---Creating User Error---")
                    return
                }
                
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                
                let newUser = ChatAppUser(firstName: firstName, lastName: lastName, emailAdress: email)
                DatabaseManager.shared.insertUser(with: newUser, completion: { success in
                    
                    if success{
                        // MARK: Upload Profile Image
                        guard let profileImage = strongSelf.profileImageView.image, let data = profileImage.pngData() else {
                            return
                        }
                        
                        let fileName = newUser.profilePicFileName
                        
                        StorageManager.shared.uploadProfilePic(with: data, fileName: fileName, completion: { result in
                            switch result{
                            case .success(let downloadUrl):
                                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                                
                            case . failure(let error):
                                print("StorageManager Error : \(error)")
                            }
                        })
                    }
                })
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func alertUserError(meg: String){
        let alert = UIAlertController(title: "Error", message: meg, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - UITextFieldDelegate

extension RegisterViewController: UITextFieldDelegate{
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


// MARK: - UIImagePickerControllerDelegate
/// 從相簿選照片或拍照，修改 App 畫面上的照片

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    
    private func presentProfileSheet(){
        let sheet = UIAlertController(title: "Profile Picture",
                                      message: "How would you like to select a picture?",
                                      preferredStyle: .actionSheet)
        
        let takeAction = UIAlertAction(title: "Take Photo", style: .default){ (action) in
            self.presentCamera()
        }
        
        let chooseAction = UIAlertAction(title: "Choose Photo", style: .default) {(action) in
            self.presentPhoto()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                                   
        sheet.addAction(takeAction)
        sheet.addAction(chooseAction)
        sheet.addAction(cancelAction)
        
        present(sheet, animated: true, completion: nil)
    }
    
    private func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    private func presentPhoto(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true, completion: nil)
    }
    
    /// 當使用者拍照或選照片後，將呼叫 UIImagePickerControllerDelegate 的 function imagePickerController(_:didFinishPickingMediaWithInfo:)
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        /// 可從參數 info 取得圖片相關資料。info 的型別是 dictionary，傳入 key .originalImage 可得到圖片。
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        self.profileImageView.image = image
    }
    
    /// Tells the delegate that the user cancelled the pick operation.
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
