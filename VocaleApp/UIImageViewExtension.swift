//
//  UIImageViewExtension.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/09.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

extension UIImageView {
    /**
     Apply a circular mask to the UIImageView, with a white border.
     */
    func applyCircularMask() {
        let circle = CAShapeLayer()
        let circularPath = UIBezierPath(ovalInRect: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))

        circle.path = circularPath.CGPath

        circle.fillColor = UIColor.blackColor().CGColor
        circle.strokeColor = UIColor.whiteColor().CGColor
        circle.lineWidth = 0

        let kBorderWidth = 5.0
        print("FRAME %f", self.frame.size.width)
        let kCornerRadius = self.frame.size.width/2
        let borderLayer = CALayer()
        let borderFrame = CGRectMake(0, 0, (self.frame.size.width), (self.frame.size.height))
        borderLayer.backgroundColor = UIColor.clearColor().CGColor
        borderLayer.frame = borderFrame
        borderLayer.cornerRadius = CGFloat(kCornerRadius)
        borderLayer.borderWidth = CGFloat(kBorderWidth)
        borderLayer.borderColor = UIColor.whiteColor().CGColor
        borderLayer.name = "borderLayer"
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                if layer.name == borderLayer.name {
                    layer.removeFromSuperlayer()
                }
            }
        }
        self.layer.addSublayer(borderLayer)

        self.layer.mask = circle
    }
    
    func applyCircularMask2() {
        let circle = CAShapeLayer()
        let circularPath = UIBezierPath(ovalInRect: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))
        
        circle.path = circularPath.CGPath
        
        circle.fillColor = UIColor.blackColor().CGColor
        circle.strokeColor = UIColor.whiteColor().CGColor
        circle.lineWidth = 0
        
        let kBorderWidth = 2.0
        let kCornerRadius = self.frame.size.width/2
        let borderLayer = CALayer()
        let borderFrame = CGRectMake(0, 0, (self.frame.size.width), (self.frame.size.height))
        borderLayer.backgroundColor = UIColor.clearColor().CGColor
        borderLayer.frame = borderFrame
        borderLayer.cornerRadius = CGFloat(kCornerRadius)
        borderLayer.borderWidth = CGFloat(kBorderWidth)
        borderLayer.borderColor = UIColor.whiteColor().CGColor
        borderLayer.name = "borderLayer"
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                if layer.name == borderLayer.name {
                    layer.removeFromSuperlayer()
                }
            }
        }
        self.layer.addSublayer(borderLayer)
        
        self.layer.mask = circle
    }

    /**
     Apply a circular mask to the imageview without any white border.
     */
    func applyCircularMaskWithoutBorder() {
        let circle = CAShapeLayer()
        let circularPath = UIBezierPath(ovalInRect: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))

        circle.path = circularPath.CGPath

        circle.fillColor = UIColor.blackColor().CGColor
        circle.strokeColor = UIColor.whiteColor().CGColor
        circle.lineWidth = 0

        let kBorderWidth = 0.0
        let borderLayer = CALayer()
        let borderFrame = CGRectMake(0, 0, (self.frame.size.width), (self.frame.size.height))
        borderLayer.backgroundColor = UIColor.clearColor().CGColor
        borderLayer.frame = borderFrame
        borderLayer.borderWidth = CGFloat(kBorderWidth)
        borderLayer.borderColor = UIColor.whiteColor().CGColor
        self.layer.addSublayer(borderLayer)

        self.layer.mask = circle
    }

    /**
     Apply a circular mask with a 'progress'-like stroke, diminishing constantly for the number of seconds provided.

     - parameter seconds: The number of seconds that the progress should count down for.
     */
    func applyCircularProgresMask(seconds: Double) {
        let circle = CAShapeLayer()
        let circularPath = UIBezierPath(ovalInRect: CGRectMake(0, 0, self.frame.size.width, self.frame.size.height))

        circle.path = circularPath.CGPath

        circle.fillColor = UIColor.blackColor().CGColor
        circle.strokeColor = UIColor.redColor().CGColor
        circle.lineWidth = 4
        circle.strokeStart = 0

        let kBorderWidth = 3.0
        let kCornerRadius = self.frame.size.width/2
        let borderLayer = CALayer()
        let borderFrame = CGRectMake(0, 0, (self.frame.size.width), (self.frame.size.height))
        borderLayer.backgroundColor = UIColor.clearColor().CGColor
        borderLayer.frame = borderFrame
        borderLayer.cornerRadius = CGFloat(kCornerRadius)
        borderLayer.borderWidth = CGFloat(kBorderWidth)
        borderLayer.borderColor = UIColor.whiteColor().CGColor
        self.layer.addSublayer(borderLayer)

        self.layer.mask = circle

        circle.strokeEnd = 0

        UIView.animateWithDuration(seconds) { () -> Void in
            circle.strokeEnd = 1
        }
    }
}
