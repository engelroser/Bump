//
//  BaseViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 04/08/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

@objc open class BaseViewController: UIViewController {

    //Data
    private var isStatusBarHidden = false
    private var isStatusBarHiddenBefore = false

    override open func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showStatusBar),
                                               name: NSNotification.Name(rawValue: Notifications.SHOW_STATUS_BAR),
                                               object: nil)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(hideStatusBar),
                                               name: NSNotification.Name(rawValue: Notifications.HIDE_STATUS_BAR),
                                               object: nil)

    }

    public func showStatusBar(){
        
        isStatusBarHiddenBefore = isStatusBarHidden
        isStatusBarHidden = false
        setNeedsStatusBarAppearanceUpdate()
        
    }
    
    public func hideStatusBar(){
        
        isStatusBarHiddenBefore = isStatusBarHidden
        isStatusBarHidden = true
        setNeedsStatusBarAppearanceUpdate()
        
    }
    
    public func restoreStatusBar(){
        
        if isStatusBarHiddenBefore {
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.HIDE_STATUS_BAR), object: nil)

        } else {
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.SHOW_STATUS_BAR), object: nil)

        }
        
    }
    
    override open var prefersStatusBarHidden: Bool {
        return isStatusBarHidden
    }

}
