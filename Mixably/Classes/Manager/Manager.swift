//
//  MIManager.swift
//  Mixably
//
//  Created by Mobile App Dev on 21/01/17.
//  Copyright © 2016 Mixably. All rights reserved.
//

import Foundation
import MediaPlayer
import Firebase

/**
Use MIManager for all calls outside managers. Don't call any method from MIServerManager and other managers from the Internal folder directly in your class. If you want to add new method to any manager class, please, use MIManger as the Facade pattern
*/

//MusicProvider ids should be as on Bump backend
public enum MusicProvider : Int {

    case none = 0
    case appleMusic = 1
    case spotify = 2
    
}

class MIManager {
    
    
    static let manager = MIManager()
    
    //Internal managers
    let serverManager: MIServerManager
    private let configManager: MIConfigManager
    private let remoteCommandCenterManager: RemoteCommandCenterManager

    //Data
    private var currentEditingPlaylist = MIPlaylist()
    public var playlistType: ProfilePlaylistType = .feed

    init() {
        
        serverManager = MIServerManager()
        configManager = MIConfigManager()
        remoteCommandCenterManager = RemoteCommandCenterManager()
        
    }
    
    /**
     Try to login to the Mixably server using auth/facebook method
     -parameter authenticationToken: token received from Facebook
     -parameter completion: completion handler
     */
    public func loginWithFacebook(authenticationToken:String, completion:@escaping (_ result: Bool) -> Void){
        
        serverManager.loginWithFacebook(authenticationToken:authenticationToken, completion: completion)
        
    }
    
    /**
     Try to logout from Mixably
     -parameter authenticationToken: token received from Facebook
     -parameter apnsToken: token received from Apns
     -parameter completion: completion handler
     */
    public func logout(authenticationToken:String, apnsToken:String, completion:@escaping () -> Void){
        
        serverManager.logout(authenticationToken:authenticationToken, apnsToken: apnsToken, completion: completion)
        
    }
    
    /**
     Open the app store to update the app
    */
    public func openAppStore(){
        
        let appStoreAppID = "id1252528402"
        
        if let url = URL(string: "itms-apps://itunes.apple.com/app/" + appStoreAppID),
            UIApplication.shared.canOpenURL(url){
            
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
            
        }
    }
    
    /**
     Get user's feed using me/feed method
     -parameter completion: completion handler
     */
    public func userFeed(offset:Int, completion: @escaping (_ result: [MIPlaylist]) -> Void){
        
        serverManager.userFeed(offset: offset, completion: {
            
            result in
            
            PlayerController.player.feedPlaylists.append(contentsOf: result)
            
            completion(result)
            
        })
        
    }
    
    /**
     Get info about playlist
     -parameter playlist: playlist to get info
     -parameter completion: completion handler
     */
    public func playListInfo(playList:MIPlaylist, completion: @escaping (_ result: MIPlaylist) -> Void){
        
        serverManager.playListInfo(playList: playList, completion: {
            
            result in
            
            if PlayerController.player.loadedPlaylists.index(of: result) == nil{
                
                PlayerController.player.loadedPlaylists.append(result)
                
            }
                        
            completion(result)
            
        })

    }
    
    /**
     Get the most used artists in playlists creation for the last 24 hours
     -parameter completion: completion handler
     */
    
    public func trendingArtists(completion:@escaping (_ result: [String]) -> Void){

        serverManager.trendingArtists(completion:completion)
        
    }
    
    /**
     Post playlist to Mixably
     -parameter completion: completion handler
     */
    public func postPlaylist(socialNetworksToShare:[String], completion:@escaping (_ result: Bool) -> Void){

        serverManager.postPlaylist(playlist: currentEditingPlaylist,socialNetworksToShare:socialNetworksToShare, completion: completion)
        
    }
    
    public func playListPlay(playList:MIPlaylist, completion:@escaping () -> Void){

        serverManager.playListPlay(playList: playList, completion: completion)

    }
    
    public func stopPlayList(playListId:String, secondsSpent:Int, completion:@escaping () -> Void){

        serverManager.stopPlayList(playListId: playListId, secondsSpent:secondsSpent, completion: completion)

    }
    
    public func registerPlaylistImpression(playList:MIPlaylist, completion:@escaping () -> Void){

        serverManager.registerPlaylistImpression(playList:playList, completion: completion)
    
    }
    
    public func reportUser(user:MIUser, completion:@escaping () -> Void){

        serverManager.reportUser(user:user, completion: completion)

    }
    
    public func reportPlaylist(playlist: MIPlaylist, completion: @escaping (_ error: Error?) -> Void) {
        
        serverManager.reportPlaylist(playlist: playlist, completion: completion)
        
    }
    
    public func hidePlaylist(playlist: MIPlaylist, completion: @escaping (_ error: Error?) -> Void) {
        
        serverManager.hidePlaylist(playlist: playlist, completion: completion)
        
    }
    
