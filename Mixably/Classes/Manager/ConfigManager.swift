//
//  MIConfigManager.swift
//  Mixably
//
//  Created by Mobile App Dev on 01/03/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import Firebase

/**
 MIConfigManager is used for loading configuration from Firebase
 */

class MIConfigManager {

    let kLoginFlagKey = "loginflag"
    
    public let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        
        FirebaseApp.configure()
        loadRemoteConfig()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadRemoteConfig(){
        
        let remoteConfigSettings = RemoteConfigSettings(developerModeEnabled: true)
        remoteConfig.configSettings = remoteConfigSettings!
        
        //Set default values
        loadLocalConfig()
        
        //Load remote values
        remoteConfig.fetch(withExpirationDuration: TimeInterval(600)) { (status, error) -> Void in
            
            if status == .success {
                
                log.debug("Config fetched!")
                self.remoteConfig.activateFetched()
                print(self.remoteConfig[Config.LATEST_APP_VERSION].stringValue!)
                
            } else {
                
                log.debug("Config not fetched")
                
            }
            
        }

    }
    
    private func loadLocalConfig(){
        
        //Try to load remote Config file and set defaults to Firebase remote config. Firebase uses default values when it's not possible to fetch remote values. If you add new remote config value don't forget to add this value to local config (file Resources/Data/Config)

        do {
            
            if let file = Bundle.main.url(forResource: "Config", withExtension: "") {
                let data = try Data(contentsOf: file)
                let json = try JSONSerialization.jsonObject(with: data, options: [])
                guard let object = json as? [String: NSObject] else {
                    
                    log.error("Local config JSON isn't valid")
                    return
                    
                }
                
                remoteConfig.setDefaults(object)
                
            } else {
                
                log.error("Cannot find local config file")
                
            }
            
        } catch {
            
            log.error(error.localizedDescription)
            
        }
        
    }

}
