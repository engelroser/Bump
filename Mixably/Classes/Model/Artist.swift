//
//  MIArtist.swift
//  Mixably
//
//  Created by Mobile App Dev on 12/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import ObjectMapper

/**
 MIArtist keeps info about an artist
 */

class MIArtist: Mappable{
    
    var name = ""
    var artworkUrl = ""
    var id = ""

    var tracks = [MITrack]()

    required convenience init?(map: Map) { self.init() }
    
    func mapping(map: Map) {
        
    }
    
}
