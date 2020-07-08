//
//  ChatsViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/8/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, RecentChatsTableViewCellDelegate, UISearchResultsUpdating {
  
   
    @IBOutlet weak var tableView: UITableView!
    
    // hold array of standard recent chats
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = [] // for search
    
    // import a <#Listener> from FireBase
    var recentListener: ListenerRegistration! // listens for new changes
    
    // instantiate a search bar controller
    let myChatSearchController = UISearchController(searchResultsController: nil)
    
    
    override func viewWillAppear(_ animated: Bool) {
        //MARK: load recent chats
        loadRecentChats()
        tableView.tableFooterView =  UIView()
        
    }
    
    
    //MARK: remove the listener when user is not logged in to save on server costs
    override func viewWillDisappear(_ animated: Bool) {
        //MARK: when will the view disapeer
        recentListener.remove()
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: make CHAT #navBar big title
        navigationController?.navigationBar.prefersLargeTitles = true
        //MARK: setup Search bar
        navigationItem.searchController = myChatSearchController
        navigationItem.hidesSearchBarWhenScrolling = true // hide search bar when scrolling
        
        myChatSearchController.searchResultsUpdater = self // object in charge of updating results in search controller
        //myChatSearchController.dimsBackgroundDuringPresentation = false   // **New: same as obscureBackgroudDuringPresentation
        // last line (55) same as below 57
        myChatSearchController.obscuresBackgroundDuringPresentation = false
        definesPresentationContext = true
        
        
        //MARK: load recent chats
        //loadRecentChats()
        setTableViewHeader()

    }
    
    
    
    
    
    //MARK: IBACTIONS
    
    
    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        
        // display table view
        // must access story board
/*
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "usersTableView") as! UsersTableViewController
        
        self.navigationController?.pushViewController(userVC, animated: true)
        */
        selectUserForChat(isGroup: false)
        
    }
    
    
    @objc func groupButtonPressed() {
        selectUserForChat(isGroup: true)
        print("DEBUG: Hello, Group button was pressed")
    }
    
    
    
    
    
    
    //MARK: TableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("we have \(recentChats.count) recents")
        if myChatSearchController.isActive && myChatSearchController.searchBar.text != "" {
            return filteredChats.count
        } else {
            
            return recentChats.count
        }
     }
     
    
    
    
    // setup UI Table Viewcell
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! RecentChatsTableViewCell
       
        //MARK: update our view to know it is now a delegate of tableView Cell
        cell.delegate = self
        
        //MARK: Display chats to Cell
        let recent: NSDictionary!
        
        
        if myChatSearchController.isActive && myChatSearchController.searchBar.text != "" {
               recent = filteredChats[indexPath.row]
           } else {
               recent = recentChats[indexPath.row]
           }
        
        cell.generateCell(recentChat: recent, indexPath: indexPath)
        
        return cell
     }

    
    
    
    //MARK: TableViewDelegate functions
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    
        //Create mute and Delete buttons
        var tempRecent: NSDictionary!
        
       // let tempDictionary: NSDictionary!
        if myChatSearchController.isActive && myChatSearchController.searchBar.text != "" {
            tempRecent = filteredChats[indexPath.row]
        } else {
            tempRecent = recentChats[indexPath.row]
        }
        
        
        //MARK: Mute + Un-Mute
        var muteTitle = "Unmute"
        var mute = false
        
        
        
        if (tempRecent[kMEMBERSTOPUSH] as! [String]).contains(FUser.currentId()) {
            muteTitle = "Mute"
            mute = true
        }
        
        
        // DELETE last CHAT item
        
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete") { (action, indexPath) in
            //print("Delete \(indexPath )")
            self.recentChats.remove(at: indexPath.row)
            //deleteRecentChat(recentChatDictionary: tempRecent)
            //MARK: delete the previous chat
            deleteRecentChat(recentChatDictionary: tempRecent)
            self.tableView.reloadData()
            
        }
        
        
        let muteAction = UITableViewRowAction(style: .default, title: muteTitle) { (action, indexPath) in
            print("Mute \(indexPath) in Chats View Controller")
            self.updatePushMembers(recent: tempRecent, mute: mute)
        }
        //let m = UISwipeActionsConfiguration(s)
        
        muteAction.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        
        return [deleteAction, muteAction]

    }
    
    
