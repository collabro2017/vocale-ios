//
//  eventCardManager.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/26.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit
import AVFoundation

protocol EventCardManagerDelegate: class {
    func uploadingVoiceMessage()
    func sentVoiceMessage()
    func cancelVoiceMessage()
}

class EventCardManager: UIView {
    var frameWidth: CGFloat = 320
    weak var delegate:EventCardManagerDelegate?
    var chatSection = false {
        didSet {
            if chatSection == true {
                leftButton.alpha = 0
                recordButton.alpha = 0
            }
        }
    }
    var toolTip1: UIView?
    var toolTip2: UIView?
    var toolTip3: UIView?
    var recordingToolTip1: UIView?
    var recordingToolTip2: UIView?
    var recordingToolTip3: UIView?
    var line1: UIImageView?
    var line2: UIImageView?
    var line3: UIImageView?
    var recordingLine1: UIImageView?
    var recordingLine2: UIImageView?
    var recordingLine3: UIImageView?
    var event: Event?

    var isBookmarked = false {
        didSet {
            if isBookmarked {
                
                rightButton.setImage(UIImage(named: "bookmarkPostAccessory"), forState: .Normal)
            } else {
                
                rightButton.setImage(UIImage(named: "bookmarkPostAccessory"), forState: .Normal)
            }
        }
    }
    var savedMode = false {
        didSet {
            if (savedMode) {
                leftButton.alpha = 0
                leftButton.frame = CGRectMake(frame.width/3,frame.height/3,frame.width/3, frame.height/3)
                leftButton.center = CGPointMake(self.recordButton.center.x, frame.height*5/6)
                var constant: CGFloat = 20
                if self.frameWidth <= 320 {
                    constant = 10
                }
                recordButton.frame = CGRectMake(frame.width/3,frame.height/3-constant,frame.width/3, frame.height/3)
                rightButton.alpha = 0
                rightButton.center = CGPointMake(frame.width/2, frame.height/2)
                
                let largerInset = 0.03*frame.width
                let smallerInset = 0.01*frame.width
                leftButton.imageEdgeInsets = UIEdgeInsets(top: largerInset, left: largerInset, bottom: largerInset, right: largerInset)
                rightButton.imageEdgeInsets = UIEdgeInsets(top: largerInset, left: largerInset, bottom: largerInset, right: largerInset)
                
                countdownLabel.center.y = recordButton.center.y
            }
        }
    }
    var audioFileURL: NSURL?
    private var recordingManager: RecordingManager?
    var bookmarkingEnabled = true {
        didSet {
            if bookmarkingEnabled {
                rightButton.alpha = 1
            } else {
                rightButton.alpha = 0
            }
        }
    }
    var timer: NSTimer?
    var countdownLabel = UILabel() {
        didSet {
            
        }
    }
    var isRecording: Bool {
        didSet {
            var leftCenter = leftButton.center
            var rightCenter = rightButton.center
            
            if (isRecording) {
                //NSUserDefaults.standardUserDefaults().setBool(false, forKey: "FirstRecordTapped")
                if NSUserDefaults.standardUserDefaults().boolForKey("FirstRecordTapped") == false {
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "FirstRecordTapped")
                    var smallIconHeight: CGFloat = 50.0
                    var bigIconHeight: CGFloat = 70.0
                    var constant: CGFloat = 0
                    if frameWidth <= 320 {
                        smallIconHeight = 44.0
                        bigIconHeight = 60.0
                        constant = 8
                    }
                    
                    //TOOLTIP 1
                    let tooltip1X = (frame.width/3)/2 - 74 - constant/2
                    let tooltip1Y = frame.height/2 - 20 - smallIconHeight/2 - 120
                    let tooltip1 = UIView(frame:  CGRectMake(tooltip1X, tooltip1Y, 140 + constant, 120))
                    tooltip1.backgroundColor = UIColor.clearColor()
                    recordingToolTip1 = tooltip1
                    let messageView1 = UIView(frame: CGRectMake(constant, 0, tooltip1.frame.size.width - constant, 70))
                    messageView1.backgroundColor = UIColor(netHex: 0x211E23)
                    messageView1.layer.cornerRadius = 4
                    messageView1.layer.borderWidth = 1
                    messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
                    messageView1.clipsToBounds = true
                    tooltip1.addSubview(messageView1)
                    let line1 = UIImageView(frame: CGRectMake(tooltip1.frame.size.width/2 - constant/2, 75, 2, tooltip1.frame.size.height - 70))
                    //line1.backgroundColor = UIColor(netHex: 0xEEEEEE)
                    line1.image = UIImage(named: "dottedLine")
                    line1.contentMode = .Top
                    line1.clipsToBounds = true
                    self.recordingLine1 = line1
                    tooltip1.addSubview(line1)
                    let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
                    titleLabel1.textAlignment = .Center
                    titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
                    titleLabel1.textColor = UIColor(netHex: 0x211E23)
                    titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
                    titleLabel1.text = "CANCEL"
                    messageView1.addSubview(titleLabel1)
                    let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
                    messageLabel1.numberOfLines = 2
                    messageLabel1.textAlignment = .Center
                    messageLabel1.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
                    messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
                    messageLabel1.backgroundColor = UIColor(netHex: 0x1098F7)
                    let messageText1 = "End the recording without sending"
                    messageLabel1.text = messageText1
                    messageView1.addSubview(messageLabel1)
                    
                    //TOOLTIP 2
                    let tooltip2X = rightButton.center.x - 140/2 - constant
                    let tooltip2Y = frame.height/2 - 20 - smallIconHeight/2 - 120
                    let tooltip2 = UIView(frame:  CGRectMake(tooltip2X, tooltip2Y, 140 + constant, 120))
                    tooltip2.backgroundColor = UIColor.clearColor()
                    recordingToolTip2 = tooltip2
                    let messageView2 = UIView(frame: CGRectMake(0,0,tooltip2.frame.size.width - constant, 70))
                    messageView2.backgroundColor = UIColor(netHex: 0x211E23)
                    messageView2.layer.cornerRadius = 4
                    messageView2.layer.borderWidth = 1
                    messageView2.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
                    messageView2.clipsToBounds = true
                    tooltip2.addSubview(messageView2)
                    let line2 = UIImageView(frame: CGRectMake(tooltip2.frame.size.width/2 + constant/2, 75, 2, tooltip2.frame.size.height - 70))
                    //line2.backgroundColor = UIColor(netHex: 0xEEEEEE)
                    line2.image = UIImage(named: "dottedLine")
                    line2.contentMode = .Top
                    line2.clipsToBounds = true
                    self.recordingLine2 = line2
                    tooltip2.addSubview(line2)
                    let titleLabel2 = UILabel(frame: CGRectMake(0, 0, messageView2.frame.size.width, 20))
                    titleLabel2.textAlignment = .Center
                    titleLabel2.font = UIFont(name: "Raleway-Bold", size: 16.0)
                    titleLabel2.textColor = UIColor(netHex: 0x211E23)
                    titleLabel2.backgroundColor = UIColor(netHex: 0xEEEEEE)
                    titleLabel2.text = "SEND"
                    messageView2.addSubview(titleLabel2)
                    
                    let messageLabel2 = UILabel(frame: CGRectMake(0, 20, messageView2.frame.size.width, messageView2.frame.size.height - 20))
                    messageLabel2.numberOfLines = 2
                    messageLabel2.textAlignment = .Center
                    messageLabel2.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
                    messageLabel2.textColor = UIColor(netHex: 0xEEEEEE)
                    messageLabel2.backgroundColor = UIColor(netHex: 0x1098F7)
                    let messageText2 = "Send your recording"
                    messageLabel2.text = messageText2
                    messageView2.addSubview(messageLabel2)
                    
                    //TOOLTIP 3
                    let tooltip3X = recordButton.center.x - 70
                    let tooltip3Y = frame.height/2 - 15 - bigIconHeight/2 - 200
                    let tooltip3 = UIView(frame:  CGRectMake(tooltip3X, tooltip3Y, 140, 200))
                    tooltip3.backgroundColor = UIColor.clearColor()
                    recordingToolTip3 = tooltip3
                    let messageView3 = UIView(frame: CGRectMake(0,0,tooltip3.frame.size.width, 70))
                    messageView3.backgroundColor = UIColor(netHex: 0x211E23)
                    messageView3.layer.cornerRadius = 4
                    messageView3.layer.borderWidth = 1
                    messageView3.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
                    messageView3.clipsToBounds = true
                    tooltip3.addSubview(messageView3)
                    let line3 = UIImageView(frame: CGRectMake(tooltip3.frame.size.width/2, 75, 2, tooltip3.frame.size.height - 80))
                    //line3.backgroundColor = UIColor(netHex: 0xEEEEEE)
                    line3.image = UIImage(named: "dottedLine")
                    line3.contentMode = .Top
                    line3.clipsToBounds = true
                    self.recordingLine3 = line3
                    tooltip3.addSubview(line3)
                    let titleLabel3 = UILabel(frame: CGRectMake(0, 0, messageView3.frame.size.width, 20))
                    titleLabel3.textAlignment = .Center
                    titleLabel3.font = UIFont(name: "Raleway-Bold", size: 16.0)
                    titleLabel3.textColor = UIColor(netHex: 0x211E23)
                    titleLabel3.backgroundColor = UIColor(netHex: 0xEEEEEE)
                    titleLabel3.text = "TIMER"
                    messageView3.addSubview(titleLabel3)
                    let messageLabel3 = UILabel(frame: CGRectMake(0, 20, messageView3.frame.size.width, messageView3.frame.size.height - 20))
                    messageLabel3.numberOfLines = 2
                    messageLabel3.textAlignment = .Center
                    messageLabel3.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
                    messageLabel3.textColor = UIColor(netHex: 0xEEEEEE)
                    messageLabel3.backgroundColor = UIColor(netHex: 0x1098F7)
                    let messageText3 = "Respond in a 60 second recording"
                    messageLabel3.text = messageText3
                    messageView3.addSubview(messageLabel3)
                    
                    if (!savedMode) {
                        addSubview(recordingToolTip1!)
                        addSubview(recordingToolTip2!)
                        addSubview(recordingToolTip3!)
                    }
                }
                if frameWidth <= 320 {
                    progress = KDCircularProgress(frame: CGRect(x: recordButton.frame.origin.x, y: recordButton.frame.origin.y, width: recordButton.frame.width-10, height: recordButton.frame.width-10))
                } else {
                    progress = KDCircularProgress(frame: CGRect(x: recordButton.frame.origin.x, y: recordButton.frame.origin.y, width: recordButton.frame.width + 8, height: recordButton.frame.width + 8))
                }
                
                progress.alpha = 0
                addSubview(progress)
                
                if (savedMode) {
                    leftCenter = CGPointMake(self.frame.width/5, self.frame.height/2 - 20)
                    rightCenter = CGPointMake(self.frame.width*4/5, self.frame.height/2 - 20)
                    
                }
                
                if let recordingTooltip1 = recordingToolTip1, let recordingTooltip2 = recordingToolTip2, let recordingTooltip3 = recordingToolTip3 {
                    recordingTooltip1.alpha = 0
                    recordingTooltip2.alpha = 0
                    recordingTooltip3.alpha = 0
                    recordingTooltip1.transform = CGAffineTransformMakeTranslation(0, 40)
                    recordingTooltip2.transform = CGAffineTransformMakeTranslation(0, 40)
                    recordingTooltip3.transform = CGAffineTransformMakeTranslation(0, 40)
                }
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                    self.leftButton.center = self.recordButton.center
                    self.rightButton.center = self.recordButton.center
                    self.leftButton.alpha = 0
                    self.rightButton.alpha = 0
                    self.recordButton.alpha = 0
                    
                    }) { (completed: Bool) -> Void in
                        if (completed) {
                            
                            self.leftButton.selected = true
                            self.rightButton.selected = true
                            
                            self.leftButton.hidden = false
                            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                                self.progress.alpha = 1
                                self.leftButton.alpha = 1
                                self.rightButton.alpha = 1
                                self.countdownLabel.alpha = 1
                                self.leftButton.center = leftCenter
                                self.rightButton.center = rightCenter
                                
                                self.recordingLine1?.alpha = 0
                                self.recordingLine2?.alpha = 0
                                self.recordingLine3?.alpha = 0
                            }) { (completed: Bool) -> Void in
                                UIView.animateWithDuration(0.3, delay: 6.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                                    if let recordingTooltip1 = self.recordingToolTip1, let recordingTooltip2 = self.recordingToolTip2, let recordingTooltip3 = self.recordingToolTip3 {
                                        recordingTooltip1.alpha = 1
                                        recordingTooltip2.alpha = 1
                                        recordingTooltip3.alpha = 1
                                        recordingTooltip1.transform = CGAffineTransformMakeTranslation(0, 0)
                                        recordingTooltip2.transform = CGAffineTransformMakeTranslation(0, 0)
                                        recordingTooltip3.transform = CGAffineTransformMakeTranslation(0, 0)
                                    }
                                }) { (completed: Bool) -> Void in
      
                                }
                                UIView.animateWithDuration(0.45, animations: { () -> Void in
                                    self.recordingLine1?.alpha = 1
                                    self.recordingLine2?.alpha = 1
                                    self.recordingLine3?.alpha = 1
                                }) { (completed: Bool) -> Void in
                                    
                                }
                            }
                            
                        }
                }
                
                
            } else {
                if (savedMode) {
                    leftCenter = CGPointMake(self.recordButton.center.x, frame.height*5/6)
                    self.leftButton.hidden = true
                }
                UIView.animateWithDuration(0.15, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                    self.recordingLine1?.alpha = 0
                    self.recordingLine2?.alpha = 0
                    self.recordingLine3?.alpha = 0
                }) { (completed: Bool) -> Void in
                    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                        self.leftButton.center = self.recordButton.center
                        self.rightButton.center = self.recordButton.center
                        self.leftButton.alpha = 0
                        self.rightButton.alpha = 0
                        if let recordingTooltip1 = self.recordingToolTip1, let recordingTooltip2 = self.recordingToolTip2, let recordingTooltip3 = self.recordingToolTip3 {
                            recordingTooltip1.alpha = 0
                            recordingTooltip2.alpha = 0
                            recordingTooltip3.alpha = 0
                            recordingTooltip1.transform = CGAffineTransformMakeTranslation(0, 40)
                            recordingTooltip2.transform = CGAffineTransformMakeTranslation(0, 40)
                            recordingTooltip3.transform = CGAffineTransformMakeTranslation(0, 40)
                        }
                        self.recordButton.alpha = 1
                        self.progress.alpha = 0
                        self.countdownLabel.alpha = 0
                        
                    }) { (completed: Bool) -> Void in
                        if (completed) {
                            self.recordingToolTip1?.removeFromSuperview()
                            self.recordingToolTip2?.removeFromSuperview()
                            self.recordingToolTip3?.removeFromSuperview()
                            self.progress.removeFromSuperview()
                            
                            self.leftButton.selected = false
                            self.rightButton.selected = false
                            
                            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                                self.leftButton.alpha = 1
                                if (self.bookmarkingEnabled) && !self.savedMode{
                                    self.rightButton.alpha = 1
                                }
                                self.leftButton.center = leftCenter
                                self.rightButton.center = rightCenter
                                
                            }) { (completed: Bool) -> Void in
                            }
                        }
                    }
                }
            }
    }
}

    func showButtonsWithAnimation(shouldAnimate: Bool) {
        if shouldAnimate {
            self.toolTip1?.alpha = 0
            self.toolTip2?.alpha = 0
            self.toolTip3?.alpha = 0
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                
                if self.frameWidth <= 320 {
                    self.leftButton.frame = CGRectMake(6, 2,self.frame.width/3 - 28, self.frame.height - 18)
                    self.rightButton.frame = CGRectMake(self.frame.width*2/3 + 22, 2,self.frame.width/3 - 28, self.frame.height - 18)
                } else if self.frameWidth < 414 {
                    self.leftButton.frame = CGRectMake(12, 5,self.frame.width/3 - 36, self.frame.height - 28)
                    self.rightButton.frame = CGRectMake(self.frame.width*2/3 + 24, 5, self.frame.width/3 - 36, self.frame.height - 28)
                    if (UIScreen.mainScreen().nativeScale == 2.8) { //ZOOMED MODE
                        self.leftButton.frame = CGRectMake(16, 5, self.frame.width/3 - 36, self.frame.height - 28)
                        self.rightButton.frame = CGRectMake(self.frame.width*2/3 + 20, 5, self.frame.width/3 - 36, self.frame.height - 28)
                    }
                } else {
                    self.leftButton.frame = CGRectMake(16, 5, self.frame.width/3 - 36, self.frame.height - 28)
                    self.rightButton.frame = CGRectMake(self.frame.width*2/3 + 20, 5, self.frame.width/3 - 36, self.frame.height - 28)
                }
                
                self.leftButton.alpha = 1
                self.rightButton.alpha = 1
                self.recordButton.alpha = 1
                self.toolTip1?.alpha = 1
                self.toolTip2?.alpha = 1
                self.toolTip3?.alpha = 1
                }) { (completed: Bool) -> Void in
            }
        } else {
            self.leftButton.center = self.recordButton.center
            self.rightButton.center = self.recordButton.center
            self.leftButton.alpha = 1
            self.rightButton.alpha = 1
            self.recordButton.alpha = 1
            self.toolTip1?.alpha = 1
            self.toolTip2?.alpha = 1
            self.toolTip3?.alpha = 1
        }
    }
    
    func hideButtonsWithAnimation(shouldAnimate: Bool) {
        if shouldAnimate {
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                self.leftButton.center = self.recordButton.center
                self.rightButton.center = self.recordButton.center
                self.leftButton.alpha = 0
                self.rightButton.alpha = 0
                self.recordButton.alpha = 0
                }) { (completed: Bool) -> Void in
            }
        } else {
            self.leftButton.center = self.recordButton.center
            self.rightButton.center = self.recordButton.center
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0
            self.recordButton.alpha = 0
        }
    }
    
    var leftButton: UIButton {
        didSet {
        }
    }
    
    var rightButton: UIButton {
        didSet {
        }
    }
    
    private var recordButton: UIButton {
        didSet {
        }
    }
    
    var progress = KDCircularProgress() {
        didSet {
            progress.startAngle = -90
            progress.progressThickness = 0.25
            progress.trackThickness = 0.25
            progress.clockwise = true
            progress.center = recordButton.center
            progress.roundedCorners = true
            progress.glowAmount = 0
            progress.angle = 300
            progress.trackColor = UIColor(netHex: 0x333134)
            progress.setColors(UIColor(red: 242/255, green: 67/255, blue: 71/255, alpha: 1))
        }
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */
    
    func setButtonCentersTo(center: CGFloat) {
        leftButton.center.y = frame.height*center
        rightButton.center.y = frame.height*center
        recordButton.center.y = frame.height*center
        countdownLabel.center.y = recordButton.center.y
        progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: recordButton.frame.width, height: recordButton.frame.height))
    }
    
    func removeToolTips() {
        UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: { 
            self.toolTip1?.alpha = 0
            self.toolTip2?.alpha = 0
            self.toolTip3?.alpha = 0
            }) { (finished) in
                self.toolTip1?.removeFromSuperview()
                self.toolTip2?.removeFromSuperview()
                self.toolTip3?.removeFromSuperview()
        }
    }
    
    init(frame: CGRect, screenWidth: CGFloat) {
        
        frameWidth = screenWidth


        leftButton = UIButton(frame: CGRectMake(6, 12,frame.width/3 - 28, frame.height - 18))
        rightButton = UIButton(frame: CGRectMake(frame.width*2/3 + 22, 12,frame.width/3 - 28, frame.height - 18))
        recordButton = UIButton(frame: CGRectMake(frame.width/3,3,frame.width/3, frame.height))
        
//        leftButton.backgroundColor = UIColor.redColor()
//        recordButton.backgroundColor = UIColor.blueColor()
//        rightButton.backgroundColor = UIColor.yellowColor()
        
        if frameWidth <= 320 {

        } else if frameWidth < 414 {
            leftButton.frame = CGRectMake(12, 14,frame.width/3 - 36, frame.height - 28)
            rightButton.frame = CGRectMake(frame.width*2/3 + 24, 14,frame.width/3 - 36, frame.height - 28)
            recordButton.frame = CGRectMake(frame.width/3,3,frame.width/3, frame.height)
            if (UIScreen.mainScreen().nativeScale == 2.8) { //ZOOMED MODE
                leftButton.frame = CGRectMake(16, 14,frame.width/3 - 36, frame.height - 28)
                rightButton.frame = CGRectMake(frame.width*2/3 + 20, 28,frame.width/3 - 36, frame.height - 28)
                recordButton.frame = CGRectMake(frame.width/3,3,frame.width/3, frame.height)
            }
        } else {
            leftButton.frame = CGRectMake(16, 14,frame.width/3 - 36, frame.height - 28)
            rightButton.frame = CGRectMake(frame.width*2/3 + 20, 28,frame.width/3 - 36, frame.height - 28)
            recordButton.frame = CGRectMake(frame.width/3,3,frame.width/3, frame.height)
        }

        //NSUserDefaults.standardUserDefaults().setBool(false, forKey: "FirstRecordTapped")
        if NSUserDefaults.standardUserDefaults().boolForKey("FirstLogin") == false {
            var smallIconHeight: CGFloat = 50.0
            var bigIconHeight: CGFloat = 70.0
            var constant: CGFloat = 0

            if frameWidth <= 320 {
                smallIconHeight = 44.0
                bigIconHeight = 60.0
                constant = 8
            }
            
            //TOOLTIP 1
            let tooltip1X = (frame.width/3)/2 - 74 - constant/2
            let tooltip1Y = frame.height/2 - 20 - smallIconHeight/2 - 105
            let tooltip1 = UIView(frame:  CGRectMake(tooltip1X, tooltip1Y, 140 + constant, 115))
            tooltip1.backgroundColor = UIColor.clearColor()
            toolTip1 = tooltip1
            let messageView1 = UIView(frame: CGRectMake(constant,0,tooltip1.frame.size.width - constant, 70))
            messageView1.backgroundColor = UIColor(netHex: 0x211E23)
            messageView1.layer.cornerRadius = 4
            messageView1.layer.borderWidth = 1
            messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
            messageView1.clipsToBounds = true
            tooltip1.addSubview(messageView1)
            let line1 = UIImageView(frame: CGRectMake(tooltip1.frame.size.width/2 - constant/2, 75, 2, tooltip1.frame.size.height - 80))
            //line1.backgroundColor = UIColor(netHex: 0xEEEEEE)
            line1.image = UIImage(named: "dottedLine")
            line1.contentMode = .Top
            line1.clipsToBounds = true
            self.line1 = line1
            tooltip1.addSubview(line1)
            let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
            titleLabel1.textAlignment = .Center
            titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
            titleLabel1.textColor = UIColor(netHex: 0x211E23)
            titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
            titleLabel1.text = "PASS"
            messageView1.addSubview(titleLabel1)
            let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
            messageLabel1.numberOfLines = 2
            messageLabel1.textAlignment = .Center
            messageLabel1.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
            messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
            messageLabel1.backgroundColor = UIColor(netHex: 0x1098F7)
            messageLabel1.text = "Pass posts you\naren’t interested in"
//            let messageText1 = "Tap “X” to\nPass a post."
//            let range = (messageText1 as NSString).rangeOfString("Pass")
//            let attributedString = NSMutableAttributedString(string:messageText1)
//            attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 14)!, NSForegroundColorAttributeName: UIColor(netHex: 0xFB4B4E)], range: range)
//            messageLabel1.attributedText = attributedString
            messageView1.addSubview(messageLabel1)
            
            //TOOLTIP 2
            let tooltip2X = rightButton.center.x - 140/2 - constant
            let tooltip2Y = frame.height/2 - 20 - smallIconHeight/2 - 105
            let tooltip2 = UIView(frame:  CGRectMake(tooltip2X, tooltip2Y, 140 + constant, 115))
            tooltip2.backgroundColor = UIColor.clearColor()
            toolTip2 = tooltip2
            let messageView2 = UIView(frame: CGRectMake(0 ,0,tooltip2.frame.size.width - constant, 70))
            messageView2.backgroundColor = UIColor(netHex: 0x211E23)
            messageView2.layer.cornerRadius = 4
            messageView2.layer.borderWidth = 1
            messageView2.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
            messageView2.clipsToBounds = true
            tooltip2.addSubview(messageView2)
            let line2 = UIImageView(frame: CGRectMake(tooltip2.frame.size.width/2 + constant/2, 75, 2, tooltip2.frame.size.height - 80))
            //line2.backgroundColor = UIColor(netHex: 0xEEEEEE)
            line2.image = UIImage(named: "dottedLine")
            line2.contentMode = .Top
            line2.clipsToBounds = true
            self.line2 = line2
            tooltip2.addSubview(line2)
            let titleLabel2 = UILabel(frame: CGRectMake(0, 0, messageView2.frame.size.width, 20))
            titleLabel2.textAlignment = .Center
            titleLabel2.font = UIFont(name: "Raleway-Bold", size: 16.0)
            titleLabel2.textColor = UIColor(netHex: 0x211E23)
            titleLabel2.backgroundColor = UIColor(netHex: 0xEEEEEE)
            titleLabel2.text = "SAVE"
            messageView2.addSubview(titleLabel2)
            let messageLabel2 = UILabel(frame: CGRectMake(0, 20, messageView2.frame.size.width, messageView2.frame.size.height - 20))
            messageLabel2.numberOfLines = 2
            messageLabel2.textAlignment = .Center
            messageLabel2.font = UIFont(name: "Raleway-Regular", size: 14.0)
            messageLabel2.textColor = UIColor(netHex: 0xEEEEEE)
            messageLabel2.backgroundColor = UIColor(netHex: 0x1098F7)
            messageLabel2.text = "Save posts to respond to later"
//            let messageText2 = "Save a post and\nrespond to it\nlater."
//            let range2 = (messageText2 as NSString).rangeOfString("Save")
//            let attributedString2 = NSMutableAttributedString(string:messageText2)
//            attributedString2.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 14)!, NSForegroundColorAttributeName: UIColor(netHex: 0xFB4B4E)], range: range2)
//            messageLabel2.attributedText = attributedString2
            messageView2.addSubview(messageLabel2)
            
            //TOOLTIP 3
            let tooltip3X = recordButton.center.x - 70
            let tooltip3Y = frame.height/2 - 20 - bigIconHeight/2 - 175
            let tooltip3 = UIView(frame:  CGRectMake(tooltip3X, tooltip3Y, 140, 175))
            tooltip3.backgroundColor = UIColor.clearColor()
            toolTip3 = tooltip3
            let messageView3 = UIView(frame: CGRectMake(0,0,tooltip3.frame.size.width, 70))
            messageView3.backgroundColor = UIColor(netHex: 0x211E23)
            messageView3.layer.cornerRadius = 4
            messageView3.layer.borderWidth = 1
            messageView3.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
            messageView3.clipsToBounds = true
            tooltip3.addSubview(messageView3)
            let line3 = UIImageView(frame: CGRectMake(tooltip3.frame.size.width/2, 75, 2, tooltip3.frame.size.height - 80))
            //line3.backgroundColor = UIColor(netHex: 0xEEEEEE)
            line3.image = UIImage(named: "dottedLine")
            line3.contentMode = .Top
            line3.clipsToBounds = true
            self.line3 = line3
            tooltip3.addSubview(line3)
            let titleLabel3 = UILabel(frame: CGRectMake(0, 0, messageView3.frame.size.width, 20))
            titleLabel3.textAlignment = .Center
            titleLabel3.font = UIFont(name: "Raleway-Bold", size: 16.0)
            titleLabel3.textColor = UIColor(netHex: 0x211E23)
            titleLabel3.backgroundColor = UIColor(netHex: 0xEEEEEE)
            titleLabel3.text = "RESPOND"
            messageView3.addSubview(titleLabel3)
            let messageLabel3 = UILabel(frame: CGRectMake(0, 20, messageView3.frame.size.width, messageView3.frame.size.height - 20))
            messageLabel3.numberOfLines = 2
            messageLabel3.textAlignment = .Center
            messageLabel3.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
            messageLabel3.textColor = UIColor(netHex: 0xEEEEEE)
            messageLabel3.backgroundColor = UIColor(netHex: 0x1098F7)
            messageLabel3.text = "Respond to posts with a voice note"
//            let messageText3 = "Reply to a post by\nrecording a voice\nnote."
//            let range3 = (messageText3 as NSString).rangeOfString("Reply")
//            let attributedString3 = NSMutableAttributedString(string:messageText3)
//            attributedString3.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 14)!, NSForegroundColorAttributeName: UIColor(netHex: 0xFB4B4E)], range: range3)
//            messageLabel3.attributedText = attributedString3
            messageView3.addSubview(messageLabel3)
        }
        
        //print(frameWidth)
        if frameWidth <= 320 {
            let largerInset = 0.06*frame.width
            let smallerInset = 0.03*frame.width
            leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            rightButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            leftButton.setImage(UIImage(named: "cancelAccessory_small"), forState: .Normal)
            rightButton.setImage(UIImage(named: "bookmarkPostAccessory_small"), forState: .Normal)
            recordButton.setImage(UIImage(named: "recordAccessorySmall"), forState: .Normal)
            leftButton.setImage(UIImage(named: "outlinedCancelAccessory_small"), forState: .Selected)
            rightButton.setImage(UIImage(named: "outlinedCheckAccessory_small"), forState: .Selected)
        } else {
            let largerInset = 0.06*frame.width
            let smallerInset = 0.03*frame.width
            leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right:0)
            rightButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            leftButton.setImage(UIImage(named: "cancelAccessory"), forState: .Normal)
            rightButton.setImage(UIImage(named: "bookmarkPostAccessory"), forState: .Normal)
            recordButton.setImage(UIImage(named: "recordAccessoryBig"), forState: .Normal)
            leftButton.setImage(UIImage(named: "outlinedCancelAccessory"), forState: .Selected)
            rightButton.setImage(UIImage(named: "outlinedCheckAccessory"), forState: .Selected)
        }
        
        //recordButton.imageEdgeInsets = UIEdgeInsets(top: smallerInset, left: smallerInset, bottom: smallerInset, right: smallerInset)
        
        if (savedMode) {
            leftButton.hidden = true
            rightButton.hidden = true
            leftButton = UIButton(frame: CGRectMake(frame.width/3,frame.height/2,frame.width/3, frame.height/2))
            //leftButton.backgroundColor = UIColor.redColor()
            rightButton = UIButton(frame: CGRectMake(frame.width*2/3,0,frame.height/3, frame.height/3))
            //rightButton.backgroundColor = UIColor.yellowColor()
            recordButton = UIButton(frame: CGRectMake(frame.width/3,0,frame.width/3, frame.height/2))
            //recordButton.backgroundColor = UIColor.greenColor()
            
            if frameWidth <= 320 {
                leftButton.setImage(UIImage(named: "cancelAccessory_small"), forState: .Normal)
                rightButton.setImage(UIImage(named: "bookmarkPostAccessory_small"), forState: .Normal)
                recordButton.setImage(UIImage(named: "recordAccessorySmall"), forState: .Normal)
                leftButton.setImage(UIImage(named: "outlinedCancelAccessory_small"), forState: .Selected)
                rightButton.setImage(UIImage(named: "outlinedCheckAccessory_small"), forState: .Selected)
            } else {
                leftButton.setImage(UIImage(named: "cancelAccessory"), forState: .Normal)
                rightButton.setImage(UIImage(named: "bookmarkPostAccessory"), forState: .Normal)
                recordButton.setImage(UIImage(named: "recordAccessoryBig"), forState: .Normal)
                leftButton.setImage(UIImage(named: "outlinedCancelAccessory"), forState: .Selected)
                rightButton.setImage(UIImage(named: "outlinedCheckAccessory"), forState: .Selected)
            }
            
            rightButton.center = CGPointMake(frame.width/2, frame.height/2)
            
            let largerInset = 0.03*frame.width
            //let smallerInset = 0.015*frame.width
            //leftButton.imageEdgeInsets = UIEdgeInsets(top: largerInset, left: largerInset, bottom: largerInset, right: largerInset)
            //rightButton.imageEdgeInsets = UIEdgeInsets(top: largerInset, left: largerInset, bottom: largerInset, right: largerInset)
            //recordButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
        
        leftButton.imageView?.contentMode = .ScaleAspectFit
        rightButton.imageView?.contentMode = .ScaleAspectFit
        recordButton.imageView?.contentMode = .ScaleAspectFit
        
        if (!bookmarkingEnabled) {
            rightButton.alpha = 0
        }
        
        isRecording = false
        
        countdownLabel = UILabel(frame: recordButton.frame)
        countdownLabel.alpha = 0
        countdownLabel.font = UIFont(name: "Raleway-Regular", size: 30)
        countdownLabel.textColor = UIColor.whiteColor()
        countdownLabel.textAlignment = .Center
        
        cancelHandler = {
            
        }
        
        super.init(frame: frame)
        
        backgroundColor = UIColor.vocaleBackgroundGreyColor()
        addSubview(leftButton)
        if (!savedMode) {
            addSubview(rightButton)
        }
        addSubview(recordButton)
        addSubview(countdownLabel)
        if NSUserDefaults.standardUserDefaults().boolForKey("FirstLogin") == false {
            addSubview(toolTip1!)
            addSubview(toolTip2!)
            addSubview(toolTip3!)
           NSNotificationCenter.defaultCenter().addObserver(self, selector: "removeToolTips", name: "TutorialViewTappedFirstTime", object: nil)
            self.toolTip1?.alpha = 0
            self.toolTip2?.alpha = 0
            self.toolTip3?.alpha = 0
            self.toolTip1?.transform = CGAffineTransformMakeTranslation(0, 40)
            self.toolTip2?.transform = CGAffineTransformMakeTranslation(0, 40)
            self.toolTip3?.transform = CGAffineTransformMakeTranslation(0, 40)
            self.line1?.alpha = 0
            self.line2?.alpha = 0
            self.line3?.alpha = 0
            UIView.animateWithDuration(0.3, delay: 0.3, options: .CurveEaseInOut, animations: {
                self.toolTip1?.alpha = 1
                self.toolTip2?.alpha = 1
                self.toolTip3?.alpha = 1
                self.toolTip1?.transform = CGAffineTransformMakeTranslation(0, 0)
                self.toolTip2?.transform = CGAffineTransformMakeTranslation(0, 0)
                self.toolTip3?.transform = CGAffineTransformMakeTranslation(0, 0)
            }) { (finished) in
                UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: {
                    self.line1?.alpha = 1
                    self.line2?.alpha = 1
                    self.line3?.alpha = 1
                }) { (finished) in
                    
                }
            }
        }
        
        leftButton.addTarget(self, action: #selector(leftButtonTapped), forControlEvents: .TouchUpInside)
        rightButton.addTarget(self, action: #selector(rightButtonTapped), forControlEvents: .TouchUpInside)
        recordButton.addTarget(self, action: #selector(recordButtonTapped), forControlEvents: .TouchUpInside)
        
          completionHandler =  {
                success, error, url in
                if let url = url, conversationController = self.conversationController {
                    let dataDictionary = ["title": "VoiceNote"]
                    do {
                        //print("!")
                        let dataDictionaryJSON = try NSJSONSerialization.dataWithJSONObject(dataDictionary, options: NSJSONWritingOptions.PrettyPrinted)
                        let dataMessagePart = LYRMessagePart(MIMEType: "application/json+voicenoteobject", data: dataDictionaryJSON)
                        
                        let cellInfoDictionary = ["height": "90"]
                        let cellInfoDictionaryJSON = try NSJSONSerialization.dataWithJSONObject(cellInfoDictionary, options: NSJSONWritingOptions.PrettyPrinted)
                        
                        let cellInfoMessagePart = LYRMessagePart(MIMEType: "application/json+voicenoteobject", data: cellInfoDictionaryJSON)
                        if let data = NSData(contentsOfURL: url) {
                            //print("!")
                            let dataType = "application/json+voicenoteobject"
                            let voiceNotePart = LYRMessagePart(MIMEType: dataType, data: data)
                            
                            var receiverID = ""
                            for participant in conversationController.conversation.participants {
                                if participant != PFUser.currentUser()?.objectId {
                                    receiverID = participant
                                }
                            }
                            
                            let defaultConfiguration = LYRPushNotificationConfiguration()
                            defaultConfiguration.alert = "You have new voice message"
                            let options = [LYRMessageOptionsPushNotificationConfigurationKey: defaultConfiguration]
                            
                            if let message = try AppDelegate.layerClient?.newMessageWithParts([dataMessagePart, cellInfoMessagePart, voiceNotePart], options:options ) {
                                
                                //let receiverID = conversationController.conversation.participants.first{
                                //print("!")
                                do {
                                    if let conversation = try AppDelegate.layerClient?.newConversationWithParticipants([receiverID], options: nil) {
                                        //print("!")
                                        conversationController.sendMessage(message)
                                        self.completeUploadWithAnimation()
                                        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                            
                                            self.conversationController?.messageInputToolbar.alpha = 1
                                            self.alpha = 0
                                            
                                            }, completion: { (completed: Bool) -> Void in
                                                
                                                self.superview?.removeFromSuperview()
                                        })
                                    }
                                } catch {
//                                    if let conversations = try AppDelegate.layerClient?.conversationsForParticipants([receiverID]), conversation = conversations.first {
                                    
                                        conversationController.sendMessage(message)
                                        self.completeUploadWithAnimation()
                                        //KGStatusBar.showSuccessWithStatus("Message Sent.")
                                        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                                            
                                            self.conversationController?.messageInputToolbar.alpha = 1
                                            self.alpha = 0
                                            
                                            }, completion: { (completed: Bool) -> Void in
                                                
                                                self.superview?.removeFromSuperview()
                                                
                                        })
                                    //}
                                }
                            }
                        }
                    } catch {
                        SVProgressHUD.showErrorWithStatus("An error occurred.  Please try again")
                        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                            
                            self.conversationController?.messageInputToolbar.alpha = 1
                            self.alpha = 0
                            
                            }, completion: { (completed: Bool) -> Void in
                                
                                self.superview?.removeFromSuperview()
                        })
                    }
                }
            
        }
        dismissEventClosure = {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            
            self.conversationController?.messageInputToolbar.alpha = 1
            self.alpha = 0
            
            }, completion: { (completed: Bool) -> Void in
            
            self.superview?.removeFromSuperview()
            })
        }
        
        cancelHandler = {
            print("CANCELHANDLER")
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.conversationController?.messageInputToolbar.alpha = 1
                self.alpha = 0
                
                }, completion: { (completed: Bool) -> Void in
                    if (completed) {
                        //self.conversationController?.messageInputToolbar.center = CGPointMake((self.conversationController?.messageInputToolbar.frame.width)!/2, self.frame.height - (self.conversationController?.messageInputToolbar.frame.height)!/2)
                        //self.conversationController?.messageInputToolbar.hidden = false
                        self.conversationController?.messageInputToolbar.alpha = 1
                        
                    self.superview?.removeFromSuperview()
                    }
            })
        }
        //backgroundColor = UIColor.whiteColor()

    }
    

    required init?(coder aDecoder: NSCoder) {
        
        leftButton = UIButton()
        rightButton = UIButton()
        recordButton = UIButton()
        
        isRecording = false
        
        cancelHandler = {
            
        }
        
        super.init(coder: aDecoder)
        
        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(recordButton)
        
        cancelHandler = {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                
                self.conversationController?.messageInputToolbar.alpha = 1
                self.alpha = 0
                
                }, completion: { (completed: Bool) -> Void in
                    
                    self.superview?.removeFromSuperview()
            })
        }
    }
    var duration = 60.0
    var recordTapped = {}
    func recordButtonTapped() {
        let microphoneGranted = {
            self.recordTapped()
            self.recordingManager = RecordingManager()
            if let recordingManager = self.recordingManager {
                if !recordingManager.isRecording {
                    //KGStatusBar.showErrorWithStatus("Recording:  Release to send")
                    recordingManager.startRecording()
                }
            }
            self.isRecording = true
            if let timer = self.timer {
                timer.invalidate()
            }
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(EventCardManager.updateCountDownLabel), userInfo: nil, repeats: true)
            self.duration = 60
            self.progress.animateFromAngle(0, toAngle: 360, duration: self.duration, relativeDuration: true) { (completed: Bool) -> Void in
                if completed {
                    //self.isRecording = false
                    if (self.isRecording) {
                        self.rightButtonTapped()
                    }
                }
            }
        }
        
        let session: AVAudioSession = AVAudioSession.sharedInstance()
        session.requestRecordPermission({(granted: Bool)-> Void in
            if granted {
                print("granted")
                dispatch_async(dispatch_get_main_queue()) {
                    microphoneGranted()
                }
            } else {
                let alert = UIAlertController(title: "Permission for microphone was denied.",
                    message: "Please enable access to microphone in the Settings app",
                    preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK".localized,
                    style: .Cancel,
                    handler: nil))
                alert.addAction(UIAlertAction(title: "Show me".localized,
                    style: .Default,
                    handler: { action in
                        AppManager.sharedInstance.openSettings()
                }))
                print("not granted")
            }
        })
    }
    
    var conversationController: ATLConversationViewController?
    
    var completionHandler: (success: Bool?, error: NSError?, url: NSURL?) -> Void = {_,_,_ in}
    
    var bookmarkEventClosure = {}
    func rightButtonTapped() {
        if (isRecording) {
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                if let recordingTooltip1 = self.recordingToolTip1, let recordingTooltip2 = self.recordingToolTip2, let recordingTooltip3 = self.recordingToolTip3 {
                    recordingTooltip1.alpha = 0
                    recordingTooltip2.alpha = 0
                    recordingTooltip3.alpha = 0
                }
            }) { (completed: Bool) -> Void in
                self.recordingToolTip1?.removeFromSuperview()
                self.recordingToolTip2?.removeFromSuperview()
                self.recordingToolTip3?.removeFromSuperview()
            }
            if let recordingManager = recordingManager {
                if recordingManager.isRecording {
                    recordingManager.stopRecordingAudio({ (success, error, audioFileUrl) -> Void in
                        self.showUploadAnimation()
                        //self.isRecording = false
                        //self.conversationController?.messageInputToolbar.hidden = false
                        self.completionHandler(success: success, error: error, url: audioFileUrl)
                    })
                }
            }
            
            if let userId = event?.owner.objectId {
                Mixpanel.sharedInstance().track("Stream Post Voice Reply Sent", properties:["duration": Int(60.0-duration) * 1000, "user": event!.owner.objectId!])
                FBSDKAppEvents.logEvent("Stream Post Voice Reply Sent", parameters:["duration": Int(60.0-duration) * 1000, "user": event!.owner.objectId!])
            }
        } else {
            isBookmarked = !isBookmarked
            bookmarkEventClosure()
            
            Mixpanel.sharedInstance().track("Stream Post Bookmarked", properties:["post": event!.objectId!, "creator" : event!.owner.objectId!])
        }
    }
    var dismissEventClosure = {}
    var cancelHandler: () -> Void
    func leftButtonTapped() {
        self.delegate?.cancelVoiceMessage()
        if (isRecording) {
            if let recordingManager = recordingManager {
                if recordingManager.isRecording {
                    recordingManager.cancelRecordingAudio()
                    //wixthCompletion(success: true, error: nil)
                    self.isRecording = false
                    cancelHandler()
                }
            }
            
            Mixpanel.sharedInstance().track("Stream Post Voice Reply Cancelled", properties:["duration": Int(60.0-duration) * 1000])
            
            recordingManager = nil
        } else {
            if (savedMode) {
            removeEventClosure()
            }
            dismissEventClosure()
            
            Mixpanel.sharedInstance().track("Stream Post Deleted", properties:["post": event!.objectId!, "creator" : event!.owner.objectId!])
        }
    }
    
    func updateCountDownLabel() {
        if(duration > 0)
        {
            countdownLabel.text = String(Int(duration--))
        } else {
        }
        
    }