    //MARK: Contacts & Feedback
    /**
     Send feedback
     -parameter email: user's email
     -parameter message: message to send
     -parameter completion: completion handler
     */
    public func sendFeedback(email: String, message:String, completion:@escaping (_ result: Bool) -> Void){
        
        serverManager.sendFeedback(email:email, message: message, completion:completion)
        
    }
    
    //MARK: Music Providers
    
    /**
     Connect music provider to the current user
     -parameter provider: music provider to connect
     -parameter completion: completion handler
     */
    public func connectMusicProvider(provider: MIMSSPS,code: String, completion: @escaping (_ result: Bool) -> Void){
        
        serverManager.connectMusicProvider(provider: provider, code: code, completion: completion)

    }
    
    /**
     Get token for music provider
     -parameter provider: music provider to connect
     -parameter completion: completion handler
     */
    public func refreshTokenForMusicProvider(provider: MIMSSPS, completion: @escaping (_ result: Bool) -> Void){
        
        serverManager.refreshTokenForMusicProvider(provider: provider, completion: completion)

    }
    
    /**
     Get user's music providers
     -parameter completion: completion handler
     */
    public func getMSSPSByMe(completion: @escaping (_ result: [MIMSSPS]) -> Void){

        serverManager.getMSSPSByMe(completion:completion)
        
    }
    
    /**
     Check if current user has connected MSSP
     */
    public func isMusicProviderConnected() -> Bool{
        
        return serverManager.musicProvider.id != .none
        
    }
    
    /**
     Get User's MSSPS
     */
    public func userMssps() -> MIMSSPS{
        
        return serverManager.musicProvider
        
    }
    
    /**
     Set music provider
     -parameter provider: music provider to set. Don't use numbers for music provider id, use values from MusicProvider enum
     */
    public func setMusicProvider(provider:MIMSSPS){
        
        serverManager.setMusicProvider(provider: provider)
        
    }
    
    /**
     Disconnect music provider to the current user
     -parameter msspid:
     -parameter completion: completion handler
     */
    public func disConnectMusicProvider(msspId: Int, completion: @escaping (_ result: Bool) -> Void){
        
        serverManager.disConnectMusicProvider(msspId: msspId, completion: completion)
        
    }
    
    /**
     Disconnect music provider to the current user
     -parameter msspid:
     -parameter completion: completion handler
     */
    public func getMSSPs(completion: @escaping (_ results: [MIMSSPS]) -> Void){
        
        serverManager.getMSSPSByMe(completion: completion)
        
    }

    
    /**
     Connect to Apple Music
     */
    public func connectAppleMusic(completion: @escaping (_ result: Bool) -> Void){
        
        serverManager.connectAppleMusic(completion: completion)
        
    }
        
    /**
     Subscribe to Apple Music
    */
    public func subscribeAppleMusic(){
        
        PlayerController.player.stopAll()
        
    }
    
    /**
     Connect to Spotify
     */
    public func connectSpotify(){
        
        PlayerController.player.stopAll()
        self.serverManager.loginSpotify()
        
    }
    
    /**
     Swap Spotify token
     */
    public func swapSpotify(authenticationToken:String){
        
        serverManager.swapSpotify(authenticationToken:authenticationToken)
        
    }
    
    //MARK: Sound Manager (transferred to PlayerController)
    
    //MARK: Create Playlist
    /**
     Create new empty playlist
     */
    public func createEmptyPlaylist(){
        
        currentEditingPlaylist = MIPlaylist()
        //Default settings
        currentEditingPlaylist.socialNetworks = [API.FACEBOOK]
        
    }
    
    /**
     Get current playlist
     */
    public func editingPlaylist() -> MIPlaylist{
        
        return currentEditingPlaylist
        
    }
    
    /**
     Add track to playlist
     */
    public func addTrackToPlayList(track:MITrack){
        
        var isAdded = false
        
        for currentTrack in currentEditingPlaylist.tracks{
            if currentTrack.trackId == track.trackId{
                
                isAdded = true
                break
                
            }
        }
        
        if isAdded == false{
            
            currentEditingPlaylist.tracks.append(track)

        }
        
    }
    
    /**
     Remove track from playlist
     */
    public func removeTrackFromPlayList(track:MITrack){
        
        for currentTrack in currentEditingPlaylist.tracks{
            if currentTrack.trackId == track.trackId, let currentIndex = currentEditingPlaylist.tracks.index(of: currentTrack){
                
                currentEditingPlaylist.tracks.remove(at: currentIndex)
                break

            }
        }
        
    }
    
    /**
     Check if a track in a playlist
     */
    public func isTrackInPlayList(track:MITrack) -> Bool{
        
        for currentTrack in currentEditingPlaylist.tracks{
            if currentTrack.trackId == track.trackId{
                
                return true
                
            }
        }
        
        return false
        
    }

