//
//  AppleMusicSearchController.swift
//  Mixably
//
//  Created by Mobile App Dev on 26/6/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import SwiftHTTP

class AppleMusicSearchController: SearchProtocol {

    func search(queryString: String, contentTypes: String, offset: Int, completion: @escaping (_ result: MISearchResponse) -> Void) {
        
        let defaultLimit = offset != 0 ? Config.SEARCH_TRACKS_PAGINATION : Config.SEARCH_TRACKS_START_LIMIT
        
        guard let escapedQuery = queryString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return completion(MISearchResponse())
        }
        
        let contentTypesArray = contentTypes.components(separatedBy: [",", " "])
        let appleMusicContentTypesArray = contentTypesArray.map { (contentType: String) -> String in
            if contentType == "artist" {
                return "musicArtist"
            } else if contentType == "track" {
                return "song"
            }
            return contentType
        }
        let appleMusicContentTypes = appleMusicContentTypesArray.joined(separator: ",")
        
        let url = "\(API.APPLE_MUSIC_BASE)search?media=music&term=\(escapedQuery)&entity=\(appleMusicContentTypes)&limit=\(defaultLimit)"
        
        getResults(url: url, completion: completion)
    }
    
    func searchForArtist(artist: MIArtist, completion: @escaping (_ result: MIArtist) -> Void) {
        
        let url = "\(API.APPLE_MUSIC_BASE)lookup?sort=recent&entity=song&media=music&id=\(artist.id)&limit=200"
        
        getResults(url: url, completion: { result in
            
            guard result.artist.count > 0 else {
                return completion(artist)
            }
            
            let artistWithTracks: MIArtist = result.artist[0]
            
            for track in result.tracks {
                
                if artistWithTracks.tracks.first(where: { $0.name == track.name }) == nil {
                    
                    artistWithTracks.tracks.append(track)
                    
                }

            }
            
            return completion(artistWithTracks)
        })
    }
    
    func searchForAlbum(album: MIAlbum, completion: @escaping (_ result: MIAlbum) -> Void) {
        
        let url = "\(API.APPLE_MUSIC_BASE)lookup?sort=recent&entity=song&media=music&id=\(album.id)"
        
        getResults(url: url, completion: { result in
            
            guard result.albums.count > 0 else {
                return completion(album)
            }
            
            let albumWithTracks: MIAlbum = result.albums[0]
            
            for track in result.tracks {
                albumWithTracks.tracks.append(track)
            }
            
            return completion(albumWithTracks)
        })
    }
    
    func getResults(url: String, completion: @escaping (_ result: MISearchResponse) -> Void) {
        
        let searchResponse = MISearchResponse()
        
        do {
            
            let opt = try HTTP.New(url, method: .GET, parameters: nil, headers: nil)
            
            opt.start { response in
                
                if let err = response.error {
                    
                    log.error("Got an error for Apple Music search: \(err.localizedDescription)")
                    completion(searchResponse)
                    return
                    
                }
                
                let jsonRootObject = try? JSONSerialization.jsonObject(with: response.data, options: [])
                
                guard let responseDictionary = jsonRootObject as? [String: Any] else {
                    
                    log.error("Cannot parse response data for Apple Music search")
                    completion(searchResponse)
                    return
                    
                }
                
                guard let results = responseDictionary["results"] as? [[String: Any]] else {
                    return completion(searchResponse)
                }
                
                self.extractTracks(results, in: searchResponse)

                self.extractArtists(results, in: searchResponse)
                
                self.extractAlbums(results, in: searchResponse)
                
                completion(searchResponse)
                
            }
            
        } catch let error {
            
            log.error("Got an error for Apple Music search \(error)")
            completion(MISearchResponse())
            
        }
    }
    
    func extractTracks(_ results: [[String: Any]], in searchResponse: MISearchResponse) -> Void {
        
        let songs = results.filter {
            $0["wrapperType"] as? String == "track"
        }
        
        for song in songs {
            let parsedTrack = self.parse(song: song)
            searchResponse.tracks.append(parsedTrack)
        }
    }
    
    func parse(song: [String: Any]) -> MITrack {
        
        let parsedTrack = MITrack()
        
        if let trackName = song["trackName"] as? String {
            parsedTrack.name = trackName
        }
        
        // TODO: Remove unnecessary formatting in track ID for Apple Music.
        if let trackId = song["trackId"] as? Int {
            parsedTrack.trackId = "itunes:track:\(trackId)"
        }
        
        if let previewUrl = song["previewUrl"] as? String {
            parsedTrack.previewUrl = previewUrl
        }
        
        if let artistName = song["artistName"] as? String {
            let artist = MIArtist()
            artist.name = artistName
            parsedTrack.artistNames.append(artist)
        }
        
        do {
            let jsonData: NSData = try JSONSerialization.data(withJSONObject: song, options: JSONSerialization.WritingOptions(rawValue: 0)) as NSData
            parsedTrack.rawData = String(data: jsonData as Data, encoding: String.Encoding.utf8)!
        } catch {
            print(error.localizedDescription)
        }
        
        return parsedTrack
    }
 
    func extractArtists(_ results: [[String: Any]], in searchResponse: MISearchResponse) -> Void {
        
        let artists = results.filter {
            $0["wrapperType"] as? String == "artist"
        }
        
        for artist in artists {
            let parsedArtist = self.parse(artist: artist)
            searchResponse.artist.append(parsedArtist)
        }
    }
    
    func parse(artist: [String: Any]) -> MIArtist {

        let parsedArtist = MIArtist()
        
        if let artistName = artist["artistName"] as? String {
            parsedArtist.name = artistName
        }
        
        if let artistId = artist["artistId"] as? Int {
            parsedArtist.id = "\(artistId)"
        }
        
        // TODO: iTunes search returns no artwork for artists.
        if let artworkUrl = artist["artworkUrl"] as? String {
            parsedArtist.artworkUrl = artworkUrl
        }
        
        return parsedArtist
    }
    
    func extractAlbums(_ results: [[String: Any]], in searchResponse: MISearchResponse) -> Void {
        
        let albums = results.filter {
            $0["wrapperType"] as? String == "collection"
        }
        
        for album in albums {
            let parsedAlbum = self.parse(album: album)
            searchResponse.albums.append(parsedAlbum)
        }
    }
    
    func parse(album: [String: Any]) -> MIAlbum {
        
        let parsedAlbum = MIAlbum()
        
        if let collectionName = album["collectionName"] as? String {
            parsedAlbum.name = collectionName
        }
        
        if let collectionId = album["collectionId"] as? Int {
            parsedAlbum.id = "\(collectionId)"
        }
        
        if let artworkUrl = album["artworkUrl100"] as? String {
            parsedAlbum.artworkUrl = artworkUrl
        }
        
        if let artistName = album["artistName"] as? String {
            parsedAlbum.artistName = artistName
        }
        
        return parsedAlbum
    }
    
}
