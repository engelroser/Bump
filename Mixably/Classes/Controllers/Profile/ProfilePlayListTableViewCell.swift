//
//  MIProfilePlayListTableViewCell.swift
//  Mixably
//
//  Created by Mobile App Dev on 06/04/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import MGSwipeTableCell
import GradientView

class MIProfilePlayListTableViewCell: MGSwipeTableCell {
    
    @IBOutlet weak var contentBackView: UIView!
    @IBOutlet weak var trackName: UILabel!
    
    @IBOutlet weak var imgThumb: UIImageView!
    @IBOutlet weak var imgPlayButton: UIImageView!
    
    //Info
    private var infoView = PlaylistInfoView()
    
    //Touches
    private var showPlaylistTouchView = UIView()
    private var playTouchView = UIView()

    //Progress
    private let progressGradientView = GradientView()
    private var progressView = UIView()

    //Artist & track name
    internal var trackNameLabel = UILabel()
    internal var artistNameLabel = UILabel()
    
    //Data
    internal var track = MITrack()
    internal var playList = MIPlaylist()
    internal var type: ProfilePlaylistType = .user
    internal var userId: String!
    
    internal var isPlaying = false
    
    internal var timer = Timer()
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        createProgressView()

        createArtistLabel()
        createTrackLabel()
        
        backgroundColor = UIColor.clear
        selectionStyle = .none
        
        imgThumb.layer.cornerRadius = 4
        imgThumb.alpha = 0.45
        imgThumb.clipsToBounds = true
        
        let showPlaylistGesture = UITapGestureRecognizer(target: self, action: #selector(self.showPlaylist))
        showPlaylistGesture.cancelsTouchesInView = true
        showPlaylistTouchView.addGestureRecognizer(showPlaylistGesture)
        
        addSubview(showPlaylistTouchView)
        
        let playPlaylistGesture = UITapGestureRecognizer(target: self, action: #selector(self.playPlaylist))
        playPlaylistGesture.cancelsTouchesInView = true
        playTouchView.addGestureRecognizer(playPlaylistGesture)

        addSubview(playTouchView)
        
        timer = Timer.scheduledTimer(timeInterval: 0.05,
                                     target: self,
                                     selector: #selector(self.updateTrackProgress),
                                     userInfo: nil,
                                     repeats: true)
        
    }
    
    private func createInfoView(){
        
        if (infoView.superview != nil){
            
            infoView.reloadData(playList:playList)
            
        }else{
            
            infoView = MIUIUtilities.createPlaylistInfoView(playList:playList, color: UIColor.white, target:self, shareAction:#selector(saveTrack), contentSize:CGSize(width:bounds.size.width, height:0))
            infoView.frame = CGRect(x:Origin.USER_PROFILE_PLAYLIST_STATS_LEFT, y:Origin.USER_PROFILE_PLAYLIST_STATS_TOP, width:bounds.size.width, height:infoView.bounds.size.height/2)
            infoView.clipsToBounds = true
            addSubview(infoView)
            
            bringSubview(toFront: showPlaylistTouchView)
            bringSubview(toFront: playTouchView)
            
        }

    }
    
    private func createProgressView(){
        
        progressView.clipsToBounds = true
        progressView.backgroundColor = Color.PLAYLIST_PROGRESS
        addSubview(progressView)
        
        sendSubview(toBack:progressView)
        
        progressGradientView.colors = [Color.PLAYLIST_REWIND_RIGHT, Color.PLAYLIST_REWIND_LEFT]
        progressGradientView.locations = [0.0, 1.0]
        progressGradientView.direction = .horizontal
        progressView.addSubview(progressGradientView)
    }
    
    private func createArtistLabel(){
        
        artistNameLabel.isHidden = true
        artistNameLabel.font = Font.PLAYLIST_CELL_ARTIST
        artistNameLabel.textColor = Color.PLAYLIST_ROW_ARTIST_NORMAL
        addSubview(artistNameLabel)
        
    }
    
    private func createTrackLabel(){
        
        trackNameLabel.isHidden = true
        trackNameLabel.font = Font.PLAYLIST_CELL_TRACK
        trackNameLabel.textColor = Color.PLAYLIST_ROW_ARTIST_NORMAL
        addSubview(trackNameLabel)
        
    }
    
    public func updateCell(playList:MIPlaylist, type:ProfilePlaylistType, userId: String){
        
        self.playList = playList
        self.type = type
        self.userId = userId
        
        //Update title
        trackName.text = playList.title
        
        //Update stats view (likes, plays)
        createInfoView()
        
        //Update artwork
        if let artworkPath = URL(string:playList.artwork){
            
            imgThumb.kf.setImage(with: artworkPath)
            
        }
        
    }
    
    //MARK: Update UI
    override func layoutSubviews() {
        
        super.layoutSubviews()
        
        showPlaylistTouchView.frame = bounds
        playTouchView.frame = imgThumb.frame
        
        progressGradientView.frame = bounds
        
        artistNameLabel.frame = CGRect(x:Origin.USER_PROFILE_PLAYLIST_LABELS_LEFT, y:Origin.USER_PROFILE_PLAYLIST_LABELS_TOP, width:bounds.size.width - Origin.USER_PROFILE_PLAYLIST_LABELS_LEFT, height:Size.PLAYLIST_ARTIST_NAME_HEIGHT)
        trackNameLabel.frame = CGRect(x:Origin.USER_PROFILE_PLAYLIST_LABELS_LEFT, y:Origin.USER_PROFILE_PLAYLIST_TRACK_NAME_TOP, width:bounds.size.width - Origin.USER_PROFILE_PLAYLIST_LABELS_LEFT, height:Size.PLAYLIST_TRACK_NAME_HEIGHT)
        
    }
    
    //MARK: Actions
    public func saveTrack(){
        
    }
    
    //MARK: Touches
    public func showPlaylist(sender: UITapGestureRecognizer){
        
        var playListFrame = UIScreen.main.bounds
        playListFrame.origin.y = playListFrame.size.height
        print(self.userId)
        if let _ = self.userId, self.userId == "me" {
            UserDefaults.standard.set(false, forKey: "fromProfile")
            
            if let topController = UIApplication.topViewController(){
                
                let detailedPlayListView = MIPlayListContentView(frame:playListFrame, playList:playList)
                topController.view.addSubview(detailedPlayListView)
                
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [UIViewAnimationOptions.curveEaseOut], animations: {
                    
                    detailedPlayListView.frame = UIScreen.main.bounds
                    
                }, completion: { finished in
                    
                    
                })
                
            }
            
        } else {
            UserDefaults.standard.set(true, forKey: "fromProfile")
            
            if let topController = viewController {
                
                let detailedPlayListView = MIPlayListContentView(frame:playListFrame, playList:playList)
                topController.parent?.view.addSubview(detailedPlayListView)
                detailedPlayListView.animationFinished()
                
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [UIViewAnimationOptions.curveEaseOut], animations: {
                    
                    detailedPlayListView.frame = UIScreen.main.bounds
                    
                }, completion: { finished in
                    
                    
                })
                
            }
            
        }
        
    }
    
