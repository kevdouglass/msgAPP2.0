//
//  AppDelegate.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 5/27/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import Firebase



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        // #AutoLogin
        // stop listening after user login
        authListener = Auth.auth().addStateDidChangeListener({ (auth, user) in
            // whenever USER login state changes
            
            Auth.auth().removeStateDidChangeListener(self.authListener!) // user log in and remove the listener
            
            // if we have logged in user
            if user != nil {
                if UserDefaults.standard.object(forKey: kCURRENTUSER) != nil {
                    // if not equal to nil we have a current user saved on local device
                    
                    // sync back to main thread to get back to application
                    DispatchQueue.main.async {
                        self.gotoApp() // back to application
                    }
                    // go to application
                    //self.gotoApp()

                    
                }
            }
  
        })

        return true
    }
    
    
    

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    
    
    // #MARK: Go to APP
    func gotoApp() {
       
       // notify user they are logged in
        // gets ID of currently logged in user
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        // present App here
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
       
        self.window?.rootViewController = mainView
       
   }
   

}

