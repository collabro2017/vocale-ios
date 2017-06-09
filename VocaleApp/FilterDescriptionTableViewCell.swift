//
//  FilterDescriptionTableViewCell.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 5/26/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class FilterDescriptionTableViewCell: UITableViewCell {
    
    @IBOutlet weak var filterButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var filterButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var middleViewHeight: NSLayoutConstraint!
    @IBOutlet weak var firstSeparatorLine: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var secondSeparatorLine: UIView!
    @IBOutlet weak var whoLabel: UILabel!
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var withinLabel: UILabel!
    @IBOutlet weak var whoValueLabel: UILabel!
    @IBOutlet weak var withinValueLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var ageValueLabel: UILabel!
    @IBOutlet weak var buttonView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        editButton.contentMode = .ScaleAspectFit
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
