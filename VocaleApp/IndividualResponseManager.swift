//
//  IndividualResponseManager.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/26.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import AVFoundation

protocol IndividualEventCardManagerDelegate: class {
    func individualUploadingVoiceMessage()
    func individualSentVoiceMessage()
    func individualCancelVoiceMessage()
    func individualUploadedVoiceMessage()
    func deleteButtonPressed()
}

class IndividualResponseManager: UIView, AVAudioPlayerDelegate {

    weak var delegate:IndividualEventCardManagerDelegate?
    private var player: AVAudioPlayer?
    var playButtonTooltip: UIView?
    var recordButtonTooltip: UIView?
    var audioData: NSData? {
        didSet {
            if let data = audioData {
                //self.activateProximitySensor()
                do {
                    try self.player = AVAudioPlayer(data: data)

                    self.player!.delegate = self
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                    UIView.animateWithDuration(0.3, animations: { () -> Void in
                    })
                } catch {
                    print(error)
                    SVProgressHUD.showErrorWithStatus("An error occurred.  Please try again")
                }
            }
        }
    }

    var voicenoteURL: NSURL?
    private var recordingManager: RecordingManager?

    var timer: NSTimer?
    var countdownLabel = UILabel() {
        didSet {

        }
    }

    var leftCenter = CGPoint(x: 0, y: 0)
    var rightCenter = CGPoint(x: 0, y: 0)
    var middleCenter = CGPoint(x: 0, y: 0)

