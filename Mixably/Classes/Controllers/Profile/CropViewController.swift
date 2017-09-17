//
//  MICropViewController.swift
//  Mixably
//
//  Created by Mobile App Dev on 17/04/2017.
//  Copyright © 2017 Mixably. All rights reserved.
//

import UIKit
import IGRPhotoTweaks

class MICropViewController: IGRPhotoTweakViewController {

    /**
     Slider to change angel.
     */
    @IBOutlet weak fileprivate var angelSlider: UISlider?
    @IBOutlet weak fileprivate var angelLabel: UILabel?
    @IBOutlet weak fileprivate var horizontalDial: HorizontalDial? {
        didSet {
            self.horizontalDial?.migneticOption = .none
        }
    }
    
    // MARK: - Life Cicle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupSlider()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    fileprivate func setupSlider() {
        self.angelSlider?.minimumValue = -Float(IGRRadianAngle.toRadians(45))
        self.angelSlider?.maximumValue = Float(IGRRadianAngle.toRadians(45))
        self.angelSlider?.value = 0.0
        
        setupAngelLabelValue(radians: CGFloat((self.angelSlider?.value)!))
    }
    
    fileprivate func setupAngelLabelValue(radians: CGFloat) {
        let intDegrees: Int = Int(IGRRadianAngle.toDegrees(radians))
        self.angelLabel?.text = "\(intDegrees)°"
    }
    
    // MARK: - Actions
    
    @IBAction func onChandeAngelSliderValue(_ sender: UISlider) {
        let radians: CGFloat = CGFloat(sender.value)
        setupAngelLabelValue(radians: radians)
        self.changedAngle(value: radians)
        
    }
    
    @IBAction func onEndTouchAngelControl(_ sender: UIControl) {
        self.stopChangeAngle()
    }
    
    @IBAction func onTouchResetButton(_ sender: UIButton) {
        self.angelSlider?.value = 0.0
        self.horizontalDial?.value = 0.0
        setupAngelLabelValue(radians: 0.0)
        
        self.resetView()
    }
    
    @IBAction func onTouchCancelButton(_ sender: UIButton) {
        self.dismissAction()
    }
    
    @IBAction func onTouchCropButton(_ sender: UIButton) {
        cropAction()
    }
    
    
    @IBAction func onTouchAspectButton(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: nil,
                                            message: nil,
                                            preferredStyle: .actionSheet)
        
        
        actionSheet.addAction(UIAlertAction(title: "Original", style: .default) { (action) in
            self.resetAspectRect()
        })
        
        actionSheet.addAction(UIAlertAction(title: "Squere", style: .default) { (action) in
            self.setCropAspectRect(aspect: "1:1")
        })
        
        actionSheet.addAction(UIAlertAction(title: "2:3", style: .default) { (action) in
            self.setCropAspectRect(aspect: "2:3")
        })
        
        actionSheet.addAction(UIAlertAction(title: "3:5", style: .default) { (action) in
            self.setCropAspectRect(aspect: "3:5")
        })
        
        actionSheet.addAction(UIAlertAction(title: "3:4", style: .default) { (action) in
            self.setCropAspectRect(aspect: "3:4")
        })
        
        actionSheet.addAction(UIAlertAction(title: "5:7", style: .default) { (action) in
            self.setCropAspectRect(aspect: "5:7")
        })
        
        actionSheet.addAction(UIAlertAction(title: "9:16", style: .default) { (action) in
            self.setCropAspectRect(aspect: "9:16")
        })
        
        actionSheet.addAction(UIAlertAction(title: "9:16", style: .cancel))
        
        present(actionSheet, animated: true, completion: nil)
    }
}

extension MICropViewController: HorizontalDialDelegate {
    func horizontalDialDidValueChanged(_ horizontalDial: HorizontalDial) {
        let degrees = horizontalDial.value
        let radians = IGRRadianAngle.toRadians(CGFloat(degrees))
        
        self.setupAngelLabelValue(radians: radians)
        self.changedAngle(value: radians)
    }
    
    func horizontalDialDidEndScroll(_ horizontalDial: HorizontalDial) {
        self.stopChangeAngle()
    }
}

