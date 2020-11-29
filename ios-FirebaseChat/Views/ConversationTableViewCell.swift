//
//  ConversationTableViewCell.swift
//  ios-FirebaseChat
//
//  Created by Wei Lun Hsu on 2020/11/29.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(userImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(messageLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        
        nameLabel.frame = CGRect(x: userImageView.right + 10,
                                 y: 10,
                                 width: contentView.width - 20 - userImageView.width,
                                 height: (contentView.height - 20) / 2)
        
        messageLabel.frame = CGRect(x: userImageView.right + 10,
                                    y: nameLabel.bottom + 10,
                                    width: contentView.width - 20 - userImageView.width,
                                    height: (contentView.height - 20) / 2)
    }
    
    public func configure(with model: Conversation){
        let imagePath = "images/\(model.otherUserEmail)_profile_picture.png"
        
        // Download Profile Image
        StorageManager.shared.downloadURL(for: imagePath, completion: { [weak self] reslt in
            switch reslt{
            case .success(let url):
                
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
                
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        })
        
        nameLabel.text = model.name
        messageLabel.text = model.latestMessage.text
    }
/*
    // 只有當你的單元格來自故事板或XIB時才會調用
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
*/
}
