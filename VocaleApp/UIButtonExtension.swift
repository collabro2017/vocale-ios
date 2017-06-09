//
//  UIButtonExtension.swift
//
//
//  Created by Rayno Willem Mostert on 2016/01/20.
//
//

import UIKit

extension UIButton {

    func setBackgroundColor(color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        CGContextSetFillColorWithColor(UIGraphicsGetCurrentContext()!, color.CGColor)
        CGContextFillRect(UIGraphicsGetCurrentContext()!, CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        self.setBackgroundImage(colorImage, forState: forState)
    }

    func startProgressView(duration: Double) {
        var rectShape = CAShapeLayer()

        let bounds = self.frame
        rectShape = CAShapeLayer()
        rectShape.bounds = bounds
        rectShape.position = self.center
        rectShape.cornerRadius = bounds.width / 2
        self.layer.addSublayer(rectShape)

        rectShape.path = UIBezierPath(ovalInRect: bounds).CGPath

        rectShape.lineWidth = 4.0
        rectShape.strokeColor = UIColor.vocaleRedColor().CGColor
        rectShape.fillColor = UIColor.clearColor().CGColor

        rectShape.strokeStart = 0
        rectShape.strokeEnd = 1

        rectShape = CAShapeLayer()

        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.toValue = 0

        let group = CAAnimationGroup()
        group.animations = [end]
        group.duration = duration
        group.autoreverses = false
        group.repeatCount = HUGE
        rectShape.addAnimation(group, forKey: nil)
    }

    func pauseProgressView() {
        if let sublayers = self.layer.sublayers {
            for layer in sublayers {
                if let layer = layer as? CAShapeLayer, let color = layer.strokeColor where UIColor(CGColor: color) == UIColor.vocaleRedColor() {
                    layer.removeFromSuperlayer()
                }
            }
        }
    }

    func startProgressView(duration: Double, fromDuration: Double) {
        var rectShape = CAShapeLayer()
        let bounds = self.frame
        rectShape = CAShapeLayer()
        rectShape.bounds = bounds
        rectShape.position = self.center
        rectShape.cornerRadius = bounds.width / 2
        self.layer.addSublayer(rectShape)
        rectShape.path = UIBezierPath(ovalInRect: bounds).CGPath
        rectShape.lineWidth = 4.0
        rectShape.strokeColor = UIColor.vocaleRedColor().CGColor
        rectShape.fillColor = UIColor.clearColor().CGColor
        rectShape.strokeStart = CGFloat(fromDuration/(duration + fromDuration))
        rectShape.strokeEnd = 1
        rectShape = CAShapeLayer()
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.toValue = 0
        let group = CAAnimationGroup()
        group.animations = [end]
        group.duration = duration - fromDuration
        group.autoreverses = false
        group.repeatCount = HUGE
        rectShape.addAnimation(group, forKey: nil)
    }

}
