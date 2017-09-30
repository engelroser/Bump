//
//  MIServerManager.swift
//  Mixably
//
//  Created by Mobile App Dev on 21/01/17.
//  Copyright © 2016 Mixably. All rights reserved.
//

import Foundation
import SwiftHTTP
import FacebookCore
import FacebookLogin
import MediaPlayer
import UIKit
import iTunesSearchAPI
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import FirebasePerformance

/**
 MIServerManager is used for server communication using SwiftHTTP framework
 */

class MIServerManager : UIView, SPTAudioStreamingDelegate, SPTAudioStreamingPlaybackDelegate, UIDocumentInteractionControllerDelegate {
    
    private var accessToken = ""
    
    public var musicProvider = MIMSSPS()
    
    private var socialNetworksToShareEditingPlaylist = [String]()
    private var sharingTimer = Timer()

    private var player: SPTAudioStreamingController?
    private var interactionController: UIDocumentInteractionController = UIDocumentInteractionController()

    private var tokensTimer = Timer()
    private var internetConnectionTimer = Timer()

    private var isUserOffline = false
    
    init() {
        
        super.init(frame:CGRect.zero)
        setupSpotify()
        
        //Start timer to check tokens
        tokensTimer = Timer.scheduledTimer(timeInterval: Config.CHECK_TOKENS_TIMEOUT,
                                                    target: self,
                                                    selector: #selector(self.checkTokens),
                                                    userInfo: nil,
                                                    repeats: true)
                
        internetConnectionTimer = Timer.scheduledTimer(timeInterval: Config.CHECK_INTERNET_CONNECTION_TIMEOUT,
                                                       target: self,
                                                       selector: #selector(checkInternet),
                                                       userInfo: nil,
                                                       repeats: true)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Internet connection
    
    public func checkInternet() {
        
        do {

            let remoteConfig = MIManager.manager.remoteConfig()
            
            if let urlToCheckNetworkConnection = remoteConfig[Config.CHECK_INTERNET_CONNECTION_URL].stringValue{
                
                let opt = try HTTP.New(urlToCheckNetworkConnection, method: .GET)
                opt.start { response in
                    
                    DispatchQueue.main.sync {
                        
                        //Check if error code is -1009 (it's a standart ios error when a device is offline)
                        if let err = response.error{
                            
                            if self.isUserOffline == false {
                                
                                self.isUserOffline = true
                                PlayerController.savePlayerState()
                                
                                MIUIUtilities.showErrorAlert(title: NSLocalizedString("network_error_title", comment: "network_error_title"), message: NSLocalizedString("network_error_message", comment: "network_error_message"), button: "")
                                
                            }
                            
                            log.error("No internet connection: \(err.localizedDescription)")
                            return
                            
                        }
                        
                        if self.isUserOffline{
                            
                            //User just connected to internet. Continue playing track if needed
                            MIUIUtilities.dismissErrorAlert()
                            self.isUserOffline = false
                            PlayerController.restorePlayerState()
                            
                        }
                        
                    }

                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(Config.CHECK_INTERNET_CONNECTION_URL) \(error)")
            
        }
        
    }
    
    //MARK: API calls
    /**
     Try to login to the Mixably server using auth/facebook method
     -parameter authenticationToken: token received from Facebook
     -parameter completion: completion handler
     */
    public func loginWithFacebook(authenticationToken:String, completion:@escaping (_ result: Bool) -> Void){
        
        //Stop all music
        PlayerController.stopAll()

        //Try login with facebook
        let apnsToken = UserDefaults.standard.string(forKey: API.APNS_TOKEN) ?? "no_token_now"
        
        do {
 
            let url = API.BASE + API.AUTH_FACEBOOK
            let parameters = [API.FACEBOOK_ACCESS_TOKEN: authenticationToken, API.APNS_TOKEN: apnsToken] as [String : String]
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]

            let opt = try HTTP.New(url, method: .POST,parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.AUTH_FACEBOOK) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.AUTH_FACEBOOK): \(err.localizedDescription)")
                    completion(false)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])

                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    return
                    
                }
                
                if let dataDictionary = responseDictionary["data"] as? [String:Any]{
                    
                    if let token = dataDictionary["accessToken"] as? String{
                        
                        MIAnalyticsManager.logEvent(AnalyticsEventLogin, parameters:["method":"facebook"])

                        //Reset guest mode flag
                        UserDefaults.standard.set(false, forKey: UserDefault.IS_GUEST_MODE)
                        UserDefaults.standard.synchronize()
                        
                        self.accessToken = token
                        
                        DispatchQueue.main.sync {
                            
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.USER_LOGGED_IN), object: nil)
                            
                        }
                        
