//
//  SearchController.swift
//  Mixably
//
//  Created by Mobile App Dev on 26/6/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation

protocol SearchProtocol {
    
    func search(queryString: String, contentTypes: String, offset: Int, completion: @escaping (_ result: MISearchResponse) -> Void)
    
    func searchForArtist(artist: MIArtist, completion: @escaping (_ result: MIArtist) -> Void)
    
    func searchForAlbum(album: MIAlbum, completion: @escaping (_ result: MIAlbum) -> Void)
    
}

class SearchController {

    static var searcher: SearchProtocol = SpotifySearchController()

    class func set(_ musicProvider: MusicProvider) {
        
        switch MIManager.manager.userMssps().id {
            case .none:
                SearchController.searcher = AppleMusicSearchController()
                break
            case .spotify:
                SearchController.searcher = SpotifySearchController()
                break
            case .appleMusic:
                SearchController.searcher = AppleMusicSearchController()
                break

        }
    }
    
    class func search(queryString: String, contentTypes: String, offset: Int, completion: @escaping (_ result: MISearchResponse) -> Void) {
        searcher.search(queryString: queryString, contentTypes: contentTypes, offset: offset, completion: completion)
    }
    
    class func searchForArtist(artist: MIArtist, completion: @escaping (_ result: MIArtist) -> Void) {
        searcher.searchForArtist(artist: artist, completion: completion)
    }
    
    class func searchForAlbum(album: MIAlbum, completion: @escaping (_ result: MIAlbum) -> Void) {
        searcher.searchForAlbum(album: album, completion: completion)
    }
    
}
