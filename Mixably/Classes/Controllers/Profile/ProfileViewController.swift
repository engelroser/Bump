//
//  MIProfileViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 04/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import GradientView
import HexColors
import Firebase
import FacebookCore
import FacebookLogin

class MIProfileViewController: SJSegmentedViewController, MIProfileHeaderViewControllerDelegate, MIViewControllerDelegate {
    
    public var userId : String?
    
    public var owner = MIUser()
    
    var isMyProfile = false
    var selectedSegment: SJSegmentTab?
    var isBtnPlayListCliked = false
    
    var isDirection = "right"
    
    //UI
    private var rightButton = UIButton()
    private var rightButtonSelected = UIButton()
    private var nonActiveCardView = UIButton()
    private var activeCardView = UIImageView()
    private var topBarView = UIView()
    
    private var loginView = UIView()
    private var facebookLoginButton = UIButton()
    
    //Profile Playlists
    private let playlistVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "MIProfileTableViewController") as! MIProfileTableViewController
    private let likedVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "MIProfileTableViewController") as! MIProfileTableViewController
    private let listinedVC = UIStoryboard(name: "Profile", bundle: nil).instantiateViewController(withIdentifier: "MIProfileTableViewController") as! MIProfileTableViewController
    
    override func viewDidLoad() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(playlistActions(_:)), name: NSNotification.Name(rawValue: Notifications.PLAYLIST_ACTIONS), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadViews), name: NSNotification.Name(rawValue: Notifications.USER_LOGGED_IN), object: nil)

        showUserProfileDetails()

        if MIManager.manager.isUserLogged() == false, userId == "me" {
            
            showLoginView()

        } else {
            
            headerViewController?.view.isHidden = false

            loginView.removeFromSuperview()
            
        }
        
    }
    
    public func reloadViews(){
        
        UIApplication.shared.keyWindow?.rootViewController = MIHomePageViewController()
        
        MIAppController.checkMSSPS(completion: {
            result in
            
            for mssps in result{
                
                MIManager.manager.refreshTokenForMusicProvider(provider: mssps, completion: {
                    _ in
                    
                })
                
            }
            
        })
        
    }
    
    private func showLoginView(){

        //Hide empty header view
        headerViewController?.view.isHidden = true

        //Hide segmented control
        headerViewHeight = 0
        
        //Create login view
        createLoginView()
        
    }
    
    private func createLoginView(){
        
        loginView.frame = CGRect(x:Origin.USER_PROFILE_LOGIN_VIEW_LEFT, y:Origin.USER_PROFILE_LOGIN_VIEW_TOP, width: view.bounds.size.width - 2*Origin.USER_PROFILE_LOGIN_VIEW_LEFT, height:view.bounds.size.height - Origin.USER_PROFILE_LOGIN_VIEW_TOP - Origin.USER_PROFILE_LOGIN_VIEW_BOTTOM)
        view.addSubview(loginView)
        
        if let bluredProfile = UIImage(named:"ProfileBlured"){
            
            let backgroundImageView = UIImageView(image:bluredProfile)
            backgroundImageView.frame = loginView.bounds
            backgroundImageView.contentMode = .scaleAspectFit
            loginView.addSubview(backgroundImageView)
            
        }
        
        createFacebookLoginButton(title:NSLocalizedString("login_with_facebook", comment: "Log in with Facebook"))
        createLoginTitle()
        createLoginMessage()

    }
    
    private func createLoginTitle(){

        let title = UILabel()
        
        title.font = UIFont(name:"HelveticaNeue-Bold", size:20)
        title.textAlignment = .center
        title.frame = CGRect(x:0, y:Origin.USER_PROFILE_LOGIN_VIEW_TITLE_TOP, width:loginView.bounds.width, height:24)
        title.text = NSLocalizedString("stay_social", comment: "stay_social")
        title.textColor = .white
        loginView.addSubview(title)

    }
    
    private func createLoginMessage(){
        
        let message = UILabel()
        
        message.font = UIFont(name:"HelveticaNeue-Light", size:18)
        message.textAlignment = .center
        message.frame = CGRect(x:Origin.USER_PROFILE_LOGIN_VIEW_MESSAGE_LEFT, y:Origin.USER_PROFILE_LOGIN_VIEW_MESSAGE_TOP, width:loginView.bounds.width - 2*Origin.USER_PROFILE_LOGIN_VIEW_MESSAGE_LEFT, height:Size.USER_PROFILE_LOGIN_VIEW_MESSAGE_HEIGHT)
        message.numberOfLines = 0
        message.text = NSLocalizedString("stay_social_message", comment: "stay_social_message")
        message.textColor = .white
        message.adjustsFontSizeToFitWidth = true

        loginView.addSubview(message)

        
    }
    
    private func createFacebookLoginButton(title:String){
        
        let tapLoginGesture = UITapGestureRecognizer(target: self, action: #selector(loginActionWithFacebook))
        
        facebookLoginButton = MIUIUtilities.createGlowButton(text:title, glowImage:Image.FACEBOOK_BUTTON_BLUR, color:Color.FACEBOOK_LOGIN, touchRecognizer: tapLoginGesture, logo: nil, logoYOffset:0)
        facebookLoginButton.frame = CGRect(x:loginView.bounds.width/2 - Size.TUTORIAL_BIG_BUTTON_WIDTH/2, y:Origin.USER_PROFILE_LOGIN_VIEW_FACEBOOK_TOP, width:Size.TUTORIAL_BIG_BUTTON_WIDTH, height:Size.TUTORIAL_BIG_BUTTON_HEIGHT)
        
        loginView.addSubview(facebookLoginButton)
        
    }
    
    public func loginActionWithFacebook() {
        self.facebookLoginButton.removeFromSuperview()
        self.createFacebookLoginButton(title:"Connecting...")
        
        let overlayView = UIView(frame: self.view.bounds)
        self.loginView.addSubview(overlayView)
        
        let indicator = UIActivityIndicatorView()
        indicator.center = CGPoint(x: 3*self.facebookLoginButton.bounds.size.width/4 + 10, y: self.facebookLoginButton.bounds.size.height/2)
        indicator.startAnimating()
        self.facebookLoginButton.addSubview(indicator)
        
        LoginManager().logIn([ .publicProfile, .email ], viewController: UIApplication.topViewController()) { loginResult in
            
            switch loginResult {
            case .failed(let error):
                print(error)
                
                //Remove the overlay view and indicator, Change the title of Facebook Login Button After failed login.
                overlayView.removeFromSuperview()
                indicator.removeFromSuperview()
                self.createFacebookLoginButton(title:NSLocalizedString("login_with_facebook", comment: "Log in with Facebook"))
                
                //Alert Controller for no response from server
                let noResponseAlertTitle = "No Response From Server"
                let noResponseAlertMessage = "Can not connect to server"
                
                let noResponseAlert = UIAlertController(title: noResponseAlertTitle, message: noResponseAlertMessage, preferredStyle: UIAlertControllerStyle.alert)
                noResponseAlert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: { (action) in
                    
                }))
                
                UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(noResponseAlert, animated: true, completion: nil)
                
            case .cancelled:
                print("User cancelled login.")
                
                //Remove the overlay view and indicator, Change the title of Facebook Login Button After cancelled login.
                overlayView.removeFromSuperview()
                indicator.removeFromSuperview()
                self.createFacebookLoginButton(title:NSLocalizedString("login_with_facebook", comment: "Log in with Facebook"))
                
                self.showFacebookLoginAlert()
                
                
            case .success( _, _, let accessToken):
                print("Logged in!")
                
                MIManager.manager.loginWithFacebook(authenticationToken:accessToken.authenticationToken,completion:{ result in

                    MIAppController.checkMSSPS(completion: {
                        result in
                        
                        for mssps in result{
                            
                            MIManager.manager.refreshTokenForMusicProvider(provider: mssps, completion: {
                                _ in
                                
                                
                            })
                            
                        }
                        
                    })

                })
                
            }
        }
    }

    //Mark: Alert View
    
    public func showFacebookLoginAlert(){
        
        //Alert Function For User's Selection.
        
        let alertTitle = "To Continue connect with Facebook"
        let alertMessage = "Authorise Mixably app to connect with Facebook"
        
        let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Connect", style: UIAlertActionStyle.default, handler: { (action) in
            
            self.loginActionWithFacebook()
            
        }))
        UIApplication.shared.keyWindow?.rootViewController?.presentedViewController?.present(alert, animated: true, completion: nil)
        
    }
    
    private func showUserProfileDetails(){
        
        reloadUserProfileDetails()
        
        super.viewDidLoad()

    }
    
    private func reloadUserProfileDetails(){
        
        let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        
        isMyProfile = (userId == "me")
        
        headerViewController = profileStoryboard.instantiateViewController(withIdentifier: "MIProfileHeaderViewController")
        let miProfileHeaderViewController = headerViewController as! MIProfileHeaderViewController
        miProfileHeaderViewController.delegate = self
        miProfileHeaderViewController.userId = self.userId!
        
        
        (playlistVC as! MIProfileTableViewController).initParam(self.userId!, type: .user, owner: self.owner)
        playlistVC.title = "Playlists"
        
        if isMyProfile {
            
            (likedVC as! MIProfileTableViewController).initParam(self.userId!, type: .liked, owner: self.owner)
            likedVC.title = "Liked"
            
            
            (listinedVC as! MIProfileTableViewController).initParam(self.userId!, type: .listened, owner: self.owner)
            listinedVC.title = "Listened"
            
            segmentControllers = [playlistVC, likedVC, listinedVC]
            
            selectedSegmentViewColor = UIColor("#E94866") ?? .red
            
        } else {
            
            segmentControllers = [playlistVC]
            selectedSegmentViewColor = .clear
            
            //Analytics
            if let curUserId = userId {
                
                MIManager.manager.getUserInfoWithUserId(userId: curUserId, completion: {(user: MIUser) in
                    
                    MIAnalyticsManager.logEvent(AnalyticsEventSelectContent, parameters:["content_type":"user_profile", "item_id":curUserId, "title":user.displayName])
                    
                })
                
            }
            
        }
        
        if MIManager.manager.isUserLogged() == true || isMyProfile == false {
            
            headerViewHeight = 403
            
            // tab setting
            
            segmentFullWidth = isMyProfile
            
            segmentBackgroundColor = .clear
            segmentTitleFont = UIFont(name: "HelveticaNeue-Bold", size: 16)!
            segmentTitleColor = UIColor.lightGray
            selectedSegmentViewHeight = 2
            segmentShadow = SJShadow(offset: CGSize(width: 0, height: 1), color: UIColor.clear, radius :0.2, opacity: 0.5)
            segmentBounces = false
            
            delegate = self
            
        }else {
            
            headerViewHeight = 0
            segmentBackgroundColor = .clear
            segmentTitleFont = UIFont(name: "HelveticaNeue-Bold", size: 0)!
            segmentTitleColor = .clear
            selectedSegmentViewHeight = 0
            segmentShadow = SJShadow(offset: CGSize(width: 0, height: 1), color: UIColor.clear, radius :0.2, opacity: 0.5)
            
        }
        
        setupUI()

        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
    }
    
    public func playlistActions(_ notification:Notification){

        if let track = notification.userInfo?["action"] as? String{
            
            switch track {
            case "like":
                print("like")
                (likedVC as! MIProfileTableViewController).initParam(self.userId!, type: .liked, owner: self.owner)
                likedVC.title = "Liked"
            case "creation":
                print("creation")
                (playlistVC as! MIProfileTableViewController).initParam(self.userId!, type: .user, owner: self.owner)
                playlistVC.title = "Playlists"
            case "listen":
                print("listen")
                (listinedVC as! MIProfileTableViewController).initParam(self.userId!, type: .listened, owner: self.owner)
                listinedVC.title = "Listened"
            default:
                print("default")
            }
        }
        
    }
    
    // MARK: Basic setting
    
    private func setupUI() {
        
        view.backgroundColor = Color.TUTORIAL_BACKGROUND_TOP
        createGradientBackground(inView:view)
        
        createTopBar()
        prepareAnimations()

    }

    private func createTopBar(){
        
        //Check if we added top bar already
        guard topBarView.superview == nil else {
            
            return
            
        }
        
        topBarView = UIView(frame:CGRect(x:0, y:0, width:view.bounds.width, height:Size.PROFILE_TOP_BAR_HEIGHT))
        topBarView.clipsToBounds = true
        view.addSubview(topBarView)
        
        createGradientBackground(inView: topBarView)
        
        if isMyProfile {
            let leftButton = MIUIUtilities.createTopBarLeftButton(image: Image.TOP_BAR_SETTINGS)
            leftButton.addTarget(self, action: #selector(showSettings), for: .touchUpInside)
            view.addSubview(leftButton)
        } else {
            
            //Add report button and back button
            createReportUserButton()
            createBackButton()
        }
        
    }
    
    private func createReportUserButton() {
        guard let reportIcon = UIImage(named: "ReportUserButtonWhite") else {
            return
        }
        
        let frame = CGRect(
            x: Origin.USER_REPORT_LEFT - Size.BUTTON_TAP_AREA,
            y: Origin.USER_REPORT_TOP - Size.BUTTON_TAP_AREA,
            width: reportIcon.size.width + Size.BUTTON_TAP_AREA * 2,
            height: reportIcon.size.height + Size.BUTTON_TAP_AREA * 2
        )
        
        let reportButton = MIPlaylistOwnerReportButton(frame: frame, owner: self.owner, reportIcon: reportIcon)
        view.addSubview(reportButton)
        
    }
    
    private func createBackButton(){
        
        let backButton = MIUIUtilities.createTextButton(text:NSLocalizedString("back", comment: "Back").uppercased())
        backButton.titleLabel?.font = Font.TUTORIAL_GOT_IT_BUTTON
        
        backButton.sizeToFit()
        backButton.frame = CGRect(x:self.view.bounds.width - Origin.CREATE_PLAYLIST_CANCEL_BUTTON_RIGHT - backButton.bounds.size.width, y:Origin.USER_PROFILE_BACK_BUTTON_TOP, width:backButton.bounds.size.width, height:Size.TUTORIAL_TUTORIAL_GOT_IT_BUTTON_HEIGHT)
        backButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        backButton.setBackgroundImage(UIImage(), for: .normal)
        
        self.view.addSubview(backButton)
        
    }
    
    //MARK: Actions
    public func cancel(){
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    private func prepareAnimations(){
        
        //Check if we added right button already
        guard rightButton.superview == nil else {
            
            return
            
        }
        
        rightButton = MIUIUtilities.createTopBarLeftButton(image: Image.TOP_BAR_PROFILE)
        
        var rightButtonFrame = rightButton.frame
        rightButtonFrame.origin.x += view.bounds.size.width

        rightButton.frame = rightButtonFrame
        
        view.addSubview(rightButton)
        
        rightButtonSelected = MIUIUtilities.createTopBarLeftButton(image: Image.TOP_BAR_PROFILE_HIGHTLIGHT)
        rightButtonSelected.alpha = 0.0
        rightButtonSelected.frame = rightButtonFrame
        view.addSubview(rightButtonSelected)
        
        if let activeImg = UIImage(named:"ActiveCard"){
            
            activeCardView.image = activeImg
            activeCardView.frame = CGRect(x:view.bounds.size.width + view.bounds.size.width/2 - activeImg.size.width/2, y:Origin.TOP_BAR_SWITCH_TOP, width:activeImg.size.width, height:Size.HOME_SWITCH_HEIGHT)
            view.addSubview(activeCardView)
            
        }
        
        if let nonActiveImg = UIImage(named:"TopBarCards"){
            
            nonActiveCardView.setImage(nonActiveImg, for: .normal)
            nonActiveCardView.addTarget(self, action: #selector(showHome), for: .touchUpInside)
            
            nonActiveCardView.frame = CGRect(x:view.bounds.size.width + view.bounds.size.width/2 - nonActiveImg.size.width/2, y:Origin.TOP_BAR_SWITCH_TOP, width:nonActiveImg.size.width, height:nonActiveImg.size.height)
            view.addSubview(nonActiveCardView)
            
        }

    }

    private func createGradientBackground(inView:UIView){
        
        let gradientView = GradientView(frame: view.bounds)
        gradientView.colors = [Color.TUTORIAL_BACKGROUND_TOP, Color.TUTORIAL_BACKGROUND_BOTTOM]
        gradientView.locations = [0.5, 1.0]
        gradientView.direction = .vertical
        
        inView.insertSubview(gradientView, at: 0)
    }
    
    private func createContentView(){
        
        view.addSubview(MIHomeContentView(frame:view.bounds))
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        return (userId != "me")
    }
    
    
    //MARK: Actions

    func showSettings(_ sender: Any) {
        
        let transition = CATransition()
        transition.duration = 0.2
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionDefault)
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        view.window!.layer.add(transition, forKey: kCATransition)
        
        if let topController = UIApplication.topViewController() {
            
            let settingsController = MISettingsViewController()
            settingsController.modalPresentationStyle = .overCurrentContext
            topController.present(settingsController, animated: false, completion: nil)

        }

    }
    
    public func showHome(){
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.SHOW_HOME), object: nil)
        
    }
    
    //Mark: HearderViewControllerDelegate
    
    func onClickPlayListButtion() {
        
        isBtnPlayListCliked = true
        //setSelectedSegmentAt(0, animated: true)
        let delayInSeconds = 0.05
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
            
            self.scrollingViewAccrodingToHeaderView(0, isMyProfile: self.isMyProfile)
            
        }
    }
    
    func didSetUserData(_ headerHeight: CGFloat, playListCount:Int) {
        headerViewHeight = headerHeight
        updateViewLayout()
        setTabTitle(index: 0, title: "Playlists")
    }
    
    //MARK: Annimations
    func updateUI(offset:CGFloat, direction:ScrollDirection){
        
        //Update profile button
        let coef = offset / Size.SCREEN_WIDTH
        rightButtonSelected.alpha = 1 - coef
        rightButton.alpha = coef
        
        var newFrame = CGRect(x:view.bounds.size.width/2 - rightButtonSelected.bounds.size.width/2 + coef*(view.bounds.size.width/2 + Origin.TOP_BAR_RIGHT_BUTTON_LEFT - Size.BUTTON_TAP_AREA + rightButtonSelected.bounds.size.width/2), y: Origin.TOP_BAR_RIGHT_BUTTON_TOP - Size.BUTTON_TAP_AREA + (1 - coef)*(3.0), width: rightButtonSelected.frame.size.width, height:rightButtonSelected.frame.size.height)
        rightButtonSelected.frame = newFrame
        rightButton.frame = newFrame

        //Update card button
        newFrame = CGRect(x:view.bounds.size.width - nonActiveCardView.bounds.size.width - Origin.TOP_BAR_RIGHT_BUTTON_LEFT + coef*(nonActiveCardView.bounds.size.width + Origin.TOP_BAR_RIGHT_BUTTON_LEFT + view.bounds.size.width/2 - nonActiveCardView.bounds.size.width/2), y:Origin.TOP_BAR_SWITCH_TOP, width:Size.HOME_CARDS_ICON_WIDTH + coef*3.0, height:Size.HOME_CARDS_ICON_HEIGHT + coef*4.0)
        
        nonActiveCardView.alpha = 1 - coef
        activeCardView.alpha = coef
        
        nonActiveCardView.frame = newFrame
        activeCardView.frame = newFrame

        if offset == Size.SCREEN_WIDTH {
            
            if isDirection == "left" {

                isDirection = "right"
                
                //Reload playlists
                playlistVC.reloadData()
                likedVC.reloadData()
                listinedVC.reloadData()
                
                // Analytics:
                MIAnalyticsManager.logScreen(AnalyticsScreens.HOME_MAIN)
                
            }
            
        } else if offset == 0 {
            
            if isDirection == "right" {
                isDirection = "left"
                
                // Analytics:
                isMyProfile ? MIAnalyticsManager.logScreen(AnalyticsScreens.PROFILE_MY_PROFILE) : MIAnalyticsManager.logScreen(AnalyticsScreens.PROFILE_OTHER_PROFILE)
                
                if isMyProfile {
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.SHOW_STATUS_BAR), object: nil)

                }

            }
            
        }
        
        if coef == 1{
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.SHOW_STATUS_BAR), object: nil)
            
            //Home screen is shown
            nonActiveCardView.isHidden = true
            activeCardView.isHidden = true
            
            rightButton.isHidden = true
            rightButtonSelected.isHidden = true

        } else{
            
            //Profile screen is shown
            nonActiveCardView.isHidden = false
            activeCardView.isHidden = false
            
            rightButton.isHidden = false
            rightButtonSelected.isHidden = false
            
        }
        
    }
    
    func lookForCreatePlaylist(_ v: UIView) -> Bool{
        
        let subs = v.subviews
        if subs.count == 0 {return false}
        for vv in subs {
            if vv is MIPlayListContentView {
                return true
            }
            lookForCreatePlaylist(vv)
        }
        
        return false
    }
    
}

extension MIProfileViewController: SJSegmentedViewControllerDelegate {
    
    func didMoveToPage(_ controller: UIViewController, segment: SJSegmentTab?, index: Int) {
        
        if selectedSegment != nil {
            selectedSegment?.titleColor(.lightGray)
            
            if selectedSegment == segments[index] && !isBtnPlayListCliked {
                scrollingViewAccrodingToHeaderView(index, isMyProfile: isMyProfile)
            }
        }
        
  
        isBtnPlayListCliked = false
        
        if segments.count > 0 {
            
            selectedSegment = segments[index]
            selectedSegment?.titleColor(UIColor("#E94866") ?? .red)
        }
    }

}

