//
//  MIMSSPS.swift
//  Mixably
//
//  Created by Mobile App Dev on 28/02/17.
//  Copyright © 2017 Mixably. All rights reserved.
//

import Foundation

/**
 MIMSSPS keeps info about a music provider (parsed from /mssps request)
 */

class MIMSSPS{
    
    var id:MusicProvider = .none
    var name = ""
    var isActive = false
    
    var token = ""
    var tokenExpirationDate: Double = 0 //time interval since 1970 (timeIntervalSince1970)
    
    var userId = ""

    var isPremiumRequired = false

}
