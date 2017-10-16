//
//  MILinks.swift
//  Mixably
//
//  Created by Mobile App Developer on 05/04/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation
import ObjectMapper

class MILinks: Mappable{

    var pUrl = ""
    var twId = ""
    var igId = ""
    var fbId = ""
    
    required convenience init?(map: Map) { self.init() }
    
    func mapping(map: Map) {
        pUrl        <- map["pUrl"]
        twId        <- map["twId"]
        igId        <- map["igId"]
        fbId        <- map["fbId"]
    }
}
