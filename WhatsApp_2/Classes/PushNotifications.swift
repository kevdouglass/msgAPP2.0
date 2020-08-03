//
//  PushNotifications.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 7/9/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import OneSignal

func sendPushNotification(memberToPush: [String], message: String) {
    
    let updatedMembers = removeCurrentUserFromMembersArray(members: memberToPush)
    
    // get the member ids to send push notification (we are given our object id, use this to send push notifications )
    getMembersToPush(members: updatedMembers) { (userPushIds) in
        /// return a *push id * for each user
        let currentUser = FUser.currentUser()!
        
        /* This is were "REAL" push notification is MADE */
        OneSignal.postNotification(["contents":[ "en":"\(currentUser.firstname) \n \(message)"], "ios_badgeType":"Increase", "ios_badgeCount":"1", "include_player_ids":userPushIds
        ])
    }
    
}


func removeCurrentUserFromMembersArray(members: [String]) -> [String] {
    /// go thru all the current users
    /// removes our current user
    /// returns the rest
    var updatedMembers : [String] = []
    
    // loop thru and check if ID matches current member
    for memberId in members {
        if memberId != FUser.currentId() {
            /// if its not current member ID we add it to our updated members
            updatedMembers.append(memberId)
        }
    }
    
    return updatedMembers
    
}

func getMembersToPush(members: [String], completion: @escaping (_ usersArray: [String]) -> Void) {
   // go and get the members pushIDs
    // access Firestore
    var pushIds: [String] = []
    var count = 0
    
    for memberId in members {
        // go to firebase and get user object
        // reference that user
        reference(.User).document(memberId).getDocument { (snapshot, error) in
            //check that snapshot was successful
            guard let snapshot = snapshot else {
                completion(pushIds)
                return
            }
            if snapshot.exists {
                let userDictionary = snapshot.data() as! NSDictionary
                let fUser = FUser.init(_dictionary: userDictionary)
                
                /// access push iD
                pushIds.append(fUser.pushId!)   // put pushId in array
                count += 1
                
                /// we dont know where it is finishing so return here
                /// check that we have gone thru all of our users
                if members.count == count {
                    completion(pushIds) /// we have gone thru all users at this point
                }
                
                
            } else {
                completion(pushIds)         // currently empty
            }
            
            
        }
    }
}
