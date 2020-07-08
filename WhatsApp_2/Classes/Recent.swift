//
//  Recent.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/10/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import Foundation

//MARK: Start private Chat with fancy chatroom ID -> is unique
func startPrivateChat(user1: FUser, user2: FUser) -> String {
    // create Unique identifier for when the two users -> when they CHat they will have same ID
    let userID1 = user1.objectId
    let userID2 = user2.objectId
    
    var chatRoomId = ""
    
    // generate a chat room ID
    let value = userID1.compare(userID2).rawValue
    
    
    // no matter which user selects chat, their chat ID will be the same
    if value < 0 {
        chatRoomId = userID1 + userID2
        }
    else {
        chatRoomId = userID2 + userID1
    }
    
    let members = [userID1, userID2]
    
    
    //    create recent chats
    createRecentChats(members: members, chatRoomId: chatRoomId, withUserName: "", typeOfChat: kPRIVATE, users:
        [user1, user2], avatarOfGroup: nil)
    
    
    return chatRoomId
}

//MARK: used only for private chat in the Group Chat
// optional because ONLY used for groupCHat
func createRecentChats(members: [String], chatRoomId: String, withUserName: String,
                       typeOfChat: String, users: [FUser]?, avatarOfGroup: String?) {
    
    var tempMembers = members // create local var to manipulate embers variable
    
    // check if user has an existing 'kCHATROOM' ID
    // look in FIREStore for the chat room ID
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        // check if we have a snapshot
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            // if we have a snapshot -> go through the snapshot Documents
            for recentChat in snapshot.documents {
                // for every recent chat in our snapshot . . .
                // going to check for recent is correct Object /User ID and not a currupt file
                //MARK: we are getting the <#JSON> so we must specify NSDictionary to  get the <#Firebase #Chat data> here! (Collection -> Fields[])
                let recent = recentChat.data() as NSDictionary
                
                
                //MARK: check if recent chat is our current user
                if let currentUserId = recent[kUSERID] {
                    //MARK: check if member is the recent do not create new object for the member
                    // if the other member
                    if tempMembers.contains(currentUserId as! String) {
                        let chatIndex = tempMembers.index(of: currentUserId as! String)!
                        tempMembers.remove(at: chatIndex) // remove user we just checked..
                    }
                }
            }
            
        }
        // MARK: create recents for fUsers: for every member that werwe left in temp array
        
        
        for userId in tempMembers {
            //MARK: create recent items!
            createRecentItems(userId: userId, chatRoomId: chatRoomId, members: members, withUser_UserName: withUserName,
                              typeOfChat: typeOfChat, users: users, avatarOfGroup: avatarOfGroup)
        }
    
    }
    
    
}

func createRecentItems(userId: String, chatRoomId: String, members: [String], withUser_UserName: String,
                       typeOfChat: String, users: [FUser]?, avatarOfGroup: String?) {
    
    // create a reference of RECENT documets in FireBase
    let localReference = reference(.Recent).document()
    let recentId = localReference.documentID
    // String representing our current date
    let date = dateFormatter().string(from: Date())
    
    var recent: [String : Any]! // empty dictionary
    
    
    // private chat reference
    if typeOfChat == kPRIVATE {
        var withUser: FUser?
        // make sure there are user objects
        if users != nil && users!.count > 0 {
            // icheck if fUser is = to current user ID - we are creating object *FOR Current User
            if userId == FUser.currentId() {
                // *FOR Current User
                withUser = users!.last! // private chat: will pass the withUser as the "last user"
                
            } else {
                // we are creating for other user
                withUser = users!.first! // private chat: will pass first user as "Current user"
            }
        }
        
        // create Recent DIctionary
        //MARK: kMEMBERSTOPUSH - which of Member in chat will be receiving push notifications, when to mute/ unmute of the chat
        //MARK: kLASTMESSAGE - lastMessage is the newest message
        //MARK: kCOUNTER - the # of messegas (unread integer # on user profile) "int x of unread messages", 0 because we want to <show Newest MSG>
        recent = [kRECENTID : recentId, kUSERID : userId, kCHATROOMID: chatRoomId, kMEMBERS : members, kMEMBERSTOPUSH : members,
                  kWITHUSERFULLNAME : withUser!.fullname, kWITHUSERUSERID: withUser!.objectId, kLASTMESSAGE : "", kCOUNTER : 0, kDATE : date, kTYPE: typeOfChat, kAVATAR : withUser!.avatar] as [String : Any]
        
        
    } else {
        // with group
        
        if avatarOfGroup != nil {
            //MARK: we have passsed an avatar to the group
            recent = [kRECENTID: recentId, kUSERID : userId, kCHATROOMID : chatRoomId, kMEMBERS : members, kMEMBERSTOPUSH : members, kWITHUSERFULLNAME : withUser_UserName, kLASTMESSAGE : "",
                      kCOUNTER : 0, kDATE : date, kTYPE : typeOfChat, kAVATAR : avatarOfGroup!] as [String : Any]
        }
    }
    
    //MARK: Save the recent Chat from the recent dictionary for Firebase
    localReference.setData(recent)
    
}



//MARK: Restart Chat

func restartRecentChat(recent: NSDictionary) {
    
    
    if recent[kTYPE] as! String == kPRIVATE {
        // our recent was a private Chat

        createRecentChats(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID] as! String, withUserName: FUser.currentUser()!.firstname, typeOfChat: kPRIVATE, users:  [FUser.currentUser()!], avatarOfGroup: nil)
    }
    
    if recent[kTYPE] as! String == kGROUP {
        //print(".... \(recent)")
        createRecentChats(members: recent[kMEMBERSTOPUSH] as! [String], chatRoomId: recent[kCHATROOMID]
            as! String, withUserName: recent[kWITHUSERFULLNAME] as! String, typeOfChat: kGROUP, users: nil, avatarOfGroup: recent[kAVATAR] as? String)

    }
}


