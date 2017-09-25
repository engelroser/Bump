//
//  MIAnalyticsManager.swift
//  Mixably
//
//  Created by Mobile App Dev on 24/5/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Firebase
import Foundation

class MIAnalyticsManager {
    
    static var isMSSPEventShouldBeSent = false
    
    class func logEvent(_ name: String, parameters:[String:Any]? = nil) {
        #if DEBUG
            print("MIAnalyticsManager logEvent:", name, parameters as Any)
        #else
            logFirebaseEvent(name, parameters: parameters)
        #endif
    }
    
    class func logScreen(_ name: String) {
        #if DEBUG
            print("MIAnalyticsManager logScreen:", name)
        #else
            logFirebaseScreen(name)
        #endif
    }
    
    private class func logFirebaseEvent(_ name: String, parameters: [String:Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
    
    private class func logFirebaseScreen(_ name: String) {
        Analytics.setScreenName(name, screenClass: name.components(separatedBy: "_")[0])
    }
}
