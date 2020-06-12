//
//  ChatsViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/8/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import FirebaseFirestore

class ChatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
 
    

   
    @IBOutlet weak var tableView: UITableView!
    
    // hold array of standard recent chats
    var recentChats: [NSDictionary] = []
    var filteredChats: [NSDictionary] = [] // for search
    
    // import a <#Listener> from FireBase
    var recentListener: ListenerRegistration! // listens for new changes
    
    override func viewWillAppear(_ animated: Bool) {
        loadRecentChats()
        
        tableView.tableFooterView =  UIView()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        //MARK: when will the view disapeer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //MARK: make CHAT #navBar big title
        navigationController?.navigationBar.prefersLargeTitles = true
        
        //MARK: load recent chats
        loadRecentChats()

    }
    
    
    
    //MARK: IBACTIONS
    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        
        // display table view
        // must access story board
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "usersTableView") as! UsersTableViewController
        
        self.navigationController?.pushViewController(userVC, animated: true)
        
        
    }
    
    
    
    
    
    
    
    //MARK: TableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("we have \(recentChats.count) recents")
        return recentChats.count
     }
     
    // setup UI Table Viewcell
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath) as! RecentChatsTableViewCell
       
        //MARK: Display chats to Cell
        let recent = recentChats[indexPath.row]
        
        cell.generateCell(recentChat: recent, indexPath: indexPath)
        
        return cell
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
    

}
