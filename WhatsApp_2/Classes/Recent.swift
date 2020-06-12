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
