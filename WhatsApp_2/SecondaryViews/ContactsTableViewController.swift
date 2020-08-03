//
//  ContactsTableViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 7/5/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import Contacts
import libPhoneNumber_iOS   /// import Contacts from iPhone
import FirebaseFirestore
import ProgressHUD

class ContactsTableViewController: UITableViewController, UISearchResultsUpdating, UserTableViewCellDelegate {

    var users: [FUser] = []
    var matchedUsers: [FUser] = [] /// users that are using app from our contact list
    var filteredMatchedUsers: [FUser] = []  /// users that we are searching for
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList: [String] = [] /// alphabetical order alphanumerics for contact list
    
    /// vars to check if there is a group chat
    var isGroup = false
    var memberIdsOfGroupChat: [String] = []
    var membersOfGroupChat: [FUser] = []
    
    /// create a SearchController to search contacts table view
    let searchController = UISearchController(searchResultsController: nil)
    
    
    lazy var contacts: [CNContact] = {      /// access ALL contacts from user phone and put in array

        
        // instantiate a Contact store object
        let contactStore = CNContactStore()
        
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactEmailAddressesKey,
            CNContactPhoneNumbersKey,
            CNContactImageDataAvailableKey,
            CNContactThumbnailImageDataKey] as [Any]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        /// end of retrieving contacts
        
        
        var results: [CNContact] = []
        
        /// Iterate all containers and APPEND their CONTACTS to our RESULTS-ARRAY
        for container in allContainers {
            
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try     contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        
        return results
    }()
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        //to remove empty cell lines
        tableView.tableFooterView = UIView()
        
        loadUsers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Contacts"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        //navigationItem.compactAppearance =
        
        searchController.searchResultsUpdater = self
        //searchController.dimsBackgroundDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false

        definesPresentationContext = true
        
