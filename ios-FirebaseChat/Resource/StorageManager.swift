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
    
    /// Upload pic to Firebase Storage and Return completion with Url String to Download
    public func uploadProfilePic(with data: Data, fileName: String, completion: @escaping(Result<String, Error>) -> Void){
        
        // fileName -> /images/afraz9-gmail-com_profile_picture.png
        
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadate, error in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else{
                print("Failed to upload ProfilePic to firebase")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
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
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePhote(with data: Data, fileName: String, completion: @escaping(Result<String, Error>) -> Void){
        
        // 1. UpLoad to Firebase
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else{
                print("Failed to Upload Message Photo")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            // 2. Get URL From Firebase
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
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
    
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping(Result<String, Error>) -> Void){
        // 1. Upload to Firebase
        storage.child("message_videos/\(fileName)").putFile(from: fileUrl, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else{
                // Failed
                print("Failed to Upload Message Video")
                completion(.failure(StorageError.failedToUpload))
                return
            }
            
            // 2. if Uploade Success, then Get Url
            self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
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
