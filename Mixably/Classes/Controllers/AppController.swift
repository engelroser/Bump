//
//  MIAppController.swift
//  Mixably
//
//  Created by Mobile App Dev on 16/6/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import StoreKit
import Firebase

class MIAppController {

    class func applicationDidBecomeActive() {
        
        if PlayerController.isPlayerPlaying() == false{
            
            checkMSSPS() { _ in
            }
            
        }
        
    }
    
    class func checkMSSPS(completion: @escaping ([MIMSSPS]) -> Void) {
        getMSSPSByMe() { result in
            
            MIAppController.checkIfAppleMusicConnected(result: result)
            
            // For use in Splash View Controller:
            completion(result)
        }
    }
    
    class func checkIfAppleMusicConnected(result: [MIMSSPS]){
        
        let isConnectedToAppleMusic: Bool = result.filter { $0.id == .appleMusic }.count > 0
        print("isConnectedToAppleMusic", isConnectedToAppleMusic)

        //User hasn't connected Apple Music account
        guard isConnectedToAppleMusic else {
            
            return
            
        }
        
        checkAppleMusicAuthorizationStatus() { isAppleMusicAuthorized in
            
            print("isAppleMusicAuthorized", isAppleMusicAuthorized)
            
            if isConnectedToAppleMusic != isAppleMusicAuthorized && isConnectedToAppleMusic {
                
                print("isConnectedToAppleMusic BUT !isAppleMusicAuthorized")
                
                // Disconnect Apple Music:
                MIManager.manager.disConnectMusicProvider(msspId: 1) { result in
                    
                    print("Disconnected Apple Music")
                    
                }
            } else if isConnectedToAppleMusic {
                
                print("isConnectedToAppleMusic AND isAppleMusicAuthorized")
                
                // Check Apple Music subscribed status:
                checkAppleMusicSubscribedStatus() { subscribedStatus in
                    
                    print("isAppleMusicSubcribed", subscribedStatus)
                                        
                    //Set Apple Music provider
                    let musicProvider = MIMSSPS()
                    musicProvider.id = .appleMusic

                    if subscribedStatus {
                        
                        Analytics.setUserProperty(AnalyticsSegments.MSSP_PREMIUM, forName: AnalyticsSegments.PREMIUM_MSSP)
                        musicProvider.isPremiumRequired = false

                    } else {
                        
                        Analytics.setUserProperty(AnalyticsSegments.MSSP_FREE, forName: AnalyticsSegments.PREMIUM_MSSP)
                        musicProvider.isPremiumRequired = true
                        
                    }
                    
                    MIManager.manager.setMusicProvider(provider: musicProvider)
                    
                    if MIAnalyticsManager.isMSSPEventShouldBeSent == true{
                        
                        MIAnalyticsManager.isMSSPEventShouldBeSent = false
                        
                        MIAnalyticsManager.logEvent(AnalyticsScreens.MSSP_CONNECT, parameters:["mssp_id":MIManager.manager.userMssps().id.rawValue, "is_premium":!MIManager.manager.userMssps().isPremiumRequired])
                        
                    }

                }
            }
        }
        
    }
    
    class func getMSSPSByMe(completion: @escaping ([MIMSSPS]) -> Void) {
        
        // Refresh tokens for music providers:
        MIManager.manager.getMSSPSByMe() { result in
            
            // Return connected MSSPS:
            completion(result)
            
            //We should test app without code below (see comment before refreshTokenForMusicProvider below). If all will work - remove it
            
            // Is this needed if we are going full Spotify SDK?
            /*
            if result.count != 0 {
                for mssps in result{
                    
                    //We don't need this call because because we just called getMSSPSByMe
                    /*MIManager.manager.refreshTokenForMusicProvider(provider: mssps, completion: {
                        result in
                        
                    })*/
                    
                }

            }*/
        }
    }
    
    class func checkAppleMusicSubscribedStatus(_ callback: @escaping (Bool) -> Void) {

        let serviceController = SKCloudServiceController()
        serviceController.requestCapabilities() { capability, error in
            
            if let error = error {
                
                print(error)
                callback(false)
                return
            }

            //From Apple documentation:
            //SKCloudServiceCapabilityMusicCatalogPlayback - The device allows playback of Apple Music catalog tracks.

            if capability.contains(SKCloudServiceCapability.musicCatalogPlayback) {
                
                print("The user has an active subscription to Apple Music and can playback music")
                callback(true)
                
            } else {
                
                print("The user does NOT have an active subscription")
                callback(false)
                
            }
            
        }
    }

    class func checkAppleMusicAuthorizationStatus(_ callback: @escaping (Bool) -> Void) {
        
        switch SKCloudServiceController.authorizationStatus() {
            
        case .authorized:
            print("authorized")
            callback(true)
            break
        case .denied:
            print("denied")
            callback(false)
            break
        case .notDetermined:
            print("notDetermined")
            callback(false)
            break
        case .restricted:
            print("restricted")
            callback(false)
            break
        }
    }
    
}
