//
//  TabbedTableHeaderView.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/20.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class TabbedTableHeaderView: UIView {
    
    var disabled = false {
        didSet {
            if disabled {
                for button in tabs {
                    button.enabled = false
                }
            } else {
                for button in tabs {
                    button.enabled = true
                }
            }
        }
    }
    
    private var tabTitles = [String]()
    private var tabs = [UIButton]()
    private var selectionHandler: (selectedTabIndex: Int) -> Void = {
        _ in
    }
    private var numberOfItemsInTabs = [Int]() {
        didSet {
        }
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    init(frame: CGRect, tabTitles: [String], selectionHandler: (selectedTabIndex: Int) -> Void) {
        super.init(frame: frame)
        backgroundColor = UIColor(netHex: 0x333134)
        self.tabTitles = tabTitles
        var count = CGFloat(0)
        let separatorLine = UIImageView(frame: CGRectMake(0, 0, frame.width, 1))
        separatorLine.image = UIImage(named: "Line")
        addSubview(separatorLine)
        for title in tabTitles {
            let x = frame.width*count/CGFloat(tabTitles.count)
            let button = UIButton(type: UIButtonType.Custom)
            button.setTitleColor(UIColor(netHex:0xEEEEEE), forState: .Selected)
            button.setTitleColor(UIColor(netHex:0x848485), forState: .Normal)
            button.titleLabel?.font = UIFont(assetIdentifier: .RalewaySemiBold, size: 14)
            button.setTitle(title, forState: .Normal)
            //button.setBackgroundColor(UIColor.vocaleHeaderBackgroundGreyColor(), forState: UIControlState.Normal)
            //button.setBackgroundColor(UIColor.vocaleHeaderBackgroundGreyColor(), forState: UIControlState.Selected)
            //button.setBackgroundColor(UIColor.vocaleHeaderBackgroundGreyColor(), forState: UIControlState.Disabled)
            button.frame = CGRectMake(x-1, 0, frame.width/CGFloat(tabTitles.count)+1, frame.height+1)
            button.addTarget(self, action: #selector(TabbedTableHeaderView.didTapButton(_:)), forControlEvents: UIControlEvents.TouchUpInside)
            tabs.append(button)
            addSubview(button)
            
            numberOfItemsInTabs.append(0)
            count++
        }
        if tabTitles.count > 0 {
            tabs[0].selected = true
        }
        
        let firstDot = UIImageView(frame: CGRectMake(frame.width/3 - 4, frame.height/2 - 4, 8, 8))
        firstDot.image = UIImage(named: "dot")
        addSubview(firstDot)
        
        let secondDot = UIImageView(frame: CGRectMake((frame.width/3)*2 - 4, frame.height/2 - 4, 8, 8))
        secondDot.image = UIImage(named: "dot")
        addSubview(secondDot)
        
        self.selectionHandler = selectionHandler
        disabled = true
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func switchToAll() {
        didTapButton(tabs.first!)
    }
    
    func didTapButton(sender: UIButton) {
        if let index = tabs.indexOf(sender) {
            selectionHandler(selectedTabIndex: index)
            for button in tabs {
                button.selected = false
            }
            sender.selected = true
        }
    }
    
    func setNumberOfItems(number: Int, inTab: Int){
        var array = numberOfItemsInTabs
        array[inTab] = number
        numberOfItemsInTabs = array
        for var i = 0; i < numberOfItemsInTabs.count; i += 1 {
            if numberOfItemsInTabs[i] > 0 {
                tabs[i].setTitle("\(tabTitles[i]) (\(numberOfItemsInTabs[i]))", forState: .Normal)
            }
        }
    }
    
    func incrementNumberOfItemsInTab(inTab: Int) {
        print("Increment", terminator: "")
        var array = numberOfItemsInTabs
        array[inTab] += 1
        numberOfItemsInTabs = array
        for var i = 0; i < numberOfItemsInTabs.count; i += 1 {
            if numberOfItemsInTabs[i] > 0 {
                tabs[i].setTitle("\(tabTitles[i]) (\(numberOfItemsInTabs[i]))", forState: .Normal)
            } else {
                tabs[i].setTitle("\(tabTitles[i])", forState: .Normal)
            }
        }
    }
    
    func decrementNumberOfItemsInTab(inTab: Int) {
        print("Decrement", terminator: "")
        var array = numberOfItemsInTabs
        array[inTab] -= 1
        numberOfItemsInTabs = array
        for var i = 0; i < numberOfItemsInTabs.count; i += 1 {
            if numberOfItemsInTabs[i] > 0 {
                tabs[i].setTitle("\(tabTitles[i]) (\(numberOfItemsInTabs[i]))", forState: .Normal)
            } else {
                tabs[i].setTitle("\(tabTitles[i])", forState: .Normal)
            }
        }
    }
    
    func setTabTitlesHidden(hidden: Bool) {
        UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            for var i = 0; i < self.numberOfItemsInTabs.count; i += 1 {
                if (hidden) {
//                    self.tabs[i].transform = CGAffineTransformMakeTranslation(0, -40)
//                    self.backgroundColor = UIColor.clearColor()
                    self.tabs[i].enabled = false
                } else {
//                    self.tabs[i].transform = CGAffineTransformMakeTranslation(0, 0);
//                    self.backgroundColor = UIColor(netHex:0x272628)
                    self.tabs[i].enabled = true
                }
            }
            }) { (completed: Bool) -> Void in
        }
    }
    
}
