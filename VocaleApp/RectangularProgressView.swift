//
//  RectangularProgressView.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/18.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class RectangularProgressView: UIView {

    var duration = 0.0
    var timer = NSTimer()
    var completion = {

    }
    var countdownLabel = UILabel() {
        didSet {
            self.addSubview(countdownLabel)
            countdownLabel.font = UIFont(name: "Raleway-Regular", size: 16)
            countdownLabel.textColor = UIColor.whiteColor()
            countdownLabel.textAlignment = .Center
        }
    }
    var rectShape = CAShapeLayer() {
        didSet {
            let bounds = self.frame

            // Create CAShapeLayerS
            rectShape = CAShapeLayer()
            rectShape.bounds = bounds
            rectShape.position = self.center
            rectShape.cornerRadius = bounds.width / 2
            self.layer.addSublayer(rectShape)

            // Apply effects here

            rectShape.path = UIBezierPath(roundedRect: CGRectMake(0, 0, self.frame.width, self.frame.height), byRoundingCorners: UIRectCorner.AllCorners, cornerRadii: CGSize(width: 4, height: 4)).CGPath

            rectShape.lineWidth = 4.0
            rectShape.strokeColor = UIColor.vocaleRedColor().CGColor
            rectShape.fillColor = UIColor.clearColor().CGColor

            // 2
            rectShape.strokeStart = 0
            rectShape.strokeEnd = 1
        }
    }

    func setProgress(progress: CGFloat) {
        rectShape = CAShapeLayer()
        rectShape.strokeEnd = progress
    }

    func startAnimatingWithDuration(seconds: Double, completion: () -> Void) {
        // 1
        self.completion = completion
        duration = seconds
        rectShape = CAShapeLayer()


        // 3
        let end = CABasicAnimation(keyPath: "strokeEnd")
        end.toValue = 0

        // 4
        let group = CAAnimationGroup()
        group.animations = [end]
        group.duration = seconds
        group.autoreverses = false
        group.repeatCount = HUGE // repeat forver
        rectShape.addAnimation(group, forKey: nil)


        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("update"), userInfo: nil, repeats: true)
    }

    func update() {
        if(duration > 0) {
            countdownLabel.text = String(Int(duration--))
        } else {
            completion()
        }

    }


    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
