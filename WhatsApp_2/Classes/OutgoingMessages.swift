//
//  OutgoingMessages.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/14/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation


class OutgoingMessage {
    
    
    
    let myMessageDictionary: NSMutableDictionary
    
    //MARK: Initializers
    
    // MARK: text message
    init(message: String, senderId: String, senderName: String, date: Date, status: String, type: String) {
        // access messageDictionary and get function [objects], forkeys (pass all elements here in objects)
        //myMessageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), status, type], forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kSENDERID as NSCopying,kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
        myMessageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date), status, type],forKeys: [kMESSAGE as NSCopying, kSENDERID as NSCopying, kSENDERNAME as NSCopying, kDATE as NSCopying, kSTATUS as NSCopying, kTYPE as NSCopying])
    }
    
    //MARK: Picture message
    init(message: String, pictureLink: String, senderId: String, senderName: String,
         date: Date, status: String, type: String) {
        myMessageDictionary = NSMutableDictionary(objects: [message, pictureLink, senderId, senderName,
            dateFormatter().string(from: date), status, type],
                                                  forKeys: [
                                                    kMESSAGE as NSCopying,
                                                    kPICTURE as NSCopying,
                                                    kSENDERID as NSCopying,
                                                    kSENDERNAME as NSCopying,
                                                    kDATE as NSCopying,
                                                    kSTATUS as NSCopying,
                                                    kTYPE as NSCopying ])
        //Error.self = false

    }
    
    //MARK: Video Message: Outgoing
    init(message: String, videoLink: String, thumbNail: NSData, senderId: String, senderName: String, date: Date, status: String, type: String) {
        ///CREATE THUMBNAIL
        let vidThumb = thumbNail.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) /// taks our nsData obj (our image) and  convert image to STRING
        
        
        // save vidThumb in dictionary because you c ant save "thumbnail" as it is NSDATA and we are expecting base
        myMessageDictionary = NSMutableDictionary(objects: [
                                                            message, videoLink, vidThumb, senderId, senderName,
                                                            dateFormatter().string(from: date), status, type ],
                                                  forKeys: [
                                                            kMESSAGE as NSCopying,
                                                            kVIDEO as NSCopying,
                                                            kPICTURE as NSCopying,
                                                            kSENDERID as NSCopying,
                                                            kSENDERNAME as NSCopying,
                                                            kDATE as NSCopying,
                                                            kSTATUS as NSCopying,
                                                            kTYPE as NSCopying ])
    
    }
    


    //MARK: Send Message
    //func sendMessagetoFirebase(chatRoomID: String, messageDictionaryParamater: NSDictionary, memberIDs: [String], membersToPush: [String]) {
    func sendMessagetoFirebase(chatRoomId: String, messageDictionary: NSMutableDictionary, memberIds: [String], membersToPush: [String]) {
    
        
        // CREATE Unique ID for chatRoom so the messages can look at if the chatroom Id is correct the messages should be stored in that
        let messageId = UUID().uuidString   // set a UUid for the grouped/ (two users) users
        
        //messageDictionary[kMESSAGEID] = messageId     //Id store the uuid in our Dictionary
        myMessageDictionary[kMESSAGEID] = messageId
        
        
        // (1) loop through memberIds to create when to create a "Message" reference
        for memberId in memberIds {
            // access messages in FIrebase
            // access memberID for document
            // generate message
            reference(.Message).document(memberId).collection(chatRoomId).document(messageId).setData(messageDictionary as! [String:Any])
        }
        
        // (2) also update recent chat and dates in "Chats" viewController
        
        // (3) send push Notificatiom
    }



}