                        completion(true)

                    }
                }else{
                    
                    completion(false)

                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.AUTH_FACEBOOK) \(error)")
            completion(false)
            
        }
        
    }
    
    /**
     Try to logout from Mixably
     -parameter authenticationToken: token received from Facebook
     -parameter apnsToken: token received from Apns
     -parameter completion: completion handler
     */
    
    public func logout(authenticationToken:String, apnsToken:String, completion:@escaping () -> Void) {
        //Try logout from Mixably Server
        do {
            
            let url = API.BASE + API.LOGOUT
            let parameters = [API.FACEBOOK_ACCESS_TOKEN: authenticationToken, API.APNS_TOKEN: "no_token_now"] as [String : String]
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .POST,parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.LOGOUT) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.LOGOUT): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion()
                    return
                    
                }
                
                guard let success = responseDictionary["success"] as? Bool, success == true else {
                    log.error("failed to logout.")
                    completion()
                    return
                }
                
                //Reset access token
                self.accessToken = ""
                
                //Logout from Spotify Player
                if MIManager.manager.userMssps().id == .spotify{
                    
                    SPTAudioStreamingController.sharedInstance().logout()
                    
                }
                
                DispatchQueue.main.sync {
                    
                    //Reset music provider
                    self.musicProvider = MIMSSPS()
                    PlayerController.stopAll()
                    
                    Analytics.setUserProperty(AnalyticsSegments.MSSP_NONE, forName: AnalyticsSegments.PREMIUM_MSSP)
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_DISCONNECTED), object: nil)
                    
                }
                
                //Reload controllers
                PlayerController.set(self.musicProvider.id)
                SearchController.set(self.musicProvider.id)
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.AUTH_FACEBOOK) \(error)")
            completion()
            
        }
    }
    
    /**
     Get available music providers
     -parameter completion: completion handler
     */
    public func getMSSPS(completion: @escaping (_ result: [MIMSSPS]) -> Void){
        
        do {
            
            let url = API.BASE + API.MSSPS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET,parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.MSSPS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.MSSPS): \(err.localizedDescription)")
                    completion([])
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion([])
                    
                    return
                    
                }
                
                var providers = [MIMSSPS]()
                
                if let dataDictionary = responseDictionary["data"] as? [[String:Any]]{
                    
                    for providerDictionary in dataDictionary{
                        
                        let provider = MIMSSPS()
                        if let providerId = MusicProvider(rawValue: providerDictionary["id"] as! Int) {
                            
                            provider.id = providerId

                        } else {
                            
                            Analytics.setUserProperty(AnalyticsSegments.MSSP_NONE, forName: AnalyticsSegments.PREMIUM_MSSP)
                            provider.id = .none
                            
                        }

                        provider.name = providerDictionary["name"] as! String
                        provider.isActive = providerDictionary["isActive"] as! Bool

                        providers.append(provider)
                        
                    }
                }
                
                completion(providers)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.MSSPS) \(error)")
            completion([])

        }
        
    }
    
    /**
     Get user's music providers
     -parameter completion: completion handler
     */
    public func getMSSPSByMe(completion: @escaping (_ result: [MIMSSPS]) -> Void){
        
        do {
            
            guard accessToken != "" else {
                
                completion([])
                return
                
            }
            
            let url = API.BASE + API.USERS + "me/" + API.MSSPS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET,parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.MSSPS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.MSSPS): \(err.localizedDescription)")
                    completion([])
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion([])
                    
                    return
                    
                }
                
                var providers = [MIMSSPS]()
                
                if let dataDictionary = responseDictionary["data"] as? [[String:Any]]{
                    
                    for providerDictionary in dataDictionary{
                        
                        let provider = MIMSSPS()
                        
                        if let providerId = MusicProvider(rawValue: providerDictionary["msspId"] as! Int) {
                            
                            provider.id = providerId
                            
                        } else {
                            
                            Analytics.setUserProperty(AnalyticsSegments.MSSP_NONE, forName: AnalyticsSegments.PREMIUM_MSSP)
                            provider.id = .none
                            
                        }

                        provider.name = providerDictionary["msspName"] as! String
                        provider.token = providerDictionary["token"] as! String
                        
                        /*if let msspId = MusicProvider(rawValue: provider.id.rawValue){
                            
                            MIManager.manager.musicProvider = msspId

                        }*/
                        
                        if let tokenExpirationStr = providerDictionary["expiresAt"] as? String{
                            
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            if let tokenExpirationDate = dateFormatter.date(from:tokenExpirationStr){
                                
                                self.musicProvider.tokenExpirationDate = tokenExpirationDate.timeIntervalSince1970
                                
                            }
                            
                        }

                        provider.isActive = true
                        
                        providers.append(provider)
                        
                    }
                }
                
                completion(providers)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.MSSPS) \(error)")
            completion([])
            
        }
        
    }
    
    /**
     Connect music provider to the current user
     -parameter provider: music provider to connect
     -parameter completion: completion handler
     */
    public func connectMusicProvider(provider: MIMSSPS,code: String, completion: @escaping (_ result: Bool) -> Void){
        
        do {
            
            let url = API.BASE + "users/" + API.CURRENT_USER_BASE + API.MSSPS
            //            self.accessToken = FBSDKAccessToken.curre
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:self.accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            let parameters = [API.PROVIDER_AUTH_TOKEN: code,API.PROVIDER_ID: provider.id.rawValue] as [String : Any]
            
            let opt = try HTTP.New(url, method: .POST,parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(url) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(url): \(err.localizedDescription)")
                    completion(false)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    
                    return
                    
                }
                
                MIAnalyticsManager.isMSSPEventShouldBeSent = true
                
                DispatchQueue.main.sync {
                    
                    PlayerController.stopAll()
                    
                }
                
                if let responseData = responseDictionary["data"] as? [String:Any]{
                    
                    self.parseMusicProviderResponse(responseData: responseData)
                    
                }
                
                DispatchQueue.main.sync {
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_CONNECTED), object: nil)
                    
                }
                
                //Reload controllers
                PlayerController.set(self.musicProvider.id)
                SearchController.set(self.musicProvider.id)

                completion(true)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.MSSPS) \(error)")
            completion(false)
            
        }
        
    }
    
    /**
     disconnect music provider to the current user
     -parameter provider: music provider to connect
     -parameter completion: completion handler
     */
    public func disConnectMusicProvider(msspId: Int, completion: @escaping (_ result: Bool) -> Void){
        
        do {
            
            let url = API.BASE + API.USERS + "me/" + API.MSSPS + "/\(msspId)"
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let method = HTTPVerb.DELETE
            
            let opt = try HTTP.New(url, method: method, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(url) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(url): \(err.localizedDescription)")
                    completion(false)
                    return
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    return
                    
                }
                
                guard let success = responseDictionary["success"] as? Bool, success == true else{
                    
                    log.error("Cannot get value for success key or success is false")
                    completion(false)
                    return
                    
                }
                
                MIAnalyticsManager.logEvent(AnalyticsScreens.MSSP_DISCONNECT, parameters:["mssp_id":msspId, "is_premium":!self.musicProvider.isPremiumRequired])
                
                //Logout from Spotify Player
                if MIManager.manager.userMssps().id == .spotify{
                    
                    SPTAudioStreamingController.sharedInstance().logout()

                }
                
                DispatchQueue.main.sync {
                    
                    //Reset music provider
                    self.musicProvider = MIMSSPS()
                    PlayerController.stopAll()
                    
                    Analytics.setUserProperty(AnalyticsSegments.MSSP_NONE, forName: AnalyticsSegments.PREMIUM_MSSP)

                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_DISCONNECTED), object: nil)
                    
                }
                
                //Reload controllers
                PlayerController.set(self.musicProvider.id)
                SearchController.set(self.musicProvider.id)
                
                //Set value for key Config.PREVIEW_MODE_KEY used to check if user has already selected Preview Mode before
                UserDefaults.standard.setValue(false, forKey: Config.PREVIEW_MODE_KEY)
                UserDefaults.standard.synchronize()

                log.error("Music provider successfully disconnected.")
                completion(true)
                return
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.USERS + "me") \(error)")
            completion(false)
            
        }
        
    }
    
    /**
     Get token for music provider
     -parameter provider: music provider to connect
     -parameter completion: completion handler
     */
    public func refreshTokenForMusicProvider(provider: MIMSSPS, completion: @escaping (_ result: Bool) -> Void){
        
        do {
            
            let url = API.BASE + "users/" + API.CURRENT_USER_BASE + API.MSSPS + "/\(provider.id.rawValue)"
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET,parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(url) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(url): \(err.localizedDescription)")
                    completion(false)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    
                    return
                    
                }
                
                if let responseData = responseDictionary["data"] as? [String:Any]{
                    
                    self.parseMusicProviderResponse(responseData: responseData)

                }
                
                //Reload controllers
                PlayerController.set(self.musicProvider.id)
                SearchController.set(self.musicProvider.id)

                completion(true)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.MSSPS) \(error)")
            completion(false)
            
        }
        
    }
    
    /**
     Parse response from connect & refresh token for a music provider
     -parameter responseData: response data
     */
    private func parseMusicProviderResponse(responseData: [String:Any]){
        
        //Check connected music provider
        var musicProviderId: MusicProvider = .none
        
        if let providerId = responseData["msspId"] as? Int, let msspId = MusicProvider(rawValue: providerId) {
            
            musicProviderId = msspId
            
        } else if let providerId = responseData["providerId"] as? Int, let msspId = MusicProvider(rawValue: providerId) {
            
            musicProviderId = msspId
            
        }
        
        //Create new music provider
        let newProvider = MIMSSPS()
        newProvider.id = musicProviderId
        
        //Check if response has a token for connected music provider
        if let token = responseData["token"] as? String {
            
            switch musicProviderId {
                
            case .spotify:
                
                self.setupSpotifyPlayer(token:token)
                
                newProvider.token = token
                
                if let tokenExpirationStr = responseData["expiresAt"] as? String{
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    if let tokenExpirationDate = dateFormatter.date(from:tokenExpirationStr){
                        
                        newProvider.tokenExpirationDate = tokenExpirationDate.timeIntervalSince1970
                        
                    }
                    
                }
            case .appleMusic:
                
                //We haven't tokens for Apple Music that's why we should request authorization each token refresh
                MIConnectMusicProviderController.appleMusicRequestPermission {

                }
                
            case .none:
                Analytics.setUserProperty(AnalyticsSegments.MSSP_NONE, forName: AnalyticsSegments.PREMIUM_MSSP)
                
            default:
                break
                
            }
            
        }
        
        setMusicProvider(provider: newProvider)
        
    }
    
    /**
     Get the most used artists in playlists creation for the last 24 hours
     -parameter completion: completion handler
     */
    public func trendingArtists(completion:@escaping (_ result: [String]) -> Void){
        
        do {
            
            let url = API.BASE + API.TRENDING_ARTISTS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.TRENDING_ARTISTS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.TRENDING_ARTISTS): \(err.localizedDescription)")
                    completion([])
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion([])
                    return
                    
                }
                
                
                guard let artists = responseDictionary["data"] as? [String] else {
                    
                    log.error("Cannot parse artists")
                    completion([])
                    return
                    
                }

                completion(artists)

            }
            
        } catch let error {
            
            log.error("Got an error for \(API.TRENDING_ARTISTS) \(error)")
            completion([])
            
        }
        
    }

    
    /**
     Post new playlist
     -parameter playlist: playlist to post
     -parameter completion: completion handler
     */
    public func postPlaylist(playlist:MIPlaylist, socialNetworksToShare:[String], completion:@escaping (_ result: Bool) -> Void){
        
        //Add tracks to Mixably
        addTracksFromPlaylist(playlist: playlist, completion: { result in

            //Upload cover for playlist
            self.uploadCoverPlaylist(playlist: playlist, completion: { result in
                
                //Create playlist on Mixably
                guard playlist.artworkId != 0 else {
                    
                    completion(false)
                    
                    return
                    
                }
                
                do {
                    
                    let url = API.BASE + API.PLAYLISTS
                    let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:self.accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
                    
                    //Create array with tracks
                    var position = 0
                    var tracks = [[String:Any]]()
                    
                    var tracksToRemove = [MITrack]()
                    
                    for track in playlist.tracks{
                        
                        
                        let trackDictionary = [API.TRACK_ID: track.trackId, API.POSITION: position] as [String : Any]
                        tracks.append(trackDictionary)
                        
                        position += 1
                        
                        tracksToRemove.append(track)
                        
                        if position == Config.MAX_TRACKS_IN_PLAYLIST {
                            break;
                        }
                        
                    }
                    
                    let parameters = [API.ARTWORK_ID:playlist.artworkId, API.CAPTION:playlist.caption, API.TITLE:playlist.title, API.TRACKS:tracks,API.IS_PRIVATE:playlist.isPrivate] as [String : Any]

                    let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
                    opt.start { response in
                        
                        log.debug("Response for \(API.PLAYLISTS) : \n\(String(describing: response.text))\n")

                        if let err = response.error {
                            
                            log.error("Got an error for \(API.PLAYLISTS): \(err.localizedDescription)")
                            completion(false)
                            return
                            
                        }
                        
                        let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                        
                        //Check if have a valid dictionary
                        guard let responseDictionary = jsonRootObject as? [String: Any] else{
                            
                            log.error("Cannot parse response data")
                            completion(false)
                            return
                            
                        }
                        
                        MIManager.manager.getUserInfoWithUserId(userId: "me") { (currentUser: MIUser) in

                            MIAnalyticsManager.logEvent(AnalyticsScreens.CREATION_FINISH, parameters:["username":currentUser.displayName, "user_id":currentUser.id])
                            
                        }
                        
                        if let responseData = responseDictionary["data"] as? [String: Any]{
                            
                            if let href = responseData["href"] as? String, let playlistId = responseData["id"] as? Int{
                                
                                playlist.href = href
                                playlist.id = playlistId
                                
                                DispatchQueue.main.async {
                                    
                                    //Find how many social networks an user use
                                    self.socialNetworksToShareEditingPlaylist = socialNetworksToShare
                                    
                                    //Instagram sharing don't work now
                                    //if self.socialNetworksToShareEditingPlaylist.index(of: API.INSTAGRAM) != nil{
                                    //
                                    //    self.publishPlayListToInstagram(playlist: playlist, completion:{
                                    //
                                    //        self.socialNetworksToShareEditingPlaylist.remove(at: self.socialNetworksToShareEditingPlaylist.index(of: API.INSTAGRAM)!)
                                    //
                                    //    })
                                        
                                    //}
                                    
                                    if self.socialNetworksToShareEditingPlaylist.index(of: API.FACEBOOK) != nil{
                                        
                                        self.publishPlaylistToFacebook(playlist: playlist, completion:{
                                            
                                            self.socialNetworksToShareEditingPlaylist.remove(at: self.socialNetworksToShareEditingPlaylist.index(of: API.FACEBOOK)!)
                                            
                                            //Check if a playlist posted in all selected social networks
                                            self.checkIfPlaylistPublished()
                                            
                                            self.tryToPostInTwitter(playlist:playlist)
                                            
                                        })
                                        
                                    }else if self.socialNetworksToShareEditingPlaylist.index(of: API.TWITTER) != nil {
                                        
                                        self.tryToPostInTwitter(playlist:playlist)
                                        
                                    }
                                    
                                    if self.socialNetworksToShareEditingPlaylist.index(of: NSLocalizedString(API.PUBLISH_TO_SPOTIFY, comment: API.PUBLISH_TO_SPOTIFY).lowercased()) != nil {
                                        
                                            self.publishPlayListToSpotify(playlist: playlist, completion:{
                                                
                                                self.socialNetworksToShareEditingPlaylist.remove(at: self.socialNetworksToShareEditingPlaylist.index(of: NSLocalizedString(API.PUBLISH_TO_SPOTIFY, comment: API.PUBLISH_TO_SPOTIFY).lowercased())!)
                                                
                                                //Check if a playlist posted in all selected social networks
                                                self.checkIfPlaylistPublished()
                                                
                                            })
                                    }
                                    
                                    self.checkIfPlaylistPublished()

                                }
                                
                            }
                            
                        }
                        
                    }
                    
                } catch let error {
                    
                    log.error("Got an error for \(API.COVERS) \(error)")
                    completion(false)
                    
                }
                
            })
            
        })

        
    }
    
    func checkIfPlaylistPublished() {
        
        if socialNetworksToShareEditingPlaylist.count == 0{
            
            sharingTimer.invalidate()
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.PLAYLIST_POSTED), object: nil)
            
        }
        
    }
    
    /**
     Add new tracks to Mixably
     -parameter playlist: playlist to post
     -parameter completion: completion handler
     */
    public func addTracksFromPlaylist(playlist:MIPlaylist, completion:@escaping (_ result: Bool) -> Void){
        
        //Separate tracks by provider, because API has a request for each provider
        let musicProviders = [API.SPOTIFY, API.ITUNES]
        var tracks = [String:[MITrack]]()
        
        for track in playlist.tracks{
            
            for musicProvider in musicProviders{
                
                if track.trackId.lowercased().contains(musicProvider.lowercased()) {
                    
                    if tracks[musicProvider] != nil{
                        
                        tracks[musicProvider]?.append(track)
                        
                    }else{
                        
                        tracks[musicProvider] = [MITrack]()
                        tracks[musicProvider]?.append(track)
                        
                    }
                }
            }
        }
        
        var uploadedProviders = 0
        let musicProvidersToUpload = Array(tracks.keys)
        
        guard musicProvidersToUpload.count != 0 else{
            
            completion(true)
            return
            
        }
        
        //Upload tracks for all music providers
        for musicProvider in musicProvidersToUpload{
            
            //For testing
            
            checkTracksFromProvider(provider:musicProvider, playlist: playlist, completion: { result in

            })
            
            addTracksFromProvider(provider:musicProvider, playlist: playlist, completion: { result in

                uploadedProviders += 1
                
                if uploadedProviders == musicProvidersToUpload.count{
                    
                    completion(true)
                    
                }
                
            })
            
        }
        
    }
    
    /**
     Add new tracks to Mixably
     -parameter provider: provider where track were found
     -parameter playlist: playlist to post
     -parameter completion: completion handler
     */
    public func addTracksFromProvider(provider:String, playlist:MIPlaylist, completion:@escaping (_ result: Bool) -> Void){
        
        do {
            
            let url = API.BASE + provider + "/" + API.TRACKS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:self.accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            //Create array with tracks
            var tracks = [[String:Any]]()
            
            for track in playlist.tracks{
                
                if let data = track.rawData.data(using: .utf8) {
                    
                    do {
                        try tracks.append((JSONSerialization.jsonObject(with: data, options: []) as? [String: Any])!)
                    } catch {
                        log.error(error.localizedDescription)
                    }
                }
                
            }
            
            let parameters = [API.TRACKS:tracks] as [String : Any]
            
            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(url) : \n\(String(describing: response.text))\n")
                log.debug(headers)
                log.debug(parameters)
                
                if let err = response.error {
                    
                    log.error("Got an error for \(url): \(err.localizedDescription)")
                    completion(false)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard (jsonRootObject as? [String: Any]) != nil else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    return
                    
                }
                
                completion(true)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.COVERS) \(error)")
            completion(false)
            
        }
        
    }
    
    /**
     Check tracks on Mixably
     -parameter provider: provider where track were found
     -parameter playlist: playlist to post
     -parameter completion: completion handler
     */
    public func checkTracksFromProvider(provider:String, playlist:MIPlaylist, completion:@escaping (_ result: Bool) -> Void){
        
        do {
            
            let url = API.BASE + provider + "/" + API.TRACKS + API.CHECK
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:self.accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            //Create array with tracks
            var tracks = [String]()
            
            for track in playlist.tracks{
                
                tracks.append(track.trackId)
                
            }
            
            let parameters = [API.TRACKS:tracks] as [String : Any]
            
            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(url) : \n\(String(describing: response.text))\n")
                log.debug(headers)
                log.debug(parameters)
                
                if let err = response.error {
                    
                    log.error("Got an error for \(url): \(err.localizedDescription)")
                    completion(false)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard (jsonRootObject as? [String: Any]) != nil else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    return
                    
                }
                
                completion(true)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.COVERS) \(error)")
            completion(false)
            
        }
        
    }

    /**
     Set music provider
     -parameter provider: music provider to set
     */
    public func setMusicProvider(provider:MIMSSPS){
        
        self.musicProvider = provider
        
    }
    
    /**
     Upload cover playlist
     -parameter playlist: playlist to post
     -parameter completion: completion handler
     */
    public func uploadCoverPlaylist(playlist:MIPlaylist, completion:@escaping (_ result: Bool) -> Void){
        
        do {
            
            var fileUrl = URL(fileURLWithPath:"")
            var coverData = NSData()
            
            fileUrl = URL(fileURLWithPath: playlist.artwork)
            coverData = try Data(contentsOf: fileUrl) as NSData
            
            let url = API.BASE + API.COVERS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            var mimeType = "image/jpeg"
            var fileName = "file.jpg"

            if fileUrl.pathExtension == "gif" {
                
                mimeType = "image/gif"
                fileName = "file.gif"
                
            }
            
            let parameters = ["file": Upload(data: coverData as Data, fileName:fileName, mimeType:mimeType)]
            
            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: HTTPParameterSerializer())
            opt.start { response in
                
                log.debug(opt)
                log.debug("Response for \(API.COVERS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.COVERS): \(err.localizedDescription)")
                    completion(false)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    return
                    
                }
                
                if let responseData = responseDictionary["data"] as? [String: Any]{
                    
                    if let artworkId = responseData["id"] as? Int{
                        
                        playlist.artworkId = artworkId
                        
                    }
                    
                }
                
                completion(true)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.COVERS) \(error)")
            completion(false)
            
        }
        
    }
    
    //MARK: Contacts & Feedback
    /**
     Send feedback
     -parameter email: user's email
     -parameter message: message to send
     -parameter completion: completion handler
     */
    public func sendFeedback(email: String, message:String, completion:@escaping (_ result: Bool) -> Void){
        
        do {
            
            let url = API.BASE + API.FEEDBACK
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            let parameters = ["device":UIDevice.current.model, "appVersion": UIApplication.appVersion(), "buildVersion": Int(UIApplication.appBuild()) ?? 1, "iosVersion":UIDevice.current.systemVersion, "message":message, "email":email] as [String : Any]

            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.FEEDBACK) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.FEEDBACK): \(err.localizedDescription)")
                    completion(false)
                    return
                    
                }
                
                completion(true)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FEED_METHOD) \(error)")
            completion(false)
            
        }
        
    }
    
    //MARK: Audio
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        
        log.debug("Streaming Did Login")

        Analytics.setUserProperty(AnalyticsSegments.MSSP_PREMIUM, forName: AnalyticsSegments.PREMIUM_MSSP)
        musicProvider.isPremiumRequired = false
        
        if MIAnalyticsManager.isMSSPEventShouldBeSent == true{
            
            MIAnalyticsManager.isMSSPEventShouldBeSent = false
            
            MIAnalyticsManager.logEvent(AnalyticsScreens.MSSP_CONNECT, parameters:["mssp_id":self.musicProvider.id.rawValue, "is_premium":!self.musicProvider.isPremiumRequired])
            
        }
        
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        
        if let fullError = error as NSError?{
            
            log.debug(fullError.userInfo)
            log.debug(fullError.code)
            log.debug(fullError.domain)
                        
            if musicProvider.id == .appleMusic {
                return
            }
            
            switch SpErrorCode(rawValue:UInt(fullError.code)) {
                
                case SPErrorNeedsPremium:
                    
                    Analytics.setUserProperty(AnalyticsSegments.MSSP_FREE, forName: AnalyticsSegments.PREMIUM_MSSP)

                    musicProvider.id = .spotify
                    musicProvider.isPremiumRequired = true
                    
                case SPErrorContextFailed:
                    PlayerController.playNextTrack()
                    break
                case SPErrorNotActiveDevice:
                    break
                default:
                    //We cannot hanle error. Just reset music provider and show error
                    //ToDo: show error
                    break
                
            }
            
            if MIAnalyticsManager.isMSSPEventShouldBeSent == true{
                
                MIAnalyticsManager.isMSSPEventShouldBeSent = false
                
                MIAnalyticsManager.logEvent(AnalyticsScreens.MSSP_CONNECT, parameters:["mssp_id":self.musicProvider.id.rawValue, "is_premium":!self.musicProvider.isPremiumRequired])

            }

        }
        
    }
    
    public func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceive event: SpPlaybackEvent) {
        
        if event.rawValue == SPPlaybackNotifyLostPermission.rawValue || event.rawValue == SPPlaybackNotifyBecameInactive.rawValue{
            
            if PlayerController.playingTrack().isPlaying{
                
                PlayerController.pauseTrack()
                
                let alert = UIAlertController(title: NSLocalizedString("playing_on_another_device_title", comment: "playing_on_another_device_title"), message: NSLocalizedString("playing_on_another_device_message", comment: "playing_on_another_device_message"), preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: "cancel"), style: UIAlertActionStyle.cancel, handler: { (action) in
                    
                }))
                
                alert.addAction(UIAlertAction(title: NSLocalizedString("play_here", comment: "play_here"), style: UIAlertActionStyle.default, handler: { (action) in
                    
                    PlayerController.resumeTrack()

                }))
                
                UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
                
            }
            
        }
        
        log.debug(event.rawValue)
        
    }

    //MARK:Apple Music
    /**
     Connect to Apple Music
     */
    public func connectAppleMusic(completion: @escaping (_ result: Bool) -> Void){
        
        MPMediaLibrary.requestAuthorization { (status) in
            
            if status == .authorized {
                
                log.debug("Connected to Apple Music")
                
                completion(true)
                
            } else {

                
                var error: String
                
                switch MPMediaLibrary.authorizationStatus() {
                    
                case .restricted:
                    error = "Media library access restricted by corporate or parental settings"
                case .denied:
                    error = "Media library access denied by user"
                default:
                    error = "Unknown error"
                    
                }
                
                log.error("Got an error during connecting to AppMusic: \(error)")

                completion(false)

            }
        }
    }
    
    //MARK: Spotify
    private func setupSpotify(){
        
        SPTAuth.defaultInstance().clientID = API.SPOTIFY_CLIENT_ID
        SPTAuth.defaultInstance().redirectURL = URL(string:API.SPOTIFY_CALLBACK_URL)
        //SPTAuth.defaultInstance().tokenSwapURL = URL(string:kTokenSwapURL)
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthPlaylistModifyPublicScope, SPTAuthStreamingScope]
        //SPTAuth.defaultInstance().tokenRefreshURL = URL(string: kTokenRefreshServiceURL)!
        SPTAuth.defaultInstance().sessionUserDefaultsKey = API.SPOTIFY_USER_SESSION_KEY
        SPTAudioStreamingController.sharedInstance().delegate = self
        SPTAudioStreamingController.sharedInstance().playbackDelegate = self

        guard let spotifyAuth = SPTAuth.defaultInstance() else{
            return
        }
        
        if let session = spotifyAuth.session, session.isValid(){
            
            do {
                
                try SPTAudioStreamingController.sharedInstance().start(withClientId: SPTAuth.defaultInstance().clientID)
                SPTAudioStreamingController.sharedInstance().delegate = self
                SPTAudioStreamingController.sharedInstance().playbackDelegate = self

                
            }catch let error as NSError{
                
                log.error("Cannot start Spotify player: \(error)")
                
            }
            
        }
        
    }
    
    private func setupSpotifyPlayer(token: String){
        
        do {
            
            if SPTAudioStreamingController.sharedInstance().loggedIn{
                
                guard SPTAudioStreamingController.sharedInstance().playbackState != nil, SPTAudioStreamingController.sharedInstance().playbackState.isPlaying == false else{
                    
                    return
                    
                }
                
                SPTAudioStreamingController.sharedInstance().logout()
                //try SPTAudioStreamingController.sharedInstance().stop()
                
            }else{
                
                try SPTAudioStreamingController.sharedInstance().start(withClientId: SPTAuth.defaultInstance().clientID)
                SPTAudioStreamingController.sharedInstance().delegate = self
                SPTAudioStreamingController.sharedInstance().playbackDelegate = self

            }

            SPTAudioStreamingController.sharedInstance().login(withAccessToken: token)
            
            self.musicProvider.token = token
            
            self.spotifyUserId(token:self.musicProvider.token, completion: {
                
            })

        }catch let error as NSError{
            
            if SPTAudioStreamingController.sharedInstance().loggedIn{
                
                SPTAudioStreamingController.sharedInstance().logout()
                
            }
            
            SPTAudioStreamingController.sharedInstance().login(withAccessToken: token)
            
            self.musicProvider.token = token
            
            self.spotifyUserId(token:self.musicProvider.token, completion: {
                
            })
            
            log.error("Cannot start Spotify player: \(error)")
            
        }
        
    }
    
    /**
     Login Spotify
     */
    public func loginSpotify() {

        guard let spotifyAuth = SPTAuth.defaultInstance() else{
            return
        }

        if let session = spotifyAuth.session, session.isValid(){
            
            // It's still valid, show the player.

        }

        if spotifyAuth.hasTokenRefreshService {
            
            SPTAuth.defaultInstance().renewSession(SPTAuth.defaultInstance().session) { error, session in
                SPTAuth.defaultInstance().session = session
                
                guard error == nil else{

                    print("*** Error renewing session: \(String(describing: error))")
                    return
                    
                }

            }
            
        }
        
        do {
            
            try SPTAudioStreamingController.sharedInstance().start(withClientId: SPTAuth.defaultInstance().clientID)
            SPTAudioStreamingController.sharedInstance().delegate = self
            SPTAudioStreamingController.sharedInstance().playbackDelegate = self
            
        }catch let error as NSError{
            
            log.error("Cannot start Spotify player: \(error)")
            
        }
        
        UIApplication.shared.open(SPTAuth.loginURL(forClientId: API.SPOTIFY_CLIENT_ID,withRedirectURL:NSURL(string: API.SPOTIFY_CALLBACK_URL) as URL!,scopes:[SPTAuthPlaylistModifyPublicScope, SPTAuthStreamingScope],responseType:"code"), options: [:], completionHandler: nil)
        
    }
    
    /**
     Swap Spotify token
     */
    public func swapSpotify(authenticationToken:String) {
        
        //Try to swap spotify token
        do {
            
            let url = API.BASE + API.AUTH_SPOTIFY_SWAP
            let parameters = [API.PROVIDER_AUTH_TOKEN: authenticationToken, API.APNS_TOKEN: "no_token_now"] as [String : String]
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .POST,parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.AUTH_SPOTIFY_SWAP) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.AUTH_SPOTIFY_SWAP): \(err.localizedDescription)")

                    return
                    
                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.AUTH_SPOTIFY_SWAP) \(error)")
            
        }
        
    }
    
    /**
     Parse spotify track dictionary to MITrack object
     -parameter trackDictionary: dictionary to parse
     */
    
    private func parseSpotifyTrack(trackDictionary: [String:Any]) -> MITrack{
        
        let newTrack = MITrack()
        
        if let name = trackDictionary["name"] as? String{
            
            newTrack.name = name
            
        }
        
        if let uri = trackDictionary["uri"] as? String{
            
            newTrack.trackId = uri
            
        }
        
        if let previewUrl = trackDictionary["preview_url"] as? String{
            
            newTrack.previewUrl = previewUrl
            
        }
        
        do {
            
            let jsonData: NSData = try JSONSerialization.data(withJSONObject: trackDictionary, options: JSONSerialization.WritingOptions(rawValue: 0)) as NSData
            newTrack.rawData = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
        
        } catch {
            print(error.localizedDescription)
        }
        
        if let artistArray = trackDictionary["artists"] as? [[String:Any]]{
            
            for artistDictionary in artistArray{
                
                if let artistName = artistDictionary["name"] as? String{

                    let newArtist = MIArtist()
                    newArtist.name = artistName

                    newTrack.artistNames.append(newArtist)

                }
                
            }
            
        }
        
        
        return newTrack
    }
    
    /**
     Parse Spotify artist dictionary to MIArtist object
     -parameter artistDictionary: dictionary to parse
     */
    private func parseSpotifyArtist(artistDictionary: [String:Any]) -> MIArtist{
        
        let newArtist = MIArtist()
        
        if let name = artistDictionary["name"] as? String{
            
            newArtist.name = name
            
        }
        
        if let id = artistDictionary["id"] as? String{
            
            newArtist.id = id
            
        }
        
        if let images = artistDictionary["images"] as? [[String:Any]]{
            
            if let artwork = images.first{
                
                if let url = artwork["url"] as? String{
                    
                    newArtist.artworkUrl = url
                    
                }

            }
            
        }
        
        return newArtist
    }
    
    /**
     Parse Spotify album dictionary to MIAlbum object
     -parameter albumDictionary: dictionary to parse
     */
    private func parseSpotifyAlbum(albumDictionary: [String:Any]) -> MIAlbum{
        
        let newAlbum = MIAlbum()
        
        if let name = albumDictionary["name"] as? String{
            
            newAlbum.name = name
            
        }
        
        if let id = albumDictionary["id"] as? String{
            
            newAlbum.id = id
            
        }
        
        if let images = albumDictionary["images"] as? [[String:Any]]{
            
            if let artwork = images.first{
                
                if let url = artwork["url"] as? String{
                    
                    newAlbum.artworkUrl = url
                    
                }
                
            }
            
        }
        
        if let artists = albumDictionary["artists"] as? [[String:Any]]{
            
            if let artist = artists.first{
                
                if let artistName = artist["name"] as? String{
                    
                    newAlbum.artistName = artistName
                    
                }
                
            }
            
        }
        
        return newAlbum
    }
    
    //MARK: Feed
    /**
     Get user's feed using me/feed method
     -parameter completion: completion handler
     */
    public func userFeed(offset:Int, completion: @escaping (_ result: [MIPlaylist]) -> Void){
        
        //Try get user's feed
        do {
            
            let trace = Performance.startTrace(name: "feed_load")
            trace?.incrementCounter(named:"reload")

            // Retrieve the MSSP ID from User Defaults (fallback to Spotify if none is set):
            let url = "\(API.BASE)\(API.FEED_METHOD)"
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            var parameters = [API.FEED_LIMIT: Config.USER_FEED_LIMIT, API.FEED_OFFSET: offset] as [String : Int]

            //If user has connected music provider show only playlists with this music provider. Otherwise show all
            if musicProvider.id != .none {
                
                parameters[API.PROVIDER_ID] = musicProvider.id.rawValue
                
            }

            let opt = try HTTP.New(url, method: .GET, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                trace?.stop()

#if DEBUG

                log.debug("Response for \(API.FEED_METHOD) : \n\(String(describing: response.text))\n")
#endif
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.FEED_METHOD): \(err.localizedDescription)")
                    completion([])
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])

                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion([])
                    return
                    
                }
                
                /*guard let dataDictionary = responseDictionary["data"] as? [String:Any] else{
                    
                    log.error("Cannot get value for data key")
                    completion([])
                    return
                    
                }*/
                
                //Try to get "playlists" value from the response
                guard let playListDictionary = responseDictionary["data"] as? [[String: Any]] else{
                    
                    log.error("Cannot get value for playlists key")
                    completion([])
                    return
                    
                }
                
                //Parse playlists
                let playLists = self.parsePlaylists(playLists:playListDictionary)
                
                if let firstPlaylist = playLists.first, offset == 0{
                    
                    if let artworkPath = URL(string:firstPlaylist.artwork){
                        
                        UIImageView().kf.setImage(with: artworkPath, completionHandler: {
                            (image, error, cacheType, imageUrl) in
                            
                            DispatchQueue.global().async {
                                
                                completion(Array(playLists))

                            }
                            
                        })
                    }
                    
                }else{
                    
                    completion(Array(playLists))

                }

                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FEED_METHOD) \(error)")
            completion([])
            
        }
        
    }
    
    /**
     Get info about playlist
     -parameter playlist: playlist to get info
     -parameter completion: completion handler
     */
    public func playListInfo(playList:MIPlaylist, completion: @escaping (_ result: MIPlaylist) -> Void){
        
        //Check if we already loaded tracks
        guard playList.tracks.count == 0 else {
            
            completion(playList)
            return
            
        }
        
        let trace = Performance.startTrace(name: "playlist_info")
        trace?.incrementCounter(named:"load")

        //Try to get tracks & detailed info about playlist
        do {
            
            let url = API.BASE + API.FEED_METHOD + String("/\(playList.id)")
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                //log.debug("Response for \(API.FEED_METHOD) : \n\(response.text)\n")
                
                trace?.stop()
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.FEED_METHOD): \(err.localizedDescription)")
                    completion(playList)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(playList)
                    return
                    
                }
                
                guard let dataDictionary = responseDictionary["data"] as? [String:Any] else{
                    
                    log.error("Cannot get value for data key")
                    completion(playList)
                    return
                    
                }
                
                //Try to get "playlists" value from the response
                guard let tracksDictionary = dataDictionary["tracks"] as? [[String: Any]] else{
                    
                    log.error("Cannot get value for playlists key")
                    completion(playList)
                    return
                    
                }
                
                //Parse tracks
                let tracks = self.parseTracks(tracks:tracksDictionary)
                
                for track in tracks{
                    
                    if playList.tracks.first(where: { $0.trackId == track.trackId }) == nil {
                        
                        playList.tracks.append(track)
                        
                    }

                }

                DispatchQueue.main.sync {

                    completion(playList)
                    
                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FEED_METHOD) \(error)")
            completion(playList)
            
        }
        
    }
    
    private func parsePlaylists(playLists:[[String:Any]]) -> [MIPlaylist]{
        
        var parsedPlayLists = [MIPlaylist]()
        
        for element in playLists {
            
            if let playList = MIPlaylist(JSON:element){
                
                parsedPlayLists.append(playList)
                                
            }
            
        }
        
        return parsedPlayLists
        
    }
    
    private func parseTracks(tracks:[[String:Any]]) -> [MITrack]{
        
        var parsedTracks = [MITrack]()
        
        for element in tracks {
            
            if let track = MITrack(JSON:element){
                
                if track.isAvailable == true{
                    
                    parsedTracks.append(track)
                    
                }
                
            }
            
        }
        
        return parsedTracks
        
    }
    
    //MARK: PlayLists
    /**
     Notify server that user started playlist
     -parameter playListId: user's playlist
     -parameter completion: completion handler
     */
    public func playListPlay(playList:MIPlaylist, completion:@escaping () -> Void){
        
        //Try get user's feed
        do {
            
            let playListId = String(playList.id)
            let url = API.BASE + API.PLAYLISTS_BASE + String("\(playListId)") + API.PLAYS_METHOD
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .POST, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.PLAYS_METHOD) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.PLAYS_METHOD): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                DispatchQueue.main.async{
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.PLAYLIST_PLAYED), object: nil, userInfo: nil)

                }
                
                MIAnalyticsManager.logEvent(AnalyticsScreens.PLST_PLAY, parameters:["plst_id":playList.id, "plst_title":playList.title])

                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FEED_METHOD) \(error)")
            completion()
            
        }
        
    }
    
    /**
     Notify server that user stopped playlist
     -parameter playListId: user's playlist
     -parameter secondsSpent: seconds soent by user
     -parameter completion: completion handler
     */
    public func stopPlayList(playListId:String, secondsSpent:Int, completion:@escaping () -> Void){
        
        //Try get user's feed
        do {
            
            let url = API.BASE + API.PLAYLISTS_BASE + String("\(playListId)") + API.STOPPED_METHOD
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            let parameters = [API.SECONDS_SPENT: secondsSpent] as [String : Int]

            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.STOPPED_METHOD) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.STOPPED_METHOD): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FEED_METHOD) \(error)")
            completion()
            
        }
        
    }
    
    //MARK: Likes & Emoji
    /**
     Like playlist
     -parameter isLike: like or dislike
     -parameter playList: playlist to like
     -parameter completion: completion handler
     */
    public func likePlayList(isLike: Bool, playList:MIPlaylist, completion:@escaping () -> Void){
        
        guard accessToken != "" else {
            
            MIUIUtilities.showFacebookLoginAlert()
            
            DispatchQueue.global().async {
                
                completion()
                
            }
            
            return
            
        }
        //Show like tutorial alert if needed
        MIUIUtilities.showTutorialAlertIfNeeded(title: NSLocalizedString("lit", comment: "Lit!"), message: Config.LIKE_TUTORIAL_ALERT, button: NSLocalizedString("got_it", comment: "Got it"))
        
        do {
            
            let url = API.BASE + API.PLAYLISTS_BASE + String("\(playList.id)") + API.LIKES
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let method = isLike ? HTTPVerb.POST : HTTPVerb.DELETE
            
            let opt = try HTTP.New(url, method: method, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.LIKES) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.LIKES): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                if isLike{
                    
                    MIAnalyticsManager.logEvent(AnalyticsScreens.PLST_LIKE, parameters:["plst_id":playList.id, "title":playList.title])

                    playList.hearts += 1

                }else{
                    
                    MIAnalyticsManager.logEvent(AnalyticsScreens.PLST_DISLIKE, parameters:["plst_id":playList.id, "title":playList.title])

                    playList.hearts -= 1

                }
                
                playList.isHearted = isLike
                
                DispatchQueue.main.sync {

                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.PLAYLIST_UPDATED), object: nil, userInfo: ["track": MITrack()])
                    
                }
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.LIKES) \(error)")
            completion()
            
        }
        
    }

    //MARK: Other playlist requests
    /**
     Register playlist impression
     -parameter playList: playlist to like
     -parameter completion: completion handler
     */
    public func registerPlaylistImpression(playList:MIPlaylist, completion:@escaping () -> Void){
  
        do {
            
            guard accessToken != "" else {
                
                completion()
                return
                
            }
            
            let url = API.BASE + API.PLAYLISTS_BASE + String("\(playList.id)") + API.IMPRESSIONS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            let parameters = [API.IMPRESSION_TYPE:API.IMPRESSION_TYPE_FEED]
            
            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.LIKES) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.LIKES): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.LIKES) \(error)")
            completion()
            
        }
    }
    
    /**
     Report a user
     -parameter user: user to report
     -parameter completion: completion handler
     */
    public func reportUser(user:MIUser, completion:@escaping () -> Void){
        
        do {
            
            let url = API.BASE + API.USERS + String("\(user.id)") + API.REPORT_USER
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .POST, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.IMPRESSIONS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.IMPRESSIONS): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                DispatchQueue.main.sync {
                    
                    //Show confirmation alert
                    MIUIUtilities.showErrorAlert(title: NSLocalizedString("user_is_reported_title", comment: "user_is_reported_title"), message: NSLocalizedString("user_is_reported_message", comment: "user_is_reported_message"), button: "OK")
                    
                }
                
                MIManager.manager.getUserInfoWithUserId(userId: "me") { (currentUser: MIUser) in

                    MIAnalyticsManager.logEvent(AnalyticsScreens.USER_REPORT, parameters:["user_id":user.id, "username":user.displayName, "reporter_id":currentUser.id])

                }
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.IMPRESSIONS) \(error)")
            completion()
            
        }
        
    }
    
    /**
     Report a playlist
     -parameter playlist: playlist to report
     -parameter completion: completion handler
     */
    public func reportPlaylist(playlist: MIPlaylist, completion: @escaping (_ error: Error?) -> Void) {
        
        do {
            
            let url = API.BASE + API.PLAYLISTS_BASE + "\(playlist.id)" + API.REPORT_PLAYLIST
            let headers = [API.X_API_HEADER: API.X_API_KEY, API.X_ACCESS_TOKEN: accessToken, API.USER_AGENT: API.USER_AGENT_VALUE] as [String: String]
            let opt = try HTTP.New(url, method: .POST, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            
            opt.start { response in
                
                DispatchQueue.main.async {
                
                    log.debug("Response for \(API.PLAYLISTS + API.REPORT_PLAYLIST) : \n\(String(describing: response.text))\n")
                    
                    if let err = response.error {
                        
                        log.error("Got an error for \(API.PLAYLISTS + API.REPORT_PLAYLIST): \(err.localizedDescription)")
                        
                        completion(err)
                        
                        return
                        
                    }
                    
                    MIAnalyticsManager.logEvent(AnalyticsScreens.PLST_REPORT, parameters:["plst_id":playlist.id, "plst_title":playlist.title, "plst_owner":playlist.owner?.displayName ?? ""])
                
                    completion(nil)
                    
                }
            }
            
        } catch let error {
            
            DispatchQueue.main.async {
                
                log.error("Got an error for \(API.PLAYLISTS + API.REPORT_PLAYLIST) \(error)")
                completion(error)
            
            }
        }
        
    }
    
    /**
     Hide a playlist
     -parameter playlist: playlist to hide
     -parameter completion: completion handler
     */
    public func hidePlaylist(playlist: MIPlaylist, completion: @escaping (_ error: Error?) -> Void) {
        
        do {
            
            let url = API.BASE + API.PLAYLISTS_BASE + "\(playlist.id)" + API.HIDE_PLAYLIST
            let headers = [API.X_API_HEADER: API.X_API_KEY, API.X_ACCESS_TOKEN: accessToken, API.USER_AGENT: API.USER_AGENT_VALUE] as [String: String]
            let opt = try HTTP.New(url, method: .POST, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            
            opt.start { response in
                
                DispatchQueue.main.async {
                    
                    log.debug("Response for \(API.PLAYLISTS + API.HIDE_PLAYLIST) : \n\(String(describing: response.text))\n")
                    
                    if let err = response.error {
                        
                        log.error("Got an error for \(API.PLAYLISTS + API.HIDE_PLAYLIST): \(err.localizedDescription)")
                        
                        completion(err)
                        
                        return
                        
                    }
                    
                    MIAnalyticsManager.logEvent(AnalyticsScreens.PLST_HIDE, parameters:["plst_id":playlist.id, "plst_title":playlist.title, "plst_owner":playlist.owner?.displayName ?? ""])

                    completion(nil)
                    
                }
            }
            
        } catch let error {
            
            DispatchQueue.main.async {
                
                log.error("Got an error for \(API.PLAYLISTS + API.HIDE_PLAYLIST) \(error)")
                completion(error)
            
            }
        }
    }
    
    //MARK: Social
    /**
     Publish playlist to Facebook Graph (private post)
     -parameter completion: playlist to share
     -parameter completion: completion handler
     */
    public func publishPlaylistToFacebook(playlist:MIPlaylist, completion:@escaping () -> Void)
    {
     
        //Uncomment privacy parameter below if you need to post only private posts
        
        /*var privacy = ""
        
        if let theJSONData = try? JSONSerialization.data(
            withJSONObject: ["value" : "SELF"],
            options: []) {
            privacy = String(data: theJSONData,
                                     encoding: .ascii)!
        }*/
        
        let remoteConfig = MIManager.manager.remoteConfig()
        var url = MIUIUtilities.shareURL(playList:playlist)
        
        if let urlParameters = remoteConfig[Config.PUBLISH_SHARE_FB_UTM].stringValue{
            
            url = url + "?" + urlParameters
            
        }
        
        let parameters = ["link" : url/*, "privacy": privacy*/] as [String : Any]
        
        if FBSDKAccessToken.current().hasGranted("publish_actions") {
            
            FBSDKGraphRequest.init(graphPath: "me/feed", parameters: parameters, httpMethod: "POST").start(completionHandler: { (connection, result, error) -> Void in
                
                completion()
                
            })

        }else{
            
            requestFBPublishPermissions(completion:{
                
                FBSDKGraphRequest.init(graphPath: "me/feed", parameters: parameters, httpMethod: "POST").start(completionHandler: { (connection, result, error) -> Void in
                    
                    completion()
                    
                })
                
            })

        }
        
    }
    
    /**
     Request publish permission for Facebook
     -parameter completion: completion handler
     */
    
    private func requestFBPublishPermissions(completion:@escaping () -> Void)
    {
        let login: FBSDKLoginManager = FBSDKLoginManager()
        
        login.logIn(withPublishPermissions: ["publish_actions"], from: UIApplication.topViewController()) { (result, error) in
            if (error != nil) {
                print(error!)
            } else if (result?.isCancelled)! {
                print("Canceled")
            } else if (result?.grantedPermissions.contains("publish_actions"))! {
                print("permissions granted")
            }
            
            completion()
            
        }
        
    }
    
    /**
     Get Spotify User Id
     -parameter token: Spotify token
     -parameter completion: completion handler
     */
    public func spotifyUserId(token:String, completion:@escaping () -> Void){
        
        do {
            
            let url = String("\(API.SPOTIFY_BASE)me")
            

            let headerToken = "Bearer \(token)"
            let headers = ["Authorization":headerToken]
            
            let opt = try HTTP.New(url!, method: .GET, headers:headers)
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error for Spotify search: \(err.localizedDescription)")
                    completion()
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion()
                    return
                    
                }
                
                if let spotifyUserId = responseDictionary["id"] as? String{
                    
                    self.musicProvider.userId = spotifyUserId
                    
                }
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for Spotify search \(error)")
            completion()
            
        }
        
    }
    
    /**
     Create new playlist at Spotify. More info at https://developer.spotify.com/web-api/create-playlist/
     -parameter playlist: playlist to share
     -parameter completion: completion handler
     */
    public func publishPlayListToSpotify(playlist:MIPlaylist, completion:@escaping () -> Void){
        
        do {
            
            let url = String("\(API.SPOTIFY_BASE)users/\(musicProvider.userId)/playlists")
            
            let headerToken = "Bearer \(musicProvider.token)"
            let headers = ["Authorization":headerToken, "Content-Type": "application/json"]
            
            let parameters = ["name":playlist.title,"description":playlist.caption]
            
            let opt = try HTTP.New(url!, method: .POST, parameters:parameters, headers:headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error for Spotify: \(err.localizedDescription)")
                    completion()
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion()
                    return
                    
                }
                
                if let playListId = responseDictionary["id"]{
                    
                    self.addTracksToSpotifyPlayList(playlist: playlist, spotifyPlaylistId: playListId as! String, completion: {
                        
                        completion()
                        
                    })
                    
                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for Spotify \(error)")
            completion()
            
        }
        
    }
    
    /**
     Create new playlist at Spotify. More info at https://developer.spotify.com/web-api/add-tracks-to-playlist/
     -parameter playlist: playlist to share
     -parameter completion: completion handler
     */
    public func addTracksToSpotifyPlayList(playlist:MIPlaylist, spotifyPlaylistId: String, completion:@escaping () -> Void){
        
        do {
            
            let url = String("\(API.SPOTIFY_BASE)users/\(musicProvider.userId)/playlists/\(spotifyPlaylistId)/tracks")
            
            let headerToken = "Bearer \(musicProvider.token)"
            let headers = ["Authorization":headerToken, "Content-Type": "application/json"]
            
            var tracks = [String]()
            
            for track in playlist.tracks{
                
                tracks.append(track.trackId)
                
            }
            
            let parameters = ["uris":tracks]
            
            let opt = try HTTP.New(url!, method: .POST, parameters:parameters, headers:headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error during adding tracks Spotify playlist: \(err.localizedDescription)")
                    completion()
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard (jsonRootObject as? [String: Any]) != nil else{
                    
                    log.error("Cannot parse response data")
                    completion()
                    return
                    
                }
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error during adding tracks Spotify playlist \(error)")
            completion()
            
        }
        
    }
    
    /**
     Create new playlist to Instagram via URL scheme
     -parameter playlist: playlist to share
     -parameter completion: completion handler
     */
    public func publishPlayListToInstagram(playlist:MIPlaylist, completion:@escaping () -> Void){
        
        do {
            let instagramURL = NSURL(string: "instagram://app")
            
            if (UIApplication.shared.canOpenURL(instagramURL! as URL)) {
                
                //Get image data
                let fileUrl = URL(fileURLWithPath: playlist.artwork)
                let coverData = try Data(contentsOf: fileUrl) as NSData
                
                let captionString = playlist.caption
                
                let writePath = (NSTemporaryDirectory() as NSString).appendingPathComponent("instagram.igo")
                if coverData.write(toFile: writePath, atomically: true) == false {
                    
                    return
                    
                } else {
                    let fileURL = NSURL(fileURLWithPath: writePath)
                    
                    interactionController = UIDocumentInteractionController(url: fileURL as URL)
                    interactionController.annotation = NSDictionary(object: captionString, forKey: "InstagramCaption" as NSCopying)
                    interactionController.delegate = self
                    
                    if let controller = UIApplication.topViewController(){
                        
                        interactionController.presentOpenInMenu(from: controller.view.frame, in: controller.view, animated: true)
                        
                    }
                    
                }
                
            } else {
                print(" Instagram isn't installed ")
            }
            
        } catch _ {
            
        }
        
    }
    
    func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController){
        
        self.socialNetworksToShareEditingPlaylist.remove(at: self.socialNetworksToShareEditingPlaylist.index(of: API.INSTAGRAM)!)
        
    }
    
    /**
     Try to post a playlist to Twitter
     */
    private func tryToPostInTwitter(playlist:MIPlaylist){
        
        if self.socialNetworksToShareEditingPlaylist.index(of: API.TWITTER) != nil {
            
            //We should remove twitter from socialNetworksToShareEditingPlaylist before posting to twitter because Swifter framework cannot handle when user taps on cancel button at Twitter authorization screen
            //We should check if a playlist posted in all selected social networks at become active handler
            self.socialNetworksToShareEditingPlaylist.remove(at: self.socialNetworksToShareEditingPlaylist.index(of: API.TWITTER)!)
            
            self.publishPlayListToTwitter(playlist: playlist, completion:{
                
                
            })
            
        }
        
    }
    
    /**
     Post new playlist to Twitter
     -parameter playlist: playlist to share
     -parameter completion: completion handler
     */
    public func publishPlayListToTwitter(playlist:MIPlaylist, completion:@escaping () -> Void){
        
        let swifter = Swifter(consumerKey: API.TWITTER_CONSUMER_KEY, consumerSecret: API.TWITTER_CONSUMER_SECRET)
        
        let url = URL(string: "swifter://success")!
        
        if let viewController = UIApplication.topViewController(){
            
            swifter.authorize(with: url, presentFrom: viewController, success: { _ in
                
                let remoteConfig = MIManager.manager.remoteConfig()
                var url = MIUIUtilities.shareURL(playList:playlist)
                
                if let urlParameters = remoteConfig[Config.PUBLISH_SHARE_TWITTER_UTM].stringValue{
                    
                    url = url + "?" + urlParameters
                    
                }
                
                swifter.postTweet(status: url, success: { status in
                    
                    completion()
                    
                }, failure: { error in
                    
                    completion()
                    
                })
                
            }, failure: { error in
                
                completion()
                
            })
            
        }
        
    }
    
    /**
     Check if user logged in
     */
    public func isUserLogged() -> Bool{
       
        return accessToken != ""
        
    }
    
    
    /**
     Get User Info
     -parameter
     id : String     me | userId
     completion: completion handler
     */
    
    public func getUserInfoWithUserId(userId: String, completion:@escaping(_ result : MIUser)->Void) {
        do {
            
            let url = API.BASE + API.USERS + userId
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.USERS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.USERS): \(err.localizedDescription)")
                    completion(MIUser())
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MIUser())
                    return
                    
                }
                
                guard let dataDictionary = responseDictionary["data"] as? [String:Any] else{
                    
                    log.error("Cannot get value for data key")
                    completion(MIUser())
                    return
                    
                }
                
                
                //Parse playlists
                if let user = MIUser(JSON:dataDictionary){
                    completion(user)
                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.USERS) \(error)")
            completion(MIUser())
            
        }
        
    }
    
    /**
     Update User Info
     -parameter
     id : String     me | userId
     completion: completion handler
     */
    
    public func updateUserInfoWithUserId(userId: String, parameters: [String:Any], completion:@escaping(_ result : MIUser, _ message:String)->Void) {
        do {
            
            let url = API.BASE + API.USERS + userId
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            
            let opt = try HTTP.New(url, method: .PUT, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.USERS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.USERS): \(err.localizedDescription)")
                    completion(MIUser(), err.localizedDescription)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
    
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MIUser(), ApiResponseErrorString.PASING_ERROR)
                    return
                    
                }
                
                guard let status = responseDictionary["success"] as? Bool else {
                    log.error("Cannot get value for success key")
                    completion(MIUser(), ApiResponseErrorString.PASING_ERROR)
                    return
                }
                
                if !status {
                    
                    let errorMessage = responseDictionary["message"] as? String ?? "Parsing error"
                    completion (MIUser(), errorMessage)
                }

                
                guard let dataDictionary = responseDictionary["data"] as? [String:Any] else{
                    
                    log.error("Cannot get value for data key")
                    completion(MIUser(), ApiResponseErrorString.PASING_ERROR)
                    return
                    
                }
                
                
                //Parse playlists
                if let user = MIUser(JSON:dataDictionary){
                    completion(user, "")
                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.USERS) \(error)")
            completion(MIUser(), error.localizedDescription)
            
        }
        
    }
    
    /**
     Upload user avatar
     -parameter
     id : String     me | userId
     completion: completion handler
     */

    
    public func uploadUserAvatar(userId: String, avatar: Data, completion:@escaping(_ result : MIUser)->Void) {
        do {
            
            let url = API.BASE + API.USERS + userId + API.AVATAR
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let parameters = ["file": Upload(data: avatar, fileName:"file", mimeType:"image/jpeg")]
            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: HTTPParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.USERS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.USERS): \(err.localizedDescription)")
                    completion(MIUser())
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MIUser())
                    return
                    
                }
                
                guard let dataDictionary = responseDictionary["data"] as? [String:Any] else{
                    
                    log.error("Cannot get value for data key")
                    completion(MIUser())
                    return
                    
                }
                
                
                //Parse playlists
                if let user = MIUser(JSON:dataDictionary){
                    completion(user)
                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.USERS) \(error)")
            completion(MIUser())
            
        }
        
    }
    
    /**
     Update user name
     -parameter
     userName : String
     completion: completion handler
     */
    
    public func updateUserName(userName: String, completion:@escaping(_ result:Bool, _ message:String)->Void) {
        do {
            
            let url = API.BASE + API.CHANGE_USER_NAME
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let parameters = ["username" : userName]
            
            let opt = try HTTP.New(url, method: .POST, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.CHANGE_USER_NAME) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.CHANGE_USER_NAME): \(err.localizedDescription)")
                    completion(false, err.localizedDescription)
                    return
                    
                }
                
                completion(true, "Success");
                
                /*
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])

                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MIUser(), ApiResponseErrorString.PASING_ERROR)
                    return
                    
                }
                
                guard let status = responseDictionary["success"] as? Bool else {
                    log.error("Cannot get value for success key")
                    completion(MIUser(), ApiResponseErrorString.PASING_ERROR)
                    return
                }
                
                if !status {
                    
                    let errorMessage = responseDictionary["message"] as? String ?? "Parsing error"
                    completion (MIUser(), errorMessage)
                }
                
                guard let dataDictionary = responseDictionary["data"] as? [String:Any] else{
                    
                    log.error("Cannot get value for data key")
                    completion(MIUser(), ApiResponseErrorString.PASING_ERROR)
                    return
                    
                }
                
                
                if let user = MIUser(JSON:dataDictionary){
                    completion(user, "")
                }*/
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.CHANGE_USER_NAME) \(error)")
            completion(false, error.localizedDescription)
            
        }
        
    }

    
    
    /*
        Check username availability
    */
    public func checkUserName(userName: String, completion:@escaping(_ result:Bool, _ message:String)->Void) {
        do {
            
            let url = API.BASE + API.CHECK_USER_NAME + userName
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.CHECK_USER_NAME) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.CHECK_USER_NAME): \(err.localizedDescription)")
                    completion(false, err.localizedDescription)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else {
                    return
                }
                
                guard let dataDictionary = responseDictionary["data"] as? [String:Any] else {
                    return
                }
                
                guard let okBool = dataDictionary["ok"] as? Bool else {
                    return
                }
                
                completion(okBool, "Success");
                
            }
            
        } catch let error {
            log.error("Got an error for \(API.CHECK_USER_NAME) \(error)")
            completion(false, error.localizedDescription)
        }
    }
    
    /*
     Get User Followers
     */
    public func getUserFollowers(userId: String, completion:@escaping()->Void) {
        do {
            
            let url = API.BASE + API.USERS + userId  + API.FOLLOWERS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.FOLLOWERS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.FOLLOWERS): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FOLLOWERS) \(error)")
            completion()
            
        }
        
    }
    
    
    /*
     Get User Following
     */
    public func getUserFollowings(userId: String, completion:@escaping()->Void) {
        do {
            
            let url = API.BASE + API.USERS + userId + API.FOLLOWINGS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: .GET, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.FOLLOWINGS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.FOLLOWINGS): \(err.localizedDescription)")
                    completion()
                    return
                    
                }
                
                
                
                completion()
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FOLLOWINGS) \(error)")
            completion()
            
        }
    }
    
    /*
     Follow and Unfollow user
     */
    public func followUnfollowUser(userId: String, isFollow: Bool, completion:@escaping(_ result:Bool, _ message: String, _ followers: Int)->Void) {
        do {
            
            let url = API.BASE + API.USERS + userId + API.FOLLOWERS
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let opt = try HTTP.New(url, method: isFollow ? .POST : .DELETE, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.FOLLOWERS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.FOLLOWERS): \(err.localizedDescription)")
                    completion(false, err.localizedDescription, 0)
                    return
                }
                
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(false,  "Cannot parse response data", 0)
                    return
                    
                }
                
                guard let dataDictionary = responseDictionary["data"] as? [String:Any] else{
                    
                    log.error("Cannot get value for data key")
                    completion(false, "Cannot get value for data key", 0)
                    return
                    
                }
                
                //Try to get "count" value from the response
                guard let count = dataDictionary["count"] as? Int else{
                    
                    log.error("Cannot get value for count")
                    completion(false, "Cannot get value for data key", 0)
                    return
                    
                }
                
                
                completion(true, "success", count)
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.FOLLOWERS) \(error)")
            completion(false, error.localizedDescription, 0)
        }
        
    }
    
    
    /*
     Get User PlayLists
     -parameter userId: User Id - (use 'me' if you want to get current logged user's playlists)
     -parameter userId: type (see ProfilePlaylistType for more info)
     -parameter completion: completion handler
     */
    public func getUserPlayLists(userId: String, offset: Int, type:ProfilePlaylistType, completion:@escaping(_ result:[MIPlaylist])->Void) {
        do {
            
            var typeStr = ""
            
            switch type{
                
                case .liked:
                    typeStr = API.LIKED
                case .listened:
                    typeStr = API.PLAYED
                default:
                    typeStr = ""
            }
            
            let url = API.BASE + API.USERS + userId + API.USER_PLAYLISTS + typeStr
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            var parameters = [API.FEED_LIMIT: 10, API.FEED_OFFSET: offset] as [String : Int]

            //If user has connected music provider show only playlists with this music provider. Otherwise show all
            if musicProvider.id != .none {
                
                parameters[API.PROVIDER_ID] = musicProvider.id.rawValue
                
            }
            
            let opt = try HTTP.New(url, method: .GET, parameters: parameters, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.USER_PLAYLISTS) : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.USER_PLAYLISTS): \(err.localizedDescription)")
                    completion([])
                    return
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion([])
                    return
                    
                }
                
                //Try to get "playlists" value from the response
                guard let playListDictionary = responseDictionary["data"] as? [[String: Any]] else{
                    
                    log.error("Cannot get value for playlists key")
                    completion([])
                    return
                    
                }
                
                //Parse playlists
                let playLists = self.parsePlaylists(playLists:playListDictionary)
                completion(Array(playLists))
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.USER_PLAYLISTS) \(error)")
            completion([])
            
        }
    }
    
    /*
     Delete account by user itself
    */
    
    public func deleteUserbyItself(completion:@escaping(_ success: Bool)->Void) {
        do {
            
            let url = API.BASE + API.USERS + "me"
            let headers = [API.X_API_HEADER:API.X_API_KEY, API.X_ACCESS_TOKEN:accessToken, API.USER_AGENT:API.USER_AGENT_VALUE] as [String : String]
            
            let method = HTTPVerb.DELETE
            
            let opt = try HTTP.New(url, method: method, parameters: nil, headers: headers, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                
                log.debug("Response for \(API.USERS + "me") : \n\(String(describing: response.text))\n")
                
                if let err = response.error {
                    
                    log.error("Got an error for \(API.USERS + "me"): \(err.localizedDescription)")
                    completion(false)
                    return
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(false)
                    return
                    
                }
                
                guard let success = responseDictionary["success"] as? Bool, success == true else{
                    
                    log.error("Cannot get value for success key or success is false")
                    completion(false)
                    return
                    
                }
                
                log.error("Account is successfully deleted.")
                completion(true)
                return
                
            }
            
        } catch let error {
            
            log.error("Got an error for \(API.USERS + "me") \(error)")
            completion(false)
            
        }
    }
    
    //MARK: Common
    public func checkTokens(){
                
        if musicProvider.tokenExpirationDate != 0, musicProvider.tokenExpirationDate - Date().timeIntervalSince1970 < Config.MIN_TIME_TO_REFRESH_TOKEN{
            
            self.getMSSPSByMe(completion: {_ in
                
            })
            
        }
        
    }
}
