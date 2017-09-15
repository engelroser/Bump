//
//  MINotificationsViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 04/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import GradientView

class MINotificationsViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
    }
    
    private func setupUI(){
        
        createGradientBackground()
        createTopBar()
        
    }
    
    private func createTopBar(){
        
        let rightButton = MIUIUtilities.createTopBarRightButton(image: Image.TOP_BAR_NOTIFICATION_SETTINGS)
        rightButton.addTarget(self, action: #selector(showNotificationSettings), for: .touchUpInside)
        view.addSubview(rightButton)
        
        let leftButton = MIUIUtilities.createTopBarLeftButton(image: Image.TOP_BAR_CARDS)
        leftButton.addTarget(self, action: #selector(showHome), for: .touchUpInside)
        view.addSubview(leftButton)
        
        let middleImageView = MIUIUtilities.createTopBarMiddleImage(image:Image.TOP_BAR_SELECTED_NOTIFICATIONS)
        view.addSubview(middleImageView)
        
    }
    
    private func createGradientBackground(){
        
        let gradientView = GradientView(frame: view.bounds)
        gradientView.colors = [Color.TUTORIAL_BACKGROUND_TOP, Color.TUTORIAL_BACKGROUND_BOTTOM]
        gradientView.locations = [0.5, 1.0]
        gradientView.direction = .vertical
        view.addSubview(gradientView)
        
    }
    
    private func createContentView(){
        
        view.addSubview(MIHomeContentView(frame:view.bounds))
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: Actions
    public func showNotificationSettings(){
        
    }
    
    public func showHome(){
        
        let transition = CATransition()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        view.window!.layer.add(transition, forKey: kCATransition)
        
        self.dismiss(animated: false, completion: nil)
        
    }
    
}
