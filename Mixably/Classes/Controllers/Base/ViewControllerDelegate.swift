//
//  MIBaseViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 05/06/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit

protocol MIViewControllerDelegate {

    //MARK: Annimations
    func updateUI(offset:CGFloat, direction:ScrollDirection)
    
}
