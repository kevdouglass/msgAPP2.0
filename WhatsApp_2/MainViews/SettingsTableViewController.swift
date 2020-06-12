//
//  SettingsTableViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 6/7/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.navigationBar.prefersLargeTitles = true
 
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 3
    }

    
    // MARK: IB Actions
  
    

    @IBAction func logoutButtonPressed(_ sender: Any) {
        print("log out pressed.")
        FUser.logOutCurrentUser { (success) in
            if success {
                // show the loginView
                self.showLoginVIew()
                
            }
        }
        
    }
    
    func showLoginVIew() {
        
       // instantiate loginView
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "welcome")
        
        // shows loginVIew
        self.present(mainView, animated: true, completion: nil)
    }
    
}
