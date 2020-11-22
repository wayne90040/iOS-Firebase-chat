//
//  StorageManager.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/21.
//

import Foundation
import FirebaseStorage

/// Allows you to get, fetch, and upload files to firebase  storage

class StorageManager {
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    // fileName -> /images/afraz9-gmail-com_profile_picture.png
    
    /// Upload pic to Firebase Storage and Return completion with Url String to Download
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping(Result<String, Error>) -> Void){
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadate, error in
            guard error == nil else{
                print("Failed to upload ProfilePic to firebase")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else{
                    print("Failed to Get Download URL")
                    completion(.failure(StorageError.failToGetDownloadURL))
                    return
                }
                
                let urlString = url.absoluteString
                print("download URL returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
    
    public func downloadURL(for path: String, completion: @escaping(Result<URL, Error>) -> Void){
        let ref = storage.child(path)
        
        ref.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failToGetDownloadURL))
                return
            }
            completion(.success(url))
        })
    }
    
    // MARK: Error
    
    enum StorageError: Error {
        case failedToUpload
        case failToGetDownloadURL
    }
}
