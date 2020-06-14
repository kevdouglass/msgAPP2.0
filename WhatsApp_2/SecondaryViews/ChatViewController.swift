//
//  ChatViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/14/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import ProgressHUD
import IQAudioRecorderController
import IDMPhotoBrowser
import AVFoundation
import AVKit    //MARK: picture messages
import FirebaseFirestore

class ChatViewController: JSQMessagesViewController{

    
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    
    
    
    
    // FIX for Iphone x (10)
    override func viewDidLayoutSubviews() {
        perform(Selector("jsq_updateCollectionViewInsets"))
    }
    // end of iPhone x - Fix
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        // create a BUTTON
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        // Do any additional setup after loading the view. senderID and senderDisplay name must be ran otherwise chat will CRASH
        self.senderId = FUser.currentId()
        self.senderDisplayName = FUser.currentUser()!.firstname
        
        // FIX for Iphone x (10)
        let constraints = perform(Selector("toolbarBottomLayoutGuide"))?.takeUnretainedValue() as! NSLayoutConstraint
        
        
        //MARK: Set priority for messages chatView constrain
        constraints.priority = UILayoutPriority(rawValue: 1000) // top priority
        self.inputToolbar.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        // end of iPhone x - Fix
        
        
        //MARK: Custom send button [ Microphone Button ]
        self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)
        self.inputToolbar.contentView.rightBarButtonItem.setTitle("", for: .normal)
    }
    
    
    
    
    //MARK: JSQMessages Delegate funtions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("accessory pressed")
        //display option Menu
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)  // OPTION menu
        // chreate 5 functions
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            
            print("Camera")
            
            
        }
        
        
        //....PHOTO Library
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            print("Photo Library")
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            print("Video Library")
        }
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            print("Share Location")
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            print("Video Library")
        }
        
        // .... set photo
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        //..... set optionMenu
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(shareVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareLocation)
        
        // ..... present the option Menu
        // IF YOU DONT WANT IPAS OPTION FOR VIEW >> self.present(optionMenu, animated: true, completion: nil)   // will Crash on Ipad
        
        //MARK: for ipad not to crash + needed for Appstore
        if (UI_USER_INTERFACE_IDIOM() == .pad)
        {
            if let currentPopoverpresentioncontroller = optionMenu.popoverPresentationController {
                
                currentPopoverpresentioncontroller.sourceView = self.inputToolbar.contentView.leftBarButtonItem
                currentPopoverpresentioncontroller.sourceRect = self.inputToolbar.contentView.leftBarButtonItem.bounds
                
                currentPopoverpresentioncontroller.permittedArrowDirections = .up
                self.present(optionMenu, animated: true, completion: nil)
                
            }
        } else {
            self.present(optionMenu, animated: true, completion: nil)
        }
    }
    
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        print("Presed send...")
        // if we have a Text the Microphone should turn into a "Ttext" button
        // whether we check micropohne or "text msg"
        if text != "" {
            // we have something in text or user has pressed microphone bjtton
            print(text!)
            // once we press our send we want to update "send" to microphone
            updateSendButton(isSend: false)
        } else {
            print("Audio message")
        }
    }
    
    
    
    
    
    
    
    
    @objc func backAction() {
        //print("Pressed Back")
        self.navigationController?.popViewController(animated: true)
    
    }
    
    //MARK: Custom Send Button
    
    //MAR
    override func textViewDidChange(_ textView: UITextView) {
        if textView.text != "" {
            updateSendButton(isSend: true)
        } else {
            updateSendButton(isSend: false)
        }
    }
    
    //MARK: Custom Send Button - update
    func updateSendButton(isSend: Bool) {
        //checking if microphone or sending msg
        if isSend {
            // replace imagere
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            // set back to micropohne
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)

        }
    }

}
