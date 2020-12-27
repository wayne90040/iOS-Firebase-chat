//
//  ProfileViewModel.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/12/27.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel{
    let title: String
    let profileModelType: ProfileViewModelType
    let handler: (() -> Void)?
}
