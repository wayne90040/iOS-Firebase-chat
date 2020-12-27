//
//  ProfileTableViewCell.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/12/27.
//

import UIKit

class ProfileTableViewCell: UITableViewCell {
    static let identifier = "ProfileTableViewCell"
    
    public func configure(with model: ProfileViewModel){
        self.textLabel?.text = model.title
        
        switch model.profileModelType {
        case .info:
            textLabel?.textAlignment = .left
            selectionStyle = .none
            
        case .logout:
            textLabel?.textAlignment = .center
            textLabel?.textColor = .red
        }
    }
}
