//
//  GroupMemberCollectionViewCell.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 7/6/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit

protocol GroupMemberCollectionViewCellDelegate {
    
    func didClickDeleteButton(indexPath: IndexPath)
    
}


class GroupMemberCollectionViewCell: UICollectionViewCell {
    
    var indexPath: IndexPath!
    var delegate: GroupMemberCollectionViewCellDelegate?
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    
    func generateCell(user: FUser, indexPath: IndexPath) {
        
        self.indexPath = indexPath
        nameLabel.text = user.firstname
        
        if user.avatar != "" {
            imageFromData(pictureData: user.avatar) { (avatarImage) in
                
                if avatarImage != nil {
                    // we have a avatar image
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
         
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        //notify delegate when "Delete" button pressed
        delegate!.didClickDeleteButton(indexPath: indexPath)
    }
    
    
    
}
