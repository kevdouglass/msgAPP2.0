//
//  NewGroupViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 7/6/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import ProgressHUD

class NewGroupViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
GroupMemberCollectionViewCellDelegate {

    
    @IBOutlet weak var editAvatarButtonOutlet: UIButton!
    @IBOutlet weak var groupIconImageView: UIImageView!
    @IBOutlet weak var groupSubjectTextField: UITextField!
    @IBOutlet weak var participantsLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var groupIconTapGesture: UITapGestureRecognizer!
    // vars to hold # of users and image of avatar
    var memberIds: [String] = []
    var allMembers: [FUser] = []
    var groupIcon: UIImage?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        groupIconImageView.isUserInteractionEnabled = true
        groupIconImageView.addGestureRecognizer(groupIconTapGesture)
        
        updateParticpantsNumberLabel() ///update # of users and set "Create button
        
    }
    
    //MARK: CollectionViewDatasource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allMembers.count
    }
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! GroupMemberCollectionViewCell
        
        cell.delegate = self
        cell.generateCell(user: allMembers[indexPath.row], indexPath: indexPath)
        
        return cell
    }
    
    
    
    
    
    //MARK: IBActions
    @objc func createButtonPressed(_ sender: Any) {
        /// called every time we click on the "CreaTE" button
        if groupSubjectTextField.text != "" {
            // create our Group chat
            // add our current user to group
            memberIds.append(FUser.currentId()) /// allows us to display each user
           
            /// save "group" icon to *FireBase*
            let avatarDataIcon = UIImage(named: "groupIcon")!.jpegData(compressionQuality: 0.7 )!
            var avatar = avatarDataIcon.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            
            /// check if user has chosen a "group icon"
            if groupIcon != nil {
                /// save "group" icon to *FireBase*
                let avatarData = groupIcon!.jpegData(compressionQuality: 0.7 )!
                avatar = avatarData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            }
            
            let groupUUId = UUID().uuidString
            
            /*
 create "Group" object
 */
            let group = Group(groupId: groupUUId, subject: groupSubjectTextField.text!, ownerId: FUser.currentId(), members: memberIds, avatarIcon: avatar)
            
            group.saveGroup()               /// save *Group* to fireStore
            
            // after saving Group to firestore we want to start Chating in our chatView
            ///CREATE "GROUP/Recent" message
            startGroupChat(group: group)
            /// go to chatView
            let chatVC = ChatViewController()
            chatVC.titleName = group.groupDictionary[kNAME] as? String
            chatVC.memberIds = group.groupDictionary[kMEMBERS] as? [String]
            chatVC.membersToPush = group.groupDictionary[kMEMBERS] as? [String]
            
            chatVC.chatRoomId = groupUUId
            chatVC.isGroup = true
            chatVC.hidesBottomBarWhenPushed = true
            
            ///present the "CHAT" view controller
            self.navigationController?.pushViewController(chatVC, animated: true)
            
        } else {
            // show error to user
            ProgressHUD.showError("Subject line is required!")
        }
        print("Create button tapped...")
    }
    
    
    @IBAction func groupIconWasTapped(_ sender: Any) {
        showIconOptions()   // allow user to choose
        //print("Group icon was tapped...")
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        ///allow user to take photo or use a pre-existing photo
         showIconOptions()   // allow user to choose
        //print("Edit button was pressed...")
        
    }
    
    
    //MARK: GroupMemberCeollectionViewCellDelegate
    func didClickDeleteButton(indexPath: IndexPath) {
        ///when user clicks delete -> click "remove" from this array
        allMembers.remove(at: indexPath.row)    // FUser object
        memberIds.remove(at: indexPath.row)        // FUser objects member Id these are both always in sync
        
        collectionView.reloadData()
        updateParticpantsNumberLabel()
    
    }
    
    //MARK: Helper functions
    
    func showIconOptions() {
        let optionMenu = UIAlertController(title: "Choose a group icon", message: nil , preferredStyle: .actionSheet)
        
        let takePhotoAction = UIAlertAction(title: "Choose/Take Photo", style: .default) { (alert) in
            
            print("camera")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert) in
            
            //print("cancel")
        }
        
        
        // show reset button incase the group button is already presented
        if groupIcon != nil {
            let resetAction = UIAlertAction(title: "Reset", style: .default) { (alert) in
                
                self.groupIcon = nil
                // set group image view with camera
                self.groupIconImageView.image = UIImage(named: "cameraIcon")
                self.editAvatarButtonOutlet.isHidden = true
                print("Reset group icon")
            }
            optionMenu.addAction(resetAction) /// add "reset" action incase it is made
        }
        
        optionMenu.addAction(takePhotoAction)   /// add actions
        optionMenu.addAction(cancelAction)
        
        
        
        /// check if device is iPad or iPhone so the view will not crash
        if ( UI_USER_INTERFACE_IDIOM() == .pad  ) {
            if let currentPopoverPresentationController = optionMenu.popoverPresentationController {
                
                currentPopoverPresentationController.sourceView = editAvatarButtonOutlet
                currentPopoverPresentationController.sourceRect = editAvatarButtonOutlet.bounds
                
                currentPopoverPresentationController.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
            }
        } else {
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    
    func updateParticpantsNumberLabel() {
        ///every time we tap "delete" we want to update the # of participants
        participantsLabel.text = "PARTICIPANTS: \(allMembers.count)"
        
        // update/ set buttons to "Create" group chat
        let createButton = UIBarButtonItem(title: "Create", style: .plain, target: self, action: #selector(self.createButtonPressed))
        self.navigationItem.rightBarButtonItems = [createButton]
        
        self.navigationItem.rightBarButtonItem?.isEnabled = (allMembers.count > 0)
    }
    
   
    
}
