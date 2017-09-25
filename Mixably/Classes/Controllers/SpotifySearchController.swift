//
//  SpotifySearchController.swift
//  Mixably
//
//  Created by Mobile App Dev on 26/6/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import SwiftHTTP

class SpotifySearchController: SearchProtocol {

    func search(queryString: String, contentTypes: String, offset: Int, completion: @escaping (_ result: MISearchResponse) -> Void) {
        
        do {
            
            var defaultLimit = Config.SEARCH_TRACKS_START_LIMIT
            
            if offset != 0{
                
                defaultLimit = Config.SEARCH_TRACKS_PAGINATION
                
            }
            
            let url = String("\(API.SPOTIFY_BASE)search?q=\(String(describing: queryString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!))&type=\(contentTypes)&limit=\(defaultLimit)&offset=\(offset)")
            
            let headers = ["Authorization":String(" Bearer \(MIManager.manager.userMssps().token)")] as [String:String]
            
            let opt = try HTTP.New(url!, method: .GET, parameters: nil, headers: headers)
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error for Spotify search: \(err.localizedDescription)")
                    completion(MISearchResponse())
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MISearchResponse())
                    return
                    
                }
                
                log.debug("Response for Spotify search : \n\(responseDictionary)\n")
                
                let searchResponse = MISearchResponse()
                
                if let tracks = responseDictionary["tracks"] as? [String:Any]{
                    
                    if let trackItems = tracks["items"] as? [[String:Any]]{
                        
                        for itemDictionary in trackItems{
                            
                            let newTrack = self.parseSpotifyTrack(trackDictionary:itemDictionary)
                            searchResponse.tracks.append(newTrack)
                            
                            if newTrack.previewUrl == ""{
                                
                                self.detailsForSpotifyTrack(trackId: newTrack.trackId, completion: { track in
                                    
                                    newTrack.previewUrl = track.previewUrl
                                    
                                })
                                
                            }
                            
                        }
                        
                    }
                }
                
                if let artists = responseDictionary["artists"] as? [String:Any]{
                    
                    if let artistItems = artists["items"] as? [[String:Any]]{
                        
                        for itemDictionary in artistItems{
                            
                            let newArtist = self.parseSpotifyArtist(artistDictionary:itemDictionary)
                            searchResponse.artist.append(newArtist)
                            
                        }
                        
                    }
                }
                
                if let artists = responseDictionary["albums"] as? [String:Any]{
                    
                    if let artistItems = artists["items"] as? [[String:Any]]{
                        
                        for itemDictionary in artistItems{
                            
                            let newAlbum = self.parseSpotifyAlbum(albumDictionary:itemDictionary)
                            searchResponse.albums.append(newAlbum)
                            
                        }
                        
                    }
                }
                
