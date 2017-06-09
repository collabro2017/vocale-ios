//
//  C2AClickWheel.swift
//  ClickWheel
//
//  Created by Dirk Gerretz on 16/03/15.
//  Copyright (c) 2015 [code2app];. All rights reserved.
//

import UIKit
import AudioToolbox

@IBDesignable class C2AClickWheel: UIButton {

    // MARK: Properties
    let π = CGFloat(M_PI)

    //@IBInspectable changes should be applied in the Attributes Inspector in Interface Builer

    // Wheel Colors
    @IBInspectable var wheelColor: UIColor = UIColor.lightGrayColor()
    @IBInspectable var buttonColor: UIColor = UIColor.darkGrayColor()

    // Switch feedback sound on/off. False is the default for debugging only
    @IBInspectable var feedbackSound: Bool = false

    // Define the thickness of the arc.
    @IBInspectable var arcWidth: CGFloat = 50

    // will be set at dragging and reflecting the angle in the clickWheel
    // an angle of 0° being at the 9 o'clock position of the wheel like in
    // a unitcircle. Also, in a unitcirlce the angle increases going counte-
    // clockwise. Therefore a decreaseing angle will increase the counter
    // so dragging feel right to the user.
    
    var angle: Int = 0 {
        didSet{
            
            if feedbackSound {
                // play click sound only every other time
                if angle % 2 == 0 {
                    playClickSound()
                }

            }
        }
    }

    override var frame: CGRect {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // the value that will be eventually used
    var counter: Int = 0
    
    // this gets set in lyoutSubview()
    var centerButton: UIButton?
    
    // sound properties
    var soundURL: NSURL?
    var soundID:SystemSoundID = 0

    // MARK: Lifecycle
    
    override func layoutSubviews() {
    /*************************************************************************************
     Why is all layout work done here rathen than in awakeFromNib()?
        
     The main reason is that I wanted to properly support Auto Layout/Auto Size Classes.
     Basically I'm creating a button programmatically on top of a button that got
     created in Interface Builder. To correctly calculate size and position of the 
     top (or center) button the exact size and position of its host (or wheel) button
     is required. When Auto Layout/Auto Size Classes are used it is here where we get
     proper values of the actual device/view. AwakeFromNib() will alway give you the
     defaults from interface builder regardless of the actual device used.
    *************************************************************************************/
        
        // as layoutSubView may get called multiple times check if button is
        // nil before instantiating
        if centerButton == nil {

            // sign up for orientation change notification
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged", name: UIDeviceOrientationDidChangeNotification, object: nil)
        
            // add circular button to the center of the clickwheel
            
            // instantiate a centerButton
            // calculate the size of the center button from the size of the wheel button
            centerButton = UIButton(frame: calculateButtonFrame())
            
            // set centerButton properties
            centerButton!.backgroundColor = buttonColor
            
            // Button title
            centerButton!.setTitle(self.titleLabel?.text, forState: .Normal)
            centerButton!.titleLabel!.font =  self.titleLabel?.font
            centerButton!.setTitleColor(self.titleColorForState(.Normal), forState: UIControlState.Normal)
            centerButton!.addTarget(nil, action: "centerClicked:", forControlEvents: .TouchUpInside)
            
            // put button on screen. You can't put a button on top of another button so, the
            // center button is also added to the main view
            //superview?.addSubview(centerButton!)
            
            // prepare sound playback
            prepareSound()
        }
    }

    override func drawRect(rect: CGRect) {

        //Define the center point of the view where you’ll rotate the arc around.
        let center = CGPoint(x:bounds.width/2, y: bounds.height/2)

        // Draw the outer arc

        // Calculate the radius based on the max dimension of the view.
        // max returns the greater of any x and y.
        var radius: CGFloat = (max(bounds.width, bounds.height)/2)

        // Define the start and end angles for the arc as radians.
        let startAngle: CGFloat = 0
        let endAngle: CGFloat = 2 * π

        // Create a path based on the center point, radius, and angles you just defined.
        var path = UIBezierPath(arcCenter: center,
            radius: (radius - arcWidth/2) - 2, // -2 to make room for drop shadows
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true)

        // these var's are used for both inner and outer ClickWheel shadows
        let ctx = UIGraphicsGetCurrentContext()!
        let shadowOutside = UIColor.grayColor()
        let shadowInside = UIColor.blackColor()
        let shadowOffset = CGSizeMake(0.0, 0.3)   //(3.1, 3.1)
        let shadowBlurRadius: CGFloat = 5.0

        // add dropshadow to ClickWheel
        CGContextSetShadowWithColor(ctx, shadowOffset, shadowBlurRadius,  (shadowOutside as UIColor).CGColor)

        // Set the line width and color before finally stroking the path.
        path.lineWidth = arcWidth
        wheelColor.setStroke()
        path.stroke()

        // draw innner circle

        // calculate radius for inner circle
        radius = radius - arcWidth

        // Create a path based on the center point, radius, and angles you just defined.
        path = UIBezierPath(arcCenter: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true)

        // add dropshadow to center button
        CGContextSetShadowWithColor(ctx, shadowOffset, shadowBlurRadius,  (shadowInside as UIColor).CGColor)

        // set color for inner circle and fill path
        buttonColor.setFill()
        path.fill()
    }

    override func continueTrackingWithTouch(touch: UITouch, withEvent event: UIEvent?) -> Bool {
        let lastPoint = touch.locationInView(self)

        let centerPoint:CGPoint  = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);

        //Calculate the direction from a center point and a arbitrary position.
        let currentAngle:Double = AngleFromNorth(centerPoint, p2: lastPoint, flipped: false);
        let angleInt = Int(floor(currentAngle))

        // only update upon new value for less fuzzy results
        if angleInt != angle {
            //Store the new angle
            angle = angleInt // Int(360 - angleInt)

            //Console out new value
            //print("Dragging: \(angle)°", terminator: "")
            
            // send noctifications other other coan register for
            sendActionsForControlEvents(.ValueChanged)
        }

        return true
    }

