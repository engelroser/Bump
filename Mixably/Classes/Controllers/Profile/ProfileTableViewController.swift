//
//  MIProfileTableViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 01.04.17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

class MIProfileTableViewController: UITableViewController {
    
    var userId = ""
    var type:ProfilePlaylistType = .user
    var playLists = [MIPlaylist]()
    var owner = MIUser()
    
    public func initParam(_ userId:String, type:ProfilePlaylistType, owner:MIUser){
        
        self.userId = userId
        self.type = type
        self.owner = owner
                
        automaticallyAdjustsScrollViewInsets = false
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 90
        
        let nib = UINib(nibName: "ProfilePlayListTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ProfilePlayListTableViewCell")
        
        reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(playlistChanged(_:)), name: NSNotification.Name(rawValue: Notifications.PLAYLIST_CHANGED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_CONNECTED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: Notifications.MUSIC_PROVIDER_DISCONNECTED), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: Notifications.HIDE_PLAYLIST), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: Notifications.PLAYLIST_PLAYED), object: nil)

    }
    
    public func playlistChanged(_ notification:Notification){
        
        reloadData()
        
    }
    
    public func reloadData(){
        
        MIUIUtilities.showLoader(inView: self.view, center:CGPoint(x:UIScreen.main.bounds.size.width/2,y: 50))

        MIManager.manager.getUserPlayLists(userId: self.userId, offset: 0, type: self.type, completion: {(result:[MIPlaylist]) in
            
            DispatchQueue.main.sync {
                
                MIUIUtilities.hideLoader()
                
                self.playLists = result
                self.tableView.reloadData()
                
            }
            
        })
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        super.viewDidAppear(animated)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playLists.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = Bundle.main.loadNibNamed("ProfilePlayListTableViewCell", owner: nil, options: nil)?[0] as! MIProfilePlayListTableViewCell
        cell.updateCell(playList:(playLists[indexPath.row]), type:self.type, userId: self.userId)
        
        return cell
    }

    private func loadNextPlaylists(){
        
        let offset = playLists.count
        
        MIManager.manager.getUserPlayLists(userId: self.userId, offset: offset, type: self.type, completion: {(result:[MIPlaylist]) in
            
            DispatchQueue.main.sync {
                
                if self.playLists.count != result.count + offset{
                    
                    self.playLists.append(contentsOf: result)
                    self.tableView.reloadData()
                    
                }
                
            }
            
        })
        
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        
        if offsetY > contentHeight - scrollView.frame.size.height {
            
            loadNextPlaylists()

        }
        
    }
}
