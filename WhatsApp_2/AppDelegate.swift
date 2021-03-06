//
//  AppDelegate.swift
//  WhatsApp_2
//
//  Created by Kevin Douglass on 5/27/20.
//  Copyright © 2020 Kevin Douglass. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation /// access user location -> must include its delegate * CLLocationManagerDelegate *
import OneSignal



@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {

    var window: UIWindow?
    var authListener: AuthStateDidChangeListenerHandle?

    ///Location variables
    var locationManager: CLLocationManager?
    var coordinates: CLLocationCoordinate2D?    /// pull user's longitude & lattitude


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        // MARK: AutoLogin
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
                }
            }
  
        })
        
        
        
        /// CALL OneSignal Here to run in App
        /*      --------->>>>   Function inside Function !!!!!!!!!!!!!           */
        func userDidLogin(userId: String) {
            self.startOneSignal()   // set OneSignal Id everytime user login
        }
        
        // ns notification center - server
        NotificationCenter.default.addObserver(forName: NSNotification.Name(USER_DID_LOGIN_NOTIFICATION), object: nil, queue: nil) { (note) in
            /// "radio channel" called every time user logs in
            // tell "radio listeners" we need to get the user id
            let userId = note.userInfo![kUSERID] as! String
            UserDefaults.standard.set(userId, forKey: kUSERID)
            UserDefaults.standard.synchronize() // ?? Unneceessary
            
            print("User has logged in.....................")
            userDidLogin(userId: userId)
        }
        
/// push notifications (part 1)
        OneSignal.initWithLaunchOptions(launchOptions, appId: kONESIGNALAPPID)
        
    
        return true
    }
    
 ///////////////////-------------------------------------------------------------------------------------------------------------------
    
    
    //MARK: LOCATION services *permissions*
    func applicationDidBecomeActive(_ application: UIApplication) {
        // as soon as it becomes active change user status to "ONLINE"
        //check if we have a current user
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : true]) { (success) in
            }
        }
        
        locationManagerStart() // ask user for location permission
        
    }
    //func sceneDidBecomeActive()
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // as soon as it becomes de-active change user status to "OFFLINE"
        // check if current user is unavailable
        if FUser.currentUser() != nil {
            updateCurrentUserInFirestore(withValues: [kISONLINE : false]) { (success) in
            }
        }
        
        locationManagerStop()
    }
    /// end of location services *permission*

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

    
    
    
    //MARK: AUTO-Login
    
    
    // MARK: Go to APP
    func gotoApp() {
       
       // notify user they are logged in
        // gets ID of currently logged in user
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: USER_DID_LOGIN_NOTIFICATION), object: nil, userInfo: [kUSERID : FUser.currentId()])
        
        // present App here
        let mainView = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(identifier: "mainApplication") as! UITabBarController
       
        self.window?.rootViewController = mainView
       
   }
    
    //MARK: Location Manager
    /// initializeing locaiton manager
    func locationManagerStart() {
        // check if we have a locatin manager .. * variables defined globally *
        if locationManager == nil {
            /// we need to then start it..
            locationManager = CLLocationManager()
            // unwrap now that we have INSTANTIATED *location*
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            /// ask user if we can get their location
            locationManager!.requestWhenInUseAuthorization()
        }
        
        locationManager!.startUpdatingLocation() // report user location
        

    }
    
    
    func locationManagerStop() {
        // check if location manager is not nil (empty)
        if locationManager != nil {
            locationManager!.stopUpdatingLocation()
        }
    }
    
    //MARK: location manager *delegate*
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("DEBUG: Failed to get location in App Delegate initializatin.")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization() // request user authorization
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()         // we have authorization, so we use it
        case .authorizedAlways:
            manager.startUpdatingLocation()         // if authorized always we can use location
        case .restricted:
            print("restricted")                    // parental controlls has restricted

        case .denied:
            locationManager = nil
            print("Denied location Access.")
            break
        }
    }
    
    /// check updated locations
    // called every time locatin of device CHANGES
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // coordinates are always equal to our "Latest corrdinate on our device
        // last object in our CLLOcation array is our most *recent* location
        coordinates = locations.last!.coordinate /// returns the latest coordinate
    }
    
    //MARK: OneSignal Notifications
    func startOneSignal() {
        // to get our OneSignalUserID
        // so we can send specific notifications to that USER id
        let status: OSPermissionSubscriptionState = OneSignal.getPermissionSubscriptionState()
       
        /// get user id from OneSignal
        let userID = status.subscriptionStatus.userId
        ///get push token
        let pushToken = status.subscriptionStatus.pushToken
        
        
        if pushToken != nil {
            // not nil if we are connected to OneSignal
            // check if we have USER id
            if let playerID = userID {
                // save it in user default
                UserDefaults.standard.set(playerID, forKey: kPUSHID)
            } else {
                UserDefaults.standard.removeObject(forKey: kPUSHID)
            }
            /// update our user defaults
            UserDefaults.standard.synchronize()
        }
        // update OneSignal ID
        updateOneSignalId()

    }
   

}

