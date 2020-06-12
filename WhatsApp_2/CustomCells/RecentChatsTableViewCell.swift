//
//  RecentChatsTableViewCell.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/11/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit

protocol RecentChatsTableViewCellDelegate {
    func didTapAvatarImage(indexPath: IndexPath)
}

class RecentChatsTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageCounterLabel: UILabel!
    
    @IBOutlet weak var messageCounterBackground: UIView!
    
    var indexPath: IndexPath!
    let tapGesture = UITapGestureRecognizer()
    //MARK: make instance of delegate
    var delegate: RecentChatsTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        // circle corner radius for message counter..
        messageCounterBackground.layer.cornerRadius = messageCounterBackground.frame.width / 2
        
        //MARK: add tap gesture recognizer on avatar image for chats
        tapGesture.addTarget(self, action: #selector(self.avatarTap))
        avatarImageView.isUserInteractionEnabled = true
        avatarImageView.addGestureRecognizer(tapGesture)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
    //MARK: Generate Cell
    func generateCell(recentChat: NSDictionary, indexPath: IndexPath) {
        
        
        self.indexPath = indexPath
       
        
        self.nameLabel.text = recentChat[kWITHUSERFULLNAME] as? String //optional -> incase no value, will not run
        self.lastMessageLabel.text = recentChat[kLASTMESSAGE] as? String
        self.messageCounterLabel.text = recentChat[kCOUNTER] as? String
        
        // check if there is an Avatar
        if let avatarString = recentChat[kAVATAR] {
            imageFromData(pictureData: avatarString as! String) { (avatarImage) in
                
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
        // check the # of unread messsages/ chats
        if recentChat[kCOUNTER] as! Int != 0 {
            // we have unread message
            self.messageCounterLabel.text = "\(recentChat[kCOUNTER] as! Int)"
            self.messageCounterBackground.isHidden = false
            self.messageCounterLabel.isHidden = false
        } else {
            // counter is 0, so hide the counter
            self.messageCounterBackground.isHidden = true
            self.messageCounterLabel.isHidden = true
        }
        
        var date: Date!
        
        if let created = recentChat[kDATE] {
            if (created as! String).count != 14 {
                // make sure the date string in Firebase is 14 characters long
                // then create new Date
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            // no recent chat saved
            date = Date()
        }
        
        self.dateLabel.text = timeElapsed(date: date)
    }
    
    @objc func avatarTap() {
        print("avatar tap at indexpath \(indexPath)")
        delegate?.didTapAvatarImage(indexPath: indexPath)
    }
    
    
    

}
