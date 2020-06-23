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
            // create video
            print("Create video")
        case kAUDIO:
            // create Audio
            print("Create Audio")
        case kLOCATION:
            // create Location
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
    
    
    
    
    
    
    
    
    
    //MARK: Create Message types
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
        

        let text = messageDictionary[kMESSAGE] as! String   // where texts are stored in dictionwry
        //create and return JSQ_message
        return JSQMessage(senderId: userid, senderDisplayName: name, date: date, text: text)
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
        
        
        // download Image
        downloadImage(imageUrl: messageDictionary[kPICTURE] as! String) { (image) in
            
            if image != nil {
                mediaItem?.image = image!
                self.collectionView.reloadData()
            }
        }
    return JSQMessage(senderId: userId, senderDisplayName: name, date: date, media: mediaItem)
        
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
