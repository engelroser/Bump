//
//  MISearchTrackViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 25/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

class MISearchTrackViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createUI();
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Analytics:
        MIAnalyticsManager.logScreen(AnalyticsScreens.CREATION_SEARCH_PREVIEW)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    private func createUI (){
        
        view.addSubview(MICreatePlayListSearchView(frame:view.bounds))
        
    }

}
