//
//  MISplashScreenViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 02/03/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase

/**
 MISplashScreenViewController shows splash screen during app launching
 */

class MISplashScreenViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        restoreSession()
        
    }
    
    private func restoreSession(){
        
        //Check if user has saved FB token
        if FBSDKAccessToken.current() != nil{
            
            //User hasn't saved FB token
            MIManager.manager.loginWithFacebook(authenticationToken:FBSDKAccessToken.current().tokenString,completion:{
                result in
                
                if result == false{
                    //Cannot login with FB. Show FB login screen

                    DispatchQueue.main.sync{
                        
                        //Show screen with 'Login with FB' button
                        let startViewController = MIStartViewController()
                        self.present(startViewController, animated: false, completion: nil)
                        
                    }
                    
                }else{
                    //User logged in successfully. Try to refresh token
                    
                    // Get connected music providers:
                    // MIManager.manager.getMSSPSByMe(completion: {
                    MIAppController.checkMSSPS(completion: {
                        result in
                        
                        if result.count == 0{
                            
                            if UserDefaults.standard.bool(forKey: Config.PREVIEW_MODE_KEY){
                                
                                //User selected already Preview Mode before. Show Home Screen
                                
                                DispatchQueue.main.sync{
                                    
                                    //We received Spotify token. We can show home screen
                                    let startViewController = MIHomePageViewController()
                                    self.present(startViewController, animated: false, completion: nil)
                                    
                                }
                                
                            }else{
                                
                                //User didn't select already Preview Mode befaore. Show Select Provider Screen
                                
                                DispatchQueue.main.sync{
                                    
                                    //Show connect provider screen
                                    let startViewController = MIStartViewController()
                                    self.present(startViewController, animated: false, completion: nil)
                                    
                                }
                                
                            }
                            
                        }else{
                            
                            //Refresh all connected providers
                            for mssps in result{
                                
                                //Now we handle only Spotify provider
                                MIManager.manager.refreshTokenForMusicProvider(provider: mssps, completion: {
                                    result in
                                    
                                    if result == true{
                                        
                                        DispatchQueue.main.sync{
                                            
                                            //We received Spotify token. We can show home screen
                                            let startViewController = MIHomePageViewController()
                                            self.present(startViewController, animated: false, completion: nil)
                                            
                                        }
                                        
                                    }else{
                                        
                                        DispatchQueue.main.sync{
                                            
                                            //Show connect provider screen
                                            let startViewController = MIStartViewController()
                                            self.present(startViewController, animated: false, completion: nil)
                                            
                                        }
                                        
                                    }
                                    
                                })
                                
                            }
                            
                        }
                        
                    })
                    
                }
                
            })
            
        }else{
            
            //Check if user has selected Guest Mode already
            if UserDefaults.standard.bool(forKey: UserDefault.IS_GUEST_MODE) {
                
                let startViewController = MIHomePageViewController()
                self.present(startViewController, animated: false, completion: nil)
                
            } else {
                
                //Cannot login with FB. Show FB login screen
                
                let startViewController = MIStartViewController()
                present(startViewController, animated: false, completion: nil)
                
            }
            
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
