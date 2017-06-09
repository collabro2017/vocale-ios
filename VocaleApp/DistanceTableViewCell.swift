//
//  DistanceTableViewCell.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 9/2/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class DistanceTableViewCell: UITableViewCell, TTRangeSliderDelegate {

    @IBOutlet weak var distanceSlider: TTRangeSlider! {
        didSet {
            distanceSlider.disableRange = true
            let numberFormatter = NSNumberFormatter()
            numberFormatter.positiveSuffix = " Miles"
            distanceSlider.numberFormatterOverride = numberFormatter
            distanceSlider.tintColor = UIColor.vocaleIncomingTextColor()
            
            distanceSlider.selectedMaximum = Float(200)
            distanceSlider.delegate = self
        }
    }
    
    // Mark: TTRangeSliderDelegate
    func rangeSlider(_: TTRangeSlider!, didChangeSelectedMinimumValue: Float, andMaximumValue: Float) -> Void {
        
    }
}
