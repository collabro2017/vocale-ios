//
//  VoiceNoteTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/29.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

protocol SavedPostDelegate: class {
    func savedPostDeleted()
    func savedPostResponded(event: Event)
}

class VoiceNoteTableViewController: UITableViewController, EventCellManagerDelegate {

    weak var delegate:SavedPostDelegate?
    var shouldReverse = false
    var event = Event()
    
    private var shouldRecord = false
    private var progressTimer: NSTimer!
    private var recordingManager: RecordingManager = RecordingManager()
    var deleteView: UILabel?
    var recordingView: UILabel?

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.navigationItem.title = "Saved Post"
        self.tableView.scrollEnabled = false
        self.tabBarController?.tabBar.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.deleteView = UILabel()
        self.deleteView?.textColor = UIColor(netHex: 0x211E23)
        self.deleteView?.textAlignment = NSTextAlignment.Center
        self.deleteView?.font = UIFont(name: "Raleway-SemiBold", size: 18)
        self.deleteView?.text = "Delete"
        self.deleteView?.frame = CGRectMake(0, self.navigationController!.view.frame.height-40, self.view.frame.width, 40)
        self.deleteView?.backgroundColor = UIColor(netHex: 0xEEEEEE)
        self.deleteView?.userInteractionEnabled = true
        self.navigationController?.view.addSubview(self.deleteView!)
        
        self.recordingView = UILabel()
        self.recordingView?.textColor = UIColor(netHex: 0xEEEEEE)
        self.recordingView?.textAlignment = NSTextAlignment.Center
        self.recordingView?.font = UIFont(name: "Raleway-Bold", size: 16)
        self.recordingView?.text = "REC"
        self.recordingView?.frame = CGRectMake(0, self.navigationController!.view.frame.height-40, self.view.frame.width, 40)
        self.recordingView?.backgroundColor = UIColor.whiteColor()
        self.navigationController?.view.addSubview(self.recordingView!)
        self.recordingView?.hidden = true
        
        let recognizer = UITapGestureRecognizer(target: self, action: "deleteViewTapped:")
        self.deleteView?.addGestureRecognizer(recognizer)
        
        self.navigationController?.setToolbarHidden(true, animated: false)

    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.deleteView?.removeFromSuperview()
        self.recordingView?.removeFromSuperview()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    // MARK: - TableView Data Source

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return view.frame.height
        } else {
            var margin = CGFloat()
            if let navBar = self.navigationController?.navigationBar {
                margin = navBar.frame.height
            }
            return abs(view.frame.height - view.frame.width - margin)
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        self.tableView.scrollEnabled = false
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCard", forIndexPath: indexPath) as! EventCardTableViewCell
        cell.savedMode = true
        cell.superViewFrame = self.view.frame
        cell.event = event
        cell.backgroundImageView.loadInBackground()
        cell.presentCardWithAnimation()
        cell.isFocusedCell = true
        cell.delegate = self
        cell.dismissEventClosure = {
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
        cell.recordTapped = {
            self.deleteView?.hidden = true
            self.recordingView?.hidden = false
            self.recordingView?.backgroundColor = UIColor(netHex: 0x333134)
            let attachment = NSTextAttachment()
            attachment.image = UIImage(named: "redDot")
            let attachmentString = NSAttributedString(attachment: attachment)
            let myString = NSMutableAttributedString(string: " REC", attributes: [NSForegroundColorAttributeName: UIColor(netHex:0xEEEEEE)])
            //let myString = NSMutableAttributedString(string: " REC")
            myString.insertAttributedString(attachmentString, atIndex: 0)
            self.recordingView?.attributedText = myString
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                }, completion: { (completed: Bool) -> Void in
            })
        }
        cell.completionHandler = {
            self.navigationController?.setToolbarHidden(true, animated: false)
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                }, completion: { (completed: Bool) -> Void in
                    self.deleteView?.hidden = false
            })
        }
        cell.flagTappedWithCompletion = {
            let report = PFObject(className: "ReportCase")
            report["claimant"] = PFUser.currentUser()
            report["event"] = self.event
            report["accused"] = self.event.owner

            let messageBox = UIAlertController(title: "Report", message: "See something inapropriate?  Tell us.", preferredStyle: UIAlertControllerStyle.Alert)
            messageBox.addTextFieldWithConfigurationHandler { (textField: UITextField) -> Void in
                report["message"] = textField.text
            }
            messageBox.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                })
            }))
            messageBox.addAction(UIAlertAction(title: "Submit", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
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
                    
                    let event = self.event
                    message = message + "\n\n" + "POST ID: " + event.objectId!
                    
                    let owner = self.event.owner
                    if let name = owner["name"] as? String {
                        message = message + "\nREPORTED USER NAME: " + name
                    }
                    if let userID = owner["username"] as? String {
                        message = message + "\n" + "REPORTED USER ID: " + userID
                    }
                    if let email = owner["email"] as? String {
                        message = message + "\n" + "REPORTED USER EMAIL: " + email
                    }
                    
                    if let text = report["message"] as? String {
                        message = message + "\n" + "MESSAGE: " + text
                    }
                    EmailManager.sharedInstance.sendMail(mail, to: "report@vocale.io", subject: "Report", message: message)
                    report.saveEventually()
                    if let currentUser = PFUser.currentUser() {
                        let blockedUser = self.event.owner
                        
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
                })
            }))

            self.presentViewController(messageBox, animated: true, completion: { () -> Void in
            })
        }
        return cell
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    // MARK: Auxiliary Methods

//    func didTapDelete() {
//        PFUser.currentUser()!.removeObject(self.event, forKey: "savedEvents")
//        PFUser.currentUser()?.saveEventually()
//        event.saveEventually()
//        event.unpinInBackground()
//        dismissViewControllerAnimated(true) { () -> Void in
//        }
//    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func deleteViewTapped(sender: UITapGestureRecognizer) {
        PFUser.currentUser()?.removeObject(event, forKey: "savedEvents")
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
            if let error = error {
                ErrorManager.handleError(error)
            } else {
                SVProgressHUD.showSuccessWithStatus("Post Deleted")
                self.navigationController?.popViewControllerAnimated(true)
                self.delegate?.savedPostDeleted()
            }
        })
    }
    
    // MARK: EventCellManagerDelegate
    func showSentView() {
        self.recordingView?.backgroundColor = UIColor(netHex: 0x86B155)
        self.recordingView?.text = "SENT"
        self.recordingView?.textColor = UIColor(netHex: 0x211E23)
        self.delegate?.savedPostResponded(self.event)
    }

    func showUplodingView() {
        self.recordingView?.backgroundColor = UIColor(netHex: 0x1098F7)
        self.recordingView?.text = "SENDING"
        self.recordingView?.textColor = UIColor(netHex: 0x211E23)
    }
    
    func showCancelView() {
        self.recordingView?.hidden = true
    }
    
}
