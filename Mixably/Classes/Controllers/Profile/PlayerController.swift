//
//  PlayerController.swift
//  Mixably
//
//  Created by Mobile App Dev on 6/20/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import MediaPlayer

protocol PlayerProtocol {
    
    var emptyPlaylists: [MIPlaylist] { get set }
    
    var feedPlaylists: [MIPlaylist] { get set }
    
    var lastPlayingTrack: MITrack { get set }
    
    var likedPlaylists: [MIPlaylist] { get set }
    
    var listenedPlaylists: [MIPlaylist] { get set }
    
    var loadedPlaylists: [MIPlaylist] { get set }
    
    var playingTrack: MITrack { get set }
    
    var playingPlaylist: MIPlaylist { get set }
    
    var playingPreviewTrack: MITrack { get set }
    
    var playerQueue: AVQueuePlayer { get set }
    
    var userPlaylists: [MIPlaylist] { get set }
    
    var trackTimer: Timer { get set }
    
    func playTrack(track: MITrack, playList: MIPlaylist, start: Int, file: String, line: Int, function: String)
    
    func playPreviewTrack(track: MITrack, playList: MIPlaylist, start: Int)
    
    func pauseTrack(track: MITrack)
    
    func resumeTrack(track: MITrack, file: String, line: Int, function: String)
    
    func stopAll()
    
    func stopPreviewTrack()
    
    func repeatPlaylist(isRepeat: Bool)
    
    func shufflePlaylist(isShuffle: Bool)
    
    func playNextTrack()
    
    func playPreviousTrack()
    
    func pauseTrack()
    
    func resumeTrack()

    func togglePlayPause()
    
    func handleInterruption(interruptionType: AVAudioSessionInterruptionType) // Called when Bump player is interrupted by another music source
    
}

class PlayerController {
    
    static var player: PlayerProtocol = SpotifyPlayerController()
    static var isRestorePlaying = false

    // What used to be in MISoundManager has been moved to SpotifyPlayerController and all of the properties of SpotifyPlayerController, as well as the majority of method definitions, have been copied into AppleMusicPlayerController.
    // This was done to have Spotify and Apple Music co-exist, and to avoid breaking existing functionality and UI within the app.
    // Note, common functionality within SpotifyPlayerController and AppleMusicPlayerController should be refactored into a centralised location and only music provider specific logic should remain in these classes.
    class func set(_ musicProvider: MusicProvider) {
        
        subscribeToNotifications()
        
        switch musicProvider {
        case .none, .spotify:
            let spotifyPlayerController = SpotifyPlayerController()
            spotifyPlayerController.emptyPlaylists = PlayerController.player.emptyPlaylists
            spotifyPlayerController.feedPlaylists = PlayerController.player.feedPlaylists
            spotifyPlayerController.lastPlayingTrack = PlayerController.player.lastPlayingTrack
            spotifyPlayerController.likedPlaylists = PlayerController.player.likedPlaylists
            spotifyPlayerController.listenedPlaylists = PlayerController.player.listenedPlaylists
            spotifyPlayerController.loadedPlaylists = PlayerController.player.loadedPlaylists
            spotifyPlayerController.playingTrack = PlayerController.player.playingTrack
            spotifyPlayerController.playingPlaylist = PlayerController.player.playingPlaylist
            spotifyPlayerController.playingPreviewTrack = PlayerController.player.playingPreviewTrack
            spotifyPlayerController.playerQueue = PlayerController.player.playerQueue
            spotifyPlayerController.userPlaylists = PlayerController.player.userPlaylists
            spotifyPlayerController.trackTimer = PlayerController.player.trackTimer
            PlayerController.player = spotifyPlayerController
            break
        case .appleMusic:
            let appleMusicPlayerController = AppleMusicPlayerController()
            appleMusicPlayerController.emptyPlaylists = PlayerController.player.emptyPlaylists
            appleMusicPlayerController.feedPlaylists = PlayerController.player.feedPlaylists
            appleMusicPlayerController.lastPlayingTrack = PlayerController.player.lastPlayingTrack
            appleMusicPlayerController.likedPlaylists = PlayerController.player.likedPlaylists
            appleMusicPlayerController.listenedPlaylists = PlayerController.player.listenedPlaylists
            appleMusicPlayerController.loadedPlaylists = PlayerController.player.loadedPlaylists
            appleMusicPlayerController.playingTrack = PlayerController.player.playingTrack
            appleMusicPlayerController.playingPlaylist = PlayerController.player.playingPlaylist
            appleMusicPlayerController.playingPreviewTrack = PlayerController.player.playingPreviewTrack
            appleMusicPlayerController.playerQueue = PlayerController.player.playerQueue
            appleMusicPlayerController.userPlaylists = PlayerController.player.userPlaylists
            appleMusicPlayerController.trackTimer = PlayerController.player.trackTimer
            PlayerController.player = appleMusicPlayerController
            break
        }
    }
    
