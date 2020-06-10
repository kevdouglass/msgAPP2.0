//
//  ProfileViewTableViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/10/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit

class ProfileViewTableViewController: UITableViewController {

    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var phonenumberLabel: UILabel!
    
    
    @IBOutlet weak var messageButtonOutlet: UIButton!
    @IBOutlet weak var callButtonOutlet: UIButton!
    @IBOutlet weak var blockButtonOutlet: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    var user: FUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // when open View ->
        setupUI()

    }

    
    //MARK: - IBactions [ fUser profile page ]
    
    @IBAction func callButtonWasPressed(_ sender: Any) {
    
    
    }
    
    @IBAction func chatButtonWasPressed(_ sender: Any) {
    
    
    }
    
    @IBAction func blockUserButtonWasPressed(_ sender: Any) {
    
    
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 3    // there are 3 sections on Profile
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1 // there is onl
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ""
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 0
        } else {
            return 30
        }
    }
    
    //MARK: Setup UI
    func setupUI() {
        // pass user to view
        if user != nil {
            self.title = "Profile"
            
            fullNameLabel.text = user!.fullname
            phonenumberLabel.text = user!.phoneNumber
            
            // update BLock/ unBlock user
            updateBlockStatus()
            
            
            imageFromData(pictureData: user!.avatar) { (avatarImage) in
                if avatarImage != nil {
                    self.avatarImageView.image = avatarImage!.circleMasked
                }
            }
        }
    }
    
    func updateBlockStatus() {
        
    }
    
}
