//
//  IndividualEventRespondentsTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/30.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit

class IndividualEventRespondentsTableViewController: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UIGestureRecognizerDelegate, IndividualEventCellManagerDelegate {

    var response = EventResponse()
    private var query: PFQuery?
    private var queryIsBusy = false
    private var extraQueryConstraints: (query: PFQuery?) -> Void = {_ in }
    var recordingView: UILabel?

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setToolbarHidden(true, animated: true)
        view.backgroundColor = UIColor.vocaleBackgroundGreyColor()
        if let name = response.repsondent["name"] as? String {
            self.navigationItem.title = name
        }
    }

    override func viewWillAppear(animated: Bool) {
        self.tableView.scrollEnabled = false
        tabBarController?.tabBar.hidden = false
        self.tableView.reloadData()
        self.navigationController?.setToolbarHidden(true, animated: false)
        
        self.recordingView = UILabel()
        self.recordingView?.textColor = UIColor(netHex: 0xEEEEEE)
        self.recordingView?.textAlignment = NSTextAlignment.Center
        self.recordingView?.font = UIFont(name: "Raleway-Bold", size: 16)
        self.recordingView?.text = "REC"
        self.recordingView?.frame = CGRectMake(0, self.navigationController!.view.frame.height-44, self.view.frame.width, 44)
        self.recordingView?.backgroundColor = UIColor.whiteColor()
        self.navigationController?.view.addSubview(self.recordingView!)
        self.recordingView?.hidden = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        recordingView?.removeFromSuperview()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("respondentCard", forIndexPath: indexPath) as? IndividualEventRespondentCardTableViewCell {
            cell.delegate = self;
            cell.superViewFrame = self.view.frame
            cell.response = response
            cell.backgroundImageView.loadInBackground()
            cell.dismissEventClosure = {
                self.response.parentEvent.responses = self.response.parentEvent.responses.filter { $0 != self.response }
                self.response.parentEvent.saveEventually()
                self.response.unpinInBackground()
                self.response.deleteInBackground()
                self.navigationController?.popViewControllerAnimated(true)

            }
            cell.flagTappedWithCompletion = {
                //                    let report = PFObject(className: "ReportCase")
                //                    report["claimant"] = PFUser.currentUser()
                //                    report["response"] = self.response
                //                    report["accused"] = self.response.repsondent
                //                    let reportController = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
                //                    reportController.inputTooltipText = "See something you didn’t like? Tell us more."
                //                    reportController.navigationItem.title = "Report"
                //                    reportController.confirmationText = "Message sent."
                //                    reportController.confirmationDescription = "Thank you for your report."
                //                    reportController.didFinishTypingWithText = {
                //                        text in
                //                        report["message"] = text
                //                        report.saveEventually()
                //                    }
                //                    self.navigationController?.pushViewController(reportController, animated: true)
                
                let report = PFObject(className: "ReportCase")
                report["claimant"] = PFUser.currentUser()
                report["response"] = self.response
                report["accused"] = self.response.repsondent
                let reportController = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
                reportController.inputTooltipText = "See something you didn’t like? Tell us more."
                reportController.navigationItem.title = "Report"
                reportController.confirmationText = "Message sent."
                reportController.confirmationDescription = "Thank you for your report."
                reportController.isReport = true
                reportController.didFinishTypingWithText = {
                    text, isBlocked in
                    report["message"] = text
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
                    
                    let event = self.response
                    message = message + "\n\n" + "RESPONSE ID: " + event.objectId!
                    
                    let owner = self.response.repsondent
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
                    report.saveEventually()
                    
                    if isBlocked == true {
                        if let currentUser = PFUser.currentUser() {
                            let blockedUser = self.response.repsondent
                            
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
                }
                self.navigationController?.pushViewController(reportController, animated: false)
            }
            return cell
        }

        let cell = tableView.dequeueReusableCellWithIdentifier("noMorePostsCard", forIndexPath: indexPath) as! NoPostsTableViewCell
        return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
            return view.frame.height
    }
    
//    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
//        if let noPostCell = cell as? NoPostsTableViewCell {
//            noPostCell.noPostsExplanationLabel.alpha = 0
//            noPostCell.noPostsLabel.alpha = 0
//            noPostCell.noPostsImageView.alpha = 0
//            UIView.animateWithDuration(0.4, delay: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
//                noPostCell.noPostsExplanationLabel.alpha = 1
//                noPostCell.noPostsLabel.alpha = 1
//                noPostCell.noPostsImageView.alpha = 1
//                }, completion: { (completed) in
//
//            })
//        }
//    }
    
    //MARK: - EventCellManagerDelegate
    func individualRecordTapped() {
        self.recordingView?.hidden = false
        self.recordingView?.backgroundColor = UIColor(netHex: 0x333134)
        let attachment = NSTextAttachment()
        attachment.image = UIImage(named: "redDot")
        let attachmentString = NSAttributedString(attachment: attachment)
        let myString = NSMutableAttributedString(string: " REC")
        myString.insertAttributedString(attachmentString, atIndex: 0)
        self.recordingView?.attributedText = myString
    }
    
    func individualShowUplodingView() {
        self.recordingView?.backgroundColor = UIColor(netHex: 0x1098F7)
        self.recordingView?.text = "SENDING"
        self.recordingView?.textColor = UIColor(netHex: 0x211E23)
    }
    
    func individualShowSentView() {
        self.recordingView?.backgroundColor = UIColor(netHex: 0x86B155)
        self.recordingView?.text = "SENT"
        self.recordingView?.textColor = UIColor(netHex: 0x211E23)
    }
    
    func individualShowCancelView() {
        self.recordingView?.hidden = true
    }
    
    func individualRecordUploaded() {
        self.recordingView?.hidden = true
    }
    
    func individualDeleteButtonTapped() {
        let alert = UIAlertController(title: "Warning", message: "Are you sure you want to delete this response? This can not be undone.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
            self.response.parentEvent.responses = self.response.parentEvent.responses.filter { $0 != self.response }
            self.response.parentEvent.saveEventually()
            self.response.unpinInBackground()
            self.response.deleteInBackground()
            self.navigationController?.popViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
        }
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

    // MARK: Auxiliary Methods

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}