    //MARK: Likes & Emoji
    /**
     Like playlist
     -parameter isLike: like or dislike
     -parameter playListId: playlist to like
     -parameter completion: completion handler
     */
    public func likePlayList(isLike: Bool, playList:MIPlaylist, completion:@escaping () -> Void){
        
        serverManager.likePlayList(isLike: isLike, playList: playList, completion: completion)
        
    }
    
    //MARK: Remote configuration
    /**
     Try to get remote configuration
     */
    public func remoteConfig() -> RemoteConfig{
        
        return  configManager.remoteConfig
        
    }
    
    //MARK: Api related to user
    /**
     Check if user logged in
     */
    public func isUserLogged() -> Bool{
        
        return serverManager.isUserLogged()
        
    }
    /**
     Getting user info with id
    */
    public func getUserInfoWithUserId(userId: String, completion:@escaping (_ user:MIUser) -> Void){
        serverManager.getUserInfoWithUserId(userId: userId, completion: completion)
    }
    
    /**
     Update user info with id
     */
    public func updateUserInfoWithUserId(userId: String, params:[String:Any], completion:@escaping (_ user:MIUser, _ message:String) -> Void){
        serverManager.updateUserInfoWithUserId(userId: userId, parameters: params, completion: completion)
    }
    
    public func updateUseName(userName: String, completion:@escaping (_ status:Bool, _ message:String) -> Void){
        serverManager.updateUserName(userName: userName, completion: completion)
    }
    
    public func checkUserName(userName: String, completion:@escaping (_ status:Bool, _ message:String) -> Void){
        serverManager.checkUserName(userName: userName, completion: completion)
    }
    
    /**
     Update user info with id
     */
    public func uploadUserAvatar(userId: String, avatar:Data, completion:@escaping (_ user:MIUser) -> Void){
        serverManager.uploadUserAvatar(userId: userId, avatar: avatar, completion: completion)
    }
    
    /**
     Getting user playlists
     */
    
    public func getUserPlayLists(userId:String, offset: Int, type: ProfilePlaylistType, completion:@escaping(_ result:[MIPlaylist]) ->Void){
        
        serverManager.getUserPlayLists(userId: userId, offset: offset, type: type, completion: {
            result in
            
            switch type{
                
                case .user:
                    
                    if offset == 0{
                        
                        PlayerController.player.userPlaylists.removeAll()
                        
                    }
                    
                    PlayerController.player.userPlaylists.append(contentsOf:result)
                
                case .liked:
                    
                    if offset == 0{
                        
                        PlayerController.player.likedPlaylists.removeAll()
                        
                    }
                    
                    PlayerController.player.likedPlaylists.append(contentsOf:result)
                case .listened:
                    
                    if offset == 0{
                        
                        PlayerController.player.listenedPlaylists.removeAll()
                        
                    }
                    
                    PlayerController.player.listenedPlaylists.append(contentsOf:result)
                default:break
            }
            
            
            completion(result)
        })
    }
    
    /**
     Follow and Unfollow user
     */
    
    public func followUnfollowUser(userId:String, isFollow:Bool, completion:@escaping(_ result:Bool, _ message: String, _ followers: Int)->Void){
        serverManager.followUnfollowUser(userId: userId, isFollow: isFollow, completion:completion)
    }
    
    /** Settings
    ** Delete user himself
    **/
    public func deleteUserbySelf(completion:@escaping(_ success: Bool) ->Void) {
        serverManager.deleteUserbyItself { (success) in
            completion(success)
        }
    }
    
    //Detect the app version
    public func getCurrentAppVersion() -> Int {
        guard let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return 0
        }
        
        return Int(version)!
    }
    
    //Create Update Alert After fetch the remote config file.
    public func createUpdateAlertWithConfig() {
        let alertTitle = "Update is available"
        let alertMessage = "Please update the app to get the best experience."
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Update", style: UIAlertActionStyle.default, handler: { (action) in
            
            MIManager.manager.openAppStore()
        }))
        
        UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
    }
    
    //Create the settings alert
    public func showSettingsAlert() {
        
        let alertTitle = "\"Bump\" would like to access Apple Music"
        let alertMessage = "Please go to Settings in your device and allow Bump to access Apple Music"
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: UIAlertActionStyle.default, handler: { (action) in
            
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, completionHandler: { (flag) in
                
                if let url = URL(string: "App-Prefs:root=\(Bundle.main.bundleIdentifier!)") {
                    
                    if #available(iOS 10.0, *) {
                        
                        UIApplication.shared.open(url, completionHandler: nil)
                        
                    } else {
                        
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(url)
                        
                    }
                }
            })
            
        }))
        
        DispatchQueue.main.async {
            
            UIApplication.topViewController()?.present(alert, animated: true, completion: nil)
            
        }
        
    }
}
