//
//  MIUserNameController.swift
//  Mixably
//
//  Created by Mobile App Dev on 29/01/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

/**
 MIUserNameController handles logic for the UserName screen
 */
class MIUserNameController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view = MIUserNameView(frame:view.bounds)
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Analytics:
        MIAnalyticsManager.logScreen(AnalyticsScreens.INTRODUCTION_USERNAME)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}