    public func playPlaylist(sender: UITapGestureRecognizer){
        
        //Send play event
        MIManager.manager.playListPlay(playList: playList,completion:{
            
        })
        
        if PlayerController.isThisPlaylistPlaying(playList: playList) {
        
            if PlayerController.isPlayerPlaying(){
                
                PlayerController.pauseTrack()

            }else{
                
                MIManager.manager.playlistType = self.type
                PlayerController.resumeTrack()

            }
            
        }else{
            
            if let firstTrack = playList.tracks.first{
                
                MIManager.manager.playlistType = self.type
                PlayerController.playTrack(track: firstTrack, playList: playList, start: 0)
                
            }else{
                
                MIManager.manager.playListInfo(playList:playList, completion:{ result in
                    
                    if let firstTrack = self.playList.tracks.first{
                        
                        MIManager.manager.playlistType = self.type
                        PlayerController.playTrack(track: firstTrack, playList: self.playList, start: 0)
                        
                    }
                    
                })
                
            }
            
        }
    }
    
    //MARK: Timers
    public func updateTrackProgress(){
        
        if PlayerController.isThisPlaylistPlaying(playList: playList) {

            if PlayerController.isPlayerPlaying(){
                
                imgPlayButton.image = UIImage(named:"PauseButton")
                
                showPlayingViews(isPlaying:true)
                
            }else{
                
                imgPlayButton.image = UIImage(named:"PlayButton")
                
                showPlayingViews(isPlaying:false)
                
            }
            
            updateProgressView()

        }else{
            
            showPlayButton()

        }
        
    }
    
    //MARK: Internal
    private func showPlayButton(){
        
        imgPlayButton.image = UIImage(named:"PlayButton")
        progressView.frame = CGRect(x:0, y:0, width:0, height:bounds.size.height)
        
        showPlayingViews(isPlaying:false)
        
    }
    
    private func showPlayingViews(isPlaying:Bool){
        
        artistNameLabel.isHidden = !isPlaying
        trackNameLabel.isHidden = !isPlaying
        
        trackName.isHidden = isPlaying
        infoView.isHidden = isPlaying
        
    }
    
    private func updateProgressView(){
        
        let track = PlayerController.playingTrack()
        
        if let artist = track.artistNames.first{
            
            artistNameLabel.text = artist.name

        }
        
        trackNameLabel.text = track.name

        if track.spentTime > 0{
            
            let rowWidth = UIScreen.main.bounds.size.width
            
            let currentProgress = Int(rowWidth)*track.spentTime/(track.durationMS/1000)
            progressView.frame = CGRect(x:0, y:0, width:CGFloat(currentProgress), height:bounds.size.height)
            
        }else{
            
            progressView.frame = CGRect(x:0, y:0, width:0, height:bounds.size.height)
            
        }
        
    }
    
}