    var isRecording: Bool {
        didSet {
            leftCenter = leftButton.center
            rightCenter = rightButton.center
            middleCenter = middleButton.center

            leftButton.backgroundColor = UIColor.clearColor()
            if (isRecording) {
                print(middleButton.frame.width)
                progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: middleButton.frame.width - 15, height: middleButton.frame.width - 15))
                progress.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
                progress.alpha = 0
                addSubview(progress)
                
                self.leftButton.frame = CGRectMake(self.leftButton.frame.origin.x + 10, self.leftButton.frame.origin.y, 50, 50)
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                    self.leftButton.center = self.middleButton.center
                    self.rightButton.center = self.middleButton.center
                    self.leftButton.alpha = 0
                    self.rightButton.alpha = 0
                    self.middleButton.alpha = 0

                    }) { (completed: Bool) -> Void in
                        if (completed) {

                            self.leftButton.selected = true
                            self.rightButton.selected = true

                            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                                self.progress.alpha = 1
                                self.leftButton.alpha = 1
                                self.rightButton.alpha = 1
                                self.countdownLabel.alpha = 1
                                self.leftButton.center = CGPoint(x:(self.frame.size.width/3)/2 + 10 , y: (self.frame.size.height/2)-25)
                                self.rightButton.center = CGPoint(x: (self.frame.size.width/3)*2 + (self.frame.size.width/3)/2, y: (self.frame.size.height/2)-25)

                                }) { (completed: Bool) -> Void in
                            }

                        }
                }


            } else {
                self.middleButton.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                    self.leftButton.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
                    self.rightButton.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
                    self.leftButton.alpha = 0
                    self.rightButton.alpha = 0
                    self.middleButton.alpha = 1
                    self.progress.alpha = 0
                    self.countdownLabel.alpha = 0

                    }) { (completed: Bool) -> Void in
                        if (completed) {
                            self.progress.removeFromSuperview()

                            self.leftButton.selected = false
                            self.rightButton.selected = false
                            
                            self.leftButton.backgroundColor = UIColor(netHex: 0xEEEEEE)
                            self.leftButton.frame = CGRectMake(0,self.frame.height - 44,self.frame.width, 44)
                            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                                self.leftButton.alpha = 1
                                self.rightButton.alpha = 1
                                self.middleButton.center = self.middleCenter
                                self.rightButton.frame = CGRectMake(self.frame.width/3 + (self.frame.width/3)/2,-20,self.frame.width/3, self.frame.height)
                                }) { (completed: Bool) -> Void in
                            }
                        }
                }
            }
        }
    }

    var isPlaying: Bool {
        didSet {

            if (isPlaying) {
                activateProximitySensor()
                leftCenter = leftButton.center
                rightCenter = rightButton.center
                middleCenter = middleButton.center

                progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: middleButton.frame.width, height: middleButton.frame.height))
                progress.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
                progress.alpha = 0
                progress.progressColors = [UIColor(red: 51/255, green: 163/255, blue: 251/255, alpha: 1)]
                addSubview(progress)
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                    //self.leftButton.center = self.middleButton.center
                    self.rightButton.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
                    self.middleButton.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
                    self.leftButton.alpha = 0
                    self.rightButton.alpha = 0
                    self.middleButton.alpha = 0

                    }) { (completed: Bool) -> Void in
                        if (completed) {

                            self.leftButton.highlighted = true

                            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                                self.progress.alpha = 1
                                self.leftButton.alpha = 1
                                self.progress.alpha = 1
                                self.countdownLabel.alpha = 1
                                //self.leftButton.center = self.leftCenter

                                }) { (completed: Bool) -> Void in
                            }

                        }
                }


            } else {
                deactivateProximitySensor()
                self.progress.removeFromSuperview()

                self.leftButton.selected = false
                self.rightButton.selected = false
                self.leftButton.highlighted = false
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                    //self.leftButton.center = self.middleButton.center
                    self.leftButton.alpha = 0
                    self.middleButton.alpha = 1
                    self.progress.alpha = 0
                    self.countdownLabel.alpha = 0

                    }) { (completed: Bool) -> Void in
                        if (completed) {
                            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                                self.leftButton.alpha = 1
                                self.rightButton.alpha = 1
                                self.middleButton.alpha = 1
                                //self.leftButton.center = self.leftCenter
                                self.rightButton.center = self.rightCenter
                                self.middleButton.center = self.middleCenter
                                self.progress.alpha = 0
                                self.countdownLabel.alpha = 0

                                }) { (completed: Bool) -> Void in
                            }
                        }
                }
            }
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

    private var middleButton: UIButton {
        didSet {
        }
    }

    var progress = KDCircularProgress() {
        didSet {
            progress.startAngle = -90
            progress.progressThickness = 0.25
            progress.trackThickness = 0.25
            progress.clockwise = true
            progress.center = middleButton.center
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

    override init(frame: CGRect) {
        
        middleButton = UIButton(frame: CGRectMake(frame.width/3 - (frame.width/3)/2,-20, frame.width/3, frame.height))
        rightButton = UIButton(frame: CGRectMake(frame.width/3 + (frame.width/3)/2,-20,frame.width/3, frame.height))
        //rightButton.backgroundColor = UIColor.redColor()
        leftButton = UIButton(frame: CGRectMake(0,frame.height - 44,frame.width, 44))
        leftButton.backgroundColor = UIColor(netHex: 0xEEEEEE)

        if frame.width <= 320 {
            leftButton.setImage(UIImage(named: "deleteButton"), forState: .Normal)
            rightButton.setImage(UIImage(named: "recordAccessorySmall"), forState: .Normal)
            middleButton.setImage(UIImage(named: "playAccessory_small"), forState: .Normal)
            leftButton.setImage(UIImage(named: "outlinedCancelAccessory_small"), forState: .Selected)
            rightButton.setImage(UIImage(named: "outlinedCheckAccessory_small"), forState: .Selected)
            leftButton.setImage(UIImage(named: "stopButton"), forState: .Highlighted)
        } else {
            leftButton.setImage(UIImage(named: "deleteButton"), forState: .Normal)
            rightButton.setImage(UIImage(named: "recordAccessoryBig"), forState: .Normal)
            middleButton.setImage(UIImage(named: "playAccessory"), forState: .Normal)
            leftButton.setImage(UIImage(named: "outlinedCancelAccessory"), forState: .Selected)
            rightButton.setImage(UIImage(named: "outlinedCheckAccessory"), forState: .Selected)
            leftButton.setImage(UIImage(named: "stopButton"), forState: .Highlighted)
        }

        //leftButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        rightButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 20)
        //middleButton.imageEdgeInsets = UIEdgeInsets(top: 30, left: 30, bottom: 30, right: 30)

        leftButton.imageView?.contentMode = .ScaleAspectFit
        rightButton.imageView?.contentMode = .ScaleAspectFit
        middleButton.imageView?.contentMode = .ScaleAspectFit

        isRecording = false
        isPlaying = false

        countdownLabel = UILabel(frame: middleButton.frame)
        countdownLabel.center = CGPoint(x: frame.size.width/2, y: frame.size.height/2 - 20)
        countdownLabel.alpha = 0
        countdownLabel.font = UIFont(name: "Raleway-Regular", size: 30)
        countdownLabel.textColor = UIColor.whiteColor()
        countdownLabel.textAlignment = .Center

        super.init(frame: frame)
        backgroundColor = UIColor(red: 30/255, green: 30/255, blue: 30/255, alpha: 1)
        addSubview(rightButton)
        addSubview(middleButton)
        addSubview(leftButton)
        addSubview(countdownLabel)

        leftButton.addTarget(self, action: #selector(IndividualResponseManager.leftButtonTapped), forControlEvents: .TouchUpInside)
        rightButton.addTarget(self, action: #selector(IndividualResponseManager.rightButtonTapped), forControlEvents: .TouchUpInside)
        middleButton.addTarget(self, action: #selector(IndividualResponseManager.middleButtonTapped), forControlEvents: .TouchUpInside)
    }
    
    func addTooltips() {
        var bigIconHeight: CGFloat = 70.0
        if frame.width <= 320 {
            bigIconHeight = 60.0
        }
        
        let tooltip1 = UIView(frame:  CGRectMake(middleButton.center.x - 74, middleButton.center.y - bigIconHeight/2 - 120, 148, 120))
        tooltip1.backgroundColor = UIColor.clearColor()
        playButtonTooltip = tooltip1
        let messageView1 = UIView(frame: CGRectMake(0,0,tooltip1.frame.size.width - 28, 70))
        messageView1.backgroundColor = UIColor(netHex: 0x211E23)
        messageView1.layer.cornerRadius = 4
        messageView1.layer.borderWidth = 1
        messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView1.clipsToBounds = true
        tooltip1.addSubview(messageView1)
        let line1 = UIImageView(frame: CGRectMake((tooltip1.frame.size.width - 2)/2, 75, 2, tooltip1.frame.size.height - 80))
        line1.image = UIImage(named: "dottedLine")
        line1.contentMode = .Top
        line1.clipsToBounds = true
        tooltip1.addSubview(line1)
        let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel1.textAlignment = .Center
        titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel1.textColor = UIColor(netHex: 0x211E23)
        titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel1.text = "PLAY"
        messageView1.addSubview(titleLabel1)
        let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
        messageLabel1.numberOfLines = 2
        messageLabel1.textAlignment = .Center
        messageLabel1.font = UIFont(name: "Raleway-Regular", size: 14.0)
        messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel1.backgroundColor = UIColor(netHex: 0x1098F7)
        let messageText1 = "Play the voice message"
        messageLabel1.text = messageText1
//        let range1 = (messageText1 as NSString).rangeOfString("Play")
//        let attributedString1 = NSMutableAttributedString(string:messageText1)
//        attributedString1.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 14)!, NSForegroundColorAttributeName: UIColor(netHex: 0x1098F7)], range: range1)
//        messageLabel1.attributedText = attributedString1
        messageView1.addSubview(messageLabel1)
        self.addSubview(playButtonTooltip!)
        
        let tooltip2 = UIView(frame:  CGRectMake(rightButton.center.x - 74, rightButton.center.y - bigIconHeight/2 - 120, 148, 120))
        tooltip2.backgroundColor = UIColor.clearColor()
        recordButtonTooltip = tooltip2
        let messageView2 = UIView(frame: CGRectMake(24,0,tooltip2.frame.size.width - 24, 70))
        messageView2.backgroundColor = UIColor(netHex: 0x211E23)
        messageView2.layer.cornerRadius = 4
        messageView2.layer.borderWidth = 1
        messageView2.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView2.clipsToBounds = true
        tooltip2.addSubview(messageView2)
        let line2 = UIImageView(frame: CGRectMake((tooltip2.frame.size.width - 2)/2 - 12, 75, 2, tooltip2.frame.size.height - 80))
        line2.image = UIImage(named: "dottedLine")
        line2.contentMode = .Top
        line2.clipsToBounds = true
        tooltip2.addSubview(line2)
        let titleLabel2 = UILabel(frame: CGRectMake(0, 0, messageView2.frame.size.width, 20))
        titleLabel2.textAlignment = .Center
        titleLabel2.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel2.textColor = UIColor(netHex: 0x211E23)
        titleLabel2.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel2.text = "REPLY"
        messageView2.addSubview(titleLabel2)
        let messageLabel2 = UILabel(frame: CGRectMake(0, 20, messageView2.frame.size.width, messageView2.frame.size.height - 20))
        messageLabel2.numberOfLines = 2
        messageLabel2.textAlignment = .Center
        messageLabel2.font = UIFont(name: "Raleway-Regular", size: 14.0)
        messageLabel2.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel2.backgroundColor = UIColor(netHex: 0x1098F7)
        let messageText2 = "Send a voice response"
        messageLabel2.text = messageText2
//        let range2 = (messageText2 as NSString).rangeOfString("Response")
//        let attributedString2 = NSMutableAttributedString(string:messageText2)
//        attributedString2.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 14)!, NSForegroundColorAttributeName: UIColor(netHex: 0xFB4B4E)], range: range2)
//        messageLabel2.attributedText = attributedString2
        messageView2.addSubview(messageLabel2)
        self.addSubview(recordButtonTooltip!)
        
        playButtonTooltip?.alpha = 0
        recordButtonTooltip?.alpha = 0
        UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.playButtonTooltip?.alpha = 1
            self.recordButtonTooltip?.alpha = 1
        }) { (finished) in
            
        }
    }



    required init?(coder aDecoder: NSCoder) {

        leftButton = UIButton()
        rightButton = UIButton()
        middleButton = UIButton()

        isRecording = false
        isPlaying = false

        super.init(coder: aDecoder)

        addSubview(leftButton)
        addSubview(rightButton)
        addSubview(middleButton)
    }
    var duration = 60.0
    var recordTapped = {}
    func middleButtonTapped() {
        
        //print("middleButtonTapped!")
        if (!isPlaying) {
            //print("play!")
            UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { 
                if let playButtonToolTip = self.playButtonTooltip, let recordButtonToolTip = self.recordButtonTooltip {
                    playButtonToolTip.alpha = 0
                    recordButtonToolTip.alpha = 0
                }
                }, completion: { (finished) in
                    self.playButtonTooltip?.removeFromSuperview()
                    self.recordButtonTooltip?.removeFromSuperview()
            })
            let device = UIDevice.currentDevice()
            device.proximityMonitoringEnabled = false
            player?.play()
            isPlaying = true
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(IndividualResponseManager.updateCountDownLabel), userInfo: nil, repeats: true)
            if let duration = player?.duration {
                self.duration = duration
            }
            self.progress.animateFromAngle(0, toAngle: 360, duration: duration, relativeDuration: true) { (completed: Bool) -> Void in
                if completed {
                    //self.isRecording = false
                    if (self.isRecording) {
                        self.rightButtonTapped()
                    }
                }
            }
        }
    }

    var completionHandler: (success: Bool?, error: NSError?, url: NSURL?) -> Void = {
        _,_,_ in
    }
    var bookmarkEventClosure = {}
    func rightButtonTapped() {
        if (isRecording) {
            if let recordingManager = recordingManager {
                if recordingManager.isRecording {
                    recordingManager.stopRecordingAudio({ (success, error, voicenoteURL) -> Void in
                        self.showUploadAnimation()
                        //
                        //
                        let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.6 * Double(NSEC_PER_SEC)))
                        dispatch_after(when, dispatch_get_main_queue()) {
                            self.completionHandler(success: success, error: error, url: voicenoteURL)
                        }
                    })
                }
            }
        } else {
            UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
                if let playButtonToolTip = self.playButtonTooltip, let recordButtonToolTip = self.recordButtonTooltip {
                    playButtonToolTip.alpha = 0
                    recordButtonToolTip.alpha = 0
                }
                }, completion: { (finished) in
                    self.playButtonTooltip?.removeFromSuperview()
                    self.recordButtonTooltip?.removeFromSuperview()
            })
            recordTapped()
            recordingManager = RecordingManager()
            if let recordingManager = recordingManager {
                if !recordingManager.isRecording {
                    //KGStatusBar.showErrorWithStatus("Recording:  Release to send")
                    recordingManager.startRecording()
                }
            }
            self.isRecording = true
            if let timer = timer {
                timer.invalidate()
            }
            timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(IndividualResponseManager.updateCountDownLabel), userInfo: nil, repeats: true)
            duration = 60
            self.progress.animateFromAngle(0, toAngle: 360, duration: duration, relativeDuration: true) { (completed: Bool) -> Void in
                if completed {
                    //self.isRecording = false
                    if (self.isRecording) {
                        self.rightButtonTapped()
                    }
                }
            }
        }
    }
    var dismissEventClosure = {}
    var cancelHandler = {}
    func leftButtonTapped() {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
            if let playButtonToolTip = self.playButtonTooltip, let recordButtonToolTip = self.recordButtonTooltip {
                playButtonToolTip.alpha = 0
                recordButtonToolTip.alpha = 0
            }
            }, completion: { (finished) in
                self.playButtonTooltip?.removeFromSuperview()
                self.recordButtonTooltip?.removeFromSuperview()
        })
        self.delegate?.individualCancelVoiceMessage()
        if (isRecording) {
            if let recordingManager = recordingManager {
                if recordingManager.isRecording {
                    recordingManager.cancelRecordingAudio()
                    //withCompletion(success: true, error: nil)
                    self.isRecording = false
                    cancelHandler()
                }
            }
            recordingManager = nil
        } else if (isPlaying) {
            stopPlayback()
        } else {
            self.delegate?.deleteButtonPressed()
            //dismissEventClosure()
        }
    }

    func stopPlayback() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
        timer?.invalidate()
        deactivateProximitySensor()
    }

    func updateCountDownLabel() {
        if(duration > 0) {
            duration -= 1
            countdownLabel.text = String(Int(duration))
        } else {
        }

    }
    var uploadImageView = UIImageView()
    func showUploadAnimation() {
        //print("individualResponseManager")
        self.delegate?.individualUploadingVoiceMessage()
        let uploadIcon = UIImage(assetIdentifier: .voiceNoteUploadArrow)
        uploadImageView = UIImageView(frame:
            CGRectMake(frame.width/2 - 35, frame.height, 70, 70))
        uploadImageView.image = uploadIcon
        uploadImageView.contentMode = .ScaleAspectFit
        addSubview(uploadImageView)
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.leftButton.alpha = 0
            self.rightButton.alpha = 0
            self.progress.alpha = 0
            self.countdownLabel.alpha = 0
            self.uploadImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 20)
            }) { (completed: Bool) -> Void in

        }
    }

    func completeUploadWithAnimation() {
        self.delegate?.individualSentVoiceMessage()
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.uploadImageView.frame.origin.y = 0 - self.uploadImageView.frame.height
            self.uploadImageView.alpha = 0
            }) { (completed: Bool) -> Void in
        }

        let checkIcon = UIImage(assetIdentifier: .voiceNoteUploadCheck)
        let checkImageView = UIImageView(frame:
            CGRectMake(self.frame.width/2 - 35, self.frame.height, 70, 70))
        checkImageView.image = checkIcon
        checkImageView.contentMode = .ScaleAspectFit

        self.addSubview(checkImageView)
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            checkImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 20)
            }) { (completed: Bool) -> Void in
                self.delegate?.individualUploadedVoiceMessage()
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

    // MARK: - Proximity Sensor

    private func activateProximitySensor() {
        let device = UIDevice.currentDevice()
        device.proximityMonitoringEnabled = true
        if device.proximityMonitoringEnabled {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(IndividualResponseManager.proximityChanged(_:)), name: "UIDeviceProximityStateDidChangeNotification", object: device)
        }
    }

    func deactivateProximitySensor() {
        let device = UIDevice.currentDevice()
        if device.proximityMonitoringEnabled {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: "UIDeviceProximityStateDidChangeNotification", object: device)
            device.proximityMonitoringEnabled = false
        }
    }

    func proximityChanged(notification: NSNotification) {
        if let player = player {
            if player.playing {
                if let device = notification.object as? UIDevice {
                    print("\(device) detected!")
                    if device.proximityState {
                        player.stop()
                        if (player.currentTime > 3) {
                            player.currentTime = player.currentTime - 3

                        } else {
                            player.currentTime = 0
                        }

                        do {
                            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
                            player.play()
                        } catch _ {
                        }
                    } else {
                        if (player.currentTime > 3) {
                            player.currentTime = player.currentTime - 3

                        } else {
                            player.currentTime = 0
                        }
                        do {
                            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                            player.play()
                        } catch _ {
                        }
                    }
                }
            }
        }
    }

    func playButtonTapped(sender: AnyObject) {
        if let player = player {
            if player.playing == false {
                player.play()
                activateProximitySensor()
            } else {
                player.pause()
                deactivateProximitySensor()
            }
        }
    }

    // MARK: - AVAudioPlayer Delegate

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        deactivateProximitySensor()
        isPlaying = false
        if let timer = timer {
            timer.invalidate()
        }
    }

    func showButtonsWithAnimation(shouldAnimate: Bool) {
        if shouldAnimate {
            self.rightButton.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
            self.middleButton.center = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2 - 20)
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                self.middleButton.frame = CGRectMake(self.frame.width/3 - (self.frame.width/3)/2,-20, self.frame.width/3, self.frame.height)
                self.rightButton.frame = CGRectMake(self.frame.width/3 + (self.frame.width/3)/2,-20,self.frame.width/3, self.frame.height)
                self.leftButton.alpha = 1
                self.rightButton.alpha = 1
                self.middleButton.alpha = 1
                }) { (completed: Bool) -> Void in
                    //NSUserDefaults.standardUserDefaults().setBool(false, forKey: "FirstResponseTapped")
                    if NSUserDefaults.standardUserDefaults().boolForKey("FirstResponseTapped") == false {
                        self.addTooltips()
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "FirstResponseTapped")
                        NSUserDefaults.standardUserDefaults().synchronize()
                    }
            }
        } else {
            self.leftButton.center = self.middleButton.center
            self.rightButton.center = self.middleButton.center
            self.leftButton.alpha = 1
            self.rightButton.alpha = 1
        }
    }

}
