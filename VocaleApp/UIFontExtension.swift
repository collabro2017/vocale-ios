//
//  UIFontExtension.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/18.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

extension UIFont {
    enum AssetIdentifier: String {
        case RalewayBlack = "Raleway-Black"
        case RalewayBlackItalic = "Raleway-BlackItalic"
        case RalewayBold = "Raleway-Bold"
        case RalewayBoldItalic = "Raleway-BoldItalic"
        case RalewayExtraBold = "Raleway-ExtraBold"
        case RalewayExtraBoldItalic = "Raleway-ExtraBoldItalic"
        case RalewayExtraLight = "Raleway-ExtraLight"
        case RalewayExtraLightItalic = "Raleway-ExtraLightItalic"
        case RalewayItalic = "Raleway-Italic"
        case RalewayLight = "Raleway-Light"
        case RalewayLightItalic = "Raleway-LightItalic"
        case RalewayMedium = "Raleway-Medium"
        case RalewayMediumItalic = "Raleway-MediumItalic"
        case RalewayRegular = "Raleway-Regular"
        case RalewaySemiBold = "Raleway-SemiBold"
        case RalewaySemiBoldItalic = "Raleway-SemiBoldItalic"
        case RalewayThin = "Raleway-Thin"
        case RalewayThinItalic = "Raleway-ThinItalic"
    }

    convenience init!(assetIdentifier: AssetIdentifier, size: CGFloat) {
        (self.init(name: assetIdentifier.rawValue,
            size: size))!
    }
}
