//
//  MIHomePageViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 02/06/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import GradientView

//We don't use UIPageController here because we need to know scrollView offset for animation. We can handle offset at UIPageController but it works very strange

class MIHomePageViewController: BaseViewController, UIScrollViewDelegate {

    //UI
    private var controllers = [UIViewController]()
    private var homeViewController = MIHomeViewController()
    private let scrollView = UIScrollView()
    
    //Data
    private var lastContentOffset: CGFloat = 0

    override func viewDidLoad() {

        super.viewDidLoad()
        
        //detect the app version and show update alert
        setupAlertUI()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showUserProfile),
                                               name: NSNotification.Name(rawValue: Notifications.SHOW_MY_PROFILE),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showHome),
                                               name: NSNotification.Name(rawValue: Notifications.SHOW_HOME),
                                               object: nil)
        
        
        setupUI()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        var index:CGFloat = 0
        
        for controller in controllers{
            
            let viewFrame = CGRect(x:index*view.bounds.size.width, y:0.0,width:view.bounds.size.width, height:view.bounds.size.height)
            controller.view.frame = viewFrame
            
            index += 1
            
        }
        
    }
    
    private func setupAlertUI() {
        let currentAppVersion = MIManager.manager.getCurrentAppVersion()
        let remoteConfig = MIManager.manager.remoteConfig()
        
        if let remoteConfigAppVersionStr = remoteConfig[Config.LATEST_APP_VERSION].stringValue, let remoteConfigAppVersion = Int(remoteConfigAppVersionStr){
    
            if currentAppVersion < remoteConfigAppVersion {
                DispatchQueue.main.async{
                    MIManager.manager.createUpdateAlertWithConfig()
                }
            }
            
        }
        
    }
    
    private func setupUI(){
        
        let profileStoryboard = UIStoryboard(name: "Profile", bundle: nil)
        let profileVC = profileStoryboard.instantiateViewController(withIdentifier: "MIProfileViewController")
        (profileVC as! MIProfileViewController).userId = "me"
        controllers.append(profileVC)
        
        controllers.append(homeViewController)
        
        createGradientBackground()
        
        //Please, read a note above about why we don't use UIPageViewController
        scrollView.frame = view.bounds
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentSize = CGSize(width:view.bounds.size.width*CGFloat(controllers.count), height:view.bounds.size.height)
        view.addSubview(scrollView)
        
        var index:CGFloat = 0
        
        for controller in controllers{
            
            let viewFrame = CGRect(x:index*view.bounds.size.width, y:0.0,width:view.bounds.size.width, height:view.bounds.size.height)
            controller.view.frame = viewFrame
            scrollView.addSubview(controller.view)
            
            index += 1
            
        }
        
        scrollView.setContentOffset(CGPoint(x: view.bounds.size.width, y: 0), animated: false)

    }

    //MARK: ScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {

        var direction: ScrollDirection = .left
        
        if (self.lastContentOffset > scrollView.contentOffset.x) {

            direction = .right
        
        }
        else if (self.lastContentOffset < scrollView.contentOffset.x) {

            direction = .left
        
        }
        
        // update the new position acquired
        self.lastContentOffset = scrollView.contentOffset.y
                
        for controller in controllers{
            
            if let controllerDelegate = controller as? MIViewControllerDelegate {

                controllerDelegate.updateUI(offset: scrollView.contentOffset.x, direction:direction)
            
            }
            
        }
        
    }
    
    //MARK: Notifications
    func showUserProfile(notification: Notification) {
        
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)

    }
    
    func showHome(notification: Notification) {
        
        scrollView.setContentOffset(CGPoint(x: view.bounds.size.width, y: 0), animated: true)
        
    }
    
    //MARK: Internal
    private func createGradientBackground(){
        
        let gradientView = GradientView(frame: view.bounds)
        gradientView.colors = [Color.TUTORIAL_BACKGROUND_TOP, Color.TUTORIAL_BACKGROUND_BOTTOM]
        gradientView.locations = [0.5, 1.0]
        gradientView.direction = .vertical
        view.insertSubview(gradientView, at: 0)
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
