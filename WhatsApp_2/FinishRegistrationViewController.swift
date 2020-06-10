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
        //ProgressHUD.show("Registering...")
        
        if nameTextField.text != "" && surnameTextField.text != "" && countryTextField.text != "" && cityTextField.text != "" && phoneTextField.text != "" {
            
            FUser.registerUserWith(email: email!, password: password!, firstName: nameTextField.text!, lastName: surnameTextField.text!) { (error) in
                
                // if there is an error
                if error != nil {
                    ProgressHUD.dismiss()
                    // show the error to the user
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
        let fullName = nameTextField.text! + " " + surnameTextField.text!
        // create a temporary dictionary
        var tempDictionary : Dictionary = [kFIRSTNAME : nameTextField.text!, kLASTNAME : surnameTextField.text!, kFULLNAME : fullName, kCOUNTRY : countryTextField.text!, kCITY : cityTextField.text!, kPHONE : phoneTextField.text!] as [String : Any]
        
        // optional avatar img
        /**
         If there is no avatar image, use the new USER INITIALS as IMG.jpg
         */
        if avatarImage == nil {
            
            imageFromInitials(firstName: nameTextField.text!, lastName: surnameTextField.text!) { (avatarInitials) in
                
                // compress the img to bit stream of data
                let avatarIMG = avatarInitials.jpegData(compressionQuality: 0.7)
                //––let avatarIMG = avatarInitials.
                //let avatarBitsStringForInitials = avatarIMG?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                let avatar_JPEG_String = avatarIMG?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
                // add the stream of avatar bits to dictionary
                tempDictionary[kAVATAR] = avatar_JPEG_String
                
                // finish #Registration
                self.finishRegistration(withValue: tempDictionary)
                
            }
            
        } else {
            // the user choses an avatar img
            let avatarData = avatarImage?.jpegData(compressionQuality: 0.7)
            //let avatarBitsStringFromNewUserIMG = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            let avatar_JPEG_String_NewUser = avatarData?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
            tempDictionary[kAVATAR] = avatar_JPEG_String_NewUser
            
            // finish #Registration
            self.finishRegistration(withValue: tempDictionary)
        }
    }
    
    // # pass in updated dictionary
    // # save 2 FireStorm
    func finishRegistration(withValue: [String : Any]) {
        updateCurrentUserInFirestore(withValues: withValue) { (error) in
            
            // if there are any errors
            if error != nil {
                // run error in #backgroundThread
                DispatchQueue.main.async {
                    ProgressHUD.showError(error!.localizedDescription)
                    print(error!.localizedDescription)
                }
                return
            }
            ProgressHUD.dismiss()
            // go to app
            self.gotoApp()
        }
    }
    
    func gotoApp() {
        cleanTextField()
        dismissKeyboard()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
        
        self.present(mainView, animated: true, completion: nil)
        
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
