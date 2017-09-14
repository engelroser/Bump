//
//  MIContactViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 16/06/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

class MIContactViewController: UIViewController {

    //Data
    var type:ContactType = .contactTeam
    
    init(type: ContactType){
        
        super.init(nibName: nil, bundle: nil)
        
        self.type = type
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
    }

    //MARK: UI
    private func setupUI(){
        
        view.backgroundColor = Color.CONTACT_BACKGROUND
        
        createContentView()
        
    }
    
    private func createContentView(){
        
        var contactView = MIContactViewBase()
        
        switch type{
            case .contactTeam:
                contactView = MIContactOurTeamView(frame: view.bounds)
            case .reportBug:
                contactView = MIReportBugView(frame: view.bounds)
            case .suggestIdea:
                contactView = MISuggestIdeasView(frame: view.bounds)
        }
        
        view.addSubview(contactView)

    }
    
    //MARK: Internal
    override var prefersStatusBarHidden: Bool {
        
        return true
        
    }
    
}
