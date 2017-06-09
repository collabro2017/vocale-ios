//
//  WhoTableViewCell.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 9/2/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class WhoTableViewCell: UITableViewCell {

    @IBOutlet weak var bothSignButton: UIButton!
    @IBOutlet weak var femaleSignButton: UIButton!
    @IBOutlet weak var maleSignButton: UIButton!
    
    @IBAction func maleButtonTapped(sender: UIButton) {
        maleSignButton.selected = true
        femaleSignButton.selected = false
        bothSignButton.selected = false
    }
    
    @IBAction func femaleButtonTapped(sender: UIButton) {
        maleSignButton.selected = false
        femaleSignButton.selected = true
        bothSignButton.selected = false
    }
    
    @IBAction func bothButtonTapped(sender: UIButton) {
        maleSignButton.selected = false
        femaleSignButton.selected = false
        bothSignButton.selected = true
    }
}
