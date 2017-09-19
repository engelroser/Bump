//
//  SpotifyPlayer.swift
//  Mixably
//
//  Created by Mobile App Dev on 6/20/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import Kingfisher
import MediaPlayer

class SpotifyPlayerController: NSObject, PlayerProtocol {
    
    var emptyPlaylists = [MIPlaylist]()
    var feedPlaylists = [MIPlaylist]()
    var lastPlayingTrack = MITrack()
    var likedPlaylists = [MIPlaylist]()
    var listenedPlaylists = [MIPlaylist]()
    var loadedPlaylists = [MIPlaylist]()
    var playingTrack = MITrack()
    var playingPlaylist = MIPlaylist()
    var playingPreviewTrack = MITrack()
    lazy var playerQueue : AVQueuePlayer = {
        return AVQueuePlayer()
    }()
    var userPlaylists = [MIPlaylist]()
    var trackTimer = Timer()
    
    private var isRepeat = false
    private var isShuffle = false
    private var player = AVPlayer()
    
    public func handleInterruption(interruptionType: AVAudioSessionInterruptionType){
        
        switch interruptionType {
            case .began:
                PlayerController.savePlayerState()
                /**/
            default :

                PlayerController.restorePlayerState()

            }
    }
    
    func playNextTrack() {
        
        if let curTrackIndex = playingPlaylist.tracks.index(of: playingTrack) {
            
            let nextIndex = curTrackIndex + 1
            
            if isShuffle {
                
                //Shuffle is ON
                var tracksToPlay = [MITrack]()
                
                for track in playingPlaylist.tracks{
                    if playingPlaylist.playedTracks.index(of:track) == nil {
                        
                        tracksToPlay.append(track)
                        
                    }
                }
                
                let randIndex = Int(arc4random_uniform(UInt32(tracksToPlay.count)))
                
                if tracksToPlay.count == randIndex {
                    
                    //Usually this case happens when we have only 1 track in a playlist
                    if let firstTrack = playingPlaylist.tracks.first{
                        
                        playTrack(track: firstTrack, playList: playingPlaylist, start:0)

                    }

                }else{
                    
                    playTrack(track: tracksToPlay[randIndex], playList: playingPlaylist, start:0)

                }
                
            } else if nextIndex < playingPlaylist.tracks.count {
                
                //We have tracks in playlist
                playTrack(track: playingPlaylist.tracks[nextIndex], playList: playingPlaylist, start:0)
                
            } else if isRepeat {
                
                //Repeat is ON
                playTrack(track: playingPlaylist.tracks[0], playList: playingPlaylist, start:0)
                
            } else {
                
                //Player is played all tracks in the current playlist and Repeat is Off
                let nextPlaylistIndex = loadedPlaylists.index(of:playingPlaylist)! + 1
                
                if nextPlaylistIndex <= loadedPlaylists.count - 1 {
                    
                    playingPlaylist = loadedPlaylists[nextPlaylistIndex]
                    playTrack(track: playingPlaylist.tracks[0], playList: playingPlaylist, start:0)
                    
                } else {
                    
                    switch MIManager.manager.playlistType {
                        
                    case .feed:
                        emptyPlaylists = feedPlaylists
                    case .user:
                        emptyPlaylists = userPlaylists
                    case .liked:
                        emptyPlaylists = likedPlaylists
                    case .listened:
                        emptyPlaylists = listenedPlaylists
                        
                        
                    }
                    
                    for playlist in emptyPlaylists {
                        
                        if playlist.id == playingPlaylist.id {
                            
                            let index = emptyPlaylists.index(of: playlist)! + 1
                            
                            if index >= emptyPlaylists.count {
                                
                                switch MIManager.manager.playlistType {
                                    
                                case .feed:
                                    
                                    MIManager.manager.userFeed(offset: emptyPlaylists.count, completion: { _ in
                                        
                                        self.emptyPlaylists = self.feedPlaylists
                                        self.playPlaylist(index:index)
                                        
                                    })
                                    
                                case .user:
                                    
                                    MIManager.manager.getUserPlayLists(userId: "me", offset:self.userPlaylists.count, type: .user, completion: {(result:[MIPlaylist]) in
                                        
                                        self.emptyPlaylists = self.userPlaylists
                                        self.playPlaylist(index:index)
                                        
                                    })
                                    
                                case .liked:
                                    
                                    MIManager.manager.getUserPlayLists(userId: "me", offset:self.likedPlaylists.count, type: .liked, completion: {(result:[MIPlaylist]) in
                                        
                                        self.emptyPlaylists = self.likedPlaylists
                                        self.playPlaylist(index:index)
                                        
                                    })
                                    
                                case .listened:
                                    
                                    MIManager.manager.getUserPlayLists(userId: "me", offset:self.listenedPlaylists.count, type: .listened, completion: {(result:[MIPlaylist]) in
                                        
                                        self.emptyPlaylists = self.listenedPlaylists
                                        self.playPlaylist(index:index)
                                        
                                    })
                                    
                                }
                                
                            } else {
                                
                                self.playPlaylist(index:index)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
    }
   
    func playPlaylist(index: Int) {
        
        let nextPlaylist = emptyPlaylists[index]
        
        MIManager.manager.playListInfo(playList: nextPlaylist, completion: {
            
            result in
            
            if self.loadedPlaylists.index(of: result) == nil {
                
                self.loadedPlaylists.append(result)
                
            }
            
            self.playingPlaylist = result
            self.playTrack(track: self.playingPlaylist.tracks[0], playList: self.playingPlaylist, start:0)
            
        })
        
    }
    
    func playPreviousTrack(){
        
        if let curTrackIndex = playingPlaylist.tracks.index(of: playingTrack) {
            
            var nextIndex = curTrackIndex - 1
            
            if isShuffle {
                nextIndex = Int(arc4random_uniform(UInt32(playingPlaylist.tracks.count)))
            }
            
            if nextIndex >= 0 {
                
                playTrack(track: playingPlaylist.tracks[nextIndex], playList: playingPlaylist, start:0)
                
            } else if isRepeat {
                
                playTrack(track: playingPlaylist.tracks.last!, playList: playingPlaylist, start:0)
                
            } else {
                
                //It was the first track in a playlist. We should start playing the previous playlist
                let prevPlaylistIndex = loadedPlaylists.index(of:playingPlaylist)! - 1
                
                if prevPlaylistIndex >= 0 {
                    
                    playingPlaylist = loadedPlaylists[prevPlaylistIndex]
                    playTrack(track: playingPlaylist.tracks[playingPlaylist.tracks.count - 1], playList: playingPlaylist, start:0)
                    
                }
            }
            
        }
        
    }
    
    func pauseTrack() {
        
        pauseTrack(track:playingTrack)
        
    }
    
    func resumeTrack() {
        
        resumeTrack(track:playingTrack)
        
    }
    
    func togglePlayPause() {
        
        if playingTrack.isPlaying {
            
            pauseTrack(track: playingTrack)
            
        } else {
            
            resumeTrack(track: playingTrack)
            
        }
        
    }
    
    func playPreviewTrack(track: MITrack, playList: MIPlaylist, start:Int) {
        
        //playTrack(track:track, playList:playList, start:start)
        
        if playingPreviewTrack.trackId != "" {
            
            pauseTrack(track: playingPreviewTrack)
            
        }
        
        //Check if current track has preview URL
        if checkIfPreviewAvailable(urlToPlay:track.previewUrl) {
            
            stopAll()
            
            playingPreviewTrack = track
            playingPreviewTrack.isPlaying = true
            
            if let urlToPlay = URL(string:track.previewUrl) {
                
                playPreviewURL(url: urlToPlay, track:track)
                
            }
            
        }
        
    }
    
    func playTrack(track: MITrack, playList: MIPlaylist, start: Int, file: String = #file, line: Int = #line, function: String = #function) {
        
        log.debug("SpotifyPlayerController playTrack \(file):\(line) : \(function)")
        
        //Artwork to show on the locked screen
        if let artWorkURL = URL(string:track.artworkUrl) {
            
            ImageDownloader.default.downloadImage(with: artWorkURL, options: [], progressBlock: nil) {
                (image, error, url, data) in
                
                if image != nil {
                    
                    let artwork = MPMediaItemArtwork.init(boundsSize: (image?.size)!, requestHandler: { (size) -> UIImage in
                        return image!
                    })
                    
                    let nowPlayingInfo = [MPMediaItemPropertyArtist : track.artistNames.first!.name,  MPMediaItemPropertyTitle : track.name, MPMediaItemPropertyArtwork : artwork, MPNowPlayingInfoPropertyPlaybackRate:"1",MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
                                          MPMediaItemPropertyPlaybackDuration: track.durationMS/1000] as [String : Any]
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    
                }
                
            }
            
        } else {
            
            var nowPlayingInfo = [String:Any]()
            
            if let artistName = track.artistNames.first {
                
                nowPlayingInfo = [MPMediaItemPropertyArtist : artistName,  MPMediaItemPropertyTitle : track.name, MPNowPlayingInfoPropertyPlaybackRate:"1",MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
                                  MPMediaItemPropertyPlaybackDuration: track.durationMS/1000] as [String : Any]
                
            } else {
                
                nowPlayingInfo = [MPMediaItemPropertyArtist : "",  MPMediaItemPropertyTitle : track.name, MPNowPlayingInfoPropertyPlaybackRate:"1",MPNowPlayingInfoPropertyElapsedPlaybackTime: 0,
                                  MPMediaItemPropertyPlaybackDuration: track.durationMS/1000] as [String : Any]
                
            }
            
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            
        }
        
        playingTrack.isPlaying = false
        playingTrack.spentTime = 0
        
        playSpotifyTrack(track:track, start:Double(start))
        playingTrack = track
        
        //Add track to played tracks. We need it to make Shuffle mode
        if playList.playedTracks.count == playList.tracks.count - 1 {
            
            playList.playedTracks.removeAll()
            
        }
        
        playList.playedTracks.append(track)
        
        trackTimer.invalidate()
        trackTimer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(self.updateTrackTimer),
                                          userInfo: nil,
                                          repeats: true)
        
        playingTrack.isPlaying = true
        
        self.playingPlaylist = playList
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_STARTED), object: nil, userInfo: ["track": playingTrack, "playlist": playingPlaylist])
        
    }
    
    func pauseTrack(track: MITrack) {
        
        //Check if preview is playingTrack
        if playingPreviewTrack.trackId != "" {
            
            playingPreviewTrack.isPlaying = false
            
            if self.playerQueue.rate > 0.0 {
                
                self.playerQueue.pause()
                
            }
            
            playingPreviewTrack = MITrack()
            
            return
            
        }
        
        trackTimer.invalidate()
        pauseSpotifyTrack(track:track)
        
        playingTrack.isPlaying = false

        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_PAUSED), object: nil, userInfo: ["track": playingTrack, "playlist": playingPlaylist])
        
    }
    
    func resumeTrack(track: MITrack, file: String = #file, line: Int = #line, function: String = #function) {
        
        log.debug("SpotifyPlayerController resumeTrack \(file):\(line) : \(function)")
        
        playingTrack.isPlaying = false
        
        if track.trackId != playingTrack.trackId {
            
            playSpotifyTrack(track:track, start:Double(track.spentTime))
            playingTrack = track
            
        } else {
            
            resumeSpotifyTrack(track:track)
            playingTrack = track
            
        }
        
        playingTrack.isPlaying = true
        
        trackTimer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(self.updateTrackTimer),
                                          userInfo: nil,
                                          repeats: true)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_STARTED), object: nil, userInfo: ["track": playingTrack, "playlist": playingPlaylist])
        
        
    }
    
    func playSpotifyTrack(track: MITrack, start: Double, file: String = #file, line: Int = #line, function: String = #function) {
        
        log.debug("SpotifyPlayerController playSpotifyTrack \(file):\(line) : \(function)")
        
        track.spentTime = Int(start)
        
        lastPlayingTrack = track
        
        var urlToPlay = track.trackId
        
        if MIManager.manager.userMssps().id == .spotify{
            
            if MIManager.manager.userMssps().isPremiumRequired{
                
                urlToPlay = track.previewUrl
                
                //Check if current track has preview URL
                if checkIfPreviewAvailable(urlToPlay:urlToPlay) {
                    
                    playPreviewURL(url: URL(string:urlToPlay)!, track:track)
                    
                }else{
                    
                    Timer.scheduledTimer(timeInterval: 1,
                                         target: self,
                                         selector: #selector(self.playNextTrack),
                                         userInfo: nil,
                                         repeats: false)
                    
                }
                
            } else {
                
                SPTAudioStreamingController.sharedInstance().playSpotifyURI(urlToPlay, startingWith: 0, startingWithPosition: start, callback:{ error in
                    
                    log.debug (error ?? "")
                    
                    if track.trackId != self.lastPlayingTrack.trackId || abs(Int(self.lastPlayingTrack.spentTime) - Int(start)) > 3 {
                        
                        self.playSpotifyTrack(track:self.lastPlayingTrack, start: Double(self.lastPlayingTrack.spentTime))
                        
                    }
                    
                })
                
            }
            
        }else if MIManager.manager.userMssps().id == .none{
            
            //Now spotify player is used to preview tracks in .none mode
            //We should add Preview Player Controller later for this case
            urlToPlay = track.previewUrl
            
            //Check if current track has preview URL
            if checkIfPreviewAvailable(urlToPlay:urlToPlay) {
                
                playPreviewURL(url: URL(string:urlToPlay)!, track:track)
                
            }else{
                
                Timer.scheduledTimer(timeInterval: 1,
                                     target: self,
                                     selector: #selector(self.playNextTrack),
                                     userInfo: nil,
                                     repeats: false)
                
            }
            
        }
        
    }
    
    func pauseSpotifyTrack(track: MITrack) {
        
        if MIManager.manager.userMssps().id == .spotify {
            
            if MIManager.manager.userMssps().isPremiumRequired{
                
                if self.playerQueue.rate > 0.0 {
                    
                    self.playerQueue.pause()
                    
                }

            }else{
                
                if SPTAudioStreamingController.sharedInstance().loggedIn {
                    SPTAudioStreamingController.sharedInstance().setIsPlaying (false, callback: nil)
                }
                
            }
            
        } else {
            
            if self.playerQueue.rate > 0.0 {
                
                self.playerQueue.pause()
                
            }
            
        }
        
    }
    
    func playPreviewURL(url: URL, track:MITrack) {
        
        DispatchQueue.global().async {

            let playerItem = AVPlayerItem.init(url: url)
            
            if self.playerQueue.rate > 0.0 {
                self.playerQueue.pause()
            }
            
            let asset = AVURLAsset(url: url, options: nil)
            let audioDuration = asset.duration
            track.previewDurationMS = Int(CMTimeGetSeconds(audioDuration))
            
            if self.playerQueue.items().count > 0 {
                
                self.playerQueue.removeAllItems()
                
            }
            
            self.playerQueue.insert(playerItem, after: nil)
            self.playerQueue.play()
            
            DispatchQueue.main.sync {
                
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.PREVIEW_TRACK_LOADED), object:nil, userInfo:["track":track] )
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(self.previewDidFinish(_:)),
                                                       name: .AVPlayerItemDidPlayToEndTime,
                                                       object: playerItem)
                
            }

        }
        
    }

    private func checkIfPreviewAvailable(urlToPlay: String) -> Bool {
        
        guard urlToPlay != "" else {
            
            MIUIUtilities.showErrorAlert(title: NSLocalizedString("preview_is_not_available", comment: "preview_is_not_available"), message: NSLocalizedString("some_tracks_have_no_preview", comment: "some_tracks_have_no_preview"), button: "Ok")
            
            return false
            
        }
        
        return true
        
    }
    
    func resumePreview() {
        
        self.playerQueue.play()
        
    }
    
    func previewDidFinish(_ notification: NSNotification) {
        
        //stopAll()
        //Handle two cases:
        // * user has Preview Mode
        // * user creates new playlist
        if playingPreviewTrack.trackId == "" {
            
            playNextTrack()
            
        } else {
            
            pauseTrack(track: playingPreviewTrack)
            
        }
        
    }
    
    func stopAll() {
        
        playingTrack.spentTime = 0
        
        pauseTrack(track:playingTrack)
        
        let nowPlayingInfo = [String : Any]()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        if MIManager.manager.userMssps().id == .spotify {
            
            if SPTAudioStreamingController.sharedInstance().loggedIn {
                
                SPTAudioStreamingController.sharedInstance().setIsPlaying (false, callback: nil)
                
            }
            
        }
        
        if self.playerQueue.rate > 0.0 {
            
            self.playerQueue.pause()
            self.playerQueue.removeAllItems()
            
        }
        
        playingPlaylist = MIPlaylist()
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_PAUSED), object: nil, userInfo: nil)
        
    }

    func stopPreviewTrack() {
        
        if playingPlaylist.id == 0 {
            
            pauseTrack(track: playingPreviewTrack)
            stopAll()
            
        }
        
    }
    
    func repeatPlaylist(isRepeat: Bool) {
        
        self.isRepeat = isRepeat
        
    }
    
    func shufflePlaylist(isShuffle: Bool) {
        
        self.isShuffle = isShuffle
        
    }
    
    func resumeSpotifyTrack(track: MITrack, file: String = #file, line: Int = #line, function: String = #function) {
        
        log.debug("SpotifyPlayerController resumeSpotifyTrack \(file):\(line) : \(function)")
        
        if MIManager.manager.userMssps().id == .spotify {
            
            if MIManager.manager.userMssps().isPremiumRequired == false{
                
                if track.spentTime == 0 {
                    
                    playSpotifyTrack(track:track, start: 0)
                    
                } else {
                    
                    SPTAudioStreamingController.sharedInstance().setIsPlaying (true, callback: nil)
                    
                }
                
            }else{
                
                resumePreview()

            }
            
        } else if MIManager.manager.userMssps().id == .none {

            resumePreview()

        }
        
    }
    
    public func updateTrackTimer() {
        
        var progressTime = playingTrack.spentTime + 1
        
        if playingTrack.durationMS/1000 == playingTrack.spentTime {
            
            trackTimer.invalidate()
            progressTime = 0
            
        }
        
        playingTrack.spentTime = progressTime
        
        if progressTime == 0 {
            
            playNextTrack()
            
        } else {
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_UPDATED), object: nil, userInfo: ["track": playingTrack])
            
        }
        
    }
}
