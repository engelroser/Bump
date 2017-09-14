//
//  MINewPlayListViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 18/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

class MINewPlayListViewController: BaseViewController {

    private var createPlayListContentView = MICreatePlayListView()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        createUI()
        
        view.isHidden = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if MIManager.manager.isMusicProviderConnected() == false{
            
            if let topController = UIApplication.topViewController(){
                
                let connectProviderController = ConnectMusicProviderViewController()
                
                topController.present(connectProviderController, animated: true, completion: {
                    
                    self.view.isHidden = false
                    
                })
                
            }
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.connectToMSSPCanceled), name: NSNotification.Name(rawValue: Notifications.USER_CANCEL_CONNECT_MUSIC_PROVIDER), object: nil)
            
        }else{
            
            self.view.isHidden = false

            //Show create playlist tutorial alert if needed
            MIUIUtilities.showTutorialAlertIfNeeded(title: NSLocalizedString("create_first_playlist", comment: "Create your first playlist"), message: Config.CREATE_PLAYLIST_TUTORIAL_ALERT, button: NSLocalizedString("got_it", comment: "Got it"))
            
            MIAnalyticsManager.logEvent(AnalyticsScreens.CREATION_START)

            
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func createUI() {
        
        //MIManager.manager.createEmptyPlaylist()
        
        createPlayListContentView = MICreatePlayListView(frame: view.bounds)
        view.addSubview(createPlayListContentView)
        
        //Check if an user reopens playlist
        if MIManager.manager.editingPlaylist().tracks.count > 0{
            
            setNextEnabled(isEnabled: true)
            
        }else{
            
            setNextEnabled(isEnabled: false)

        }

    }
    
    public func setNextEnabled(isEnabled: Bool){
        
        createPlayListContentView.isNextEnabled(isEnabled:isEnabled)
        
    }
    
    public func showPage(page: Int){
        
        createPlayListContentView.showPage(atIndex: page)
        
    }
    
    public func showNextScreen(){

        createPlayListContentView.showNextScreen()
        
    }
    
    //MARK: Connect music actions
    public func connectToMSSPCanceled(){
        
        view.isHidden = true

        dismiss(animated: true, completion: nil)
        
    }
    
    public func providerConnected(){
        
        MIUIUtilities.hideStandartLoader()

    }
    
}
