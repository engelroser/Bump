//
//  MIHomeViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 31/01/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import GradientView
import StoreKit

class MIHomeViewController: BaseViewController, MIViewControllerDelegate {

    //UI
    public let contentView = UIView()
    private var preloaderView = MIFeedPreloaderView()
    
    private let topBarView = UIView()
    private var bottomBarView = UIView()

    public var homeContentView = MIHomeContentView()
    
    private let EQButton = MIUIUtilities.createTopBarRightButton(image: Image.TOP_BAR_EQ)
    private let notificationsButton = UIButton()
    
    public var likeButton = UIButton()

    // Require session active flag
    public var isRequireSessionActive = false // This falg set as true When app init
    
    //Data
    private var isOpeningDetailedPlaylist = false
    private var isOpenedDetailedPlaylist = false

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(trackStarted(_:)), name: NSNotification.Name(rawValue: Notifications.TRACK_STARTED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackPaused(_:)), name: NSNotification.Name(rawValue: Notifications.TRACK_PAUSED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(trackPaused(_:)), name: NSNotification.Name(rawValue: Notifications.STOP_ALL), object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(playlistSwiped(_:)), name: NSNotification.Name(rawValue: Notifications.PLAYLIST_CAROUSEL_SWIPPED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(playlistChanged(_:)), name: NSNotification.Name(rawValue: Notifications.PLAYLIST_CHANGED), object: nil)


        // Notification
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showUserProfile),
                                               name: NSNotification.Name(rawValue: Notifications.USER_AVATAR_CLICKED),
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: Notifications.PLAYLIST_POSTED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_DISCONNECTED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_CONNECTED), object: nil)

        setupUI()
        
        DispatchQueue.main.async {
            //Show tutorial alert if needed
            self.showFeedTutorialAlertIfNeeded()
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)
        
        // Analytics:
        MIAnalyticsManager.logScreen(AnalyticsScreens.HOME_MAIN)
        
    }
    
    public func setupUI(){
        
        //createGradientBackground()
        
        // Add preloader:
        preloaderView = MIFeedPreloaderView(frame:view.bounds)
        view.addSubview(preloaderView)
        
        // Add bars:
        createTopBar()
        createBottomBar()
        
        loadFeed()
        
    }
    
    public func reloadData(){
        
        preloaderView.isHidden = false
        EQButton.isHidden = true

        loadFeed()
    }
    
    //MARK: Tutorial
    private func showFeedTutorialAlertIfNeeded(){
        
        MIUIUtilities.showTutorialAlertIfNeeded(title: NSLocalizedString("welcome_to_bump", comment: "Welcome to bump!"), message: Config.FEED_TUTORIAL_ALERT, button: NSLocalizedString("got_it", comment: "Got it"))
        
    }
    
    public func loadFeed() {
        
        MIManager.manager.userFeed(offset: 0, completion: { (result: [MIPlaylist]) in
            
            DispatchQueue.main.sync {

                self.createContentView(result: result)
                
                // Remove preloader:
                self.preloaderView.isHidden = true
                
                // Shift top bar to content view:
                if self.topBarView.superview != nil {
                    
                    self.topBarView.removeFromSuperview()
                    
                }
                
                self.contentView.addSubview(self.topBarView)
                
                // Add bars:
                // self.createTopBar()
                // self.createBottomBar()
                
            }
            
        })
        
    }
    
    private func createTopBar() {
        setupTopBarView()
        createLeftButton()
        createMiddleButton()
        createRightButton()
        // createTopBarSwitch()
        // createNotificationButton()
        
        view.addSubview(topBarView)
        
        topBarView.alpha = 0.7
        
        let bottomAnimationOffset:CGFloat = 10
        
        UIView.animate(withDuration: 0.15, delay: 0.05, options: [UIViewAnimationOptions.curveEaseOut], animations: {
            
            self.topBarView.alpha = 1.0
            self.topBarView.frame = CGRect(
                x:0,
                y: bottomAnimationOffset,
                width: self.view.bounds.size.width,
                height: Origin.TOP_BAR_LEFT_BUTTON_LEFT + Size.HOME_TOP_BAR_HEIGHT
            )
            
            
        }, completion: { finished in
            
            // self.createBottomBar()
            
            UIView.animate(withDuration: 0.15, delay: 0.05, options: [UIViewAnimationOptions.curveEaseOut], animations: {
                
                self.topBarView.frame = CGRect(
                    x: 0,
                    y: 0,
                    width: self.view.bounds.size.width,
                    height: Origin.TOP_BAR_LEFT_BUTTON_LEFT + Size.HOME_TOP_BAR_HEIGHT
                )
                
            }, completion: { finished in
                
            })
            
        })
    }
    
    private func setupTopBarView() {
        topBarView.frame = CGRect(
            x: 0,
            y: -(Origin.TOP_BAR_LEFT_BUTTON_LEFT + Size.HOME_TOP_BAR_HEIGHT),
            width: view.bounds.size.width,
            height: Origin.TOP_BAR_LEFT_BUTTON_LEFT + Size.HOME_TOP_BAR_HEIGHT
        )
    }
    
    private func createLeftButton() {
        let leftButton = MIUIUtilities.createTopBarLeftButton(image: Image.TOP_BAR_PROFILE)
        leftButton.addTarget(self, action: #selector(showProfile), for: .touchUpInside)
        
        topBarView.addSubview(leftButton)
    }
    
    private func createMiddleButton() {
        guard let activeCardImage = UIImage(named: "ActiveCard") else {
            return
        }
        let activeCardImageView = UIImageView(image: activeCardImage)
        activeCardImageView.frame = CGRect(
            x: view.bounds.size.width/2 - activeCardImage.size.width/2,
            y: Origin.TOP_BAR_SWITCH_TOP,
            width: activeCardImage.size.width,
            height: Size.HOME_SWITCH_HEIGHT
        )
        
        topBarView.addSubview(activeCardImageView)
    }
    
    private func createRightButton() {
        EQButton.setImage(Image.TOP_BAR_EQ_GLOW, for: .selected)
        EQButton.frame = CGRect(
            x: UIScreen.main.bounds.size.width - (Image.TOP_BAR_EQ?.size.width)! - 13 - Size.BUTTON_TAP_AREA,
            y: 36 - Size.BUTTON_TAP_AREA,
            width: (Image.TOP_BAR_EQ?.size.width)! + Size.BUTTON_TAP_AREA*2,
            height: (Image.TOP_BAR_EQ?.size.height)! + Size.BUTTON_TAP_AREA*2
        )
        EQButton.addTarget(self, action: #selector(showPlayer), for: .touchUpInside)
        EQButton.isHidden = true
        
        topBarView.addSubview(EQButton)
    }
    
    private func createTopBarSwitch() {
        let topBarSwitch = TopBarSwitch(frame:CGRect(
            x: view.bounds.size.width/2 - Size.HOME_SWITCH_WIDTH/2,
            y: Origin.TOP_BAR_SWITCH_TOP,
            width: Size.HOME_SWITCH_WIDTH,
            height: Size.HOME_SWITCH_HEIGHT
        ))
        
        topBarView.addSubview(topBarSwitch)
    }
    
    private func createNotificationButton() {
        let notificationImage = Image.TOP_BAR_NOTIFICATIONS
        
        notificationsButton.frame = CGRect(x:view.bounds.size.width - (notificationImage?.size.width)! - Size.BUTTON_TAP_AREA - Origin.TOP_BAR_RIGHT_BUTTON_LEFT, y:Origin.TOP_BAR_RIGHT_BUTTON_TOP - Size.BUTTON_TAP_AREA, width:(notificationImage?.size.width)! + 2*Size.BUTTON_TAP_AREA, height:(notificationImage?.size.height)! + 2*Size.BUTTON_TAP_AREA)
        notificationsButton.setImage(notificationImage, for: .normal)
        notificationsButton.backgroundColor = UIColor.clear
        notificationsButton.addTarget(self, action: #selector(showNotifications), for: .touchUpInside)
        
        topBarView.addSubview(notificationsButton)
    }
    
    private func createBottomBar() {
        
        if bottomBarView.superview != nil{
            
            bottomBarView.removeFromSuperview()
            bottomBarView = UIView()
            
        }
        
        setupBottomBarView()
        createShareButton()
        createCreatePlaylistButton()
        createLikeButton()
        
        // view.addSubview(bottomBarView)
        view.insertSubview(bottomBarView, belowSubview: topBarView)
        
        bottomBarView.alpha = 0.7
        
        let bottomAnimationOffset:CGFloat = 10
        
        UIView.animate(withDuration: 0.15, delay: 0.05, options: [UIViewAnimationOptions.curveEaseOut], animations: {
            
            self.bottomBarView.alpha = 1.0
            self.bottomBarView.frame = CGRect(x:0, y: self.view.bounds.size.height - self.bottomBarView.bounds.size.height + bottomAnimationOffset, width:self.view.bounds.size.width, height:self.bottomBarView.bounds.size.height)
            
            
        }, completion: { finished in
            
            UIView.animate(withDuration: 0.15, delay: 0.05, options: [UIViewAnimationOptions.curveEaseInOut], animations: {
                
                self.bottomBarView.frame = CGRect(x:0, y: self.view.bounds.size.height - self.bottomBarView.bounds.size.height, width:self.view.bounds.size.width, height:self.bottomBarView.bounds.size.height)
                
            }, completion: { finished in
                
                
            })
            
        })

    }
    
    private func setupBottomBarView() {
        bottomBarView.frame = CGRect(
            x: 0,
            y: view.bounds.size.height,
            width: view.bounds.size.width,
            height: Size.HOME_BOTTOM_BAR_HEIGHT
        )
    }
    
    private func createShareButton() {
        guard let shareImage = UIImage(named: "ShareCircleButton") else {
            return
        }
        let shareButton = UIButton()
        shareButton.frame = CGRect(
            x: Origin.HOME_COMMENT_BUTTON_RIGHT,
            y: 0,
            width: shareImage.size.width,
            height: shareImage.size.height
        )
        shareButton.setImage(shareImage, for: .normal)
        shareButton.backgroundColor = .clear
        shareButton.addTarget(self, action: #selector(sharePlayList), for: .touchUpInside)
        
        bottomBarView.addSubview(shareButton)
    }
    
    private func createCreatePlaylistButton() {
        guard let createPlaylistImage = UIImage(named: "CreatePlayListButton") else {
            return
        }
        let createPlaylistButton = UIButton()
        createPlaylistButton.frame = CGRect(
            x: view.bounds.size.width/2 - createPlaylistImage.size.width/2,
            y: bottomBarView.bounds.size.height -  createPlaylistImage.size.height,
            width: createPlaylistImage.size.width,
            height: createPlaylistImage.size.height
        )
        createPlaylistButton.setImage(createPlaylistImage, for: .normal)
        createPlaylistButton.backgroundColor = .clear
        createPlaylistButton.addTarget(self, action: #selector(createNewPlayList), for: .touchUpInside)
            
        bottomBarView.addSubview(createPlaylistButton)
    }
    
    private func createLikeButton() {
        guard
            let likeImage = UIImage(named: "LikeButton"),
            let likeFilledImage = UIImage(named: "LikeButtonFilled")
            else {
            return
        }
        likeButton = UIButton()
        likeButton.frame = CGRect(
            x: view.bounds.size.width - likeImage.size.width - Origin.HOME_LIKE_BUTTON_RIGHT,
            y: 0,
            width: likeImage.size.width,
            height: likeImage.size.height
        )
        likeButton.setImage(likeImage, for: .normal)
        likeButton.setImage(likeFilledImage, for: .selected)
        likeButton.backgroundColor = .clear
        likeButton.addTarget(self, action: #selector(like), for: .touchUpInside)
        
        bottomBarView.addSubview(likeButton)
    }
    
    private func createGradientBackground(){
        
        let gradientView = GradientView(frame: view.bounds)
        gradientView.colors = [Color.TUTORIAL_BACKGROUND_TOP, Color.TUTORIAL_BACKGROUND_BOTTOM]
        gradientView.locations = [0.5, 1.0]
        gradientView.direction = .vertical
        view.addSubview(gradientView)
        
    }
    
    private func createContentView(result: [MIPlaylist]){
        
        contentView.frame = view.bounds
        // view.addSubview(contentView)

        view.insertSubview(contentView, belowSubview: bottomBarView)
        
        if homeContentView.superview != nil{
            homeContentView.removeFromSuperview()
        }
        
        homeContentView = MIHomeContentView(frame:view.bounds)
        homeContentView.cardCarousel.nextCardsLoaded(result: result)
        contentView.addSubview(homeContentView)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: Annimations
    func updateUI(offset:CGFloat, direction:ScrollDirection){
        
        homeContentView.updateUI(offset: offset, direction:direction)
        
        let coef = offset / Size.SCREEN_WIDTH
        bottomBarView.alpha = coef
        
        if coef != 1{
            
            topBarView.isHidden = true
            
        }else{
            
            topBarView.isHidden = false
            
            if isOpenedDetailedPlaylist {
               
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.HIDE_STATUS_BAR), object: nil)
            
            }

        }
        
    }
    
    //MARK: Actions
    public func showProfile(){
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.SHOW_MY_PROFILE), object: nil)

    }
    
    public func showNotifications(){
        
        let transition = CATransition()
        transition.duration = 0.2
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        view.window!.layer.add(transition, forKey: kCATransition)
        
        self.present(MINotificationsViewController(), animated: false, completion: nil)
        
    }
    
    public func showPlayer(){
        
        homeContentView.showPlayer()
        
    }
    
    public func showBottomBar(isShow: Bool){
        
        UIView.animate(withDuration: 0.15, delay: 0.05, options: [UIViewAnimationOptions.curveEaseOut], animations: {
            
            var bottomBarFrame = self.bottomBarView.frame
            
            if isShow{
                
                bottomBarFrame.origin.y = self.view.bounds.size.height - self.bottomBarView.frame.size.height

            }else{
                
                bottomBarFrame.origin.y = self.view.bounds.size.height

            }

            self.bottomBarView.frame = bottomBarFrame
            
        }, completion: { finished in
            
        })
        
    }
    
    public func createNewPlayList(){

        if MIManager.manager.isUserLogged() {
            
            self.present(MINewPlayListViewController(), animated: true, completion: nil)
            
        } else {
            
            MIUIUtilities.showFacebookLoginAlert()
            
        }
        
    }
    
    public func like(sender: UIButton){
        
        homeContentView.likePlaylist(isLike: sender)
        
    }
    
    public func showPlayList(playList:MIPlaylist){
        
        guard isOpeningDetailedPlaylist == false else{
            
            return
            
        }
        
        isOpeningDetailedPlaylist = true
        
        //Add Mark
        UserDefaults.standard.set(false, forKey: "fromProfile")
        
        var playListFrame = self.view.bounds
        playListFrame.origin.y = playListFrame.size.height
        
        let detailedPlayListView = MIPlayListContentView(frame:playListFrame, playList:playList)
        contentView.addSubview(detailedPlayListView)
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [UIViewAnimationOptions.curveEaseOut], animations: {
            
            self.topBarView.isHidden = true
            detailedPlayListView.frame = self.view.bounds
            
        }, completion: { finished in
            
            detailedPlayListView.animationFinished()
            self.isOpeningDetailedPlaylist = false
            self.isOpenedDetailedPlaylist = true
            
        })
        
        bottomBarView.isHidden = true
        
    }
    
    public func sharePlayList(){
        
        if let topCard = homeContentView.cardCarousel.cards.first{
            
            MIUIUtilities.sharePlaylist(playList: topCard.playList,view:self.view)

        }
        
    }
    
    public func hidePlayList(){
        
        self.topBarView.isHidden = false
        self.bottomBarView.isHidden = false
        
        isOpenedDetailedPlaylist = false
        
    }
    
    //MARK: Notifications
    public func trackStarted(_ notification:Notification){
        
        notificationsButton.frame = CGRect(x:EQButton.frame.origin.x - 10 - notificationsButton.bounds.size.width, y:notificationsButton.frame.origin.y, width:notificationsButton.bounds.size.width, height:notificationsButton.bounds.size.height)

        EQButton.isHidden = false
        EQButton.isSelected = true
        
    }
    
    public func trackPaused(_ notification:Notification){
        
        EQButton.isSelected = false

    }
    
    public func playlistChanged(_ notification:Notification){
        
        if let playList = notification.userInfo?["playList"] as? MIPlaylist {
            
            if let topPlaylist = homeContentView.cardCarousel.cards.first?.playList, topPlaylist.id == playList.id{
                
                likeButton.isSelected = playList.isHearted

            }

        }
        
	}
    
    public func playlistSwiped(_ notification:Notification){
        
        if let playList = notification.userInfo?["playList"] as? MIPlaylist {
            
            likeButton.isSelected = playList.isHearted
            
        }
        
    }
	

    //MARK: show user profile
    func showUserProfile(notification: Notification) {
        
        if UIApplication.topViewController() is MIProfileViewController {
            
            return
            
        }
        
        //Analytics
        MIAnalyticsManager.logScreen(AnalyticsScreens.PROFILE_OTHER_PROFILE)
        
        let userInfo = notification.userInfo as! [String : MIUser]
        if let owner = userInfo["user"]  {
        
            let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
            let profileVC = profileStoryboard.instantiateViewController(withIdentifier: "MIProfileViewController")
            (profileVC as! MIProfileViewController).userId = String(owner.id)
            (profileVC as! MIProfileViewController).owner = owner
            
            UIApplication.topViewController()?.present(profileVC, animated: true, completion: nil)
        }
    }
    
    public func subscribeAppleMusic() {
        let cloudServiceController = SKCloudServiceController()
        
        SKCloudServiceController.requestAuthorization { (status) in
            
            if status != .authorized { return }
            
            cloudServiceController.requestCapabilities { (capability, error) in
                
                self.presentAppleMusicWindow(capability: capability)
                
            }
        }
    }
    
    private func presentAppleMusicWindow(capability: SKCloudServiceCapability) {
        
        if #available(iOS 10.1, *) {
            
            if capability.contains(.musicCatalogSubscriptionEligible) && !capability.contains(.musicCatalogPlayback) {
                
                let controller = SKCloudServiceSetupViewController()
                controller.delegate = self
                
                controller.load(options: [.action : SKCloudServiceSetupAction.subscribe], completionHandler: nil)
                
                UIApplication.topViewController()?.present(controller, animated: true, completion: nil)
                
            }
            
        }
        
    }
}

extension MIHomeViewController: SKCloudServiceSetupViewControllerDelegate {
    @available(iOS 10.1, *)
    func cloudServiceSetupViewControllerDidDismiss(_ cloudServiceSetupViewController: SKCloudServiceSetupViewController) {
        
        MIAppController.applicationDidBecomeActive()
        
    }
}
