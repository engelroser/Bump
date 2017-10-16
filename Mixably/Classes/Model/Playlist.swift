//
//  MIPlaylist.swift
//  Mixably
//
//  Created by Mobile App Dev on 7/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import ObjectMapper

/**
 MIPlaylist keeps info about each playlist. Parsed from feed response
 */

class MIPlaylist: Mappable,Equatable{
    
    var id = 0
    var href = ""
    
    var owner: MIUser?
    var artwork = ""
    var tracks = [MITrack]()
    var playedTracks = [MITrack]()

    var artworkId = 0
    
    var title = ""
    var caption = ""
    
    var hearts = 0
    var isHearted = false
    
    var plays = 0
    var comments = 0

    var isPrivate = false
    var socialNetworks = [String]()

    var tags = [MITag]()

    //AD
    var isAd = false
    var adURL = ""
    var eventArtist = ""
    var eventTime = ""
    var eventLocation = ""
    
    required convenience init?(map: Map) { self.init() }
    
    func mapping(map: Map) {
        
        id                  <- map["id"]
        href                <- map["href"]
        
        owner               <- map["creator"]
        artwork             <- map["imageUrl"]
        tracks              <- map["tracks"]

        title               <- map["name"]
        caption             <- map["caption"]

        hearts              <- map["likeCount"]
        isHearted           <- map["isLiked"]
        
        plays               <- map["playCount"]
        
        var parsedtags:[String]?
        parsedtags             <- map["tags"]
        
        if parsedtags != nil{
            
            for tag in parsedtags!{
                
                let newTag = MITag()
                newTag.name = tag
                
                tags.append(newTag)
                
            }

        }
        
        //AD
        isAd               <- map["isAd"]
        adURL              <- map["adUrl"]
        
        eventArtist        <- map["eventArtist"]
        eventTime          <- map["eventTime"]
        eventLocation      <- map["eventLocation"]

    }

    static func == (left: MIPlaylist, right: MIPlaylist) -> Bool {
        return left.id == right.id
    }
    
}
