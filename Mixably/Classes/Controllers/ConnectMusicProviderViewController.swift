//
//  ConnectMSSPViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 05/07/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import GradientView

//
// ConnectMusicProviderViewController shows a screen where a user can connect music provider
//
// To handle tapping on Cancel button your class should subscribe on Notifications.USER_CANCEL_CONNECT_MUSIC_PROVIDER
// To handle connecting to MSSP your class should subscribe on Notifications.MUSIC_PROVIDER_CONNECTED
//
// See MINewPlayListViewController for example
//

class ConnectMusicProviderViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createGradientBackground()
        
        view.addSubview(MIConnectMusicProviderView(frame:view.bounds, showGuestLogin:false, message:NSLocalizedString("connect_mssp", comment: "Connect music provider")))
        createCancelButton()
        
        //Handle connecting to MSSP
        NotificationCenter.default.addObserver(self, selector: #selector(self.musicProviderConnected), name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_CONNECTED), object: nil)
        
    }
    
    private func createCancelButton(){
        
        let cancelButton = MIUIUtilities.createTextButton(text:NSLocalizedString("cancel", comment: "Cancel").uppercased())
        cancelButton.titleLabel?.font = Font.TUTORIAL_GOT_IT_BUTTON

        cancelButton.sizeToFit()
        cancelButton.frame = CGRect(x:view.bounds.width - Origin.CONNECT_MSSP_CANCEL_RIGHT - cancelButton.bounds.size.width, y:Origin.CONNECT_MSSP_CANCEL_TOP, width:cancelButton.bounds.size.width, height:Size.CONNECT_MSSP_CANCEL_HEIGHT)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        
        view.addSubview(cancelButton)
        
    }
    
    private func createGradientBackground(){
        
        let gradientView = GradientView(frame: view.bounds)
        gradientView.colors = [Color.TUTORIAL_BACKGROUND_TOP, Color.TUTORIAL_BACKGROUND_BOTTOM]
        gradientView.locations = [0.5, 1.0]
        gradientView.direction = .vertical
        view.addSubview(gradientView)
        
    }
    
    //MARK: Actions
    public func cancel(sender: UIButton!) {
        
        dismiss()
        
        //Send notification that user dismissed this screen
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.USER_CANCEL_CONNECT_MUSIC_PROVIDER), object: nil)
        
    }
    
    //MARK: Notifications
    public func musicProviderConnected(){
        
        //User connected a music provider. Dismiss this screen
        dismiss()
        
    }
    
    private func dismiss(){
    
        let transition: CATransition = CATransition()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromBottom
        self.view.window!.layer.add(transition, forKey: nil)
    
        dismiss(animated: false, completion: nil)

    }
    
    //MARK: Internal
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
}
