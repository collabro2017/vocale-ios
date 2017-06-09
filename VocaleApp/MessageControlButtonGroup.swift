//
//  MessageControlButtonGroup.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/03/19.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class MessageControlButtonGroup: UIView {

    var leftButton: UIButton {
        didSet {
            leftButton.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
            leftButton.backgroundColor = UIColor.whiteColor()
            leftButton.setImage(UIImage(named: "FlagMessageAccessory"), forState: .Normal)
            leftButton.addTarget(self, action: #selector(MessageControlButtonGroup.leftTapped), forControlEvents: UIControlEvents.TouchUpInside)
        }
    }

    var rightButton: UIButton {
        didSet {
            rightButton.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
            rightButton.backgroundColor = UIColor.whiteColor()
            rightButton.setImage(UIImage(named: "endMessageAccessory"), forState: .Normal)
            rightButton.addTarget(self, action: #selector(MessageControlButtonGroup.rightTapped), forControlEvents: UIControlEvents.TouchUpInside)
        }
    }

    var leftButtonTapped = {}
    var rightButtonTapped = {}

    override init(frame: CGRect) {
        leftButton = UIButton()
        rightButton = UIButton()

        super.init(frame: frame)

        rightButton.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
        rightButton.setImage(UIImage(named: "endMessageAccessory"), forState: .Normal)
        rightButton.addTarget(self, action: #selector(MessageControlButtonGroup.rightTapped), forControlEvents: UIControlEvents.TouchUpInside)

        leftButton.frame = CGRect(x: 0, y: 0, width: 75, height: 75)
        leftButton.setImage(UIImage(named: "FlagMessageAccessory"), forState: .Normal)
        leftButton.addTarget(self, action: #selector(MessageControlButtonGroup.leftTapped), forControlEvents: UIControlEvents.TouchUpInside)

        leftButton.imageView?.contentMode = .ScaleAspectFit
        rightButton.imageView?.contentMode = .ScaleAspectFit

        leftButton.center = CGPointMake(frame.width/4, frame.height/2.2)
        rightButton.center = CGPointMake(frame.width*3/4, frame.height/2.2)

        addSubview(leftButton)
        addSubview(rightButton)

        let leftButtonLabel = UILabel(frame: CGRectMake(leftButton.frame.origin.x, leftButton.frame.origin.y+leftButton.frame.height+5, leftButton.frame.width, 20))
        leftButtonLabel.textColor = UIColor.whiteColor()
        leftButtonLabel.textAlignment = .Center
        leftButtonLabel.font = UIFont(name: "Raleway-Regular", size: 18)
        leftButtonLabel.text = "Report"

        addSubview(leftButtonLabel)

        let rightButtonLabel = UILabel(frame: CGRectMake(rightButton.frame.origin.x, rightButton.frame.origin.y+rightButton.frame.height+5, rightButton.frame.width, 20))
        rightButtonLabel.textColor = UIColor.whiteColor()
        rightButtonLabel.textAlignment = .Center
        rightButtonLabel.font = UIFont(name: "Raleway-Regular", size: 18)
        rightButtonLabel.text = "End"
        addSubview(rightButtonLabel)

    }

    required init?(coder aDecoder: NSCoder) {
        leftButton = UIButton()
        rightButton = UIButton()
        super.init(coder: aDecoder)

        leftButton.center = CGPointMake(frame.width/4, frame.height/2)
        rightButton.center = CGPointMake(frame.width/4, frame.height/2)

        addSubview(leftButton)
        addSubview(rightButton)

        let leftButtonLabel = UILabel(frame: CGRectMake(leftButton.frame.origin.x, leftButton.frame.origin.y+leftButton.frame.height, leftButton.frame.width, 20))
        leftButtonLabel.textColor = UIColor.whiteColor()
        leftButtonLabel.font = UIFont(name: "Raleway-Regular", size: 22)
        addSubview(leftButtonLabel)

        let rightButtonLabel = UILabel(frame: CGRectMake(rightButton.frame.origin.x, rightButton.frame.origin.y+rightButton.frame.height, rightButton.frame.width, 20))
        rightButtonLabel.textColor = UIColor.whiteColor()
        rightButtonLabel.font = UIFont(name: "Raleway-Regular", size: 22)
        addSubview(rightButtonLabel)
    }

    func leftTapped() {
        leftButtonTapped()
    }

    func rightTapped() {
        rightButtonTapped()
    }
}
