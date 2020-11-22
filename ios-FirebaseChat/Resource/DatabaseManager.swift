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
    
    static func toSafeEmail(with email: String) -> String{
        var result = email.replacingOccurrences(of: ".", with: "-")
        result = result.replacingOccurrences(of: "@", with: "-")
        return result
    }
    
    /// Insert New uesr to Database
    public func insertUser(with user: ChatAppUser, completion: @escaping(Bool) -> Void){
        database.child(user.safeEmail).setValue(["fisrt_name": user.firstName, "last_name": user.lastName], withCompletionBlock: { error, _ in
            guard error == nil else {
                print("Failed to Insert New user to Database")
                completion(false)
                return
            }
            
            // 寫入 user array - > 搜尋使用者
            /// observeSingleEvent 只触发一次事件回调。这对于读取只需要加载一次且不希望之后更改的数据非常有用。
            self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var usersCollection = snapshot.value as? [[String: String]]{
                    // append user to user Array
                    
                    let newUser = ["name": user.firstName + " " + user.lastName, "email": user.safeEmail]
                    usersCollection.append(newUser)
                    
                    self.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                    
                }else{
                    // create user Array
                    let newCollection: [[String: String]] = [["name": user.firstName + " " + user.lastName, "email": user.safeEmail]]
                    self.database.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
                        
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        completion(true)
                    })
                }
            })
        })
    }
    
    /// Check if user exist
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
    
    /// Get Firebase users array
    public func getAllUsers(completion: @escaping(Result<[[String: String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let result = snapshot.value as? [[String: String]] else {
                completion(.failure(DatabaseManagerError.failedToFetch))
                return
            }
            
            completion(.success(result))
        })
    }
    
    public enum DatabaseManagerError: Error{
        case failedToFetch
    }
}



