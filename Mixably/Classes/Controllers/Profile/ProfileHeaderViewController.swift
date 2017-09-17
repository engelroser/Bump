//
//  MIProfileHeaderViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 31.03.17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

class MIProfileHeaderViewController: UIViewController {
    
    var isMyProfile = true
    
    public var userId : String = "" {
        didSet{
            isMyProfile = (userId == "me")
        }
    }
    
    private var user: MIUser?
    public var delegate :MIProfileHeaderViewControllerDelegate?

    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var imgUserIcon: UIImageView!
    @IBOutlet weak var btnSettings: UIButton!
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var btnEditProfile: UIButton!
    @IBOutlet weak var lblUserName: UILabel!
    @IBOutlet weak var lblDescription: UILabel!
    @IBOutlet weak var lblPlayListsCount: UILabel!
    @IBOutlet weak var lblPlayFollowingCount: UILabel!
    @IBOutlet weak var btnFollowing: UIButton!
    @IBOutlet weak var btnPlaylist: UIButton!
    @IBOutlet weak var btnFollowers: UIButton!
    @IBOutlet weak var lblFollowersCount: UILabel!
    @IBOutlet weak var btnFaceBook: UIButton!
    @IBOutlet weak var btnInstagram: UIButton!
    @IBOutlet weak var btnTwitter: UIButton!
    @IBOutlet weak var btnWeb: UIButton!
    @IBOutlet weak var btnCards: UIButton!
    
    @IBOutlet weak var btnBack: UIButton!
    @IBOutlet weak var btnFollow: UIButton!
    
    @IBOutlet weak var constraintViewTop: NSLayoutConstraint!
    @IBOutlet weak var constraintAvatarTop: NSLayoutConstraint!
    @IBOutlet weak var constraintDescriptionBottom: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isMyProfile{
            
            btnBack.isHidden = true
            btnFollow.isHidden = true
            btnEditProfile.isHidden = false
            //imgUserIcon.isHidden = false
            btnSettings.isHidden = false
            //btnCards.isHidden = false
            
        }else{
            btnBack.isHidden = false
            btnEditProfile.isHidden = true
            //imgUserIcon.isHidden = true
            btnSettings.isHidden = true
            //btnCards.isHidden = true
            
            constraintAvatarTop.constant -= 17
        
        }
        
        //Hide the social components
        btnFollow.isHidden = true
        btnFollowing.isHidden = true
        lblPlayFollowingCount.isHidden = true
        btnPlaylist.isHidden = true
        lblPlayListsCount.isHidden = true
        btnFollowers.isHidden = true
        lblFollowersCount.isHidden = true

