//
//  MessageEventTableViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/03/19.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit

class MessageEventTableViewController: UITableViewController {

    var event = Event()
    var profileViewMode = false
    var conversationListController: ConversationListViewController?
    var conversation: LYRConversation?
    var woutReturnButton = false
    var shouldSwipeRight = true

    private var shouldRecord = false
    private var progressTimer: NSTimer!
    private var recordingManager: RecordingManager = RecordingManager()

    // MARK: View Controller LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setToolbarHidden(true, animated: true)
        self.navigationItem.title = "Chat Info"
        self.tableView.scrollEnabled = false
        self.tabBarController?.tabBar.hidden = true
    }

    // MARK: - Table view

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

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        self.tableView.scrollEnabled = false
        let cell = tableView.dequeueReusableCellWithIdentifier("eventCard", forIndexPath: indexPath) as! EventCardTableViewCell
        cell.savedMode = true
        cell.shouldSwipeRight = shouldSwipeRight
        cell.messageMode = true
        cell.superViewFrame = self.view.frame
        cell.event = event
        cell.backgroundImageView.loadInBackground()
        cell.presentCardWithAnimation()
        cell.isFocusedCell = true
        cell.topRightButton.hidden = true
        cell.dismissEventClosure = {
            if let conversationListController = self.conversationListController {
                var error: NSError?
                self.conversation?.delete(LYRDeletionMode.AllParticipants, error: &error)
                self.navigationController?.popToViewController(conversationListController, animated: true)
            }
        }
        cell.recordTapped = {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                }, completion: { (completed: Bool) -> Void in

            })
        }
        cell.completionHandler = {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                }, completion: { (completed: Bool) -> Void in

            })
        }
        cell.flagTappedWithCompletion = {
            let report = PFObject(className: "ReportCase")
            report["claimant"] = PFUser.currentUser()
            report["event"] = self.event
            report["accused"] = self.event.owner
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
                
                message = message + "\n" + "MESSAGE: " + text
                EmailManager.sharedInstance.sendMail(mail, to: "report@vocale.io", subject: "Report", message: message)
                report.saveEventually()
                
                if isBlocked == true {
                    
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
                }
            }
            self.navigationController?.pushViewController(reportController, animated: true)
        }
        if profileViewMode {
            cell.scrollView.scrollRectToVisible(CGRectMake(cell.scrollView.frame.size.width, 0, cell.scrollView.frame.size.width, cell.scrollView.frame.size.height), animated: false)
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

    func didTapDelete() {
        PFUser.currentUser()?.removeObject(event, forKey:"savedEvents")
        event.saveEventually()
        event.unpinInBackground()
        dismissViewControllerAnimated(true) { () -> Void in

        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }


}
