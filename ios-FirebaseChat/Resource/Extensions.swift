//
//  Extensions.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/1.
//

import Foundation
import UIKit

// MARK: - UIView

extension UIView{
    
    public var width: CGFloat{
        return frame.size.width
    }
    
    public var height: CGFloat{
        return frame.size.height
    }
    
    public var top: CGFloat{
        return frame.origin.y
    }
    
    public var bottom: CGFloat{
        return frame.size.height + frame.origin.y
    }
    
    public var left: CGFloat{
        return frame.origin.x
    }
    
    public var right: CGFloat{
        return frame.size.width + frame.origin.x
    }
}

// MARK: - Notification.Name

extension Notification.Name{
    /// Notificaiton  when user logs in
    static let didLogInNotification = Notification.Name("didLogInNotification")
}
