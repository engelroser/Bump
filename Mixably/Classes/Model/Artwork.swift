//
//  MIArtwork.swift
//  Mixably
//
//  Created by Mobile App Dev on 08/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import ObjectMapper

/**
 MIArtwork keeps info about a playlist artwork
 */

class MIArtwork: Mappable{
    
    var url = ""
    
    required convenience init?(map: Map) { self.init() }
    
    func mapping(map: Map) {
        
        url                         <- map["url"]
        
    }
    
}
