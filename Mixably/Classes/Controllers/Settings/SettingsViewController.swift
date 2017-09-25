//
//  MISettingsViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 5/10/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

class MISettingsViewController: UIViewController {

    private var settingsContentView = MISettingsListContentView()
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        view.isOpaque = false
        
        createUI()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Analytics:
        MIAnalyticsManager.logScreen(AnalyticsScreens.SETTINGS)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.HIDE_STATUS_BAR), object: nil)

        settingsContentView.createCurrentMSSPsDataSource()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        super.viewWillDisappear(animated)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.SHOW_STATUS_BAR), object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func createUI (){
        
        settingsContentView = MISettingsListContentView(frame: view.bounds)
        settingsContentView.containerViewController = self
        
        view.addSubview(settingsContentView)
    }

    func dismissPage() {
        
        MIAnalyticsManager.logScreen(AnalyticsScreens.PROFILE_MY_PROFILE)

        for view in self.view.subviews {
            view.removeFromSuperview()
        }
        
        let transition = CATransition()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromRight
        self.view.window!.layer.add(transition, forKey: kCATransition)
        
        self.dismiss(animated: false, completion: nil)
        
    }
    
    func cancelSportifyHandler () {
        let alertController = UIAlertController(title: "Can not connect Spotify.", message: "Connect your Spotify account to enjoy Mixably experience.", preferredStyle: UIAlertControllerStyle.alert)
        
        let connectAction = UIAlertAction(title: "Connect", style: UIAlertActionStyle.default) {
            (result : UIAlertAction) -> Void in
            self.settingsContentView.swSpotifyChanged(isEnabled: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) {
            (result : UIAlertAction) -> Void in
            self.settingsContentView.createCurrentMSSPsDataSource()
        }
        
        alertController.addAction(connectAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

}
