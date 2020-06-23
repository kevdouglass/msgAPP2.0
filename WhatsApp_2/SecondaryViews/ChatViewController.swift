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

//class ChatViewController: JSQMessagesViewController{
// add delegates for UIKit/ imagePicker
class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // provide to chat viewVC (recent chats -> chatsView())
    var chatRoomId: String!
    var memberIds: [String]!
    var membersToPush: [String]!
    var titleName: String!
    var isGroup: Bool?
    var group: NSDictionary?
    var withUsers: [FUser] = [] // instantiate empty array of FUser

    
    
    /// NEW CHAT Listenerz
    var typingListener: ListenerRegistration?
    var updatedChatListener: ListenerRegistration?
    var newChatListener: ListenerRegistration?
    
    
    
    let legitTypes = [kAUDIO, kVIDEO, kTEXT, kLOCATION, kPICTURE]
    
    
    var maxMessagesNumber = 0
    var minimumMessageNumber = 0
    var oldLoad = false // for loading all messages - button
    var loadedMessagesCount = 0
    
    
    
    /// Variables to hold message: array
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessage: [NSDictionary] = [] // store msg we load then send to JSQ message
    var allPictureMessages: [String] = [] // for PICS
    
    var initialLoadComplete = false     // as soon as we open chatView open the 11 messages
    
    var outgoingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    
    var incomingBubble = JSQMessagesBubbleImageFactory()?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    //MARK: CUstom Headers
    let leftBarButtonView : UIView = {
       let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        return view
    }()
    
    let avatarButton : UIButton = {
       let button = UIButton(frame: CGRect(x: 0, y: 10, width: 25, height: 25))
        return button
    }()
    
    let titleLabel : UILabel = {
        let title = UILabel(frame: CGRect(x: 30, y: 10, width: 140, height: 15))
        title.textAlignment = .left
        title.font = UIFont(name: title.font.fontName, size: 14)
        
        return title
    }()

    let subTitleLabel : UILabel = {
        let subtitle = UILabel(frame: CGRect(x: 30, y: 25, width: 140, height: 15))
        subtitle.textAlignment = .left
        subtitle.font = UIFont(name: subtitle.font.fontName, size: 10)
        
        return subtitle
    }()
    
    
    
    
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
        
        //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        // set custom title for user who is in CHAT
        setCustomTitle()
        
        
        /// LOAD MESSAGES into collectionView
        loadMessages()
        
        
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
    
    
    
    //MARK: JSQ_messages DataSource functions
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        // pass data to cell (data = [messagas as! jsq_message)
        let data = messages[indexPath.row]
        
        ///Set text color
        if data.senderId == FUser.currentId() {
            // outgoing chat
            cell.textView?.textColor = .white
        } else {
            // incoming text
            cell.textView?.textColor = .black
        }
        
        return cell

    }
    
    //MARK: display JSQ_message Data
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        
        return messages[indexPath.row]  // display our message
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count   // display # of cells we have
    }
    
    //MARK: create message BUBBLE
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let data = messages[indexPath.row]
        
        
        // check what kind of text bubble will show in COllectionView
        if data.senderId == FUser.currentId() {
            // outgoing text
            return outgoingBubble
        } else {
            return incomingBubble
        }
        
    }
    

    ///HERE >>>>>>>>>>> Required JSQ_message functions
    //MARK: JSQ_ read and "delivered" status
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
            // >>HERE << we are DISPLAY timestamp for every message
        
        if indexPath.item % 3 == 0 {
            let message = messages[indexPath.row]   // store our emssage
            
            return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
        }
        
        return nil
        
    }
    
    ///TIME STAMP for messages
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!,
                                 heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
            if indexPath.item % 3 == 0 {
                let message = messages[indexPath.row]   // store our emssage
                
                //return JSQMessagesTimestampFormatter.shared()?.attributedTimestamp(for: message.date)
                return kJSQMessagesCollectionViewCellLabelHeightDefault
            }
            
        return 0.0
    }
    
    
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        
        
        let message = objectMessages[indexPath.row]
        
        // return NS Attributed String
        let status: NSAttributedString!
        
        let attributedStringColor = [NSAttributedString.Key.foregroundColor : UIColor.darkGray] // create "deliverd" in Dark Gray
        
        // check if delivered or "read"
        switch message[kSTATUS] as! String {
        case kDELIVERED :
            status = NSAttributedString(string: kDELIVERED) // put word "delivered"
        case kREAD :
            let statusText = "Read" + " " + readTimeFrom(dateString: message[kREADDATE] as! String)            // extrame time from dat
            status = NSAttributedString(string: statusText, attributes: attributedStringColor)
        
        default:
            status = NSAttributedString(string: "✔")
        }
        
        // check if there are any for indexPath
        if indexPath.row == (messages.count - 1) {
            //print("yes......")
            return status
            
        } else {
            return NSAttributedString(string: "")
        }
        
        
        
    }
    
    //MARK: Delivery Status
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
            
        let data = messages[indexPath.row]
        
        if data.senderId == FUser.currentId() {
           // print("test.....") -> not this
            // if we are the sender: we dont want a "delivered" when we sent
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }
        
    }
    
    
    
    
    
    
    //MARK: JSQMessages Delegate funtions
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("accessory pressed")
        // creAte  instance of newly created "Camara" class
        let camera = Camara(delegate_: self) // error bcuz needs to conform to delegatre protocal
        
        //MARK: display option Menu
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)  // OPTION menu
        
        
        // create 5 functions
        let takePhotoOrVideo = UIAlertAction(title: "Camera", style: .default) { (action) in
            
            print("Camera")
        }
        
        
        //....PHOTO Library
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (action) in
            // present photo library in options menu
            camera.PresentPhotoLibrary(target: self, canEdit: false)
            print("Photo Library")
        }
        
        let shareVideo = UIAlertAction(title: "Video Library", style: .default) { (action) in
            //camera.PresentionVideoLibrary(target: self, canEdit: false)
            camera.PresentVideoLibrary(target: self, canEdit: false) //(target: self, canEdit: false)
            print("Video Library")
            //Camara.PresentPhotoLibrary(<#T##self: Camara##Camara#>)

            
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
            self.sendMessage(text: text, date: date, picture: nil, location: nil, video: nil, audio: nil)
            // once we press our send we want to update "send" with picture to microphone photo
            updateSendButton(isSend: false)
        } else {
            print("Audio message")
        }
    }
    
    
    
    
    
    
    ///Function to load earlier messages
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("Load more!.....")
        // load more messages
        self.loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minimumMessageNumber)
        self.collectionView.reloadData() // reload data to present older chats
        
    }
    
    
    // MESSAGING --------------------------- (SEND MESSAGEs)
 
    //MARK: Send Messagess
    func sendMessage(text: String?, date: Date, picture: UIImage?, location: String?, video: NSURL?, audio: String?) {
        
        ///OUTGOING -> send to FIrestore
        var outgoingMessage: OutgoingMessage?
        let currentUser = FUser.currentUser()!
        
        //INCOMing user JSQ_messages to get incoming messages
        // Text Message: "If our text is not nil"
        // check what type of message we are watching
        if let text = text {
            /// genereate an >outgoing message< (a text message)
            outgoingMessage = OutgoingMessage(message: text, senderId: currentUser.objectId,
                                              senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        
        
        /// picture message
        if let pic = picture {
            // we have recieved a picture here
            // so upload the image...
            uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) {
                (imageLink) in
                
                if imageLink != nil {
                    // we have an image! -> create an outgoing message for our picture message
                    let text = "[\(kPICTURE)]"
                    
                    outgoingMessage = OutgoingMessage(message: text,
                                                      pictureLink: imageLink!,
                                                      senderId: currentUser.objectId,
                                                      senderName: currentUser.firstname,
                                                      date: date,
                                                      status: kDELIVERED,
                                                      type: kPICTURE)
                    
                    // play a "sent message" sound
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    //
                    self.finishSendingMessage()
                    
                    // save our Image to FireStore
                    //self.finishSendingMessage()
                    outgoingMessage?.sendMessagetoFirebase(chatRoomId: self.chatRoomId,
                                                           messageDictionary: outgoingMessage!.myMessageDictionary,
                                                           memberIds: self.memberIds,
                                                           membersToPush: self.membersToPush)
                }
            }
            
            // incase <upload> is Unsuccessfult
            return // if we dont upload any messages
        }
        
        
        //MARK: Send Video -------------<<<<<<<<<<<<<<<<<      HERE          >>>>>>>>>>>>>>>>>>--------- !!! yes
        if let video = video {
            // get the video
            let videoData = NSData(contentsOfFile: video.path!)

            ///genereate thumbnail - written in DOwnloader.swift" file"
            
            //let thumbNail = videoThumbnail(video: video)
            //let dataThumbnail = thumbNail.jpegData(compressionQuality: 0.3)
                   // **OR **
            let dataThumbNail = videoThumbnail(video: video).jpegData(compressionQuality: 0.3)
            uploadVideo(video: videoData!, chatRoomId: chatRoomId,
                        view: self.navigationController!.view) { (videoLink) in
                            
                            if videoLink != nil {
                                /// present this to user on <most recent message/ text recieved >
                                let text = "[\(kVIDEO)]"
                                
                                outgoingMessage = OutgoingMessage(message: text,
                                                                  videoLink: videoLink!,
                                                                  thumbNail: dataThumbNail! as NSData,
                                                                  senderId: currentUser.objectId,
                                                                  senderName: currentUser.firstname,
                                                                  date: date,
                                                                  status: kDELIVERED,
                                                                  type: kVIDEO)
                                
                                JSQSystemSoundPlayer.jsq_playMessageSentSound()
                                self.finishSendingMessage()
                                
                                
                                
                                outgoingMessage?.sendMessagetoFirebase( chatRoomId: self.chatRoomId,
                                                                       messageDictionary: (outgoingMessage!.myMessageDictionary),
                                                                       memberIds: self.memberIds,
                                                                       membersToPush: self.membersToPush)
                            }
            }
            return
        }
        
        
        //MARK: JSQ_ system sound player: when user send message the phone will make a "send sound"
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        //outgoingMessage!.sendMessagetoFirebase(chatRoomID: chatRoomId, messageDictionaryParamater: outgoingMessage!.messageDictionary, memberIDs: memberIds,membersToPush: membersToPush)
        //outgoingMessage!.sendMessagetoFirebase(chatRoomID: chatRoomId, nessageDictionary: outgoingMessage!.myMessageDictionary, memberIDs: memberIds, membersToPush: membersToPush)
        // update recent chat to display last message and date
        outgoingMessage!.sendMessagetoFirebase(chatRoomId: chatRoomId, messageDictionary: outgoingMessage!.myMessageDictionary, memberIds: memberIds, membersToPush: membersToPush)
    
    }
    
    
    //MARK: Load Messages from FireCLoud
    func loadMessages() {
        // get last 11 messages, about what we can fit on the view controller. we will have another way to store the previous in the background
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11)
            .getDocuments { (snapshotOfEleven, error) in
                
                // check if we get any snapshot back
                guard let snapshotOfEleven = snapshotOfEleven else {
                    // initial loading is done
                    print("initial loading of messages is done.")
                    self.initialLoadComplete = true
                    // listen for new chats
                    return
                }
                
                // sorting all messages using the Date
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshotOfEleven.documents)) as NSArray).sortedArray(using:
                    [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary]
                
                // if a corrupt message, will deletefrom array so application does not terminate on USer
                //MARK: remove bad messages
                // takes array of bad messages and loads into loadedMessage
                self.loadedMessage = self.removeBadMessages(allmessagesArray: sorted)
                self.insertMessages()   // insert messages into the *View
                self.finishReceivingMessage(animated: true) // add animated load at bottom of collectionView
                
                print("we have \(self.messages.count) messages loaded")
                
                //MARK: insert Messages
                self.initialLoadComplete = true // have now deleted last 11 messages
                
                // MARK: get picture Messags and store in array for pics
                
                
                
                
                //MARK: Get all old messages in background
                self.getOldMessagesInBackground()
                
                
                
                
                
                //MARK: Start listening for new chats
                self.listenForNewChats()
                
                
                
                
                
                
                
                
                //<<<<<<,here
        }
    }
    
    
    
    //MARK: Listen >> For new Chats
    
    func listenForNewChats() {
        
        var lastMessageDate = "0"
        
        if loadedMessage.count > 0 {
            // we have some last message to set the data
            lastMessageDate = loadedMessage.last![kDATE] as! String // string becaUSE WE are saving STRING in our firebase
            
        }
        
        // create listener for any new chats
        // can either have netork constantly pulling or
        // have update every time the user enters/ exits
        newChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(
            kDATE, isGreaterThan: lastMessageDate).addSnapshotListener({ (snapshot, error) in
                
                guard let snapshot = snapshot else { return }
                
                if !snapshot.isEmpty {
                    /// check a new object has been added to firestore
                    for diff in snapshot.documentChanges {
                        if diff.type == .added {    // check if added new message
                            // add to messages
                            let itemAdded = diff.document.data() as NSDictionary
                            
                            ///check if a proper message
                            if let type = itemAdded[kTYPE] {
                                //check if type is Legit type
                                if self.legitTypes.contains(type as! String) {
                                    
                                    
                                    // This is for picture messages
                                    if type as! String == kPICTURE {
                                        //add to pictures
                                        
                                    }
                                    
                                    if self.insertInitialLoadMessages(messageDictionary: itemAdded) {
                                        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                                    }
                                    
                                    // refresh our View
                                    self.finishReceivingMessage()
                                    
                                }
                            }
                        }
                    }
                }

            })
    }
    
    
    
    
    
    //MARK: Get old messages (Load messages in background)
    func getOldMessagesInBackground() {
        //check if any messages
        // check that date is less than 11-days
        if loadedMessage.count > 10 {
            let firstMessageDate = loadedMessage.first![kDATE] as! String
            
            //referenece firebase
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }
                
                // sort through dictioary
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(
                    using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary] /// get all sorted in dictionary
                
                self.loadedMessage = self.removeBadMessages(allmessagesArray: sorted) + self.loadedMessage
                
                
                
                /// GET the picture messages

                
                // exact # of messages to show
                self.maxMessagesNumber = self.loadedMessage.count - self.loadedMessagesCount - 1
                self.minimumMessageNumber = self.maxMessagesNumber - kNUMBEROFMESSAGES
                
                
            }
        }
    }
    
    
    
    
    
    
    
    //MARK: Insert Messages
    // will take loaded messages -> create JSQ_messages item
    func insertMessages() {
        maxMessagesNumber = loadedMessage.count - loadedMessagesCount        // check how many messages are Loaded from array of all messages
        minimumMessageNumber = maxMessagesNumber - kNUMBEROFMESSAGES        // <kNUMBEROFMESSAGES > stored with 10 messages in F_User file (# that is shown)
        
        if minimumMessageNumber < 0 {
            minimumMessageNumber = 0
        }
        
        // mark: create a message
        for idx in minimumMessageNumber..<maxMessagesNumber {
            let messageDictionary = loadedMessage[idx]
            
            // insert Message into array
            insertInitialLoadMessages(messageDictionary: messageDictionary)
            
            loadedMessagesCount += 1    // loads one message to dictionary (10 + 1)
        }
        
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessage.count)
        
    }
    
    
    
    func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
        // incoming messages go left outgoing goes on Right side
        // check incoming
        
        //MARK: Incoming MSG
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
            ///update message status if we recieved read message status
        }
        
        
        //let message = IncomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
       // let message = IncomingMessage.createMessage(messageDictionary)
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        if message != nil {
            //these two must be in-sync at all times -> both musht be called
            objectMessages.append(messageDictionary)
            messages.append(message!)   // unrwap the JSQmessage
        }
        return isIncoming(messageDictionary: messageDictionary) // will tell our return value what our message is
    }
    
    
    
    
    
    
    
    
    
    
    
    //<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    //MARK: LoadMoreMessages
    func loadMoreMessages(maxNumber: Int, minNumber: Int) {
        
        
        if oldLoad {
            maxMessagesNumber = minNumber - 1
            minimumMessageNumber = maxMessagesNumber - kNUMBEROFMESSAGES
        }
        
        if minimumMessageNumber < 0 {
            minimumMessageNumber = 0
        }
        
        
        /// Go thru array of loaded messages
        for idx in (minimumMessageNumber ... maxMessagesNumber).reversed() {
            // go through old messages array and reverse order
            let idx_messageDictionary = loadedMessage[idx]
            insertNewMessage(messageDictionary: idx_messageDictionary)
        }
        oldLoad = true
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessage.count)
    }
    
    
    
    func insertNewMessage(messageDictionary: NSDictionary) {
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        let message = incomingMessage.createMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        
        // insert into array of JSQ message
        objectMessages.insert(messageDictionary, at: 0) // set at begining of array
        messages.insert(message!, at: 0)
    }
    
    
    
    
    
    
    
    
    
    
    
    
    @objc func backAction() {
        //print("Pressed Back")
        self.navigationController?.popViewController(animated: true)
    
    }
    
    //MARK: check if info button is pressed
    @objc func infoButtonPressed() {
        print("Show image messages")
    }
    
    @objc func showGroup() {
        print("Show Group")
    }
    
    @objc func showUserProfile() {
        //get profile view
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        // get user we are chatting and save as GLOBAL variable for every time we want to show user information
        profileVC.user = withUsers.first! // get first item in array of users
            self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    
    
    //MARK: Custom Send Button
    //MARK: JSQ_viewController << !!!!!!!!!
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
            // replace image
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "send"), for: .normal)
        } else {
            // set it back to micropohne
            self.inputToolbar.contentView.rightBarButtonItem.setImage(UIImage(named: "mic"), for: .normal)

        }
    }
    
    //MARK: Update UI: Custom Header for Chat between users
    func setCustomTitle() {
        leftBarButtonView.addSubview(avatarButton)
        leftBarButtonView.addSubview(titleLabel)
        leftBarButtonView.addSubview(subTitleLabel)
        
        let infoButton = UIBarButtonItem(image: UIImage(named: "info"), style: .plain, target: self, action: #selector(self.infoButtonPressed))
        
        // instantiate infoButton as rightBar button
        self.navigationItem.rightBarButtonItem = infoButton
        
        let leftBarButtonItem = UIBarButtonItem(customView: leftBarButtonView)
        self.navigationItem.leftBarButtonItems?.append(leftBarButtonItem)
        
        //check if chat is group chat or not for Chat Header
        if isGroup! {
            avatarButton.addTarget(self, action: #selector(self.showGroup), for: .touchUpInside)
        } else {
            avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
        }
        
        
        // get users from firestore
        // returns array of Fuser objects
        getUsersFromFirestore(withIds: memberIds) { (withUsers) in
            self.withUsers = withUsers
            //get avatars
            if !self.isGroup! {
                // then it is one on one chat -> update user info
                // set online status
                self.setUIForSingleChat()
                // name
            }
        }
    }
    
    
    func setUIForSingleChat() {
        let withUser = withUsers.first!
        
        imageFromData(pictureData: withUser.avatar) { (image) in
            if image != nil {
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        titleLabel.text = withUser.fullname
        
        // set header labels when not in groupChat
        if withUser.isOnline {
            subTitleLabel.text = "Online"
            
        } else {
            subTitleLabel.text = "Offline"
        }
        avatarButton.addTarget(self, action: #selector(self.showUserProfile), for: .touchUpInside)
    }
    
    
    //MARK: UIImagePicker Controller delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        ///check if a picture or  a video
        
        let video = info[UIImagePickerController.InfoKey.mediaURL] as? NSURL
        let picture = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        
        // send message
        sendMessage(text: nil, date: Date(), picture: picture, location: nil, video: video, audio: nil)
        
        picker.dismiss(animated: true, completion: nil)
        
        
    }
    
    
    
    
    
    
    
    //MARK: Helper functions
    
    func readTimeFrom(dateString: String) -> String {
        let date = dateFormatter().date(from: dateString)
        
        let currentDateformat = dateFormatter()
        currentDateformat.dateFormat = "HH:mm"  // take a date - turn into hourse and minutes
        
        return currentDateformat.string(from: date!)
    }
    
    
    
    
    
    
    // loop through array of dicionary(messages) and check for any potential bad messages
    func removeBadMessages(allmessagesArray: [NSDictionary]) -> [NSDictionary] {
        
        var tempMessage = allmessagesArray
        
        
        
        for message in tempMessage {
            if message[kTYPE] != nil {
                if !self.legitTypes.contains(message[kTYPE] as! String) {
                    // if it doesnt contain "legit type" -> then it is a bad message
                    // REMOVE
                    tempMessage.remove(at: tempMessage.index(of: message)!) // removes "bad message" from "temp message" array
                }
            } else {
                tempMessage.remove(at: tempMessage.index(of: message)!) // removes "bad message" from "temp message" array
            }
        }
        // done with loop -> return the dictionary
        return tempMessage
    }
    
    
    func isIncoming(messageDictionary: NSDictionary) -> Bool {
        if FUser.currentId() == messageDictionary[kSENDERID] as! String {
            return false
        } else {
            return true // incoming message
        }
    }

}