        btnFaceBook.imageView?.contentMode = .scaleAspectFit
        btnInstagram.imageView?.contentMode = .scaleAspectFit
        btnTwitter.imageView?.contentMode = .scaleAspectFit
        btnWeb.imageView?.contentMode = .scaleAspectFit
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MIManager.manager.getUserInfoWithUserId(userId: userId, completion: {(user: MIUser) in
            DispatchQueue.main.async {
                self.setUserData(user)
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var prefersStatusBarHidden: Bool {
        
        return !isMyProfile
    }
    
    override func viewDidLayoutSubviews() {
        
        if user != nil {
        
            delegate?.didSetUserData!(self.contentView.frame.height, playListCount: (user?.playlistCount)!)
        }
    }
    
    //MARK: - set user data
    public func setUserData(_ user: MIUser){
        
        self.user = user
        lblUserName.text = user.profileDisplayName
        lblDescription.text = user.biography
        imgAvatar.kf.setImage(with: URL(string: user.profilePictureUrl))
        lblPlayListsCount.text = String(user.playlistCount)
        lblPlayFollowingCount.text = String(user.followingsCount)
        lblFollowersCount.text = String(user.followersCount)
        
        btnPlaylist.setTitle(user.playlistCount > 1 ? "PLAYLISTS" : "PLAYLIST", for: .normal)
        btnFollowers.setTitle( user.followersCount > 1 ? "FOLLOWERS" : "FOLLOWER", for: .normal)
        
        if Size.SCREEN_WIDTH <= 320{
            
            let font = btnPlaylist.titleLabel?.font
            
            let smallFont = UIFont(name: (font?.fontName)!, size: (font?.pointSize)! - 2)
            btnPlaylist.titleLabel?.font = smallFont
            btnFollowers.titleLabel?.font = smallFont
            btnFollowing.titleLabel?.font = smallFont

        }

        if let socialLinks = user.links {
            
            if !socialLinks.fbId.isEmpty {
                btnFaceBook.setImage(UIImage(named: "ic_facebook_enabled"), for: .normal)
            }
        
            if !socialLinks.igId.isEmpty {
                btnInstagram.setImage(UIImage(named: "ic_instagram_enabled"), for: .normal)
            }
            
            if !socialLinks.twId.isEmpty {
                btnTwitter.setImage(UIImage(named: "ic_twitter_enabled"), for: .normal)
            }
            
            if !socialLinks.pUrl.isEmpty {
                btnWeb.setImage(UIImage(named: "ic_web_enabled"), for: .normal)
            }
        }
        
        if !(user.biography.isEmpty) {
            constraintDescriptionBottom.constant = 31
        }
        
        if !isMyProfile {
            btnFollow.setImage(UIImage(named: user.isFollowing ? "ic_follow" : "ic_followed"), for: .normal)
            
            //Add report button
            createReportUserButton()
            
        }
        
        self.view.setNeedsLayout()
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
        
        let reportButton = MIPlaylistOwnerReportButton(frame: frame, owner: user, reportIcon: reportIcon)
        contentView.addSubview(reportButton)
        
    }
    
    func showEditProfile() {
        
        if user != nil {
        
            let editProfileVC = self.storyboard?.instantiateViewController(withIdentifier: "MIEditProfileViewController") as! MIEditProfileViewController
            editProfileVC.user = user
                    
            self.present(editProfileVC, animated: true, completion: nil)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    func dismissPage() {
        
        if (isMyProfile) {
            let transition = CATransition()
            transition.duration = 0.2
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionPush
            transition.subtype = kCATransitionFromRight
            view.window!.layer.add(transition, forKey: kCATransition)
        }
        
        self.dismiss(animated: isMyProfile ? false : true, completion: nil)
    }
    
    @IBAction func onClickBtnCards(_ sender: Any) {
     
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: Notifications.SHOW_HOME), object: nil)

    }
    
    
    @IBAction func onClickBtnSetting(_ sender: Any) {
        let transition = CATransition()
        transition.duration = 0.2
        transition.type = kCATransitionReveal
        transition.subtype = kCATransitionFromLeft
        view.window!.layer.add(transition, forKey: kCATransition)
        
        self.present(MISettingsViewController(), animated: false, completion: nil)
    }
    
    @IBAction func onClickBtnEditProfile(_ sender: Any) {
        showEditProfile()
    }
    
    @IBAction func onTapProfileImageGesture(_ sender: Any) {
        if isMyProfile {
            showEditProfile()
        }
    }
    
    @IBAction func onClickBtnFaceBook(_ sender: Any) {
        if let fbId = user?.links?.fbId {
            if !fbId.isEmpty {
                
                //Uncomment code below to show app's browser again
                //showWebView(withUrl: SocialPublicUrlLink.FACEBOOK_LINK + fbId)
                
                let url = URL(string: SocialPublicUrlLink.FACEBOOK_LINK + fbId)!
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
                
            }
        }
    }
    
    @IBAction func onClickBtnInstagram(_ sender: Any) {
        if let igId = user?.links?.igId {
            if !igId.isEmpty {
                showWebView(withUrl: SocialPublicUrlLink.INSTAGRAM_LINK + igId)
            }
        }
    }
    
    @IBAction func onClickBtnTwitter(_ sender: Any) {
        if let twId = user?.links?.twId {
            if !twId.isEmpty {
                showWebView(withUrl: SocialPublicUrlLink.TWITTER_LINK + twId)
            }
        }
    }
    
    @IBAction func onClickBtnWeb(_ sender: Any) {
        
        if let pUrl = user?.links?.pUrl {
            if !pUrl.isEmpty {
                showWebView(withUrl: pUrl)
            }
        }
    }
    
    func showWebView(withUrl url:String) {
        let webVC = self.storyboard?.instantiateViewController(withIdentifier: String(describing:MIWebViewController.self)) as! MIWebViewController
        
        webVC.url = url
        
        self.present(webVC, animated: true, completion: nil)
    }
    
    @IBAction func onClickPlayBtnLists(_ sender: Any) {
        delegate?.onClickPlayListButtion!()
    }
    
    @IBAction func onClickPlayListsArea(_ sender: Any) {
        delegate?.onClickPlayListButtion!()
    }
    
    @IBAction func onClickBtnFollowing(_ sender: Any) {
    }
    
    @IBAction func onClickBtnFollowers(_ sender: Any) {    }
    
    @IBAction func onClickBtnBack(_ sender: Any) {
        dismissPage()
    }
    
    @IBAction func onClickBtnUserFollow(_ sender: Any) {
        
        MIManager.manager.followUnfollowUser(userId: userId, isFollow: !(user?.isFollowing)!, completion: {(result: Bool, message:String, followers:Int) in
            if result {
                self.user?.isFollowing = !(self.user?.isFollowing)!
                self.user?.followersCount = followers
                
                DispatchQueue.main.async {
                    self.btnFollow.setImage(UIImage(named: (self.user?.isFollowing)! ? "ic_follow" : "ic_followed"), for: .normal)
                    self.lblFollowersCount.text = String(followers)
                    self.btnFollowers.setTitle( followers > 1 ? "FOLLOWERS" : "FOLLOWER", for: .normal)
                }
            }
        })
    }
}

@objc protocol MIProfileHeaderViewControllerDelegate {
    @objc optional func onClickPlayListButtion()
    @objc optional func onClickFollowingButtion()
    @objc optional func onClickFollowersButtion()
    @objc optional func didSetUserData(_ headerHeight: CGFloat, playListCount: Int)
}
