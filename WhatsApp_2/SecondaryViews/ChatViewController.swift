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
class ChatViewController: JSQMessagesViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, IQAudioRecorderViewControllerDelegate {
    
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate /// get access to our app Delegate
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
    
    ///counting for user typing
    var typingCounter = 0
    
    
    /// Variables to hold message: array
    var messages: [JSQMessage] = []
    var objectMessages: [NSDictionary] = []
    var loadedMessage: [NSDictionary] = [] // store msg we load then send to JSQ message
    var allPictureMessages: [String] = [] // for PICS
    
    var initialLoadComplete = false     // as soon as we open chatView open the 11 messages
    
    
    
    ///AVATAR sources
    var jsqAvatarDictionary: NSMutableDictionary?
    var avatarImageDictionary: NSMutableDictionary?
    var showAvatars = true
    var firstLoad: Bool?
    
    
    
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
    
    
    //MARK: RECENT > CHAT * COUNTER * <
    override func viewWillAppear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatRoomId)
    }
    override func viewWillDisappear(_ animated: Bool) {
        clearRecentCounter(chatRoomId: chatRoomId)
    }
    
    
    
    
    // FIX for Iphone x (10)
    override func viewDidLayoutSubviews() {
        perform(Selector("jsq_updateCollectionViewInsets"))
    }
    // end of iPhone x - Fix
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        /// Create typing observer to show other user when a user is *typing* ...
        createTypingObserver()
        
        // load user defaults
        loadUserDefaults()
        
        /// Add menu option for JSQ messages cell
        /// When user clicks on each message (picture, text, locatoin or video it will now show a prompt to "delete" that message
        JSQMessagesCollectionViewCell.registerMenuAction(#selector(delete))
        
        
        navigationItem.largeTitleDisplayMode = .never
        
        // create a BUTTON
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(self.backAction))]
        
        
        // check if our chat is a "GROUP" chat
        if isGroup! {
            getCurrentGroup(withId: chatRoomId) // grabs our group and sets up our user interface
        }
        
        
        
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        
        jsqAvatarDictionary = [:] //empty dicrionary
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
    
    
    /// JSQ message collection view * Required for Avatar Images  >> on side of each message <<< *
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        // get indexpath dot row to see what message to show
        let message = messages[indexPath.row]
        
        // get the avatar
        var avatar: JSQMessageAvatarImageDataSource
        
        if let testAvatar = jsqAvatarDictionary!.object(forKey: message.senderId) {
            avatar = testAvatar as! JSQMessageAvatarImageDataSource
        } else {
            /// otherwise if user has no avatar in our Dictionary
            avatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        }
        
        return avatar
        
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
            
            camera.PresentMultyCamara(target: self, canEdit: false) /// presents "CAMERA" to take photo or video *will no work on simulator * user can take photo and send to eachother now
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
            
        }
        
        
        
        let shareLocation = UIAlertAction(title: "Share Location", style: .default) { (action) in
            print("DEBUG: Sharing Location in ChatVIewController")
            if self.haveAccessToUserLocation() {
                print("Debug: location is \(kLOCATION)")
                self.sendMessage(text: nil, date: Date(), picture: nil, location: kLOCATION, video: nil, audio: nil)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
        }
        
        // .... set photo
        takePhotoOrVideo.setValue(UIImage(named: "camera"), forKey: "image")
        sharePhoto.setValue(UIImage(named: "picture"), forKey: "image")
        shareVideo.setValue(UIImage(named: "video"), forKey: "image")
        shareLocation.setValue(UIImage(named: "location"), forKey: "image")
        
        //..... set optionMenu
        optionMenu.addAction(takePhotoOrVideo)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareVideo)
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
            
            let audioVC = AudioViewController(delegate_: self)
            audioVC.presentAudioRecorder(target: self)
            
            
            
            
        }
    }
    
    
    
    
    
    
    ///Function to load earlier messages
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, header headerView: JSQMessagesLoadEarlierHeaderView!, didTapLoadEarlierMessagesButton sender: UIButton!) {
        print("Load more!.....")
        // load more messages
        self.loadMoreMessages(maxNumber: maxMessagesNumber, minNumber: minimumMessageNumber)
        self.collectionView.reloadData() // reload data to present older chats
        
    }
    
    
    //MARK: to be able to see our video playing and see when anytime a user taps on a JSQ_message bubble
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        
        
        print("tap on message at \(indexPath)")
        
        let messageDictionary = objectMessages[indexPath.row]
        let messageType = messageDictionary[kTYPE] as! String
        
        // once we have our type we need to check if video, text, picture, location
        switch messageType {
        case kPICTURE:                                                  /* By Picture Message */
            print("DEBUG: picture message tapped at \(indexPath.row)")
            
            /// Present the picture message on a seperate view controller
            
            let message = messages[indexPath.row]
            // then access the media *photo*
            let mediaItem = message.media as! JSQPhotoMediaItem
            
            
            
            print("DEBUG: The media item is: \(mediaItem)")
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            let browser = IDMPhotoBrowser(photos: photos)
            
            // present the photo in browser
            //self.present(browser!, animated: true, completion: nil)
            self.present(browser!, animated: true, completion: nil)
            
            
        case kLOCATION:                                         /* By Location */
            
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQLocationMediaItem
            // instantiate our Map
            let mapView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MapViewController") as! MapViewController
            mapView.location = mediaItem.location // our jsq_media item for location
            ///add these to our navigation controller
            self.navigationController?.pushViewController(mapView, animated: true)
            
            print("DEBUG: location message type was  tapped")
            
            
            

        case kVIDEO:                                           /* By Video */
            print("DEBUG: picture message tapped")
                // acces our array of messages and access the video mesage from it
            let message = messages[indexPath.row]
            let mediaItem = message.media as! VideoMessage
            
            let player = AVPlayer(url: mediaItem.fileURL! as URL)
            // initialize a movie player
            let moviePlayer = AVPlayerViewController()
            
            let vidSession = AVAudioSession.sharedInstance()
            // make sure no errors
            try! vidSession.setCategory(.playAndRecord, mode: .default , options: .defaultToSpeaker)
            
            moviePlayer.player = player
            
            
            /// as soon as the video is open *tapped by user * ...
            self.present(moviePlayer, animated: true) {
                moviePlayer.player!.play()  /// it should play automagically
            }
     

        default:
            print("DEBUG: Unknown message tapped in collectionView")
        }
    }
    
    //MARK: >> check if user tapped avatar image
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        
        // present the profile view of F-user object
        // get the image from fUser object
        let senderId = messages[indexPath.row].senderId /// returns the unique identifiers for the user who sent the message.
        var selectedUser: FUser?
        
        
        // if the sender id is same as fUser current id, then the avatar p;icture was taapped
        if senderId == FUser.currentId() {
            selectedUser = FUser.currentUser()
        } else {
            for user in withUsers {
                if user.objectId == senderId { /// if the user is selected, it is the user
                    selectedUser = user
                }
            }
        }
        /// SHOW user profile
        presentUserProfile(forUser: selectedUser!)
        
    }
    
    
    //MARK: > MULTIMEDIA < Mesages
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        
        // check if our app should show a MENU option
        //super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath))
        super.collectionView(collectionView, shouldShowMenuForItemAt: indexPath)
        return true
    }
    
    /// function helps message that is to be copied so it does not repeat when "copied" is pressed
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        
        /// shows options for text messages -> "delete" & "copy" -> check whether it is a media or text message
        if messages[indexPath.row].isMediaMessage { // get the specific message that was pushed by user
            if action.description == "delete:" {    // will show "delete" for MEDIA messages
                return true
            } else {
                return false
            }
        }
        else {         // else it is a text message
            if action.description == "delete:" || action.description == "copy:" {  /// will show  "copy and delete" for TEXT msg
                return true
            } else {
                return true
            }
        }
    }
    
    //MARK: Delete message
    /// function to be called every time the user deletes a message, deletes from collectionView and from our FireBase!!
    // remove from collectoin View and FIrebase
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didDeleteMessageAt indexPath: IndexPath!) {
        let messageId = objectMessages[indexPath.row][kMESSAGEID] as! String    // get object message of our currently Tapped msg and get the message ID from the object emssages DICTIONAREY, then return it as a String
        // delete message from object message
        objectMessages.remove(at: indexPath.row)
        // have 2 arrays that are synced
        // also deleting from messages
        messages.remove(at: indexPath.row)
        
        /// delete message from *Firebase
        // write from ougoing messages function
        OutgoingMessage.deleteMessage(withId: messageId, chatRoomId: chatRoomId)
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
            /// ENCRYPT the outgoing message
            let encryptedTextMSG = Encryption.encryptText(chatRoomID: chatRoomId, decryptMessage: text)
            /// genereate an >outgoing message< (a text message)
            outgoingMessage = OutgoingMessage(message: encryptedTextMSG, senderId: currentUser.objectId,
                                              senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kTEXT)
        }
        
        
        /// picture message
        if let pic = picture {
            /// ENCRYPT the outgoing message
            
            // we have recieved a picture here
            // so upload the image...
            uploadImage(image: pic, chatRoomId: chatRoomId, view: self.navigationController!.view) {
                (imageLink) in
                
                if imageLink != nil {
                    
                    let encryptedTextPIC = Encryption.encryptText(chatRoomID: self.chatRoomId, decryptMessage: "[\(kPICTURE)]")

                    // we have an image! -> create an outgoing message for our picture message
                   /// don't need this when encrypting let text = "[\(kPICTURE)]"
                    
                    outgoingMessage = OutgoingMessage(message: encryptedTextPIC,
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
                                
                                let encryptedTextVIDEO = Encryption.encryptText(chatRoomID: self.chatRoomId, decryptMessage: "[\(kVIDEO)]")

                                /// present this to user on <most recent message/ text recieved >
                                //let text = "[\(kVIDEO)]"
                                
                                /// without video encryption
//                                outgoingMessage = OutgoingMessage(message: text,
//                                                                  videoLink: videoLink!,
//                                                                  thumbNail: dataThumbNail! as NSData,
//                                                                  senderId: currentUser.objectId,
//                                                                  senderName: currentUser.firstname,
//                                                                  date: date,
//                                                                  status: kDELIVERED,
//                                                                  type: kVIDEO)
                                ///pass video encryption
                                outgoingMessage = OutgoingMessage(message: encryptedTextVIDEO,
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
        
        //MARK: send Audio * check *
        if let audioPath = audio {
            // we have an audio object
            // upload it
            uploadAudio(audioPath: audioPath, chatRoomId: chatRoomId, view: (self.navigationController?.view)!) { (audioLink) in
                // check if we recieve the link
                if audioLink != nil {
                    /// we recieved an audio lnk
                    let encryptedTextAUDIO = Encryption.encryptText(chatRoomID: self.chatRoomId, decryptMessage: "[\(kAUDIO)]")

                    //let text = "[\(kAUDIO)]" // shown in "Recent msg" cell
                    /// non-encrypted Audio message

//                    outgoingMessage = OutgoingMessage(message: text, audio: audioLink!, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kAUDIO)
                    /// encrypted Audio text message
                    outgoingMessage = OutgoingMessage(message: encryptedTextAUDIO,
                                                       audio: audioLink!,
                                                       senderId: currentUser.objectId,
                                                       senderName: currentUser.firstname,
                                                       date: date,
                                                       status: kDELIVERED,
                                                       type: kAUDIO)
                    ///play message sound for sent
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    outgoingMessage!.sendMessagetoFirebase(chatRoomId: self.chatRoomId, messageDictionary: outgoingMessage!.myMessageDictionary, memberIds: self.memberIds, membersToPush: self.membersToPush)
                }
            }
            return
        }
        
        //MARK: SEND * LOCATION * message
        if location != nil {
            print("Send location message")
            
            // get lattitudde and longitude
          let latt: NSNumber = NSNumber(value: appDelegate.coordinates!.latitude)
          let long: NSNumber = NSNumber(value: appDelegate.coordinates!.longitude)
           
            
            let encryptedTextLOCATION = Encryption.encryptText(chatRoomID: self.chatRoomId, decryptMessage: "[\(kLOCATION)]")

            // get the text * the location message *
            //let text = "[\(kLOCATION)]"
            //print("Debuging: \(text)")
            
            //  call out instantiated  *OUTGOING* message
            /// for NON-Encrypted location
//            outgoingMessage = OutgoingMessage(message: text, latitude: latt, longitude: long, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kLOCATION)
           /// ENCRYPTED * location * MEssage
            outgoingMessage = OutgoingMessage(message: encryptedTextLOCATION, latitude: latt, longitude: long, senderId: currentUser.objectId, senderName: currentUser.firstname, date: date, status: kDELIVERED, type: kLOCATION)

        }
        
        
        
        
        
        //MARK: Makes outgoing message go to FIrebase and send to user in Chat View Controller
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
        
        /// To update most * Recent * message status
        updatedChatListener = reference(.Message).document(FUser.currentId()).collection(chatRoomId).addSnapshotListener({ (snapshot, error) in
            
            guard let snapshot = snapshot else {
                return
            }
            
            /// check if snapshot is empty
            if !snapshot.isEmpty {
                // if not empty
                
//                 same as writing the  snapshot.documentChanges.forEach( --> below
//                for diff in snapshot.documentChanges {
//
//                }
                
                
                // check if it was *modified* not added or deleted
                snapshot.documentChanges.forEach( { (diff) in
                    
                    
                    
                    if diff.type == .modified {
                        /// means our object was modified
                        // update local message
                        self.updateMessage(messageDictionary: diff.document.data() as NSDictionary)
                    }
                    
                    
                })
            }
            
            
        })
        
        
        
        
        
        
        
        
        
        
        // get last 11 messages, about what we can fit on the view controller. we will have another way to store the previous in the background
        reference(.Message).document(FUser.currentId()).collection(chatRoomId).order(by: kDATE, descending: true).limit(to: 11).getDocuments { (snapshotOfEleven, error) in
                
                // check if we get any snapshot back
                guard let snapshotOfEleven = snapshotOfEleven else {
                    // initial loading is done
                    self.initialLoadComplete = true
                    /// listen for new chats
                    self.listenForNewChats()
                   // print("initial loading of messages is done.")

                    
                    
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
                self.getPictureMessages()
                
                
                
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
                                    
                                    
                                    /// This is for picture messages
                                    if type as! String == kPICTURE {
                                        //add to pictures
                                        self.addNewPictureMessageLink(link: itemAdded[kPICTURE] as! String)
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
    
    
    
    
    
    //MARK: Get old messages (Load messages in background) when more than 10
    func getOldMessagesInBackground() {
        //check if any messages
        // check that date is less than 11-days
        if loadedMessage.count > 10 {
            let firstMessageDate = loadedMessage.first![kDATE] as! String
            
            //referenece firebase
            reference(.Message).document(FUser.currentId()).collection(chatRoomId).whereField(kDATE, isLessThan: firstMessageDate).getDocuments { (snapshot, error) in
                
                guard let snapshot = snapshot else { return }
                
                // sort through dictioary
                let sorted = ((dictionaryFromSnapshots(snapshots: snapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: true)]) as! [NSDictionary] /// get all sorted in dictionary
                
                self.loadedMessage = self.removeBadMessages(allmessagesArray: sorted) + self.loadedMessage
                
                
                
                /// GET the picture messages
                self.getPictureMessages()

                
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
        for idx in minimumMessageNumber ..< maxMessagesNumber {
            let messageDictionary = loadedMessage[idx]
            
            // insert Message into array
            insertInitialLoadMessages(messageDictionary: messageDictionary)
            
            loadedMessagesCount += 1    // loads one message to dictionary (10 + 1)
        }
        
        /// >>>>>>>>>>>>>>>>>>>>>>>>>>>>                CHANGED from ( != )
        self.showLoadEarlierMessagesHeader = (loadedMessagesCount != loadedMessage.count)
        
    }
    
    
    
    func insertInitialLoadMessages(messageDictionary: NSDictionary) -> Bool {
        // incoming messages go left outgoing goes on Right side
        // check incoming
        
        //MARK: Incoming MSG
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        
        if (messageDictionary[kSENDERID] as! String) != FUser.currentId() {
            ///update message status if we recieved read message status
            //updateMessage(messageDictionary: incomingMessage)
            OutgoingMessage.updateMessage(withId: messageDictionary[kMESSAGEID] as! String, chatRoomId: chatRoomId, memberIds: memberIds) ///updates our chat
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
    
    
    //MARK: Update most recent MSG in user's ChatView controller
    func updateMessage(messageDictionary: NSDictionary) {
        /// takes our message and updates the message *locally* it is already stored in Firebase
        
        for idx in 0 ..< objectMessages.count {
            /// goes through each message in the array
            let temp = objectMessages[idx]
            
            /// check if it was our message that was update/ or checked
            if messageDictionary[kMESSAGEID] as! String == temp[kMESSAGEID] as! String {
                objectMessages[idx] = messageDictionary
                self.collectionView!.reloadData()
            }
        }
        
        
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
            //loadedMessagesCount += 1
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
    
    
    
    
    
    
    
    
    
    //MARK: IBActions for the chat
    
    
    @objc func backAction() {
        //print("Pressed Back")
        // before we go back we want to clear our "Recent counter"
        clearRecentCounter(chatRoomId: chatRoomId)
        removeListeners()
        self.navigationController?.popViewController(animated: true)
    
    }
    
    //MARK: check if info button is pressed
    
    @objc func infoButtonPressed() {
        
        // we want to display our collection view by passing our image View links
        let mediaVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mediaView") as! PicturesCollectionViewController
        
        mediaVC.allImageLinks = allPictureMessages
        
        self.navigationController?.pushViewController(mediaVC, animated: true)
        print("DEBUG: Showing all image messages")
    }
    
    
    
    
    @objc func showGroup() {
        /// inititialize/ present our "Group" view controller
        let groupVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "groupView") as! GroupViewController
        
        // set our group"
        groupVC.group = group!
        self.navigationController?.pushViewController(groupVC, animated: true)
        print("Show Group View Controller")
    }
    
    
    
    
    @objc func showUserProfile() {
        //get profile view
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        
        
        // get user we are chatting and save as GLOBAL variable for every time we want to show user information
        profileVC.user = withUsers.first! // get first item in array of users
            self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    func presentUserProfile(forUser: FUser) {
        //get profile view
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "profileView") as! ProfileViewTableViewController
        // get user we are chatting and save as GLOBAL variable for every time we want to show user information
        profileVC.user = forUser
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
    
    //MARK: Typing observer (..... .. . )
    
    func createTypingObserver() {
        // every time our user is typing we want to save in firebase "user is typing = true "
        // when user is typing it will show typing indicator from firevase to user
        typingListener = reference(.Typing).document(chatRoomId).addSnapshotListener({ (snapshot, error) in
            guard let snapshot = snapshot else { return }
            
            // check if snapshot exists
            if snapshot.exists {
                // save the typeing for all the users, whether
                for data in snapshot.data()! {
                    // array of key/ value pairs we need to unwrap
                    if data.key != FUser.currentId() {
                        let typing = data.value as! Bool
                        self.showTypingIndicator = typing
                        if typing {
                            self.scrollToBottom(animated: true) /// once user starts typing it will automatically scroll the other user to bottom of screen to show them other user is typing
                        }
                    }
                }
            } else {
                // firebase has no typing indicator so we make
                // checiing either user is typing or not & will not crash the program
                reference(.Typing).document(self.chatRoomId).setData([FUser.currentId() : false])
            }
        })
    }
    
    func typingCounterStart() {
        typingCounter += 1
        
        typingCounterSave(isTyping: true)
        
        self.perform(#selector(self.typingCounterStop), with: nil, afterDelay: 2.0)
    }
   
//    @objc func typingCounterStop
    
    @objc func typingCounterStop() {
        typingCounter -= 1
        if typingCounter == 0 {
            typingCounterSave(isTyping: false)
        }
    }
    
    func typingCounterSave(isTyping: Bool) {
        reference(.Typing).document(chatRoomId).updateData([FUser.currentId() : isTyping])
    }
    
    
    //MARK: UI text view *delegate*
    // check when someone is texting someing in our textView
    override func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
       
        typingCounterStart()
        return true
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
    
    //MARK: IQ Audio Delegate: allows user to press/ send a Audio Recorder
    
    ///Audio Recorder did finish with audio path
    func audioRecorderController(_ controller: IQAudioRecorderViewController, didFinishWithAudioAtPath filePath: String) {
        
        // incase user finished recording -> we send message
        controller.dismiss(animated: true, completion: nil)
        self.sendMessage(text: nil, date: Date(), picture: nil, location: nil, video: nil, audio: filePath)
        
        
        
    }
    
    
    /// when USER cancels recording -> we cancel the view
    func audioRecorderControllerDidCancel(_ controller: IQAudioRecorderViewController) {
        controller.dismiss(animated: true, completion: nil)



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
            self.getAvatarImages()
            if !self.isGroup! {
                // then it is one on one chat -> update user info
                // set online status
                self.setUIForSingleChat()
                // name
            }
        }
    }
    
    
    //MARK: setup UI for single chat
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
    
    
    //MARK: Setup UI for *Group chats*
    func setUIForGroupChat() {
        //get the avatar of your group
        imageFromData(pictureData: (group![kAVATAR] as! String)) { (image) in
                
            if image != nil {
                // set image to avatar image
                avatarButton.setImage(image!.circleMasked, for: .normal)
            }
        }
        // set the title
        titleLabel.text = titleName
        subTitleLabel.text = ""
        
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
    
    
    
    //MARK: Get avatar images
    func getAvatarImages() {
        
        // check i fwe can show avatars *if our user want s to see avatar
        
        if showAvatars {
            ///change our default avatar size to cgSize 0 we are going to change it in  viwdidLoad
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 30, height: 30)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 30, height: 30)

            // get avatar from current user in avatarImageFrom(fUser: FUSER) {// going to get the avatr
            avatarImageFrom(fUser: FUser.currentUser()!)  // get current user avatar
            
            ///for every user
            for user in withUsers {
                avatarImageFrom(fUser: user)
            }
            
            // create jsq avatra function
        }
    }
    
    
    func avatarImageFrom(fUser: FUser){
        if fUser.avatar != "" {
            // we do have avatar object
            dataImageFromString(pictureString: fUser.avatar) { (imageData) in
                
                if imageData == nil {
                     return
                }
                
                /// if our avatar dict already; had it
                if self.avatarImageDictionary != nil {
                    // update avatar if we have itt
                    self.avatarImageDictionary!.removeObject(forKey: fUser.objectId) // avatar will be removed from avatar dictionary
                    self.avatarImageDictionary!.setObject(imageData!, forKey: fUser.objectId as NSCopying) // set a new avatar
                } else {
                    // create one
                    self.avatarImageDictionary = [fUser.objectId : imageData!]
                }
                
                /// create JSQ_avatars from our dictionary...
                // save to jsq
                self.createJSQAvatars(avatarDictionary: self.avatarImageDictionary)
            }
        }
    }
 
    
//    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        let headerSize = CGRect(x: 0, y: 0, width: 40, height: 40) as! CGRect
//        retun headerSize
//
//    }
    
    //MARK: Create a JSQ avatar
    func createJSQAvatars(avatarDictionary: NSMutableDictionary?) {
        let defaultAvatr = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        
        if avatarDictionary != nil {
            
            /// go thru all the member ids
            for userID in memberIds {
               // check if there is any data
                if let avatarImageData = avatarDictionary![userID] {
                    
                    let jsqAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: avatarImageData as! Data), diameter: 70)
                    
                    // set the image
                    self.jsqAvatarDictionary!.setValue(jsqAvatar, forKey: userID)
                } else {
                    // default avatar is the default of the current user * initiials
                    self.jsqAvatarDictionary!.setValue(defaultAvatr, forKey: userID)
                }
            }
            self.collectionView.reloadData() /// reload collection view and show avatar images
        }
    }
    
    
    
    
    
    //MARK: Location access
    
    /// see if our device currently has access to the users location
    func haveAccessToUserLocation() -> Bool {
        // check if app delegate location manager is set
        if appDelegate.locationManager != nil {
            // we have a location
            print("Debug: Has access to user location")
            /// means we do have location (*user has authenticated it*)
            return true
        } else {
            ProgressHUD.showError("Please give access to location services in settings")
            print("Please give access to location services in settings")
            return false
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //MARK: Helper functions
    
    /// saves our standard user defaults
    func loadUserDefaults() {
        // check first load
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)   /// our first run has happened already
            userDefaults.set(showAvatars, forKey: kSHOWAVATAR)
            
            userDefaults.synchronize()
        }
        
        showAvatars = userDefaults.bool(forKey: kSHOWAVATAR) /// incase we dont have the key, we show << here >>
        // check for background image
        checkForBackgroundImage()
        
    }
    
    /// cehck if we have any images saved for our image defaults for our background
    func checkForBackgroundImage() {
        if userDefaults.object(forKey: kBACKGROUBNDIMAGE) != nil {
            // we have a background image
            self.collectionView.backgroundColor = .clear
            
            // create imageView the size of our screen
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
            imageView.image = UIImage(named: userDefaults.object(forKey: kBACKGROUBNDIMAGE) as! String)!
            
            /// set aspect ratio for background view of image so it fits various sizes of iPhone
            imageView.contentMode = .center     // will zoom in on images but fill the screen on iPHONE 10
                    /* OR */
            //imageView.contentMode = .scaleAspectFill    // TODO get bigger images so it fits BIGGEST iphone images
            
            self.view.insertSubview(imageView, at: 0)   // first view in our subview heirarchy
        }
    }
    
    
    
    
    //MARK: picture messages
    func addNewPictureMessageLink(link: String) {
        allPictureMessages.append(link)
        
    }
    
    func getPictureMessages() {
        allPictureMessages = []
        // go thru all messages in firebase and check if the string is == kPICTURE message
        for message in loadedMessage {
            if message[kTYPE] as! String == kPICTURE {
                allPictureMessages.append(message[kPICTURE] as! String)
            }
        }
    }
    
    // end picture messages
    
    
    
    
    
    //MARK: MSG send/ recieved time
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
    
    //MARK: removes all listeners with dataBase to attemp to not run as much data processing with this app and firebase
    func removeListeners() {
        
        if typingListener != nil {
            typingListener!.remove()
        }
        if newChatListener != nil {
            newChatListener!.remove()
        }
        if updatedChatListener != nil {
            updatedChatListener!.remove()
        }
    }

    
    
    
    /// get our current group
    // we have our groupID (same as chatRoom Id), grab the ID to get the group name
    func getCurrentGroup(withId: String) {
        // access FireBase reference
        reference(.Group).document(withId).getDocument { (snapshot, error) in
            
            guard let snapshot = snapshot else { return }
            
            // if snapshot exists
            if snapshot.exists {
              ///  set group dictionary to the snapshot.data dictionary
                self.group = snapshot.data() as! NSDictionary
                self.setUIForGroupChat()
            }
        }
    }
}
