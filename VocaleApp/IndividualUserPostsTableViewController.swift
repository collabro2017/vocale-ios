//
//  IndividualUserPostsTableViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/17.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class IndividualUserPostsTableViewController: UITableViewController, UIGestureRecognizerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    var user: PFUser?
    var events = [Event]()
    var voiceNoteRecorder: VoiceNoteRecorder?
    var stopGestureRecognizer: UITapGestureRecognizer?
    
    private var shouldFetch = true
    private var query: PFQuery?
    private var queryIsBusy = false
    private var topCell: EventCardTableViewCell? {
        willSet {
            topCell?.isFocusedCell = false
        }
        didSet {
            topCell?.isFocusedCell = true
        }
    }
    private var activityIndicatorView = DGActivityIndicatorView(type: .BallClipRotatePulse, tintColor: UIColor.vocaleRedColor(), size: 140)
    
    // MARK: View Controller LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        queryEvents()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - TableView Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCard", forIndexPath: indexPath) as! EventCardTableViewCell
        cell.superViewFrame = self.view.frame
        cell.event = events[indexPath.row]
        cell.backgroundImageView.loadInBackground()
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "didLongTapCell:")
        longPressGestureRecognizer.delegate = self
        cell.addGestureRecognizer(longPressGestureRecognizer)
        
        let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(IndividualUserPostsTableViewController.didSwipeUp(_:)))
        swipeUpGestureRecognizer.direction = .Up
        cell.addGestureRecognizer(swipeUpGestureRecognizer)
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(IndividualUserPostsTableViewController.didSwipeDown(_:)))
        swipeDownGestureRecognizer.direction = .Down
        cell.addGestureRecognizer(swipeDownGestureRecognizer)
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return view.frame.width
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let eventcard = cell as? EventCardTableViewCell {
            eventcard.backgroundImageView.loadInBackground()
            let frame = cell.frame
            cell.frame = CGRectMake(cell.frame.origin.x, cell.frame.origin.y + 50, cell.frame.width, cell.frame.height)
            UIView.animateWithDuration(1, animations: { () -> Void in
                cell.frame = frame
            })
        }
        if events.count - indexPath.row < 5 {
            if shouldFetch && !queryIsBusy {
                addEventsFromQuery(query)
                shouldFetch = false
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (action: UIAlertAction) -> Void in
            if self.events.count > indexPath.row {
                let event = self.events[indexPath.row]
                event.pinInBackground()
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { (action: UIAlertAction) -> Void in
            let messageBox = UIAlertController(title: "Report post", message: "See something you didn't like?  Tell us.", preferredStyle: .Alert)
            messageBox.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
                
            })
            messageBox.addAction(UIAlertAction(title: "Send", style: .Default, handler: { (action: UIAlertAction) -> Void in
                if let text = messageBox.textFields?.first?.text {
                    let reportCase = PFObject(className: "ReportCase")
                    reportCase["message"] = text
                    reportCase["claimant"] = PFUser.currentUser()
                    if self.events.count < indexPath.row {
                        reportCase["event"] = self.events[indexPath.row]
                        reportCase["defendant"] = self.events[indexPath.row].owner
                    }
                    var message = ""
                    var mail = "report@vocale.io"
                    if let user = PFUser.currentUser() {
                        if let name = user["name"] as? String {
                            message = "NAME: " + name
                        }
                        if let userID = user["username"] as? String {
                            message = message + "\n" + "ID: " + userID
                        }
                        if let email = user["email"] as? String {
                            message = message + "\n" + "EMAIL: " + email
                            mail = email
                        }
                    }
                    
                    let event = self.events[indexPath.row]
                    message = message + "\n\n" + "POST ID: " + event.objectId!
                    
                    let owner = self.events[indexPath.row].owner
                    if let name = owner["name"] as? String {
                        message = message + "\nREPORTED USER NAME: " + name
                    }
                    if let userID = owner["username"] as? String {
                        message = message + "\n" + "REPORTED USER ID: " + userID
                    }
                    if let email = owner["email"] as? String {
                        message = message + "\n" + "REPORTED USER EMAIL: " + email
                    }
                    
                    message = message + "\n" + "MESSAGE: " + text
                    EmailManager.sharedInstance.sendMail(mail, to: "report@vocale.io", subject: "Report", message: message)
                    reportCase.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                        if let error = error {
                            ErrorManager.handleError(error)
                        } else {
                            SVProgressHUD.showSuccessWithStatus("The case has been reported.")
                        }
                    })
                    if let currentUser = PFUser.currentUser() {
                        let blockedUser = self.events[indexPath.row].owner
                        
                        let userQuery = PFQuery(className:"BlockedUsers")
                        userQuery.whereKey("userId", equalTo: currentUser.objectId!)
                        userQuery.getFirstObjectInBackgroundWithBlock {
                            (object: PFObject?, error: NSError?) -> Void in
                            if let error = error {
                                if error.code == 101 {
                                    let user = PFObject(className:"BlockedUsers")
                                    user["userId"] = currentUser.objectId
                                    user["name"] = currentUser.firstName
                                    user.addUniqueObject(blockedUser, forKey:"blockedUsers")
                                    user.saveInBackground()
                                }
                            } else {
                                if let user = object {
                                    let user = user
                                    user.addUniqueObject(blockedUser, forKey:"blockedUsers")
                                    user.saveInBackground()
                                }
                            }
                        }
                        
                        let blockedUserQuery = PFQuery(className:"BlockedUsers")
                        blockedUserQuery.whereKey("userId", equalTo: blockedUser.objectId!)
                        blockedUserQuery.getFirstObjectInBackgroundWithBlock {
                            (object: PFObject?, error: NSError?) -> Void in
                            if let error = error {
                                if error.code == 101 {
                                    let user = PFObject(className:"BlockedUsers")
                                    user["userId"] = blockedUser.objectId
                                    user["name"] = blockedUser.firstName
                                    user.addUniqueObject(currentUser, forKey:"blockedUsers")
                                    user.saveInBackgroundWithBlock {
                                        (success: Bool, error: NSError?) -> Void in
                                        if (success) {
                                            // The object has been saved.
                                            NSNotificationCenter.defaultCenter().postNotificationName("ReportedUserNotification", object: self)
                                        } else {
                                            // There was a problem, check error.description
                                        }
                                    }
                                }
                            } else {
                                if let user = object {
                                    let user = user
                                    user.addUniqueObject(currentUser, forKey:"blockedUsers")
                                    user.saveInBackgroundWithBlock {
                                        (success: Bool, error: NSError?) -> Void in
                                        if (success) {
                                            // The object has been saved.
                                            NSNotificationCenter.defaultCenter().postNotificationName("ReportedUserNotification", object: self)
                                        } else {
                                            // There was a problem, check error.description
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }))
            messageBox.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            self.presentViewController(messageBox, animated: true) { () -> Void in }
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        self.presentViewController(actionSheet, animated: true) { () -> Void in
            
        }
    }
    
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
    }

    // MARK: - DZN EmptyDataSet
    
    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        let originalImage = UIImage(assetIdentifier: .VocaleClearWhite)
        let image = UIImage(CGImage: originalImage!.CGImage!, scale: originalImage!.scale*2, orientation: originalImage!.imageOrientation)
        return image
    }
    
    func imageAnimationForEmptyDataSet(scrollView: UIScrollView!) -> CAAnimation! {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
        animation.toValue = NSValue(CATransform3D: CATransform3DMakeRotation(CGFloat(M_PI_2), 0, 0, 1))
        animation.duration = 0.25
        animation.cumulative = true
        animation.repeatCount = Float.infinity
        return animation
    }
    
    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "This is the Browse View."
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18), NSForegroundColorAttributeName: UIColor.whiteColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "This is where posts will be displayed.  From here you can explore and respond to nearby posts."
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        paragraph.alignment = .Center
        
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    // MARK: Actions
    
    func stopRecording() {
        if let voiceNoteRecorder = voiceNoteRecorder, stopGestureRecognizer = stopGestureRecognizer {
            voiceNoteRecorder.stopRecording({ (success, error, url) -> Void in
                
                if let url = url, topCell = self.topCell, indexPath = self.tableView.indexPathForCell(topCell) where indexPath.row < self.events.count {
                    let event = self.events[indexPath.row]
                    let eventResponse = EventResponse()
                    eventResponse.parentEvent = event
                    if let user = PFUser.currentUser() {
                        eventResponse.repsondent = user
                    }
                    eventResponse.timeStamp = NSDate()
                    //KGStatusBar.showErrorWithStatus("Sending voice note...")
                    
                    if let data = NSData(contentsOfURL: url) {
                        if let file = PFFile(name: url.lastPathComponent, data: data) {
                            eventResponse.voiceNote = file
                        }
                    }
                    
                    eventResponse.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                        if let error = error {
                            ErrorManager.handleError(error)
                        } else {
                            //KGStatusBar.showSuccessWithStatus("Voice note sent")
                            event.responses.append(eventResponse)
                            event.saveEventually()
                        }
                    })
                    
                }
                self.voiceNoteRecorder?.removeFromSuperview()
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.tabBarController?.tabBar.alpha = 1
                    }, completion: { (completed: Bool) -> Void in
                        if completed {
                            self.tabBarController?.tabBar.hidden = false
                        }
                })
                for cell in self.tableView.visibleCells {
                    UIView.animateWithDuration(0.5, animations: { () -> Void in
                        cell.alpha = 1
                        if let cell = cell as? EventCardTableViewCell {
                            cell.recordingMode = false
                        }
                    })
                }
                self.voiceNoteRecorder = nil
            })
            voiceNoteRecorder.removeFromSuperview()
            tableView.removeGestureRecognizer(stopGestureRecognizer)
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                self.tabBarController?.tabBar.alpha = 1
                }, completion: { (completed: Bool) -> Void in
                    if completed {
                        self.tabBarController?.tabBar.hidden = false
                    }
            })
            for cell in tableView.visibleCells {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    cell.alpha = 1
                    if let cell = cell as? EventCardTableViewCell {
                        cell.recordingMode = false
                    }
                })
            }
        }
        voiceNoteRecorder = nil
    }
    
    func didSwipeUp(sender: AnyObject) {
        if let sender = sender as? UISwipeGestureRecognizer, cell = topCell, indexPath = tableView.indexPathForCell(cell) {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                cell.frame.origin.y = cell.frame.origin.y - cell.frame.height
                }, completion: { (completed: Bool) -> Void in
            })
            if let secondCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)) as? EventCardTableViewCell {
                topCell = secondCell
                UIView.animateWithDuration(0.5, delay: 0.15, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                    
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section), atScrollPosition: .Top, animated: false)
                    }, completion: { (completed: Bool) -> Void in
                        if (completed) {
                            cell.frame.origin.y = cell.frame.origin.y + cell.frame.height
                        }
                })
            }
        }
    }
    
    func didSwipeDown(sender: AnyObject) {
        if let sender = sender as? UISwipeGestureRecognizer, cell = topCell, indexPath = tableView.indexPathForCell(cell) {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                }, completion: { (completed: Bool) -> Void in
            })
            if let secondCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)) as? EventCardTableViewCell {
                topCell = secondCell
                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                    
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section), atScrollPosition: .Top, animated: false)
                    }, completion: { (completed: Bool) -> Void in
                        if (completed) {
                            
                        }
                })
            }
        }
    }
    
    // MARK: IBActions
    
    @IBAction func didLongTapCell(sender: AnyObject) {
        if let sender = sender as? UILongPressGestureRecognizer, cell = sender.view as? EventCardTableViewCell, event = cell.event {
            if sender.state == UIGestureRecognizerState.Began {
                if let user = PFUser.currentUser() where PFAnonymousUtils.isLinkedWithUser(user) {
                    SVProgressHUD.showErrorWithStatus("Please log in using Facebook")
                    tabBarController?.selectedIndex = 1
                }
                
                if let indexPath = tableView.indexPathForCell(cell) {
                    topCell = cell
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
                    cell.recordingMode = true
                    if let nextCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)) as? EventCardTableViewCell {
                        UIView.animateWithDuration(0.5, animations: { () -> Void in
                            nextCell.alpha = 0
                        })
                    }
                }
                if voiceNoteRecorder == nil {
                    var height = (self.tabBarController?.tabBar.frame.height)!*2
                    var y = (self.tabBarController?.tabBar.frame.origin.y)! - (self.tabBarController?.tabBar.frame.height)!
                    if let navigationController = navigationController {
                        height = navigationController.view.frame.height - navigationController.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - view.frame.width
                        y = navigationController.view.frame.height - height
                    }
                    voiceNoteRecorder = VoiceNoteRecorder(frame: CGRectMake(0, y, self.tableView.frame.width, height))
                    if let voiceNoteRecorder = voiceNoteRecorder {
                        
                        self.navigationController?.view.addSubview(voiceNoteRecorder)
                        voiceNoteRecorder.event = event
                        voiceNoteRecorder.startRecording()
                        stopGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(IndividualUserPostsTableViewController.stopRecording))
                        if let  stopGestureRecognizer = stopGestureRecognizer {
                            self.tableView.addGestureRecognizer(stopGestureRecognizer)
                        }
                        UIView.animateWithDuration(0.5, animations: { () -> Void in
                            self.tabBarController?.tabBar.alpha = 0
                            }, completion: { (completed: Bool) -> Void in
                                if completed {
                                    self.tabBarController?.tabBar.hidden = true
                                }
                        })
                        activityIndicatorView = DGActivityIndicatorView(type: .BallClipRotatePulse, tintColor: UIColor.vocaleRedColor(), size: 140)
                        navigationController!.view.addSubview(activityIndicatorView)
                        
                    }
                }
            } else if sender.state == UIGestureRecognizerState.Ended {
                
                if let button = (voiceNoteRecorder?.hitTest(sender.locationOfTouch(sender.numberOfTouches()-1, inView: voiceNoteRecorder), withEvent: nil)) as? UIButton {
                    if button.tag == 1020 {
                        voiceNoteRecorder?.cancelTapped({ (success, error) -> Void in
                            self.voiceNoteRecorder?.removeFromSuperview()
                            UIView.animateWithDuration(0.5, animations: { () -> Void in
                                self.tabBarController?.tabBar.alpha = 1
                                }, completion: { (completed: Bool) -> Void in
                                    if completed {
                                        self.tabBarController?.tabBar.hidden = false
                                    }
                            })
                            for cell in self.tableView.visibleCells {
                                UIView.animateWithDuration(0.5, animations: { () -> Void in
                                    cell.alpha = 1
                                    if let cell = cell as? EventCardTableViewCell {
                                        cell.recordingMode = false
                                    }
                                })
                            }
                            self.voiceNoteRecorder = nil
                        })
                    }
                }
                stopRecording()
                activityIndicatorView.removeFromSuperview()
            }
            if let navigationController = navigationController {
                activityIndicatorView.center = sender.locationOfTouch(sender.numberOfTouches()-1, inView: navigationController.view)
                activityIndicatorView.startAnimating()
                
                let location = sender.locationOfTouch(sender.numberOfTouches()-1, inView: voiceNoteRecorder)
                if let voiceNoteRecorder = voiceNoteRecorder where distanceBetween(point: location, andPoint: voiceNoteRecorder.cancelButton.center) < view.frame.height/2 {
                    let center = voiceNoteRecorder.cancelButton.center
                    var factor = 1+((view.frame.height/2) - distanceBetween(point: location, andPoint: voiceNoteRecorder.cancelButton.center))/(view.frame.height)
                    factor = factor*factor
                    voiceNoteRecorder.cancelButton.frame.size = CGSizeMake(voiceNoteRecorder.originalCancelButtonSize.width*factor, voiceNoteRecorder.originalCancelButtonSize.height*factor)
                    voiceNoteRecorder.cancelButton.center = center
                    
                }
            }
        }
    }
    
    // MARK: Auxiliary Methods
    
    func queryEvents() {
        
        let query = Event.query()
        if let user = user {
            query?.whereKey("owner", equalTo: user)
        }
        query?.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
        query?.limit = 100
        queryIsBusy = true
        query?.findObjectsInBackgroundWithBlock({ (objects:[PFObject]?, error:NSError?) -> Void in
            self.queryIsBusy = false
            if error == nil {
                if let events = objects as? [Event] {
                    self.query = query
                    self.events = events
                    self.tableView.reloadData()
                    if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
                        self.topCell = topCell
                    }
                    self.tableView.scrollEnabled = false
                    self.refreshControl?.endRefreshing()
                    if events.count < query?.limit {
                        self.shouldFetch = false
                    } else {
                        self.shouldFetch = true
                    }
                }
            } else {
                ErrorManager.handleError(error)
            }
        })
    }
    
    func addEventsFromQuery(query: PFQuery?) {
        query?.skip = events.count
        queryIsBusy = true
        query?.findObjectsInBackgroundWithBlock({ (objects:[PFObject]?, error:NSError?) -> Void in
            self.queryIsBusy = false
            if error == nil {
                if let events = objects as? [Event] {
                    self.events.appendContentsOf(events)
                    self.tableView.reloadData()
                    if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
                        self.topCell = topCell
                    }
                    self.tableView.scrollEnabled = false
                    if events.count < query?.limit {
                        self.shouldFetch = false
                    } else {
                        self.shouldFetch = true
                    }
                }
            } else {
                ErrorManager.handleError(error)
            }
        })
    }
    
    func distanceBetween(point p1:CGPoint, andPoint p2:CGPoint) -> CGFloat {
        return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2))
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}
