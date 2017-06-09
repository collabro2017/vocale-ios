//
//  BookmarkButton.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/18.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class BookmarkButton: UIButton {
    enum ButtonState {
        case bookmarkState
        case bookmarkedState
        case returnState
    }
    var buttonState: ButtonState = .bookmarkState {
        didSet {
            switch buttonState {
            case .bookmarkState: alpha = 0
            case .bookmarkedState: setImage(UIImage(assetIdentifier: .bookmarkedButton), forState: .Normal)
                alpha = 0
            case .returnState: setImage(UIImage(assetIdentifier: .returnButton), forState: .Normal)
                alpha = 1
            }
        }
    }
}
