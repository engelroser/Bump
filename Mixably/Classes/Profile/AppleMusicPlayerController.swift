//
//  AppleMusicPlayer.swift
//  Mixably
//
//  Created by Mobile App Dev on 6/20/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import Kingfisher
import MediaPlayer

class AppleMusicPlayerController: NSObject, PlayerProtocol {
    
    var emptyPlaylists = [MIPlaylist]()
    var feedPlaylists = [MIPlaylist]()
    var lastPlayingTrack = MITrack()
    var likedPlaylists = [MIPlaylist]()
    var listenedPlaylists = [MIPlaylist]()
    var loadedPlaylists = [MIPlaylist]()
    var userPlaylists = [MIPlaylist]()
    
    var playingTrack = MITrack()
    var playingPlaylist = MIPlaylist()
    var playingPreviewTrack = MITrack()
    lazy var playerQueue: AVQueuePlayer = {
        return AVQueuePlayer()
    }()
    var trackTimer = Timer()
    
    private var isRepeat = false
    private var isShuffle = false
    
    let systemMusicPlayer = MPMusicPlayerController.systemMusicPlayer()
    
    public func handleInterruption(interruptionType: AVAudioSessionInterruptionType){
        
        //We don't need to make here anything because MPMusicPlayerController handles interruptions
    }
    
