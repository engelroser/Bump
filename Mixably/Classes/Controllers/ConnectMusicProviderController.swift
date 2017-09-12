//
//  MIConnectMusicProviderController.swift
//  Mixably
//
//  Created by Mobile App Dev on 15/6/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import StoreKit

class MIConnectMusicProviderController {

    class func connectAppleMusic() {
        
        appleMusicRequestPermission {
            
            let provider = MIMSSPS()
            provider.id = .appleMusic
            
            MIManager.manager.connectMusicProvider(provider: provider, code: "") {
                (result: Bool) in
                
                //We should post all notifications in main thread otherwise we should use DispatchQueue.main.async to avoid crashes and that's why UI is updating so long
                DispatchQueue.main.sync {
                    
                    // Broadcast the notification that Apple Music has succesfully connected:
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.CONNECTED_APPLE_MUSIC), object: nil)
                    
                }
                
                // Check subscription:
                MIAppController.checkMSSPS() { _ in
                }
            }
        }
    }
    
    class func appleMusicRequestPermission(_ callback: @escaping () -> Void) {
        
        switch SKCloudServiceController.authorizationStatus() {
            
        case .authorized:
            print("authorized")
            // Proceed.
            callback()
            return
        case .denied:
            print("denied")
            // Request authorization.
            break
        case .notDetermined:
            print("notDetermined")
            // Request authorization.
            break
        case .restricted:
            print("restricted")
            // Do not request authorization.
            return
        }
        
        SKCloudServiceController.requestAuthorization { (status:SKCloudServiceAuthorizationStatus) in
            
            switch status {
                
            case .authorized:
                // Proceed.
                callback()
                break
            case .denied:
                print("denied")
                MIManager.manager.showSettingsAlert()
                
                if UserDefaults.standard.bool(forKey: "appleMusicSettings") {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.CONNECTED_APPLE_MUSIC), object: nil)
                }
                
            case .notDetermined:
                print("notDetermined")
            default:
                break
            }
            
        }
        
    }
    
}
