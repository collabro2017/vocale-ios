//
//  UIColorExtension.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/09.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//(238,238,238)

import UIKit

extension UIColor {
    static func vocaleRedColor() -> UIColor {
        return UIColor(red: 246/255, green: 60/255, blue: 62/255, alpha: 1)
    }
    static func vocaleGreyColor() -> UIColor {
        return UIColor(red: 197/255, green: 197/255, blue: 197/255, alpha: 1)
    }
    static func vocaleLightGreyColor() -> UIColor {
        return UIColor(red: 238/255, green: 238/255, blue: 238/255, alpha: 1)
    }
    static func vocaleBackgroundGreyColor() -> UIColor {
        return UIColor(red: 33/255, green: 30/255, blue: 35/255, alpha: 1)
    }
    static func vocaleHeaderBackgroundGreyColor() -> UIColor {
        return UIColor(red: 39/255, green: 38/255, blue: 40/255, alpha: 1)
    }
    static func vocaleRECViewBackgroundColor() -> UIColor {
        return UIColor(netHex: 0x333134);
    }
    static func vocaleOrangeColor() -> UIColor {
        return UIColor(netHex: 0xFB4B4E);
    }
    static func vocalePushGreenColor() -> UIColor {
        return UIColor(netHex: 0x86B155);
    }
    static func vocalePushBlueColor() -> UIColor {
        return UIColor(netHex: 0x1098F7);
    }
    static func vocaleTextGreyColor() -> UIColor {
        return UIColor(netHex: 0xEEEEEE)
    }
    static func vocaleFilterTextColor() -> UIColor {
        return UIColor(netHex: 0xEEEEEE)
    }
    static func vocaleIncomingTextColor() -> UIColor {
        return UIColor(netHex: 0x211E23)
    }
    static func vocaleIncomingBubbleViewColor() -> UIColor {
        return UIColor(netHex: 0xB7B7B7)
    }
    static func vocaleOutgoingBubbleViewColor() -> UIColor {
        return UIColor(netHex: 0x333134)
    }
    static func vocaleConversationTitleColor() -> UIColor {
        return UIColor(netHex: 0xDEDEDE)
    }
    static func vocalePlaceholderTextColor() -> UIColor {
        return UIColor(netHex: 0xC7C7CD)
    }
    static func vocaleSecondLevelTextColor() -> UIColor {
        return UIColor(netHex: 0xB7B7B7)
    }
    static func vocaleSavedPostNotificationColor() -> UIColor {
        return UIColor(netHex: 0x848485)
    }
    
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}
