//
//  TimePickerViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/29/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class TimePickerViewController: UIViewController {
    
    enum timeFramePickerMode {
        case hours
        case days
    }
    var registerFlow = false
    var currentTimeFramePickerMode: timeFramePickerMode = .days {
        didSet {
            if currentTimeFramePickerMode == .hours {
                hoursOrDaysLabel.text = "Hours"
                
                counterLabel.text = "\(currentHourCounterValue)"
                let countAngle = currentHourCounterValue*360/maxCount
                
            } else {
                hoursOrDaysLabel.text = "Days"
                
                counterLabel.text = "\(currentDayCounterValue)"
                let countAngle = currentDayCounterValue*360/maxCount
                
            }
        }
    }
    
    var shouldTrackDuration = true // Used by Mixpanel
    
    var createPostTapped = false
    var hourMode = true
    var eventInCreation = Event()
    var progressView: KDCircularProgress?
    var countAngle = 0
    var maxCountAngle = 360
    var maxCount = 12
    var maxHourCount = 6
    var currentHourCounterValue = 0 {
        didSet {
            counterLabel.text = "\(currentHourCounterValue)"
        }
    }
    var currentDayCounterValue = 0 {
        didSet {
            counterLabel.text = "\(currentDayCounterValue)"
        }
    }
    
    @IBOutlet weak var slideYourFingerLabel: UILabel! {
        didSet {
            slideYourFingerLabel.text = "Slide your finger around the circle to\nselect the timeframe for your post."
        }
    }
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var hoursOrDaysLabel: UILabel!
    @IBOutlet weak var tuner: C2AClickWheel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.backBarButtonItem?.title = ""
        progressView = KDCircularProgress(frame: CGRectMake((view.frame.width-320)/2, (view.frame.height - 80)/2 - 160, 320, 320), colors: UIColor.vocaleRedColor())
        progressView?.trackColor = UIColor.darkGrayColor()
        progressView?.trackThickness = progressView!.trackThickness/3
        progressView?.progressThickness = progressView!.trackThickness
        progressView?.glowAmount = 0
        tuner?.superview?.addSubview(progressView!)
        //tuner?.superview?.insertSubview(progressView!, belowSubview: tuner)
        tuner?.wheelColor = UIColor.clearColor()
        tuner?.buttonColor = UIColor.clearColor()
        tuner?.backgroundColor = UIColor.clearColor()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit"), style:UIBarButtonItemStyle.Plain, target: self, action: #selector(closeTapped))
        currentTimeFramePickerMode = .days
        
        let degrees = -90.0
        tuner?.transform = CGAffineTransformMakeRotation(CGFloat(degrees * M_PI/180.0))
        progressView?.transform = CGAffineTransformMakeRotation(CGFloat(degrees * M_PI/180.0))
        title = "Timeframe"
        navigationController?.toolbar.barTintColor = UIColor(netHex: 0xEEEEEE)
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if eventInCreation.timeframe > 12 {
            hourMode = false
            self.currentTimeFramePickerMode = .days
            currentDayCounterValue = eventInCreation.timeframe/24
            progressView?.animateFromAngle(0, toAngle: 180 + (eventInCreation.timeframe/24 * 30) , duration: 0.1, completion: { (completion: Bool) -> Void in
                
            })
        } else {
            hourMode = true
            self.currentTimeFramePickerMode = .hours
            currentHourCounterValue = eventInCreation.timeframe
            progressView?.animateFromAngle(0, toAngle: eventInCreation.timeframe * 15, duration: 0.1, completion: { (completion: Bool) -> Void in
                
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tunerTuned(sender: AnyObject) {
        if tuner.angle > countAngle {
            if countAngle < maxCountAngle {
                countAngle = tuner.angle
                print(countAngle)
                progressView?.animateFromAngle((progressView?.angle)!, toAngle: countAngle, duration: 0.1, completion: { (completion: Bool) -> Void in
                    
                })
                
                if countAngle < 180 {
                    hourMode = true
                    self.currentTimeFramePickerMode = .hours
                    currentHourCounterValue = Int((Double(countAngle)/180)*Double(maxCount + 1))
                } else {
                    hourMode = false
                    self.currentTimeFramePickerMode = .days
                    currentDayCounterValue = Int((Double(countAngle-180)/180)*Double(maxCount - maxHourCount)) + 1
                }
                
            }
        } else {
            if countAngle > 0 {
                countAngle = tuner.angle
                progressView?.animateFromAngle((progressView?.angle)!, toAngle: countAngle, duration: 0.1, completion: { (completion: Bool) -> Void in
                    
                })
                
                if countAngle < 180 {
                    hourMode = true
                    self.currentTimeFramePickerMode = .hours
                    currentHourCounterValue = Int((Double(countAngle)/180)*Double(maxCount + 1))
                } else {
                    hourMode = false
                    self.currentTimeFramePickerMode = .days
                    currentDayCounterValue = Int((Double(countAngle-180)/180)*Double(maxCount - maxHourCount)) + 1
                }
                
            }
        }
    }
    
    // MARK: Actions
    
    func nextTapped() {
        if (self.currentTimeFramePickerMode == .days) {
            eventInCreation.eventDate = NSDate().dateByAddingDays(currentDayCounterValue)
            eventInCreation.timeframe = currentDayCounterValue*24
        } else {
            eventInCreation.timeframe = currentHourCounterValue
            eventInCreation.eventDate = NSDate().dateByAddingHours(currentHourCounterValue)
        }
        eventInCreation.isPast = false
        if eventInCreation.timeframe == 0 {
            let alert = UIAlertController(title: "", message: "Please select a timeframe between 1 hour and 6 days.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            self.presentViewController(alert, animated: true) { () -> Void in }
        } else {
            //self.performSegueWithIdentifier("toHamzaPhotoController", sender: self)
            self.navigationController?.popViewControllerAnimated(true)
            if shouldTrackDuration {
                Mixpanel.sharedInstance().track("New Post - Timeframe added",
                                                properties: ["duration" : eventInCreation.timeframe])
                
                shouldTrackDuration = false
            }
        }
    }
    
    @IBAction func nextTapped(sender: AnyObject) {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        nextTapped()
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destinationVC = segue.destinationViewController as? HamzaImagePickerCollectionViewController {
            destinationVC.event = eventInCreation
            destinationVC.tags = eventInCreation.tags
            destinationVC.registerFlow = self.registerFlow
            destinationVC.createPostTapped = self.createPostTapped
        }
        if let destinationVC = segue.destinationViewController as? CreatedEventConfirmationTableViewController {
            destinationVC.eventInCreation = eventInCreation
            destinationVC.createPostTapped = self.createPostTapped
        }
    }
    
    func closeTapped() {
        if registerFlow == true {
            let alert = UIAlertController(title: "Quit Setup?", message: "Are you sure you want to quit signing up? You will be logged out and your details will not be saved.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SetupCancelled")
                self.navigationController?.popToRootViewControllerAnimated(true)
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        } else {
            let alert = UIAlertController(title: "Cancel Confirmation", message: "Are you sure you want to cancel creating this post?", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
                Mixpanel.sharedInstance().track("New Post - Canceled", properties: ["screen" : "Timeframe picker", "duration" : self.eventInCreation.timeframe])
                self.navigationController?.popToRootViewControllerAnimated(true)
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        }
    }
    
}
