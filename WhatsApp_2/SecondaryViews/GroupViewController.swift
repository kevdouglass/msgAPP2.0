//
//  GroupViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 7/6/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import ProgressHUD

class GroupViewController: UIViewController {

    
    @IBOutlet var iconTapGesture: UITapGestureRecognizer!
    @IBOutlet weak var cameraAvatarButtonOutlet: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var groupNameTextField: UITextField!
    
    var group: NSDictionary!
    //icon
    var groupIcon: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set camera button to be user interaction enabled
        cameraAvatarButtonOutlet.isUserInteractionEnabled = true
        cameraAvatarButtonOutlet.addGestureRecognizer(iconTapGesture)
        
        setupUI()
        
        // create "invite" bar button
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Invite Users", style: .plain, target: self, action: #selector(self.inviteUsers))]
    }
    

   
    
  //MARK: IBactions
    
    @IBAction func editButtonWasPressed(_ sender: Any) {
        showGroupIconOptions()
        print("edit button was pressed...")
    }
    
    @IBAction func cameraIconWasTapped(_ sender: Any) {
        showGroupIconOptions()
        print("Camera icon was pressed...")

    }
    
    @IBAction func saveButtonWasPressed(_ sender: Any) {
        /// update our "group" once name/ avatar is edited/changed
        var withValues : [String : Any]!
        /// set our dictionary, can change one or both items
        if groupNameTextField.text != "" {
            withValues = [kNAME : groupNameTextField.text!] /// user has updated the name
        } else {
            /// the user is trying to save a group chat without SAVING a group name/ subject id
            ProgressHUD.showError("Group subject is required!")
            return
        }
        
        // check the avatar
        let avatarData = cameraAvatarButtonOutlet.image?.jpegData(compressionQuality: 0.7)!
        // can also use UIJPEGRepresentation(cameraAvatarButtonOutlet.image" for avatarData
        let avatarString = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        withValues = [kNAME : groupNameTextField.text!, kAVATAR : avatarString!]
        // update our GROUP
        Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)
        // NOW -> since group name/ group avatar has changed, (someone has renamed the group) we need to change the last RECENT msg to match uptaded name/avatar
        withValues = [kWITHUSERFULLNAME : groupNameTextField.text!, kAVATAR : avatarString!]
        ///update most recent MESSAGE for ALL members of the new GroupChat
        updateExistingRecentWithNewValues(chatRoomId: group[kGROUPID] as! String, members: group[kMEMBERS] as! [String], withValues: withValues)
        self.navigationController?.popToRootViewController(animated: true)    /// when you click "Save" button "popToRoot" takes us back to "Recent Chat" view controller as it is the "Root" in this case, if wanted to go ONLY to the "JSQMessage" then only popViewController(animated: true), however this does not update the group name until user goes into "Chats" viewController then back to JSQmess. VC
    }
    

    
    
    @objc func inviteUsers() {
        // create a seperate table view for inviting users
        /// called every time user "invites" users
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "inviteUsersTableView") as! InviteUsersTableViewController
        
        userVC.group = group
        self.navigationController?.pushViewController(userVC, animated: true)
    }
    
    
    
    
    
    //MARK: Helpers
    
    func setupUI() {
        self.title = "Group"
        
        groupNameTextField.text = group[kNAME] as? String
        
        imageFromData(pictureData: group[kAVATAR] as! String) { (avatarImage) in
            
            if avatarImage != nil {
                self.cameraAvatarButtonOutlet.image = avatarImage!.circleMasked
            }
        }
    }
    
    
    
    
    func showGroupIconOptions() {
        /// setup option alert menu
        let optionMenu = UIAlertController(title: "Choose Group Icon", message: nil, preferredStyle: .actionSheet)
        let takePhotoAction = UIAlertAction(title: "Take/Choose Photo", style: .default) { (alert) in
            /// will have code to take a picture >> here <<
            print("Camera")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (alert) in
            
        }
        
        if groupIcon != nil {
            let resetAction = UIAlertAction(title: "Reset", style: .default) { (alert) in
                self.groupIcon = nil
                self.cameraAvatarButtonOutlet.image = UIImage(named: "cameraIcon")
                self.editButton.isHidden = true
                
            }
            optionMenu.addAction(resetAction)
        }
        
        optionMenu.addAction(takePhotoAction)
        optionMenu.addAction(cancelAction)
        
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            if let currentPopoverPresentationController = optionMenu.popoverPresentationController {
                
                currentPopoverPresentationController.sourceView = editButton
                currentPopoverPresentationController.sourceRect = editButton.bounds
                
                currentPopoverPresentationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        } else {
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    
}