    // Apple Sourcecode Example
    // Calculate the direction in degrees from a center point to an arbitrary position.
    func AngleFromNorth(p1:CGPoint , p2:CGPoint , flipped:Bool) -> Double {
        var v:CGPoint  = CGPointMake(p2.x - p1.x, p2.y - p1.y)
        let vmag:CGFloat = Square(Square(v.x) + Square(v.y))
        var result:Double = 0.0
        v.x /= vmag;
        v.y /= vmag;
        let radians = Double(atan2(v.y,v.x))
        result = RadiansToDegrees(radians)
        return (result >= 0  ? result : result + 360.0);
    }

    func orientationChanged() {
        // re-calculate center button frame when screen roteated
        if let button = centerButton {
            button.frame = calculateButtonFrame()
        }
    }

    // MARK: Converters
    func DegreesToRadians (value:Double) -> Double {
        return value * M_PI / 180.0
    }

    func RadiansToDegrees (value:Double) -> Double {
        return value * 180.0 / M_PI
    }

    func Square (value:CGFloat) -> CGFloat {
        return value * value
    }

    func calculateButtonFrame() ->CGRect{

        let buttonWidth = calculateCenterButtonSize(self.frame.width, arcWidth: self.arcWidth)

        let positionX = self.center.x - (buttonWidth / 2)
        let positionY = self.center.y - (buttonWidth / 2)
        
        let newFrame = CGRectMake(positionX, positionY, buttonWidth, buttonWidth)

        return newFrame
    }

    func calculateCenterButtonSize(width: CGFloat, arcWidth: CGFloat) -> CGFloat {
        // at this point it is already clear that both width and heights are equal
        // This was checked when the host view was pulled out in Interface Builder

        // this calcualtes the max diagonal for the square inside the ClickWheel
        let diagonal = (width - (arcWidth * 2)) * 1.0

        // calculate square side length using Pythagoras' law
        return sqrt((pow(diagonal, 2.0) / 2))
    }
    
    //MARK: Sound
    func prepareSound() {
        let filePath = NSBundle.mainBundle().pathForResource("Click", ofType: "mp3")

        if let fPath = filePath {
            soundURL = NSURL(fileURLWithPath: fPath)
        }
    }

    func playClickSound(){
        
        AudioServicesCreateSystemSoundID(soundURL!, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

}