    func playTrack(track: MITrack, playList: MIPlaylist, start: Int, file: String = #file, line: Int = #line, function: String = #function) {
        
        log.debug("AppleMusicPlayerController playTrack \(file):\(line) : \(function)")
        
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
        
        playAppleMusicTrack(track: track, start: Double(start))
        playingTrack = track
        
        // Add track to played tracks. We need it to make Shuffle mode
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
    
    func playAppleMusicTrack(track: MITrack, start: Double) {
        
        print("playAppleMusicTrack ID", track.trackId)
        
        track.spentTime = Int(start)
        
        lastPlayingTrack = track
        
        var urlToPlay = track.trackId
        
        let userProvider = MIManager.manager.userMssps()
        
        if userProvider.id == .appleMusic && userProvider.isPremiumRequired {
            
            urlToPlay = track.previewUrl
            
            //Check if current track has preview URL
            if checkIfPreviewAvailable(urlToPlay:urlToPlay) {
                
                playPreviewURL(url: URL(string:urlToPlay)!, track:track)
                
            }
            
        } else {
            
            if track.trackId != playingTrack.trackId {
                systemMusicPlayer.setQueueWithStoreIDs([track.trackId])
            }
            
            systemMusicPlayer.currentPlaybackTime = start
            systemMusicPlayer.play()
            
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
    
    func pauseTrack(track: MITrack) {
        
        if playingPreviewTrack.trackId != "" {
            
            playingPreviewTrack.isPlaying = false
            
            if self.playerQueue.rate > 0.0 {
                
                self.playerQueue.pause()
                
            }
            
            playingPreviewTrack = MITrack()
            
            return
            
        }
        
        trackTimer.invalidate()
        pauseAppleMusicTrack(track: track)
        
        playingTrack.isPlaying = false
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_PAUSED), object: nil, userInfo: ["track": playingTrack, "playlist": playingPlaylist])
    }
    
    func pauseTrack() {
        pauseTrack(track: playingTrack)
    }
    
    func pauseAppleMusicTrack(track: MITrack) {
        print("pauseAppleMusicTrack", track.name)
        
        if MIManager.manager.userMssps().id == .appleMusic && MIManager.manager.userMssps().isPremiumRequired == false {
            
            systemMusicPlayer.pause()
            
        } else {
            
            if self.playerQueue.rate > 0.0{
                
                self.playerQueue.pause()
                
            }
            
        }
        
    }
    
    func resumeTrack(track: MITrack, file: String = #file, line: Int = #line, function: String = #function) {
        
        log.debug("AppleMusicPlayerController resumeTrack \(file):\(line) : \(function)")
        
        playingTrack.isPlaying = false
        
        if track.trackId != playingTrack.trackId {
            
            playAppleMusicTrack(track: track, start: Double(track.spentTime))
            playingTrack = track
            
        } else {
            
            resumeAppleMusicTrack(track: track)
            playingTrack = track
            
        }
        
        playingTrack.isPlaying = true
        
        trackTimer.invalidate()
        trackTimer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(self.updateTrackTimer),
                                          userInfo: nil,
                                          repeats: true)
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_STARTED), object: nil, userInfo: ["track": playingTrack, "playlist": playingPlaylist])
    }
    
    func resumeTrack() {
        resumeTrack(track: playingTrack)
    }
    
    func resumeAppleMusicTrack(track: MITrack) {
        
        let userProvider = MIManager.manager.userMssps()
        
        if userProvider.id == .appleMusic {
            
            if userProvider.isPremiumRequired == false{
                
                systemMusicPlayer.play()

            }else{
                
                resumePreview()

            }
            
        }
        
    }
    
    func togglePlayPause(){
        
        if playingTrack.isPlaying {
            
            pauseTrack(track: playingTrack)
            
        } else {
            
            resumeTrack(track: playingTrack)
            
        }
        
    }
    
    func stopAll() {
        playingTrack.spentTime = 0
        pauseTrack(track:playingTrack)
        
        let nowPlayingInfo = [String : Any]()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        if self.playerQueue.rate > 0.0 {
            self.playerQueue.pause()
        }
        
        playingPlaylist = MIPlaylist()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_PAUSED), object: nil, userInfo: nil)
    }
    
    func stopPreviewTrack() {

        stopAll()
        
    }
    
    func repeatPlaylist(isRepeat: Bool) {
        self.isRepeat = isRepeat
    }
    
    func shufflePlaylist(isShuffle: Bool) {
        self.isShuffle = isShuffle
    }
    
    func playNextTrack() {
        if let curTrackIndex = playingPlaylist.tracks.index(of: playingTrack) {
            
            let nextIndex = curTrackIndex + 1
            
            if isShuffle {
                
                //Shuffle is ON
                var tracksToPlay = [MITrack]()
                
                for track in playingPlaylist.tracks {
                    if playingPlaylist.playedTracks.index(of:track) == nil {
                        
                        tracksToPlay.append(track)
                        
                    }
                }
                
                let randIndex = Int(arc4random_uniform(UInt32(tracksToPlay.count)))
                playTrack(track: tracksToPlay[randIndex], playList: playingPlaylist, start:0)
                
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
    
    func playPreviousTrack() {
        
        if let curTrackIndex = playingPlaylist.tracks.index(of: playingTrack){
            
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
    
    // Non protocol.
    
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
            
            //Check player's state.
            //Uncomment code below to add skiping tracks which are not playable for some reason
            //if MIManager.manager.userMssps().isPremiumRequired == false && progressTime > 3{
            //
            //    if systemMusicPlayer.playbackState != .playing && playingTrack.isPlaying{
            //        playNextTrack()
            //    }
            //
            //}
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.TRACK_UPDATED), object: nil, userInfo: ["track": playingTrack])
            
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
    
    private func checkIfPreviewAvailable(urlToPlay: String) -> Bool {
        
        guard urlToPlay != "" else {
            
            let alertController = UIAlertController(title: "Preview is not available", message: "Some tracks has no preview.", preferredStyle: UIAlertControllerStyle.alert)
            
            let DestructiveAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.destructive, handler: nil)
            
            alertController.addAction(DestructiveAction)
            
            if let curViewController = UIApplication.topViewController() {
                
                curViewController.present(alertController, animated: true, completion: nil)
                
            }
            
            return false
            
        }
        
        return true
        
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
    
    func resumePreview() {
        
        if self.playerQueue.items().count > 0{
            
            self.playerQueue.play()

        }
        
    }
    
}
