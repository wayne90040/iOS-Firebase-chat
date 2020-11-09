//
//  DatabaseManager.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/9.
//

import Foundation
import FirebaseDatabase

class DatabaseManager{
    static let shared = DatabaseManager()
    private let database = Database.database().reference()
    
    public func insertUser(with user: ChatAppUser){
        database.child(user.emailAdress).setValue(["fisrt_name": user.firstName, "last_name": user.lastName])
    }

}