    //MARK: Notifications
    class func subscribeToNotifications(){
        
        //Subscribe to player interruption notifications. Apple Music handles all interruptions so we should handle them in the Spotify player only
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(handleMusicInterruption(_:)), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())

    }
    
    @objc class func handleMusicInterruption(_ notification: NSNotification) {

        guard let value = (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue,
            let interruptionType =  AVAudioSessionInterruptionType(rawValue: value)
            else {
                log.debug("Received music interruption notification: \(notification.userInfo?[AVAudioSessionInterruptionTypeKey] ?? "")")
                return }
        
        player.handleInterruption(interruptionType: interruptionType)
        
    }
    
    class func savePlayerState(){
        
        isRestorePlaying = player.playingTrack.isPlaying
        
        if isRestorePlaying{
            
            player.pauseTrack()
            
        }
    }
    
    class func restorePlayerState(){
        
        if isRestorePlaying{
            
            player.resumeTrack()
            isRestorePlaying = player.playingTrack.isPlaying

        }
        
    }

    //MARK: Playback
    class func isThisPlaylistPlaying(playList: MIPlaylist) -> Bool {
        return playList.id == player.playingPlaylist.id
    }
    
    class func isPlayerPlaying() -> Bool {
        return player.playingTrack.isPlaying
    }
    
    class func playTrack(track: MITrack, playList: MIPlaylist, start: Int, file: String = #file, line: Int = #line, function: String = #function) {
        log.debug("PlayerController playTrack \(file):\(line) : \(function)")
        player.playTrack(track: track, playList: playList, start: start, file: file, line: line, function: function)
    }
    
    class func playPreviewTrack(track: MITrack, playList: MIPlaylist, start: Int) {
        
        player.playPreviewTrack(track: track, playList: playList, start: start)
        
    }
    
    class func pauseTrack(track: MITrack) {
        player.pauseTrack(track: track)
    }
    
    class func pausePreviewTrack(track: MITrack) {
        player.pauseTrack(track: track)
    }
    
    class func resumeTrack(track: MITrack, file: String = #file, line: Int = #line, function: String = #function) {
        log.debug("PlayerController resumeTrack \(file):\(line) : \(function)")
        player.resumeTrack(track: track, file: file, line: line, function: function)
    }
    
    class func stopAll() {
        player.stopAll()
    }
    
    class func stopPreviewTrack() {
        player.stopPreviewTrack()
    }
    
    class func repeatPlaylist(isRepeat: Bool){
        player.repeatPlaylist(isRepeat:isRepeat)
    }
    
    class func shufflePlaylist(isShuffle: Bool) {
        player.shufflePlaylist(isShuffle:isShuffle)
    }
    
    class func playingTrack() -> MITrack{
        return player.playingTrack
    }
    
    
    // MARK: - Remote Command Center:
    
    class func playNextTrack() {
        player.playNextTrack()
    }
    
    class func playPreviousTrack() {
        player.playPreviousTrack()
    }
    
    class func pauseTrack() {
        player.pauseTrack()
    }
    
    class func resumeTrack() {
        player.resumeTrack()
    }
    
    class func togglePlayPause() {
        player.togglePlayPause()
    }
}
