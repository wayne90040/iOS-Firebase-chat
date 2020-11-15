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
        
        database.child(user.safeEmail).setValue(["fisrt_name": user.firstName, "last_name": user.lastName])
        
    }
    
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            
            guard snapshot.value as? [String: Any] != nil else{
                completion(false)
                return
            }
            
            completion(true)
        })
    }

}



