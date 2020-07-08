//
//  InviteUsersTableViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 7/7/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import ProgressHUD
import Firebase


class InviteUsersTableViewController: UITableViewController, UserTableViewCellDelegate {
   

    @IBOutlet weak var headerView: UIView!
    
    var allUsers: [FUser] = []
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList : [String] = []
    
    var newMemberIds: [String] = []
    var currentMemberIds: [String] = []
    var group: NSDictionary!    // pass this group to our "invite users"
    
    
    //MARK: View will appear
    override func viewWillAppear(_ animated: Bool) {
       /// when view appears we want to LOAD our users
        loadUsers(filter: kCITY)
    }
    
    
        //MARK: View will disappear
    override func viewWillDisappear(_ animated: Bool) {
        ProgressHUD.dismiss()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set title
        self.title = "Users"
        // get rid of empty tableView cells
        tableView.tableFooterView = UIView()
        // create "Done" button for when group is complete
        self.navigationItem.rightBarButtonItems = [UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.doneButtonPressed))]
        
        // make the "done" button dissappear (disable)
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        currentMemberIds = group[kMEMBERS] as! [String]
    }

    
    
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.allUsersGrouped.count   /// returns all the users in the array
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionTitle = self.sectionTitleList[section]
        
        let users = self.allUsersGrouped[sectionTitle]
        return users!.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell
        
            let sectionTitle = self.sectionTitleList[indexPath.section]
            
            let users = self.allUsersGrouped[sectionTitle]
            
        let user = users![indexPath.row]
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        cell.delegate = self
        
        return cell
        
        
    }
    
    //MARK: tableView
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitleList[section]
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.sectionTitleList
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // deselect the row
        tableView.deselectRow(at: indexPath, animated: true)
        
        let sectionTitle = self.sectionTitleList[indexPath.section]
        // put checkMark on users we want in our Group Chat
        // first check if user is already selected "checked"
        // if not checked, add to the array of users
        let users = self.allUsersGrouped[sectionTitle]
        let selectedUser = users![indexPath.row]    ///access specific user whos CELL was tapped on
        
        // see if the user "tapped" is already in "Group"
        if currentMemberIds.contains(selectedUser.objectId) {
            ProgressHUD.showError("Already in the group!")
            return
        }
        
        /// checkMarks
        if let cell = tableView.cellForRow(at: indexPath) {
            /// check that we have a cell
            if cell.accessoryType == .checkmark {
                cell.accessoryType = .none // remove the checkmark if already there
            } else {
                cell.accessoryType = .checkmark // add the checkmark
            }
        }
        /// add or remove users from array
        let selected = newMemberIds.contains(selectedUser.objectId)
        
        
        // if user is selected" -> remove from the user array
        if selected {
            // remove
            let objectIndex = newMemberIds.firstIndex(of: selectedUser.objectId)!
            newMemberIds.remove(at: objectIndex)
        } else {
            // add to user array
            newMemberIds.append(selectedUser.objectId)
        }
        
        print("new member IDs: \(newMemberIds)")
        print("current member IDs \(currentMemberIds)")
        /* activate button when there are 1 or more user */
        self.navigationItem.rightBarButtonItem?.isEnabled = (newMemberIds.count > 0)
    }
    
    
    
    
    
    
    
    
    
    
    

    //MARK: Load Users from firebase with filter
    // filter by:
    // CIty
    // COuntry
    // BOTH
    func loadUsers(filter: String) {
        ProgressHUD.show() // shows loading bar
         
        //var query: Query!
        var query = reference(.User).order(by: kFIRSTNAME, descending: false)
        // case: -> Different Filters for user location query
        switch filter {
        case kCITY:
            // access *FireBase with REference function
            // reference references different type of folders
            // This query will access current User City
            // users are in order of FirstName not descending
            query = reference(.User).whereField(kCITY, isEqualTo: FUser.currentUser()!.city).order(by: kFIRSTNAME, descending: false)
        case kCOUNTRY:
            query = reference(.User).whereField(kCOUNTRY, isEqualTo: FUser.currentUser()!.country).order(by: kFIRSTNAME, descending: false)
        default:
            // default is get all user in User folder
            // order users by First Name
            query = reference(.User).order(by: kFIRSTNAME, descending: false)
        }
        
        // run our query
        // always make sure arrays are empty before running this function..
        // otherwise the users will duplicate everytime you look at the different filter/ searches
        query.getDocuments { (querySnapshot, error) in
            
            // reset these 3 every time this func is called
            self.allUsers = []  // empty array
            self.sectionTitleList = []  // empty array
            self.allUsersGrouped = [:] // empty dictionary
            
            // check if any errors
            if error != nil {
                print(error!.localizedDescription)
                ProgressHUD.dismiss()
                self.tableView.reloadData() // cleans the table view if error
                return
            }
            guard let querySnapshot = querySnapshot else {
                ProgressHUD.dismiss()
                return
            }
            
            //MARK: check if snapshot has data (USER)
            if !querySnapshot.isEmpty {
                // go through snapshot of USER: Document-Firebase
                for userDictionary in (querySnapshot.documents) {
                    let userDictionary = userDictionary.data() as NSDictionary
                    let fUser = FUser(_dictionary: userDictionary)
                    
                    // if the user is logged in - want to make sure they are not only viewing their profile
                    if fUser.objectId != FUser.currentId() {
                        self.allUsers.append(fUser)
                    }
                }
                // MARK:split Users to groups/ Sorting
                self.splitDataIntoSections()
                self.tableView.reloadData()
            }
            self.tableView.reloadData()
            ProgressHUD.dismiss()
        }
    }
    
    
    
    
    
    
    //MARK: IBactions
    
    @objc func doneButtonPressed() {
        /// update our group and save it to our firebase
        updateGroup(group: group)
    }
    
    
    @IBAction func filterSegmentValueChanged(_ sender: UISegmentedControl) {

        switch sender.selectedSegmentIndex {
        case 0:
            loadUsers(filter: kCITY)
        case 1:
            loadUsers(filter: kCOUNTRY)
        case 2:
            loadUsers(filter: "")
        default:
            return
        }

    }
    
    
    //MARK: Users TableVIew Cell Delegate (to get action when user taps Avatar img)
    func didTapAvatarImage(indexPath: IndexPath) {
        
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileViewTableViewController
        
        var user: FUser
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let users = self.allUsersGrouped[sectionTitle]
        
        
        user = users![indexPath.row]
        
        
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)

    }
    
    //MARK: Helper Functions
    
    func updateGroup(group: NSDictionary) {
        /// add new members to a "Group Chat"
        
        // get the members selected
        let tempMembers = currentMemberIds + newMemberIds   /// our "temp members"
        let tempMembersToPush = group[kMEMBERSTOPUSH] as! [String] + newMemberIds /// updates members to push for NOTIFICATIONS
        let withValues = [kMEMBERS : tempMembers, kMEMBERSTOPUSH : tempMembersToPush]
        
        Group.updateGroup(groupId: group[kGROUPID] as! String, withValues: withValues)  /// updates our "Group" in Firebase
        
        // update our most "Recent" msg to show in Chats View Controller
        createRecentForNewGroupMembers(groupId: group[kGROUPID] as! String, groupName: group[kNAME] as! String, membersToPush: tempMembersToPush, avatar: group[kAVATAR] as! String)
        
        // update members and membersToPush in firebase to mirror new number of members in group chats
        updateExistingRecentWithNewValues(chatRoomId: group[kGROUPID] as! String, members: tempMembers, withValues: withValues)
        // start a group chat
        goToGroupChat(membersToPush: tempMembersToPush, members: tempMembers)
    }
    
    
    
    func goToGroupChat(membersToPush: [String], members: [String]) {
        /// take user to group chat
        let chatVC = ChatViewController()
        chatVC.titleName = group[kNAME] as! String
        chatVC.memberIds = members
        chatVC.membersToPush = membersToPush
        chatVC.chatRoomId = group[kGROUPID] as! String
        chatVC.isGroup = true
        chatVC.hidesBottomBarWhenPushed = true
        
        self.navigationController?.pushViewController(chatVC, animated: true) // present "Group" chat
    }
    
    
    
    fileprivate func splitDataIntoSections() {
        
        var sectionTitle: String = ""
        
        for idx in 0..<self.allUsers.count {
            
            let currentUser = self.allUsers[idx]
            
            let firstChar = currentUser.firstname.first!
            
            let firstCharString = "\(firstChar)"
            
            if firstCharString != sectionTitle {
                sectionTitle = firstCharString
                self.allUsersGrouped[sectionTitle] = []
                
                if !sectionTitleList.contains(sectionTitle) {
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            
            // add the users first initial to *filter* through all users in firebase
            self.allUsersGrouped[firstCharString]?.append(currentUser)
            
        }
        
        
    }
    
    
    
    
}