var uploadImageView = UIImageView()
    func showUploadAnimation() {
        if chatSection == false {
            self.delegate?.uploadingVoiceMessage()
            let uploadIcon = UIImage(assetIdentifier: .voiceNoteUploadArrow)
            uploadImageView.backgroundColor = UIColor.redColor()
            if self.frameWidth <= 320 {
                uploadImageView = UIImageView(frame: CGRectMake(frame.width/2 - 35, frame.height + 10, 70, 70))
            } else if self.frameWidth < 414 {
                uploadImageView = UIImageView(frame: CGRectMake(frame.width/2 - 35, frame.height, 70, 70))
                if (UIScreen.mainScreen().nativeScale == 2.8) { //ZOOMED MODE
                    uploadImageView = UIImageView(frame: CGRectMake(frame.width/2 - 35, frame.height - 30, 70, 70))
                }
            } else {
                print(frame.height)
                uploadImageView = UIImageView(frame: CGRectMake(frame.width/2 - 35, frame.height - 30, 70, 70))
            }

            uploadImageView.image = uploadIcon
            uploadImageView.contentMode = .ScaleAspectFit
            addSubview(uploadImageView)
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.leftButton.alpha = 0
                self.rightButton.alpha = 0
                self.progress.alpha = 0
                self.countdownLabel.alpha = 0
                if self.frameWidth <= 320 {
                    self.uploadImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 6)
                } else if self.frameWidth < 414 {
                    self.uploadImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 8)
                    if (UIScreen.mainScreen().nativeScale == 2.8) { //ZOOMED MODE
                        self.uploadImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 10)
                    }
                } else {
                    self.uploadImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 10)
                }
                
            }) { (completed: Bool) -> Void in
                
            }
        }
    }
    
    var removeEventClosure = {}
    
    func completeUploadWithAnimation() {
        if chatSection == false {
            self.delegate?.sentVoiceMessage()
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.uploadImageView.frame.origin.y = 0 - self.uploadImageView.frame.height
                self.uploadImageView.alpha = 0
                
            }) { (completed: Bool) -> Void in
                
            }
            
            let checkIcon = UIImage(assetIdentifier: .voiceNoteUploadCheck)
            let checkImageView = UIImageView()
            if frameWidth <= 320 {
                checkImageView.frame = CGRectMake(frame.width/2 - 35, frame.height + 10, 70, 70)
            } else {
                checkImageView.frame = CGRectMake(frame.width/2 - 35, frame.height, 70, 70)
            }
            checkImageView.image = checkIcon
            checkImageView.contentMode = .ScaleAspectFit
            
            addSubview(checkImageView)
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                if self.frameWidth <= 320 {
                    checkImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 6)
                } else if self.frameWidth < 414 {
                    checkImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 9)
                    if (UIScreen.mainScreen().nativeScale == 2.8) { //ZOOMED MODE
                        checkImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 10)
                    }
                } else {
                    checkImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 10)
                }
                    
            }) { (completed: Bool) -> Void in
                
            }
            
            UIView.animateWithDuration(0.4, delay: 0.8, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                checkImageView.frame.origin.y = 0 - checkImageView.frame.height
                checkImageView.alpha = 0
            }) { (completed: Bool) -> Void in
                if (completed) {
                    self.isRecording = false
                }
            }

        }
    }
}
