//
//  FinishRegistrationViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 5/28/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import ProgressHUD

class FinishRegistrationViewController: UIViewController {

    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var surnameTextField: UITextField!
    
    @IBOutlet weak var countryTextField: UITextField!
    
    @IBOutlet weak var cityTextField: UITextField!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    
    //MARK: variables
    var email: String!
    var password: String!
    var avatarImage: UIImage?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(email, password)

        self.dismiss(animated: true, completion: nil)
        // Do any additional setup after loading the view.
    }
    
    //MARK IBActions
    @IBAction func cancelButtonPressed(_ sender: Any) {
        //
        cleanTextField()
        dismissKeyboard()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismissKeyboard()
        ProgressHUD.show("Registering...")
        
        if nameTextField.text != "" && surnameTextField.text != "" && countryTextField.text != "" && cityTextField.text != "" && phoneTextField.text != "" {
            
            FUser.registerUserWith(email: email!, password: password!, firstName: nameTextField.text!, lastName: surnameTextField.text!) { (error) in
                
                if error != nil {
                    ProgressHUD.dismiss()
                    ProgressHUD.showError(error!.localizedDescription) // read out errors
                    return  // break
                }
                // if no error
                self.registerUser()
            }
            
        } else {
            ProgressHUD.showError("All fields are required")
        }
    }
    //MARK: HelperFuncs
    func registerUser() -> Void {
        return
    }
    
    
    func dismissKeyboard() {
        self.view.endEditing(false)
    }
    func cleanTextField() -> Void {
        nameTextField.text = ""
        surnameTextField.text = ""
        countryTextField.text = ""
        cityTextField.text = ""
        phoneTextField.text = ""
    }

}
