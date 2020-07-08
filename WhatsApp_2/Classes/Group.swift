//
//  Group.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 7/6/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation
import FirebaseFirestore

class Group {
    
    let groupDictionary: NSMutableDictionary
    
    init(groupId: String, subject: String, ownerId: String, members: [String], avatarIcon: String) {
        
        groupDictionary = NSMutableDictionary(objects: [groupId, subject, ownerId, members, members, avatarIcon], forKeys: [kGROUPID as NSCopying, kNAME as NSCopying, kOWNERID as NSCopying, kMEMBERS as NSCopying, kMEMBERSTOPUSH as NSCopying, kAVATAR as NSCopying])
    }
    
    func saveGroup() {
        ///savs "Group chat" to Firebase reference
        let date = dateFormatter().string(from: Date())
        
        // set date for our group
        groupDictionary[kDATE] = date
        
        // reference firestore to make a new Node(document) that is for "GROUP"
        reference(.Group).document(groupDictionary[kGROUPID] as! String).setData(groupDictionary as! [String: Any])
    }
    
    class func updateGroup(groupId: String, withValues: [String: Any]) {
        reference(.Group).document(groupId).updateData(withValues)
    }
}
