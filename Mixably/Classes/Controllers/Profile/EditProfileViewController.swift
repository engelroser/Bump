//
//  MIEditProfileViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 04.04.17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import GradientView
import SnapKit

class MIEditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    
    @IBOutlet weak var imgAvatar: UIImageView!
    @IBOutlet weak var viewEditUserName: UIView!
    @IBOutlet weak var viewEditUserDescription: UIView!
    @IBOutlet weak var viewEditFaceBookAccount: UIView!
    @IBOutlet weak var viewEditInstagramAccount: UIView!
    @IBOutlet weak var viewEditTwitterAccount: UIView!
    @IBOutlet weak var viewEditUserWebsite: UIView!
    @IBOutlet weak var viewBottomBar: UIView!
    
    @IBOutlet weak var constraintUserWebHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintUserNameHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintUserDescHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintBottomBar: NSLayoutConstraint!
    var user: MIUser?
    
    var userName : MIProfileEditUserName!
    var userDescription: MIProfileEditUserName!
    var userFacebookAccount: MIProfileEditUserName!
    var userInstagramAccount: MIProfileEditUserName!
    var userTwitterAccount: MIProfileEditUserName!
    var userWebsite: MIProfileEditUserName!
    
    var isUserAvatarChanged = false
    var isUserNameChanged = false
    let imagePicker = UIImagePickerController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        // Do any additional setup after loading the view.
        
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Analytics:
        MIAnalyticsManager.logScreen(AnalyticsScreens.PROFILE_EDIT_PROFILE)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func setupUI() {
        
        //Observe keyboard notifications to calculate table view height
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrameNotification), name: .UIKeyboardWillChangeFrame, object: nil)
        
        // set backgroundColor
        view.backgroundColor = Color.TUTORIAL_BACKGROUND_TOP
        
        //New Added Code
        viewBottomBar.backgroundColor = Color.TUTORIAL_BACKGROUND_TOP
        
        
        
        // config
        let remoteConfig = MIManager.manager.remoteConfig()
        
        // user name
        if !(user?.isHandleSet)! {
            userName = createMIProfileEditView()
            userName.isExistMinMax = true
            userName.text = (user?.profileDisplayName)!
            userName.editType = ProfileEditType.UserName
            userName.maxSymbols = (remoteConfig["username_string_max_length"].numberValue?.intValue)!
            userName.minSymbols = (remoteConfig["username_string_min_length"].numberValue?.intValue)!
            userName.regExpression = remoteConfig["username_string_pattern"].stringValue!
            viewEditUserName.addSubview(userName)
            fillSubviewToParent(userName)
        } else {
            constraintUserNameHeight.constant = 0
        }
        
        // user description
        userDescription = createMIProfileEditView()
        userDescription.isWebSiteEdit = true
        userDescription.isExistMinMax = true
        userDescription.placeHolder = Profile.PLACEHOLDER_DESCRIPTION
        userDescription.fontSize = 16
        userDescription.isJustify = true
        userDescription.text = (user?.biography)!
        userDescription.maxSymbols = 500
        userDescription.minSymbols = 1
        userDescription.editType = ProfileEditType.UserDescription
        viewEditUserDescription.addSubview(userDescription)
        fitParent(viewEditUserName, ToSubView: userDescription)
        
        userDescription.textViewDidChange(userDescription.txtName)
        
        userDescription.changeTextViewHeightHandler = { () -> Void in
            self.constraintUserDescHeight.constant = self.userDescription.frame.size.height
        }
        
        // user facebook account
        userFacebookAccount = createMIProfileEditView()
        userFacebookAccount.placeHolder = Profile.PLACEHOLDER_FACEBOOK
        if let link = user?.links {
            userFacebookAccount.text = (link.fbId)
        }
        userFacebookAccount.editType = ProfileEditType.FacebookAccount
        userFacebookAccount.regExpression = remoteConfig["social_media_input_regexp"].stringValue!
        userFacebookAccount.txtName.textContainer.maximumNumberOfLines = 2
        userFacebookAccount.txtName.textContainer.lineBreakMode = .byTruncatingTail
        viewEditFaceBookAccount.addSubview(userFacebookAccount)
        fillSubviewToParent(userFacebookAccount)
        
        
        // user instagram account
        userInstagramAccount = createMIProfileEditView()
        userInstagramAccount.placeHolder = Profile.PLACEHOLDER_INSTAGRAM
        if let link = user?.links {
            userInstagramAccount.text = (link.igId)
        }
        userInstagramAccount.editType = ProfileEditType.InstagramAccount
        userInstagramAccount.txtName.textContainer.maximumNumberOfLines = 2
        userInstagramAccount.txtName.textContainer.lineBreakMode = .byTruncatingTail
        userInstagramAccount.regExpression = remoteConfig["social_media_input_regexp"].stringValue!
        viewEditInstagramAccount.addSubview(userInstagramAccount)
        fillSubviewToParent(userInstagramAccount)
        
        // user twitter account
        userTwitterAccount = createMIProfileEditView()
        userTwitterAccount.placeHolder = Profile.PLACEHOLDER_TWITTER
        if let link = user?.links {
            userTwitterAccount.text = (link.twId)
        }
        userTwitterAccount.editType = ProfileEditType.TwitterAccount
        userTwitterAccount.txtName.textContainer.maximumNumberOfLines = 2
        userTwitterAccount.txtName.textContainer.lineBreakMode = .byTruncatingTail
        userTwitterAccount.regExpression = remoteConfig["social_media_input_regexp"].stringValue!
        viewEditTwitterAccount.addSubview(userTwitterAccount)
        fillSubviewToParent(userTwitterAccount)
        
        // user website account
        userWebsite = createMIProfileEditView()
        userWebsite.placeHolder = Profile.PLACEHOLDER_SITE
        userWebsite.maxSymbols = 100
        userWebsite.minSymbols = 1
        userWebsite.editType = ProfileEditType.UserWebsite
        userWebsite.isWebSiteEdit = true
        userWebsite.isJustify = true
        if let link = user?.links {
            userWebsite.text = (link.pUrl)
        }
        
        viewEditUserWebsite.addSubview(userWebsite)
        fitParent(viewEditUserName, ToSubView: userWebsite)
        userWebsite.textViewDidChange(userWebsite.txtName)
        
        
        
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 1) {
            self.constraintUserDescHeight.constant = self.userDescription.frame.size.height
            self.constraintUserWebHeight.constant = self.userWebsite.frame.size.height
            self.view.layoutIfNeeded()
        }
        
        userWebsite.changeTextViewHeightHandler = { () -> Void in
            self.constraintUserWebHeight.constant = self.userWebsite.frame.size.height
        }
     
        imgAvatar.kf.setImage(with: URL(string: (user?.profilePictureUrl)!))
    }
    
    
    private func createMIProfileEditView() -> MIProfileEditUserName{
        
        let edtView = Bundle.main.loadNibNamed("ProfileEditUserName", owner: nil, options: [:])?.first as! MIProfileEditUserName
        
        return edtView
    }
    
    private func fillSubviewToParent(_ view : UIView) {
        view.snp.makeConstraints{ (make) -> Void in
            
            make.edges.equalToSuperview()
        }
    }
    
    private func fitParent (_ parentView : UIView, ToSubView subView : UIView) {
        
        subView.snp.makeConstraints { (make) -> Void in
            
            make.width.equalTo(parentView)
            make.centerX.equalTo(parentView)
            make.top.equalToSuperview()
        }
    }
    
    
    //MARK: change avatar image
    
    func showAlertForCameraOrGallery(){
        
        let alert = MISelectCoverActionSheet(title: nil, message: nil, style: .actionSheet)
        alert.addTextFieldWithConfigurationHandler() { textField in
            textField?.frame.size.height = Size.CREATE_PLAYLIST_COVER_ACTION_SHEET
            textField?.backgroundColor = nil
            textField?.textColor = UIColor.black
            textField?.layer.borderColor = nil
            textField?.layer.borderWidth = 0
            textField?.font = Font.CREATE_PLAYLIST_COVER_ACTION_SHEET
        }
        
        
        alert.configContentView = { view in
            if let view = view as? AlertContentView {
                view.titleLabel.font = UIFont.boldSystemFont(ofSize: 0)
                view.messageLabel.font = UIFont.boldSystemFont(ofSize: 0)
                view.textBackgroundView.layer.cornerRadius = 3.0
                view.textBackgroundView.clipsToBounds = true
                view.layer.cornerRadius = 12
                
            }
        }
        
        alert.configContainerWidth = {
            
            return self.view.bounds.size.width - 2*38
            
        }
        
        alert.configContainerCornerRadius = {
            
            return 8
            
        }
        
        alert.addAction(AlertAction(title: "Camera Roll", style: .default, handler: { action in
            
            self.showCameraOrGallary(false)
            
        }))
        
        alert.addAction(AlertAction(title: "Take a photo", style: .default, handler: { action in
            
            self.showCameraOrGallary(true)
            
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    func showCameraOrGallary(_ isCamera:Bool) {
        
        if isCamera && !UIImagePickerController.isSourceTypeAvailable(.camera){
            
            let alert  = UIAlertController(title: "Warning", message: "You don't have camera", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        imagePicker.delegate = self
        imagePicker.sourceType = isCamera ? .camera : .photoLibrary;
        imagePicker.allowsEditing = true
        
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func validateUserInfo() -> Bool {
        
        if !(user?.isHandleSet)! {
            if user?.profileDisplayName != userName.getTextValue() {
                if Global.validateString(pattern: userName.regExpression, compare: userName.getTextValue()) {
                    isUserNameChanged = true
                } else {
                    return false
                }
            }
        }
        
        if !Global.validateString(pattern: userFacebookAccount.regExpression, compare: userFacebookAccount.getTextValue()) {
            return false
        }
        
        if !Global.validateString(pattern: userTwitterAccount.regExpression, compare: userTwitterAccount.getTextValue()) {
            return false
        }
        
        if !Global.validateString(pattern: userInstagramAccount.regExpression, compare: userInstagramAccount.getTextValue()) {
            return false
        }
        
        if userWebsite.getTextValue().characters.count == 0 {
            
        } else {
            if !(Global.verifyUrl(urlString:userWebsite.getTextValue()) && !Global.isContainsCaptalizeCharacter(text: userWebsite.getTextValue())){
                return false
            }
        }
        
        
        
        return true
    }
    
    @IBAction func onClickBtnCancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func onClickBtnChangePicture(_ sender: Any) {
        
        showAlertForCameraOrGallery()
    }
    
    @IBAction func onClickBtnSave(_ sender: Any) {
        
        if !validateUserInfo() {
            return
        }
        
        if isUserAvatarChanged {

            let avatar = UIImageJPEGRepresentation(imgAvatar.image!, 0.5)
            
            MIManager.manager.uploadUserAvatar(userId: "me", avatar: avatar!, completion: {(user:MIUser) in
                if user.id != 0 {
                    if self.isUserNameChanged {
                        self.updateUserName()
                    }
                    else {
                        self.updateUserInfo()
                    }
                }else {
                    log.error("Failed to update avatar")
                }
            })
        } else {
            if self.isUserNameChanged {
                self.updateUserName()
            }
            else {
                self.updateUserInfo()
            }

        }
    }
    
    private func updateUserName() {
        MIManager.manager.updateUseName(userName: userName.getTextValue(), completion: {(status:Bool, message:String) in
            if status {
                self.updateUserInfo()
                self.isUserNameChanged = false
            } else {
                log.error("Failed to update avatar")
            }
        })
    }
    
    private func updateUserInfo() {
        
        //New Added Code
        
        var pUrlTemp = ""
        
        if userWebsite.getTextValue().characters.count > 0 {
            if !userWebsite.getTextValue().contains("http://") && !userWebsite.getTextValue().contains("https://") {
                
                pUrlTemp = "http://\(userWebsite.getTextValue())"
                
            } else {
                pUrlTemp = userWebsite.getTextValue()
            }
        }
        
        let params = [
            "biography": userDescription.getTextValue(),
            "links": [
                "igId": userInstagramAccount.getTextValue(),
                "pUrl": pUrlTemp,
                "twId": userTwitterAccount.getTextValue(),
                "fbId": userFacebookAccount.getTextValue()
            ],
            "marketId": user?.marketId ?? 1
        ] as [String : Any]
        
        MIManager.manager.updateUserInfoWithUserId(userId: "me", params: params, completion: {(user: MIUser, message:String) in
            
            if user.id != 0 {
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                log.error("Failed to update user info")
            }
        })
    }

    @IBAction func onClickAvatar(_ sender: Any) {
        showAlertForCameraOrGallery()
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: false) {
            if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
                self.imgAvatar?.image = image
            } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.imgAvatar?.image = image
            }
            self.isUserAvatarChanged = true
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false) {
        }
    }
    
    //MARK: Keyborad notifications
    func keyboardWillShow(notification: NSNotification) {
        
        self.constraintBottomBar.constant = 0
        
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let keyboardHeight = keyboardSize.height
            
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 1) {
                self.constraintBottomBar.constant = self.constraintBottomBar.constant + keyboardHeight
                self.view.layoutIfNeeded()
            }
            
        }
        
    }
    
    func keyboardWillChangeFrameNotification(notification: NSNotification) {
        
        keyboardWillShow(notification:notification)
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 1) {
            self.constraintBottomBar.constant = 0
            self.view.layoutIfNeeded()
        }
        
    }
}
