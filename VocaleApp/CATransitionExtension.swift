//
//  CATransitionExtension.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/10.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

extension CATransition {
    static func fadeTransition() -> CATransition {
        let transition = CATransition()
        transition.duration = 0.5
        transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.type = kCATransitionFade
        transition.subtype = kCATransitionFromRight
        return transition
    }
}
