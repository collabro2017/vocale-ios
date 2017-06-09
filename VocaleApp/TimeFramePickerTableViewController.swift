//
//  TimeFramePickerTableViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/27.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class TimeFramePickerTableViewController: UITableViewController {

    enum timeFramePickerMode {
        case hours
        case days
    }
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

    var createPostTapped = false
    var hourMode = true
    var eventInCreation = Event()
    var progressView: KDCircularProgress?
    var countAngle = 0
    var maxCountAngle = 720
    var maxCount = 24
    var maxHourCount = 12
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
    @IBOutlet weak var hoursOrDaysSegmentedControl: UISegmentedControl!
    @IBOutlet weak var hoursOrDaysLabel: UILabel!
    @IBOutlet weak var tuner: C2AClickWheel!


    // MARK: View Controller LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem?.title = ""
        tableView.scrollEnabled = false
        progressView = KDCircularProgress(frame: CGRectMake((view.frame.width-320)/2, 50, 320, 320), colors: UIColor.vocaleRedColor())
        progressView?.trackColor = UIColor.darkGrayColor()
        progressView?.trackThickness = progressView!.trackThickness/3
        progressView?.progressThickness = progressView!.trackThickness
        progressView?.glowAmount = 0
        tuner?.superview?.addSubview(progressView!)
        tuner?.wheelColor = UIColor.clearColor()
        tuner?.buttonColor = UIColor.clearColor()
        tuner?.backgroundColor = UIColor.redColor()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit"), style:UIBarButtonItemStyle.Plain, target: self, action: #selector(closeTapped))
        currentTimeFramePickerMode = .days

        let degrees = -90.0
        tuner?.transform = CGAffineTransformMakeRotation(CGFloat(degrees * M_PI/180.0))
        progressView?.transform = CGAffineTransformMakeRotation(CGFloat(degrees * M_PI/180.0))
        title = "Timeframe"
        navigationController?.toolbar.barTintColor = UIColor(netHex: 0xEEEEEE)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    @IBAction func segmentedControlDidChange(sender: AnyObject) {
        if hoursOrDaysSegmentedControl.selectedSegmentIndex == 0 {
            currentTimeFramePickerMode = .hours
        } else {
            currentTimeFramePickerMode = .days
        }
    }

    @IBAction func tunerTuned(sender: AnyObject) {
        if tuner.angle > countAngle {
            if countAngle < maxCountAngle {
                countAngle = tuner.angle
                progressView?.animateFromAngle((progressView?.angle)!, toAngle: countAngle, duration: 0.1, completion: { (completion: Bool) -> Void in

                })

                if countAngle < 180 {
                    hourMode = true
                    self.currentTimeFramePickerMode = .hours
                    currentHourCounterValue = Int((Double(countAngle)/360)*Double(maxCount + 1))
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
                   currentHourCounterValue = Int((Double(countAngle)/360)*Double(maxCount + 1))
                } else {
                    hourMode = false
                    self.currentTimeFramePickerMode = .days
                    currentDayCounterValue = Int((Double(countAngle-180)/180)*Double(maxCount - maxHourCount)) + 1
                }

            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

     // MARK: - TableView Delegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 0
        } else if indexPath.row == 2 {
            return view.frame.width
        }
        return tableView.rowHeight
    }

    // MARK: Actions

    func nextTapped() {
        if (self.currentTimeFramePickerMode == .days) {
        eventInCreation.eventDate = NSDate().dateByAddingDays(currentDayCounterValue)
            eventInCreation.timeframe = currentDayCounterValue*24
        } else {
            eventInCreation.timeframe = currentDayCounterValue
            eventInCreation.eventDate = NSDate().dateByAddingHours(currentHourCounterValue)
        }
        eventInCreation.isPast = false
        
        
        self.performSegueWithIdentifier("toHamzaPhotoController", sender: self)
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
            destinationVC.createPostTapped = self.createPostTapped
        }
        if let destinationVC = segue.destinationViewController as? CreatedEventConfirmationTableViewController {
            destinationVC.eventInCreation = eventInCreation
            destinationVC.createPostTapped = self.createPostTapped
        }
    }
    
    func closeTapped() {
        let alert = UIAlertController(title: "Cancel Confirmation", message: "Are you sure you want to cancel creating this post?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
    }
}