//MARK: HERE >>>>>>>>>
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // look if in search mode or not
        var recent: NSDictionary!
        
        if myChatSearchController.isActive && myChatSearchController.searchBar.text != "" {
            recent = filteredChats[indexPath.row]
        } else {
            recent = recentChats[indexPath.row]
        }
        //once we click on tne recent chatVIew we want to go to..
        //MARK: Restart the Chat
        restartRecentChat(recent: recent)
        
        
        
        
        
        
        //MARK: Show chatView andchat view  components 
        let chatVC = ChatViewController()
        chatVC.hidesBottomBarWhenPushed = true  //hide navigation TAB
        // before we use navigateConroller we
        chatVC.titleName = (recent[kWITHUSERFULLNAME] as? String)!
        chatVC.memberIds = (recent[kMEMBERS] as? [String])!
        chatVC.membersToPush = (recent[kMEMBERSTOPUSH] as? [String])!
        chatVC.chatRoomId = (recent[kCHATROOMID] as? String)!
        //chatVC.isGroup = false
        chatVC.isGroup = (recent[kTYPE] as! String) == kGROUP
        navigationController?.pushViewController(chatVC, animated: true)
    }
    
    
    
    
    
    
    
    //MARK: Load Recent Chats
    func loadRecentChats() {
        // load "Documents" from 'Currnt user' in Firestore
        // once logged out of the "Chats" View - we will turn off the listenerRegistration with firebase
        // access references -> .recent -> wherefield -> pass user and check to make sure is equal to Fuser current id -> add snap shot listener
        recentListener = reference(.Recent).whereField(kUSERID, isEqualTo: FUser.currentId()).addSnapshotListener({ (chatSnapshot, error) in
            
            guard let chatSnapshot = chatSnapshot else { return }
            
            // access recent chats array to make sure there isnt duplicate objects in the view
            self.recentChats = []
            
            if !chatSnapshot.isEmpty {
                // sort most recent chat/ message by date
                
                // put the chat/MSG documents in a variable (type: NSArray) so we can sort the data by data/time
                let sorted = ((dictionaryFromSnapshots(snapshots: chatSnapshot.documents)) as NSArray).sortedArray(using: [NSSortDescriptor(key: kDATE, ascending: false)]) as! [NSDictionary]
                
                // loop through the sorted items
                for recent in sorted {
                    // check if last recent is empty string
                    // check to make sure has correct chat room id
                    // check to make sure there is a recent ID
                    if recent[kLASTMESSAGE] as! String != "" && recent[kCHATROOMID] != nil && recent[kRECENTID] != nil {
                        self.recentChats.append(recent)
                    }
                }
                self.tableView.reloadData()
            }
        })
    }
    
    
    //MARK: setTableVIewHeader for "Chats" view
    
    func setTableViewHeader() {
        //create 2 views
        // add to tableView
        
        //create big, header view
        // tableView.frame.width> stretch from one frame to another, height = 45 pts
        //let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 45))
        //create button for inside the View saying "New Group"
        // height is 10 less than header so 5pt margin on top+bottom
        //let buttonView = UIView(frame: CGRect(x: 0, y: 5, width: tableView.frame.width, height: 35))
        let buttonView = UIView(frame: CGRect(x: 0, y: 5, width: tableView.frame.width, height: 35))
        
        // take length of tableVIew and subtract by 110 so it ends up towards the right hand side of the header for tableView, 10 pt margin
        //let buttonPosition = tableView.frame.width - 110
        let buttonPosition = tableView.frame.width - 150

        let groupButton = UIButton(frame: CGRect(x: buttonPosition, y: 10, width: 100, height: 20))
        
        //MARK: add target allows USER to tap button
        groupButton.addTarget(self, action: #selector(self.groupButtonPressed), for: .touchUpInside)
        
        // set button/ title
        groupButton.setTitle("New Group", for: .normal)
        // set button text color
        let buttonColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        groupButton.setTitleColor(buttonColor, for: .normal)
        
        // set line above/ between chats tableView
        let lineSeperatorHeight = headerView.frame.height - 1
        let lineSeperatorWidth = headerView.frame.width
        let lineView = UIView(frame: CGRect(x: 0, y: lineSeperatorHeight, width: lineSeperatorWidth, height: 1))
        // set color for lineView/ seperator
        lineView.backgroundColor = #colorLiteral(red: 0.8319024444, green: 0.8269578815, blue: 0.8357037306, alpha: 1)
        
        // add buttons and view components to tableView-header
        buttonView.addSubview(groupButton)
        headerView.addSubview(buttonView)
        headerView.addSubview(lineView)
        tableView.tableHeaderView = headerView
    }
    

    
    //MARK: RecentChatCell Delegate:
    //want our avatarTap to display the profileView
    func didTapAvatarImage(indexPath: IndexPath) {
        //access the "Filtered-recent chats element
       // let recentChat =
        
        let recentChat: NSDictionary!
         
         // checks dictionary items for search bar use
         if myChatSearchController.isActive && myChatSearchController.searchBar.text != "" {
                recentChat = filteredChats[indexPath.row]
            } else {
                recentChat = recentChats[indexPath.row]
            }
         
        
        //Check if Private or Group Chat
        if recentChat[kTYPE] as! String == kPRIVATE {
            
            //access firestore user -> userID -> Document (path) = where path = recentChat[withUSeruserID] as! string -> get documnet
            // kWITHUSERuserID is on path so dont have to search
            reference(.User).document(recentChat[kWITHUSERUSERID] as! String).getDocument { (userSnapshot, error) in
                print(userSnapshot)
                guard let snapshot = userSnapshot else { return }
                
                if snapshot.exists {
                    let userDict = snapshot.data() as! NSDictionary
                    
                    let tempUser = FUser(_dictionary: userDict)
                    
                    
                    //take the user and get profile view, then display it
                    self.showUserProfile(user: tempUser)
                }
                
                
                
            }
            
        }
        
      }
    
    //MARK: Display our user
    func showUserProfile(user: FUser) {
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileViewTableViewController
        
        profileVC.user = user
        
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    
    
    
    
    
    //MARK: Search Controller Functions
    
    func filtterContentForSearchText(searchText: String, scope: String = "All") {
        filteredChats = recentChats.filter({ (recentChat) -> Bool in
            return (recentChat[kWITHUSERFULLNAME] as! String).lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        
        filtterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    
    //MARK: Helper functions
    /// mute users from other users
    func updatePushMembers(recent: NSDictionary, mute: Bool) {
        // tell whether we should mute or unmute it
        // get the members to push
        
        var membersToPush = recent[kMEMBERSTOPUSH] as! [String]
        
        if mute {
            // remove our user from array as they are being MUTED
            //let index = membersToPush.index(of: FUser.currentId())!

            let index = membersToPush.firstIndex(of: FUser.currentId())!
            membersToPush.remove(at: index)
        } else {
            /// they are being unMUTED
            membersToPush.append(FUser.currentId())
        }
        
        /// SAVE changes to * Firesoter * function written in Recents.Swift
        updateExistingRecentWithNewValues(chatRoomId: recent[kCHATROOMID] as! String, members: recent[kMEMBERS] as! [String], withValues: [kMEMBERSTOPUSH : membersToPush])
    }
    
    func selectUserForChat(isGroup: Bool) {
        
//
//        let contactsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "contactsView") as! ContactsTableViewController
        let contactsVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "contactsView") as! ContactsTableViewController
        
        contactsVC.isGroup = isGroup
        
        
        self.navigationController?.pushViewController(contactsVC, animated: true)
    }
    
}
