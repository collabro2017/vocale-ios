//
//  CounterBarButtonItem.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/02/01.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class CounterButtonView: UIButton {
    
    var counterBackgroundColor: UIColor = UIColor(netHex: 0x86B155)
    
//    var postsCount = false {
//        didSet {
//            counterBackgroundColor = UIColor(netHex: 0x86B155)
//        }
//    }
//    
//    var messagesCount = false {
//        didSet {
//            counterBackgroundColor = UIColor(netHex: 0x1098F7)
//        }
//    }
    
    var showsPlus = false {
        didSet {
            if showsPlus {
                counterLabel?.text = "+"                
            }
        }
    }
    var count = 0 {
        didSet {
            counterLabel?.text = "\(count)"
            //print(counterLabel?.text, terminator: "")
            if count > 0 {
                self.backgroundColor = counterBackgroundColor
                self.layer.borderWidth = 0
                counterLabel?.font = UIFont.systemFontOfSize(16)
                counterLabel?.textColor = UIColor.blackColor()
            } else {
                counterLabel?.text = "●"
                counterLabel?.font = UIFont.systemFontOfSize(13)
                self.backgroundColor = UIColor.clearColor()
                counterLabel?.textColor = counterBackgroundColor
                self.layer.borderWidth = 1
            }
        }
    }
    func setCount(count: Int, withFontSize fontSize: CGFloat) {
        counterLabel?.removeFromSuperview()
        counterLabel = UILabel(frame: bounds)
        counterLabel?.font = UIFont.systemFontOfSize(fontSize)
        counterLabel?.textAlignment = .Center
        
        counterLabel?.textColor = UIColor.blackColor()
        addSubview(counterLabel!)
        
        self.count = count
        if count > 0 {
            self.backgroundColor = counterBackgroundColor
        } else {
            self.backgroundColor = UIColor(netHex: 0x4A484B)

        }
    }
    
    private var counterLabel: UILabel?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 4
        layer.masksToBounds = true
        layer.borderColor = UIColor(netHex: 0x848485).CGColor
        layer.borderWidth = 1
        counterLabel = UILabel(frame: frame)
        counterLabel?.font = UIFont.systemFontOfSize(22)
        counterLabel?.textColor = UIColor.blackColor()
        counterLabel?.textAlignment = .Center
        if let counterLabel = counterLabel {
            addSubview(counterLabel)
        }
        self.backgroundColor = UIColor(netHex: 0x4A484B)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        layer.cornerRadius = 4
        layer.masksToBounds = true
        layer.borderColor = UIColor(netHex: 0xB7B7B7).CGColor
        layer.borderWidth = 1
        counterLabel = UILabel(frame: bounds)
        counterLabel?.font = UIFont.systemFontOfSize(22)
        counterLabel?.textColor = UIColor.blackColor()
        counterLabel?.textAlignment = .Center
        counterLabel?.text = "●"
        if let counterLabel = counterLabel {
            addSubview(counterLabel)
        }
        self.backgroundColor = UIColor(netHex: 0x4A484B)
    }
    
    convenience init(frame: CGRect, posts: Bool) {
        self.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        if posts == true {
            counterBackgroundColor = UIColor(netHex: 0x86B155)
        } else {
            counterBackgroundColor = UIColor(netHex: 0x1098F7)
        }
    }
}
