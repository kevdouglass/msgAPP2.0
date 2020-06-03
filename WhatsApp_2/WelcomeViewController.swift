//
//  WelcomeViewController.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 5/27/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import ProgressHUD


class WelcomeViewController: UIViewController {

    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var repeatPasswordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    //MARK: IBActions
    
    @IBAction func logginButtonPressed(_ sender: Any) {
       print("login")
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" {
            // if everything is good: call loginUser()
            loginUser()
            
        } else {
            ProgressHUD.showError("Email and Password is missing!")
            
        }
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
       // print("register")
        dismissKeyboard()
        
        if emailTextField.text != "" && passwordTextField.text != "" && repeatPasswordTextField.text != "" {
            // register user: as fields are filled in ...
            // make sure password fields match
            if (passwordTextField.text == repeatPasswordTextField.text) {
                registerUser()
            } else {
                ProgressHUD.showError("Passwords don't match!")
            }
           
        } else {
            ProgressHUD.showError("All fields are required!")
        }


    }
    
    @IBAction func backgroundTap(_ sender: Any) {
        print("dismiss")
        dismissKeyboard()
    }


    //MARK: Helper Functions
    func loginUser() {
        ProgressHUD.show("Login...")
        
        FUser.loginUserWith(email: emailTextField.text!, password: passwordTextField.text!) {
            (error) in
            
            if error != nil {
                ProgressHUD.showError(error!.localizedDescription)
                return  // return as we have an error at this point
            }
            // if no error...
            //present the app
            self.gotoApp()
            
        }
    }
    
    func registerUser() {
        print("register")
        // access segue
        performSegue(withIdentifier: "welcomeToFinishReg", sender: self)
        cleanTextFields()
        dismissKeyboard()
        
        // go to other view
        
        
    }
    
    
    func dismissKeyboard() -> Void {
        self.view.endEditing(false)
    }
    
    func cleanTextFields() -> Void {
        emailTextField.text = ""
        passwordTextField.text = ""
        repeatPasswordTextField.text = ""
    }
    
    func gotoApp() {
        
        ProgressHUD.dismiss()
        
        cleanTextFields()
        dismissKeyboard()
        
        print("show the App")
        // present App here
    }
    
    // MARK: Navigation
    
    // prepare for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // check if the identifier for SEGUE is correct
        if segue.identifier == "welcomeToFinishReg" {
            let vc = segue.destination as! FinishRegistrationViewController
            vc.email = emailTextField.text!
            vc.password = passwordTextField.text!
        }
    }

}
