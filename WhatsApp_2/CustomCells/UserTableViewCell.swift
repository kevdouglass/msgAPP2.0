//
//  UserTableViewCell.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/7/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit

protocol UserTableViewCellDelegate: UITableViewCell {
    func didTapAvatarImage(indexPath: IndexPath)
    
}

class UserTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    var indexPath: IndexPath!
    var tapGestureRecognizer = UITapGestureRecognizer() // user tap on #IMG
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // add gesture recognize if usr presses image
       // tapGestureRecognizer.addTarget(self, action: #selector(self.avatarTap)) // user tap on img
//tapGestureRecognizer.addTarget(self, action: #selector(self.avatarTap))
        tapGestureRecognizer.addTarget(self, action: #selector(self.avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGestureRecognizer)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    
    //MARK: Create a *Cell
    func generateCellWith(fUser: FUser, indexPath: IndexPath) {
        self.indexPath = indexPath
        
        self.fullNameLabel.text = fUser.fullname
        
        if fUser.avatar != "" {
            imageFromData(pictureData: fUser.avatar) { (avatarImage) in
                // once avatar image is ready this will fire it up
                
                if avatarImage != nil {
                   // self.avatarImageView.image = avatarImage!.circleMasked
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    // check if there was avatar tap for gesture recognizer
    @objc func avatarTap() {
        print("Avatar tap at \(indexPath)")
        print("Avatar tap at \(indexPath)")
    }
    
}
