//
//  AppDelegate.swift
//  Mixably
//
//  Created by Mobile App Dev on 20/01/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Swifter
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window:UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        ////////////////////////////
        //Giphy API Key
        SwiftyGiphyAPI.shared.apiKey = API.GiphyAPIKeyProduction
        ////////////////////////////
        
        ///////////////////////////
        //Only for simulator usage
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            
            log.debug("DOCUMENTS DIRECTORY: \n\(documentsPath)\n")
            
        }
        ///////////////////////////
        
        window = UIWindow.init(frame: UIScreen.main.bounds)
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        if let currentWindow = window{
            
            currentWindow.backgroundColor = UIColor.black
            
            currentWindow.makeKeyAndVisible()
            
            let storyboard = UIStoryboard(name: "SplashScreen", bundle: nil)
            let viewController = storyboard.instantiateViewController(withIdentifier :"SplashScreen") as! MISplashScreenViewController
            currentWindow.rootViewController = viewController
            
        }
        
        // Push Notifications Permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {(accepted, error) in
            if accepted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        
        return true

    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map{ String(format: "%02x", $0) }.joined()
        // Token saved to the UserDefaults
        UserDefaults.standard.set(token, forKey:API.APNS_TOKEN)
        
    }
    
    private func openUserProfile(userId: String) {
        
        //Analytics
        MIAnalyticsManager.logScreen(AnalyticsScreens.PROFILE_OTHER_PROFILE)
        
        let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        let profileVC = profileStoryboard.instantiateViewController(withIdentifier: String(describing: MIProfileViewController.self))
        (profileVC as! MIProfileViewController).userId = userId
        
        self.window?.rootViewController?.present(profileVC, animated: true, completion: nil)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        //Send push_notif_received event
        let state = UIApplication.shared.applicationState
        
        if state == .background || state == .inactive {
            
            // background mode
            MIAnalyticsManager.logEvent(AnalyticsScreens.PUSH_NOTIF_RECEIVED, parameters:["mode":"background"])

        }
        else if state == .active {
            
            // foreground mode
            MIAnalyticsManager.logEvent(AnalyticsScreens.PUSH_NOTIF_RECEIVED, parameters:["mode":"foreground"])

        }
        
        if let actionUserId = userInfo["actionUserId"] as? String {
            openUserProfile(userId: actionUserId)
        }
        
        //Send push_notif_open event
        if let actionType = userInfo["actionType"] {
            MIAnalyticsManager.logEvent(AnalyticsScreens.PUSH_NOTIF_OPEN, parameters:["actionType":actionType])
        }
        
    }
    
    // This method gets called when receiving a Notification and the app is on the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Displays an alert with the message of the Notification and calls the 'didReceiveRemoteNotification' method
        
        completionHandler(.alert)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; h  ere you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        MIAppController.applicationDidBecomeActive()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        if url.absoluteString.indexOf("swifter") != nil{
            
            Swifter.handleOpenURL(url)

        }

        if SPTAuth.defaultInstance().canHandle(url) {
            
            let provider = MIMSSPS()
            provider.id = .spotify
            
            if let code = url.getQueryItemValueForKey(key: "code"){
                
                MIManager.manager.connectMusicProvider(provider:provider, code: code, completion: {
                    (result: Bool) in
                    
                    if result == false{
                        
                        //Looks like an user has a connected spotify account already. Try to refresh token
                        MIManager.manager.refreshTokenForMusicProvider(provider:provider, completion: {
                            
                            (result: Bool) in
                            
                                let currentViewController = UIApplication.topViewController()
                                if (currentViewController != nil && currentViewController!.isKind(of: MISettingsViewController.self)) {
                                    currentViewController?.viewWillAppear(true)
                                } else {
                                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.CONNECTED_SPOTIFY), object: nil)
                                }
                            
                        })
                        
                    }else{
                        
                        // Broadcast the notification that Spotify has succesfully connected:
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.CONNECTED_SPOTIFY), object: nil)
                        
                    }
                    
                })
                
                /*NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.CONNECTED_SPOTIFY), object: nil)

                MIManager.manager.swapSpotify(authenticationToken:code)*/
                
            } else {
                let currentViewController = UIApplication.topViewController()
                if (currentViewController != nil && currentViewController!.isKind(of: MISettingsViewController.self)) {
                    (currentViewController as! MISettingsViewController).cancelSportifyHandler()
                }
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.CONNECTED_SPOTIFY_FAILED), object: nil)

            }
            
            /*SPTAuth.defaultInstance().handleAuthCallback(withTriggeredAuthURL: url) { error, session in

                if error != nil {
                    
                    print("*** Auth error: \(error)")
                    return
                }
                else {
                    SPTAuth.defaultInstance().session = session
                    
                    //SPTAudioStreamingController.sharedInstance().login(withAccessToken: SPTAuth.defaultInstance().session.accessToken)
                    
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.CONNECTED_SPOTIFY), object: nil)
                    
                }
                
            }*/
        }
        
        return FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
    
}

