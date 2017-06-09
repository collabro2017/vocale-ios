//
//  AgeTableViewCell.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 9/2/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class AgeTableViewCell: UITableViewCell, TTRangeSliderDelegate {

    @IBOutlet weak var ageSlider: TTRangeSlider! {
        didSet {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.positiveSuffix = " years"
            ageSlider.numberFormatterOverride = numberFormatter
            ageSlider.selectedMaximum = Float(100)
            ageSlider.selectedMinimum = Float(18)
            ageSlider.tintColor = UIColor.vocaleIncomingTextColor()
            ageSlider.delegate = self
        }
    }
    
    // Mark: TTRangeSliderDelegate
    func rangeSlider(_: TTRangeSlider!, didChangeSelectedMinimumValue: Float, andMaximumValue: Float) -> Void {

    }
    
}
