//
//  MITutorialViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 22/01/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

/**
 MITutorialViewController handles logic for start screens (Facebook login screen, Spotify and Apple Music connections, Username screen and Tutorial screen)
 */

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class MIStartViewController: UIViewController {
    
    var tutorialView: MITutorialView?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tutorialView = MITutorialView(frame: view.bounds)
        view.addSubview(tutorialView!)

        NotificationCenter.default.addObserver(self, selector: #selector(MIStartViewController.providerConnected), name: NSNotification.Name(rawValue: Notifications.CONNECTED_SPOTIFY), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MIStartViewController.providerConnected), name: NSNotification.Name(rawValue: Notifications.CONNECTED_APPLE_MUSIC), object: nil)

        if FBSDKAccessToken.current() != nil{
            
            userLogged()
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: Facebook Login actions
    
    public func userLogged() {
        
        tutorialView!.showPage(atIndex:1)
        
    }
    
    //MARK: Connect music actions
    public func providerConnected(){

        self.gotIt()

    }
    
    public func usePreviewMode(){
        
        self.gotIt()

    }
    
    //MARK: Tutorial page actions
    public func gotIt(){
        
        MIManager.manager.getUserInfoWithUserId(userId: "me") { (user: MIUser) in
            
            DispatchQueue.main.sync {
                
                NotificationCenter.default.removeObserver(self)
                
                if user.isHandleSet {
                    self.present(MIHomePageViewController(), animated: true, completion: nil)
                } else {
                    self.present(MIUserNameController(), animated: true, completion: nil)
                }
            }
        }
    }
}