//MARK: Update Recent chats

func updateRecents(chatRoomId: String, lastMessage: String) {
    /// this is called every time we are sending a message... >> Called in OUTGOINGMESSAGE.Swift
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        // check if there is a snapshot
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            // we have a "RECENT CHAT" object
            for recent in snapshot.documents {
                // fpr every recent item let current
                let mostRecentMSG = recent.data() as NSDictionary
                
                updateRecentItem(recent: mostRecentMSG, lastMessage: lastMessage)
            }
        }
    }
}






/// this function will be called from our "Chats" View controller when we are sendinfg message
func updateRecentItem(recent: NSDictionary, lastMessage: String) {
    
    // update the recent msgs date
    let date = dateFormatter().string(from: Date())
    
    var counter = recent[kCOUNTER] as! Int
    
    /// update all the "recent" chat item counters, + 1 every time a message is sent and is not read.
    if recent[kUSERID] as? String != FUser.currentId() {
        counter += 1
    }
    
    // crete a dictionary of  values we want to update
    let values = [kLASTMESSAGE : lastMessage, kCOUNTER : counter, kDATE : date] as [String : Any]
    
    reference(.Recent).document(recent[kRECENTID] as! String).updateData(values)
}
















//MARK: Delete Recent CHats

func deleteRecentChat(recentChatDictionary: NSDictionary) {
    
    if let recentID = recentChatDictionary[kRECENTID] {
        // if we have a recent ID then we access our "Recent" file and say what we want to delete
        
        //MARK: >>    DELETE! < FIreDOcument Item
        reference(.Recent).document(recentID as! String).delete()
    }
}


//MARK: Clear recent messags >COUNTER>


func clearRecentCounterItem(recent: NSDictionary) {
    reference(.Recent).document(recent[kRECENTID] as! String).updateData([kCOUNTER : 0])
}

// get chatRoom Id
func clearRecentCounter(chatRoomId: String) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        
        // check if there is a snapshot
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            // we have a "RECENT CHAT" object
            for recent in snapshot.documents {
                // fpr every recent item let current
                let currentRecent = recent.data() as NSDictionary
                
                if currentRecent[kUSERID] as? String == FUser.currentId() {
                    /// if it's the correct current user
                    
                    clearRecentCounterItem(recent: currentRecent)
                }
            }
        }
    }
}

//MARK: "Group" chats *Most Recent MSG*

func startGroupChat(group: Group) {
    
    let chatRoomId = group.groupDictionary[kGROUPID] as! String
    let members = group.groupDictionary[kMEMBERS] as! [String]
    
    //createRecent(members: [String], chatRoomId: String, withUserName: String, type: String, users: [FUser]?,
    createRecentChats(members: members, chatRoomId: chatRoomId, withUserName: group.groupDictionary[kNAME] as! String, typeOfChat: kGROUP, users: nil, avatarOfGroup: (group.groupDictionary[kAVATAR] as? String))
    
}


func createRecentForNewGroupMembers(groupId: String, groupName: String, membersToPush: [String], avatar: String) {
    
    /// if one member invites another user ..
    // goes into createRecentChats function and sees if therere is already a "Recent" message for group
    createRecentChats(members: membersToPush, chatRoomId: groupId, withUserName: groupName, typeOfChat: kGROUP, users: nil, avatarOfGroup: avatar)
    
}









func updateExistingRecentWithNewValues(chatRoomId: String, members: [String], withValues: [String : Any]) {
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: chatRoomId).getDocuments { (snapshot, error) in
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                /// browse the recent firebase snapshot document ...
                ///  read recent as NSDictionary object
                let recent_ = recent.data() as NSDictionary
                
                updateRecent(recentId: recent_[kRECENTID] as! String, withValues: withValues)
            }
        }
    }
}

func updateRecent(recentId: String, withValues: [String : Any]) {
    /// update every RECENT in firebase from our chat
    reference(.Recent).document(recentId).updateData(withValues)
}






//MARK: BlockUser
func blockUser(userToBlock: FUser) {
    
    
    // create chat room ID to block user from the chat
    // create Unique identifier for when the two users -> when they CHat they will have same ID
    let userID1 = FUser.currentId()
    let userID2 = userToBlock.objectId
    
    var chatRoomId = ""
    
    // generate a chat room ID
    let value = userID1.compare(userID2).rawValue
    
    
    // no matter which user selects chat, their chat ID will be the same
    if value < 0 {
        chatRoomId = userID1 + userID2
    }
    else {
        chatRoomId = userID2 + userID1
    }
    
    // get all the RECENTS from the chatRoomId so we can delete them
    getRecents(forChatRoomId: chatRoomId)
}

/// get all the RECENTS from the chatRoomId so we can delete them
func getRecents(forChatRoomId: String) {
    
    reference(.Recent).whereField(kCHATROOMID, isEqualTo: forChatRoomId).getDocuments { (snapshot, error) in
        
        guard let snapshot = snapshot else { return }
        
        if !snapshot.isEmpty {
            for recent in snapshot.documents {
                
                let recents = recent.data() as NSDictionary
                
                deleteRecentChat(recentChatDictionary: recents)
            }
        }
    }
}