                completion(searchResponse)
                
            }
            
        } catch let error {
            
            log.error("Got an error for Spotify search \(error)")
            completion(MISearchResponse())
            
        }
        
    }
    
    func searchForArtist(artist: MIArtist, completion: @escaping (_ result: MIArtist) -> Void) {
        
        do {
            
            let url = String("\(API.SPOTIFY_BASE)artists/\(artist.id)/albums")
            
            let headers = ["Authorization":String(" Bearer \(MIManager.manager.serverManager.musicProvider.token)")] as [String:String]
            
            let opt = try HTTP.New(url!, method: .GET, parameters: nil, headers: headers)
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error for Spotify search: \(err.localizedDescription)")
                    completion(MIArtist())
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MIArtist())
                    return
                    
                }
                
                if let trackItems = responseDictionary["items"] as? [[String:Any]]{
                    
                    var albumsToLoad = trackItems.count

                    for itemDictionary in trackItems{
                        
                        let album = self.parseSpotifyAlbum(albumDictionary: itemDictionary)
                        
                        self.searchForAlbum(album: album, completion: {
                            
                            result in
                            
                            for track in result.tracks {
                                
                                if artist.tracks.first(where: { $0.name == track.name }) == nil {
                                    
                                    artist.tracks.append(track)
                                    
                                }
                                
                            }
                                                        
                            albumsToLoad -= 1
                            
                            //Check if all albums was loaded
                            if albumsToLoad == 0{
                                
                                completion(artist)

                            }
                            
                        })
                        
                    }
                    
                }
                
            }
            
        } catch let error {
            
            log.error("Got an error for Spotify search \(error)")
            completion(MIArtist())
            
        }
    }
    
    func searchForAlbum(album: MIAlbum, completion: @escaping (_ result: MIAlbum) -> Void) {
        
        do {
            
            let url = String("\(API.SPOTIFY_BASE)albums/\(album.id)/tracks")
            
            let headers = ["Authorization":String(" Bearer \(MIManager.manager.serverManager.musicProvider.token)")] as [String:String]
            
            let opt = try HTTP.New(url!, method: .GET, parameters: nil, headers: headers)
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error for Spotify search: \(err.localizedDescription)")
                    completion(MIAlbum())
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MIAlbum())
                    return
                    
                }
                
                if let trackItems = responseDictionary["items"] as? [[String:Any]]{
                    
                    for itemDictionary in trackItems{
                        
                        let newTrack = self.parseSpotifyTrack(trackDictionary:itemDictionary)
                        
                        if album.tracks.first(where: { $0.trackId == newTrack.trackId }) == nil {
                            
                            album.tracks.append(newTrack)
                            
                        }
                    }
                    
                }
                
                completion(album)
                
            }
            
        } catch let error {
            
            log.error("Got an error for Spotify search \(error)")
            completion(MIAlbum())
            
        }
        
    }
    
    
    
    
    
    
    
    private func parseSpotifyTrack(trackDictionary: [String:Any]) -> MITrack{
        
        let newTrack = MITrack()
        
        if let name = trackDictionary["name"] as? String{
            
            newTrack.name = name
            
        }
        
        if let uri = trackDictionary["uri"] as? String{
            
            newTrack.trackId = uri
            
        }
        
        if let previewUrl = trackDictionary["preview_url"] as? String{
            
            newTrack.previewUrl = previewUrl
            
        }
        
        do {
            
            let jsonData: NSData = try JSONSerialization.data(withJSONObject: trackDictionary, options: JSONSerialization.WritingOptions(rawValue: 0)) as NSData
            newTrack.rawData = NSString(data: jsonData as Data, encoding: String.Encoding.utf8.rawValue)! as String
            
        } catch {
            print(error.localizedDescription)
        }
        
        if let artistArray = trackDictionary["artists"] as? [[String:Any]]{
            
            for artistDictionary in artistArray{
                
                if let artistName = artistDictionary["name"] as? String{
                    
                    let newArtist = MIArtist()
                    newArtist.name = artistName
                    
                    newTrack.artistNames.append(newArtist)
                    
                }
                
            }
            
        }
        
        
        return newTrack
    }
    
    /**
     Parse Spotify artist dictionary to MIArtist object
     -parameter artistDictionary: dictionary to parse
     */
    private func parseSpotifyArtist(artistDictionary: [String:Any]) -> MIArtist{
        
        let newArtist = MIArtist()
        
        if let name = artistDictionary["name"] as? String{
            
            newArtist.name = name
            
        }
        
        if let id = artistDictionary["id"] as? String{
            
            newArtist.id = id
            
        }
        
        if let images = artistDictionary["images"] as? [[String:Any]]{
            
            if let artwork = images.first{
                
                if let url = artwork["url"] as? String{
                    
                    newArtist.artworkUrl = url
                    
                }
                
            }
            
        }
        
        return newArtist
    }
    
    /**
     Parse Spotify album dictionary to MIAlbum object
     -parameter albumDictionary: dictionary to parse
     */
    private func parseSpotifyAlbum(albumDictionary: [String:Any]) -> MIAlbum{
        
        let newAlbum = MIAlbum()
        
        if let name = albumDictionary["name"] as? String{
            
            newAlbum.name = name
            
        }
        
        if let id = albumDictionary["id"] as? String{
            
            newAlbum.id = id
            
        }
        
        if let images = albumDictionary["images"] as? [[String:Any]]{
            
            if let artwork = images.first{
                
                if let url = artwork["url"] as? String{
                    
                    newAlbum.artworkUrl = url
                    
                }
                
            }
            
        }
        
        if let artists = albumDictionary["artists"] as? [[String:Any]]{
            
            if let artist = artists.first{
                
                if let artistName = artist["name"] as? String{
                    
                    newAlbum.artistName = artistName
                    
                }
                
            }
            
        }
        
        return newAlbum
    }
    
    
    public func detailsForSpotifyTrack(trackId:String, completion: @escaping (_ result: MITrack) -> Void) {
        
        do {
            
            //Remove spotify:track: from track id
            let trackIdToSearch = trackId.replacingOccurrences(of: "spotify:track:", with: "")
            let url = String("\(API.SPOTIFY_BASE)tracks/\(trackIdToSearch)")
            
            let headers = ["Authorization":String(" Bearer \(MIManager.manager.serverManager.musicProvider.token)")] as [String:String]
            
            let opt = try HTTP.New(url!, method: .GET, parameters: nil, headers: headers)
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error for Spotify search: \(err.localizedDescription)")
                    completion(MITrack())
                    
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                //Check if have a valid dictionary
                guard let responseDictionary = jsonRootObject as? [String: Any] else{
                    
                    log.error("Cannot parse response data")
                    completion(MITrack())
                    return
                    
                }
                
                
                let newTrack = self.parseSpotifyTrack(trackDictionary:responseDictionary)
                completion(newTrack)
                
            }
            
        } catch let error {
            
            log.error("Got an error for Spotify search \(error)")
            completion(MITrack())
            
        }
        
    }

}
