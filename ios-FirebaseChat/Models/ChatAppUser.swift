//
//  ChatAppUser.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/9.
//

import Foundation

struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAdress: String
    
    var safeEmail: String{
        var safeEmail = emailAdress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
