//
//  ProfileViewTableViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/10/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import ProgressHUD


class ProfileViewTableViewController: UITableViewController {

    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phonenumberLabel: UILabel!
    
    
    @IBOutlet weak var messageButtonOutlet: UIButton!
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var blockButtonOutlet: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var user: FUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: when fUser opens View -> Display fUser_info
        setupUI()

    }

    
    //MARK: - IBactions [ fUser profile page ]
    
    @IBAction func callButtonWasPressed(_ sender: Any) {
        print("call user \(user!.fullname)")
    
    }
    
    @IBAction func chatButtonWasPressed(_ sender: Any) {
    
        
        //MARK: Check if it is a blocked user
        if !checkBlockedStatus(withUser: user!) {
            
            //MARK: start private chat
            let chatVC = ChatViewController()
            chatVC.titleName = user!.firstname
            chatVC.membersToPush = [FUser.currentId(), user!.objectId]
            chatVC.memberIds = [FUser.currentId(), user!.objectId]
            chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: user!)
            
            chatVC.isGroup = false
            chatVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(chatVC, animated: true)
            //startPrivateChat(user1: FUser.currentUser()!, user2: user)
        } else {
            ProgressHUD.showError("This user is not available for Chat!")
        }
        print("chat with user \(user!.fullname)")
    }
    
    
    
    @IBAction func blockUserButtonWasPressed(_ sender: Any) {
    print("Block user Pressed")
        // access current users, blocked users
        var currentBlockIds = FUser.currentUser()!.blockedUsers
        
        //MARK: if user is in blockList -> we want to be able to remove the fUser
        if currentBlockIds.contains(user!.objectId) {
            
            //MARK: find where in the array contains this user
            let blocked_index = currentBlockIds.index(of: user!.objectId)!
            currentBlockIds.remove(at: blocked_index)
        } else {
            //MARK: add the user to the blockedUser array
            currentBlockIds.append(user!.objectId)
        }
        
        //MARK: update users in FIreStore
        updateCurrentUserInFirestore(withValues: [kBLOCKEDUSERID : currentBlockIds]) { (error) in
            
            if error != nil {
                print("error \(error!.localizedDescription)")
                return
            }
            // update button outlet
            self.updateBlockStatus()
            /// may not need this ---->>>>  blockButtonOutlet.reloadInputViews()
        }
        
        blockUser(userToBlock: user!)
       
        
    
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3    // there are 3 sections on Profile
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1 // there is only in ea. section
    }

    //MARK: remove title-section in table View
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    //MARK: initialize an empty VIew for clean title
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    //MARK: set 'height' for each tableVIew Header section
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // check if section is at index[0] - there is no header at index 0
        if section == 0 {
            return 0
        } else {
            // set the TableView header width to 30
            return 30
        }
    }
    
    
    
    
    //MARK: Setup UI
    func setupUI() {
        // pass user to view
        if user != nil {
            // if we have a user ->
            self.title = "Profile"
            
            fullNameLabel.text = user!.fullname
            phonenumberLabel.text = user!.phoneNumber
            
            // update BLock/ unBlock user
            updateBlockStatus()
            
            // send the fUser avatar image to the UIView
            imageFromData(pictureData: user!.avatar) { (avatarImage) in
                if avatarImage != nil {
                    // make the user image rounded
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    
    
    //MARK: block user from other users
    func updateBlockStatus() {

        // if it is not current user
        // hide + show buttons
        if user!.objectId != FUser.currentId() {
            blockButtonOutlet.isHidden = false
            messageButtonOutlet.isHidden = false
            callButtonOutlet.isHidden = false
        } else {
            blockButtonOutlet.isHidden = true
            messageButtonOutlet.isHidden = true
            callButtonOutlet.isHidden = true
        }
        
        //MARK: if user is in our blockedList
        if FUser.currentUser()!.blockedUsers.contains(user!.objectId) {
            
            blockButtonOutlet.setTitle("Unblock User", for: .normal)
           // tableView.reloadData()
                // blockButtonOutlet.reloadInputViews()

        } else {
            blockButtonOutlet.setTitle("Block User", for: .normal)
            tableView.reloadData()

        }
        
    }
    
}
