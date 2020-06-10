//
//  ChatsViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/8/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit

class ChatsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // make CHAT #navBar big title
        navigationController?.navigationBar.prefersLargeTitles = true

    }
//MArk:IBACTIONS
    @IBAction func createNewChatButtonPressed(_ sender: Any) {
        
        // display table view
        // must access story board
        let userVC = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "usersTableView") as! UsersTableViewController
        
        self.navigationController?.pushViewController(userVC, animated: true)
        
        
    }
    

}
