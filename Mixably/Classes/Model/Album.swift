//
//  MIAlbum.swift
//  Mixably
//
//  Created by Mobile App Dev on 24/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import ObjectMapper

/**
 MIAlbum keeps info about an album
 */

class MIAlbum: Mappable{
    
    var id = ""
    var name = ""
    var artworkUrl = ""
    var artistName = ""

    var tracks = [MITrack]()

    required convenience init?(map: Map) { self.init() }
    
    func mapping(map: Map) {
        
    }
    
}
