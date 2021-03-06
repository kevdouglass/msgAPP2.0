//
//  IncomingMessages.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/14/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import JSQMessagesViewController

class IncomingMessage {
    var collectionView: JSQMessagesCollectionView
    
    init(collectionView_: JSQMessagesCollectionView) {
        collectionView = collectionView_
    }
    
    //MARK: create message - pass message from fireStore to this function to call
    func createMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage? {
        
        
        var message: JSQMessage?
        //check type of message we recienve
        let type = messageDictionary[kTYPE] as! String
        
        switch type {
        case kTEXT:
            //create text messate
            print("//create text message")
            //createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId) //      because jsq messages returns a jsq message we can store it in a VAR
            message = createTextMessage(messageDictionary: messageDictionary, chatRoomId: chatRoomId)
        case kPICTURE:
            // create picture
            print("Create Picture")
            message = createPictureMessage(messageDictionary: messageDictionary)
        case kVIDEO:
            // create video message
            message = createVideoMessage(messageDictionary: messageDictionary)
            print("DEBUG: Creating video message")
        case kAUDIO:
            // create Audio
            message = createAudioMessage(messageDictionary: messageDictionary)
            print("Create Audio Message")
        case kLOCATION:
            // create Location
            message = createLocationMessage(messageDictionary: messageDictionary)
            print("create Location")
        default:
            print("unkown message type")
        }
        
        // if there is a message -> return it
        if message != nil {
            return message
        }
        
        return nil
    }
    
    
    
    
    
    
    
    
    
    //MARK: Create Message types for JSQMessage [ Decrypted ]
    func createTextMessage(messageDictionary: NSDictionary, chatRoomId: String) -> JSQMessage {
        let name = messageDictionary[kSENDERNAME] as? String
        let userid = messageDictionary[kSENDERID] as? String
        
        // make sure correct date/time is given
        var date: Date! // instantiate a date new date obj
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date() // date equal new date
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        /// non decrypted text
        //let text = messageDictionary[kMESSAGE] as! String   // where texts are stored in dictionwry
        
        /// DECRYPT text
        let decryptedText = Encryption.decryptText(chatRoomID: chatRoomId, encryptedMessage: messageDictionary[kMESSAGE] as! String)
        //create and return JSQ_message
        return JSQMessage(senderId: userid, senderDisplayName: name, date: date, text: decryptedText)
    }
    
    
    
    
    // CrEAte picture message -> called whenever we wnat to send a new picture message
    func createPictureMessage(messageDictionary: NSDictionary) -> JSQMessage {

        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        // check date
        var date: Date! // new date object
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        
        let mediaItem = PhotMediaItem(image: nil) // pass nil until photo is readty + downloaded
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!) //create JSQ_msgs
        
        
        /// download Image
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String) { (image) in
            
            if image != nil {
                mediaItem?.image = image!
                self.collectionView.reloadData()
            }
        }
    return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
        
    }


    func createVideoMessage(messageDictionary: NSDictionary) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date: Date!
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        let videoURL = NSURL(fileURLWithPath: messageDictionary[kVIDEO] as! String)
        
        /// >>>>>>>>>>>>>>>>>        let mediaItem =
        
        // pass video url and return outogoing status for user function
        let mediaItem = VideoMessage(withFileURL: videoURL,
                                     maskOutgoing: returnOutgoingStatusForUser(senderId: userId!))
        
        
        // download video
        downloadVideo(videoUrl: messageDictionary[kVIDEO] as! String) { (isReadyToPlay, fileName) in
            
            ///once we get our file we create NSURL with the fileURL path
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(filename: fileName))
            
            mediaItem.status = kSUCCESS
            mediaItem.fileURL = url
            
            /// now we got the video and need to make
            /// now we have the video and need to take thumbnail off the video
            
            imageFromData(pictureData: messageDictionary[kPICTURE] as! String, withBlock: { (image) in
                ///check if image is ready..
                
                if image != nil {
                    print("DEBUG: the image is \(image!)")
                    // mmake sure we have an image
                    mediaItem.image = image!
                    self.collectionView.reloadData() /// reload the screen as soon as the image is put on the image cell
                }
            })
            
            // we want to refresh now that we have loaded our video and so the loading bar will disapper
            self.collectionView.reloadData()
        }
        /// return the "VIDEO MESSAGE" to the user
        return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
        
    }
    
    
    // MARK: CREATE AUDIO MESSage
    
    func createAudioMessage(messageDictionary: NSDictionary) -> JSQMessage {
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userId = messageDictionary[kSENDERID] as? String
        
        var date: Date!
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date()
                
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        let audioItem = JSQAudioMediaItem(data: nil)
        audioItem.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userId!)


        /// create audio message with media item
        let audioMessage = JSQMessage(senderId: userId!, displayName: name!, media: audioItem)
        
        // Download and set Audio msg data
        downloadAudio(audioUrl: messageDictionary[kAUDIO] as! String) {
            (fileName) in
            
            let url = NSURL(fileURLWithPath: fileInDocumentsDirectory(filename: fileName))
            
            let audioData = try? Data(contentsOf: url as URL)
            audioItem.audioData = audioData
            
            self.collectionView.reloadData()
        }
        
        return audioMessage!
    }

    //MARK: Create a shareed-Location Message
    func createLocationMessage(messageDictionary: NSDictionary) -> JSQMessage {
        
        
        let name = messageDictionary[kSENDERNAME] as? String
        let userid = messageDictionary[kSENDERID] as? String
        
        // make sure correct date/time is given
        var date: Date! // instantiate a date new date obj
        
        if let created = messageDictionary[kDATE] {
            if (created as! String).count != 14 {
                date = Date() // date equal new date
            } else {
                date = dateFormatter().date(from: created as! String)
            }
        } else {
            date = Date()
        }
        
        
        //let text = messageDictionary[kMESSAGE] as! String   // where texts are stored in dictionwry
        let latitude = messageDictionary[kLATITUDE] as? Double
        let longitude = messageDictionary[kLONGITUDE] as? Double
        
        // creaTE JSQ message
        let mediaItem = JSQLocationMediaItem(location: nil)
        // once we get our location we want to refresh and show
        
        mediaItem?.appliesMediaViewMaskAsOutgoing = returnOutgoingStatusForUser(senderId: userid! )
        
        let location = CLLocation(latitude: latitude!, longitude: longitude!)
        
        // set the location media item then reload the collection view
        mediaItem?.setLocation(location, withCompletionHandler: {
            self.collectionView.reloadData()
        })
        
        //create and return JSQ_message
        return JSQMessage(senderId: userid, senderDisplayName: name, date: date, media: mediaItem)
    }
    
    
    
    
    
    



    //MARK: Helper
    // incoming or outgoing message(photo)
    func returnOutgoingStatusForUser(senderId: String) -> Bool {
// same as return**       if senderId == FUser.currentId() {
//            return true
//        } else {
//            return false
//        }
        
        return senderId == FUser.currentId()
    }
    
    
}