        setupButtons()    // two buttons on the top-right side
    }
    
    
    
    
    //MARK: TableViewDataSource
    // check if searching
    override func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return self.allUsersGrouped.count
        }
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // check if user is in search mode or not
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredMatchedUsers.count
        } else {
            // find section title
            let sectionTitle = self.sectionTitleList[section]
            
            // find users for given section title
            let users = self.allUsersGrouped[sectionTitle]
            
            // return count for users
            return users!.count
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // initialize the cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! UserTableViewCell
        
        var user: FUser
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            
            let sectionTitle = self.sectionTitleList[indexPath.section]
            //get all users of the section
            let users = self.allUsersGrouped[sectionTitle]
            
            user = users![indexPath.row]
        }
        
        cell.delegate = self
        cell.generateCellWith(fUser: user, indexPath: indexPath)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            return self.sectionTitleList[section]
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if searchController.isActive && searchController.searchBar.text != "" {
            return nil
        } else {
            return self.sectionTitleList
        }
    }
    
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return index
    }
    
    
    
    
    //MARK: TableViewDelegate
    // when we click on a user
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// select a USER in "Contacts" list table view controller
        tableView.deselectRow(at: indexPath, animated: true)
        
        // first check if is a 1-on-1 chat << OR ...
        let sectionTitle = self.sectionTitleList[indexPath.section]
        let userToChat: FUser
        // check if we are in search mode or not
        if searchController.isActive && searchController.searchBar.text != "" {
            /// in search mode our UserToChat is our filtered matched users
            userToChat = filteredMatchedUsers[indexPath.row]
        } else {
            // our user is NOT in "CHAT"
            let users = self.allUsersGrouped[sectionTitle]
            
            userToChat = users![indexPath.row]
        }
        // check if it is a group chat
        if !isGroup {
            // 1 on 1 chat
            // start chatting (if user has not blocked user)
            if !checkBlockedStatus(withUser: userToChat) {
                
                let chatVC = ChatViewController()
                
                
                chatVC.titleName = userToChat.firstname
                chatVC.memberIds = [FUser.currentId(), userToChat.objectId]
                chatVC.membersToPush = [FUser.currentId(), userToChat.objectId]
                // pass chatroom
                chatVC.chatRoomId = startPrivateChat(user1: FUser.currentUser()!, user2: userToChat)
                chatVC.isGroup = false /// is not a group chat in this instance
                chatVC.hidesBottomBarWhenPushed = true
                
                self.navigationController?.pushViewController(chatVC, animated: true)   /// add ChatVC to Stack
            } else {
                ProgressHUD.showError("This user is not available for chat.")
            }
            
        } else {
            // is Group chat
            // ** checkMarks
            ///when user is clicked
            if let cell = tableView.cellForRow(at: indexPath) {
                if cell.accessoryType == .checkmark {
                    cell.accessoryType = .none
                } else {
                    cell.accessoryType = .checkmark
                }
            }
            
            // add/remove user from th array
            let selected = memberIdsOfGroupChat.contains(userToChat.objectId)
            
            if selected {
                let objectIndex = memberIdsOfGroupChat.firstIndex(of: userToChat.objectId)
                
                memberIdsOfGroupChat.remove(at: objectIndex!)
                // remove member of group chat
                membersOfGroupChat.remove(at: objectIndex!)
            } else {
                // add user to members of group chat
                memberIdsOfGroupChat.append(userToChat.objectId)    /// passes the members ID
                membersOfGroupChat.append(userToChat)               /// passes the user
            }
            
            // check  whether "Next" button should be enabled
            let membercount = ( memberIdsOfGroupChat.count > 0 )
            self.navigationItem.rightBarButtonItem?.isEnabled = membercount
        }
    }
    
    
    
    //MARK: IBActions
    
    @objc func inviteButtonPressed() {
        /// invite button pressed
        let text = "Hey! Lets chat on BatChat \(kAPPURL)"
        
        let objectsToShare: [Any] = [text]
        
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        activityViewController.setValue("Lets Chat on BatChat", forKey: "subject")
        
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    @objc func searchNearByButtonPressed() {
        // shows view for users to search
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "usersTableView") as! UsersTableViewController
        
        self.navigationController?.pushViewController(userVC, animated: true)
        print("Search near by pressed...")
        
    }
    
    
    /// "NEXT" button pressed
    @objc func nextButtonPressed() {
        ///Present the view
        let newGroupVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "newGroupView") as! NewGroupViewController
        
        newGroupVC.memberIds = memberIdsOfGroupChat
        newGroupVC.allMembers = membersOfGroupChat
        
        self.navigationController?.pushViewController(newGroupVC, animated: true)
        
        print("next button pressed...")
    }
    
    
    
    
    
    
    
    
    
    
    //MARK: Load Users to tableView --> ContactsTableView
    func loadUsers() {
        ProgressHUD.show()  // show users it is loading users
        /// show users in firebase in DESCENDING order
        reference(.User).order(by: kFIRSTNAME, descending: false).getDocuments { (snapshot, error) in
            
            guard let snapshot = snapshot else {
                // if it is loading snapshot then dismiss the progress hud loading symbol
                ProgressHUD.dismiss()
                return
            }
            
            
            if !snapshot.isEmpty {
                self.matchedUsers = []
                self.users.removeAll()  // clear the array
            
                for userDictionary in snapshot.documents {
                    let userDictionary = userDictionary.data() as NSDictionary /// set user dictionary
                    // put dictionary in FUser object
                    let fUser = FUser(_dictionary: userDictionary)
                    if fUser.objectId != FUser.currentId() {
                        self.users.append(fUser)
                    }
                }
                ProgressHUD.dismiss()
                self.tableView.reloadData()
                
            }
            ProgressHUD.dismiss()
            self.compareUsers()     // check if there are any matches
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    func compareUsers() {
        
        for user in users {
            
            if user.phoneNumber != "" { // if phone # is not empty
                
                let contact = searchForContactUsingPhoneNumber(phoneNumber: user.phoneNumber)
                
                // match user phone numbe with contacts in phone
                  
                //if we have a match, we add to our array to display them
                if contact.count > 0 {
                    matchedUsers.append(user)
                }
                
                self.tableView.reloadData()
                
            }
        }
        //        updateInformationLabel()
        
        self.splitDataInToSection()
    }
    
    //MARK: Contacts
    
    func searchForContactUsingPhoneNumber(phoneNumber: String) -> [CNContact] {
        /// check if there is a match of any firebasE phone #... if so, we dont want duplicates in firebase
        var result: [CNContact] = []
        
        //go through all contacts
        for contact in self.contacts {
            
            if !contact.phoneNumbers.isEmpty {
                
                //get the digits only of the phone number and replace + with 00
                let phoneNumberToCompareAgainst = updatePhoneNumber(phoneNumber: phoneNumber, replacePlusSign: true)
                
                //go through every number of each contac
                for phoneNumber in contact.phoneNumbers {
                    
                    let fulMobNumVar  = phoneNumber.value
                    let countryCode = fulMobNumVar.value(forKey: "countryCode") as? String
                    let phoneNumber = fulMobNumVar.value(forKey: "digits") as? String
                    
                    let contactNumber = removeCountryCode(countryCodeLetters: countryCode, fullPhoneNumber: phoneNumber!)
                    
                    //compare phoneNumber of contact with given user's phone number
                    if contactNumber == phoneNumberToCompareAgainst {
                        result.append(contact)
                    }
                    
                }
            }
        }
        
        return result
    }
    
    
    func updatePhoneNumber(phoneNumber: String, replacePlusSign: Bool) -> String {
        
        if replacePlusSign {
            return phoneNumber.replacingOccurrences(of: "+", with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
            
        } else {
            return phoneNumber.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
        }
    }
    
    
    func removeCountryCode(countryCodeLetters: String?, fullPhoneNumber: String) -> String {
        
        let phoneUtil = NBPhoneNumberUtil()
        //let countryCode = CountryCode()
        
        if countryCodeLetters != nil {
            do {
                let phoneNumber: NBPhoneNumber = try phoneUtil.parse(fullPhoneNumber, defaultRegion: countryCodeLetters!.uppercased())
                let formattedString: String = try phoneUtil.format(phoneNumber, numberFormat: .E164)
                
                return phoneNumber.nationalNumber.stringValue
            } catch let error as NSError {
                print("Debug: error at \(error.localizedDescription)")
                return ""
            }
        } else {
            return ""
        }
        
        
//        let countryCodeToRemove = countryCode.codeDictionaryShort[countryCodeLetters.uppercased()]
//
//        //remove + from country code
//        let updatedCode = updatePhoneNumber(phoneNumber: countryCodeToRemove!, replacePlusSign: true)
//
//        //remove countryCode
//        let replacedNUmber = fullPhoneNumber.replacingOccurrences(of: updatedCode, with: "").components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
//
//
//                print("Code \(countryCodeLetters)")
//                print("full number \(fullPhoneNumber)")
//                print("code to remove \(updatedCode)")
//                print("clean number is \(replacedNUmber)")
//
//        return replacedNUmber
    }
    
    fileprivate func splitDataInToSection() {
        
        // set section title "" at initial
        var sectionTitle: String = ""
        
        // iterate all records from array
        for i in 0..<self.matchedUsers.count {
            
            // get current record
            let currentUser = self.matchedUsers[i]
            
            // find first character from current record
            let firstChar = currentUser.firstname.first!
            
            // convert first character into string
            let firstCharString = "\(firstChar)"
            
            // if first character not match with past section title then create new section
            if firstCharString != sectionTitle {
                
                // set new title for section
                sectionTitle = firstCharString
                
                // add new section having key as section title and value as empty array of string
                self.allUsersGrouped[sectionTitle] = []
                
                // append title within section title list
                // first check if the section title is already in the array of titles
                if !sectionTitleList.contains(sectionTitle) {
                 
                    self.sectionTitleList.append(sectionTitle)
                }
            }
            
            // add record to the section
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
        tableView.reloadData()
    }
    


    //MARK: Search Controller functions --> Required protocall functions didTapAvatar
    func updateSearchResults(for searchController: UISearchController) {
        filteredContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filteredContentForSearchText(searchText: String, scope: String = "All") {
        filteredMatchedUsers = matchedUsers.filter({ (user) -> Bool in
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()  // refresh the tableView
    }
    
    
    
    //MARK: UserTableViewCellDelegate --> Required protocall functions didTapAvatar
    func didTapAvatarImage(indexPath: IndexPath) {
        // show avatar
        let profileVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "profileView") as! ProfileViewTableViewController
        
        var user: FUser!
        
        if searchController.isActive && searchController.searchBar.text != "" {
            user = filteredMatchedUsers[indexPath.row]
        } else {
            // we are not in search
            let sectionTitle = self.sectionTitleList[indexPath.row]
            
            // get all the users that belong in this section
            let users = self.allUsersGrouped[sectionTitle]
            
            // our user is the "users" we just created
            user = users![indexPath.row]
        }
        profileVC.user = user
        self.navigationController?.pushViewController(profileVC, animated: true)
    }
    
    //MARK: Helpers
    
    /// show the buttons at the top right hand corner of the Contacts View Controller
    func setupButtons() {
        ///depending on whther GROUP or a 1 on 1 chat ..
        
        if isGroup {
            // for group chat show "Next" button
            let nextButton = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(self.nextButtonPressed))
            self.navigationItem.rightBarButtonItem = nextButton
            self.navigationItem.rightBarButtonItems!.first!.isEnabled = false // by default we dont want to see this, only when the user to group chat is selected
        } else {
            // for 1 - on - 1 chat
            let inviteButton = UIBarButtonItem(image: UIImage(named: "invite"), style: .plain, target: self, action: #selector(self.inviteButtonPressed))
            
            let searchButton = UIBarButtonItem(image: UIImage(named: "nearMe"), style: .plain, target: self, action: #selector(self.searchNearByButtonPressed))
            
            /// add the buttons to the navigation controller
            self.navigationItem.rightBarButtonItems = [inviteButton, searchButton]
            
        }
        
    }
}
