//
//  UsersTableViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/8/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import Firebase
import ProgressHUD

class UsersTableViewController: UITableViewController, UISearchResultsUpdating {
    // *regquired for protocal
   
    /*func updateSearchResults(for searchController: UISearchController) {
        
    }
    */
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var filterSegmentControl: UISegmentedControl!
    
    // save users from #firebase
    var allUsers: [FUser] = [] // All Users in our Firebase
    var filteredUsers: [FUser] = [] // Stores the reuslts typed in searchBar
    // so we can alphabeticl Users
    var allUsersGrouped = NSDictionary() as! [String : [FUser]]
    var sectionTitleList: [String] = []
    
    
    // create Search controller (searchBar)
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Users"
        navigationItem.largeTitleDisplayMode = .never
        
        // instantiate new #View controller
        // appears under table view data
        // if no data then no tableView lines
        tableView.tableFooterView = UIView()
        
        
        navigationItem.searchController = searchController
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        loadUsers(filter: kCITY)
       
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // code for # of sections - when search bar is active
        if searchController.isActive && searchController.searchBar.text != "" {
            return 1
        } else {
            return allUsersGrouped.count
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredUsers.count
        } else {
            // find section Title
            let sectionTitle = self.sectionTitleList[section]
            
            // user for Given Title
            let users = self.allUsersGrouped[sectionTitle]
            
            return users!.count
        }
        //return allUsers.count
    }

        override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       // let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! UserTableViewCell

        // Configure the cell...
            var user: FUser
            if searchController.isActive && searchController.searchBar.text != "" {
                user = filteredUsers[indexPath.row]
            } else {
                //let sectionTitle = self.sectionTitleList[indexPath.row] -> gives same name
                let sectionTitle = self.sectionTitleList[indexPath.section] // section accesses each user
                let users = self.allUsersGrouped[sectionTitle]
                
                user = users![indexPath.row]
                
            }
            cell.generateCellWith(fUser: user, indexPath: indexPath)
            //cell.generateCellWith(fUser: allUsers[indexPath.row], indexPath: indexPath)

        return cell
    }
    
    
    //MARK: TableView Delegate
    // will return the *HEADER for each section (A,B,C,D...Z)
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            return ""
        } else {
            // return the section title
            return sectionTitleList[section]
        }
    }
    
    // RETURN the index of the section
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
    
    
    
    
    
    // Mark: Load users
    // filter by:
    // CIty
    // COuntry
    // BOTH
    func loadUsers(filter: String) {
        ProgressHUD.show() // shows loading bar
        var query: Query!
        
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
            
            // check if snapshot has data (USER)
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
    
    
    //mark: IBACTIONs
    
    @IBAction func fiterSegmentValueChanged(_ sender: UISegmentedControl) {
        
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
    
    
    
    //MARK: Search controller
    func filterContentForSearchText(searchText: String, scope: String = "ALL" ) {
        filteredUsers = allUsers.filter({ (user) -> Bool in
            // check if searchName match with search text
            return user.firstname.lowercased().contains(searchText.lowercased())
        })
        tableView.reloadData()
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!) // takes texgt and filters
    }
    
    //MARK: Helper FUnctions
    fileprivate func splitDataIntoSections() {
        var sectionTitle: String = ""
        
        //MARK: loop through current users in FIrebase
        for idx in 0..<self.allUsers.count {
            let currentUser = self.allUsers[idx]
            
            let firstChar = currentUser.firstname.first!
            
            let firstCharString = "\(firstChar)"
            // check if first character of Users name matches the section
            if firstCharString != sectionTitle {
                sectionTitle = firstCharString
                self.allUsersGrouped[sectionTitle] = []
                
                self.sectionTitleList.append(sectionTitle)
            }
            self.allUsersGrouped[firstCharString]?.append(currentUser)
        }
        
    }
    
    
}
