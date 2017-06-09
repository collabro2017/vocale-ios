//
//  UIViewExtension.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/10.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

extension UIView {

    func runSpinAnimation(duration: CGFloat, rotations: CGFloat, repeats: Float) {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(float: Float(CGFloat(M_PI) * CGFloat(2) * CGFloat(rotations) * duration))
        rotationAnimation.duration = Double(duration)
        rotationAnimation.cumulative = true
        rotationAnimation.repeatCount = repeats
        self.layer.addAnimation(rotationAnimation, forKey: "rotationAnimation")
    }

}
