//
//  IndividualEventRespondentsTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/30.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit

class IndividualEventRespondentsTableViewController: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UIGestureRecognizerDelegate {
    
    var event = Event()
    var savedResponses = [EventResponse]()
    var selectedResponse = EventResponse()
    var firstAnimate = true
    private var shouldFetch = true
    private var tableHeaderView: TabbedTableHeaderView?
    var responseControllerTab: NoPostsTableViewCell.ResponseType = .All
    
    private var query: PFQuery?
    private var queryIsBusy = false
    private var topCell: IndividualEventRespondentCardTableViewCell? {
        willSet {
            topCell?.isFocusedCell = false
        }
        didSet {
            topCell?.isFocusedCell = true
        }
    }
    private var extraQueryConstraints: (query: PFQuery?) -> Void = {_ in }
    
    private var activityIndicatorView = DGActivityIndicatorView(type: .BallClipRotatePulse, tintColor: UIColor.vocaleRedColor(), size: 140)
    private var busyNavigationBarOptions = BusyNavigationBarOptions() {
        didSet {
            busyNavigationBarOptions.animationType = .Bars
            busyNavigationBarOptions.color = UIColor.vocaleRedColor()
            busyNavigationBarOptions.alpha = 0.65
            busyNavigationBarOptions.barWidth = 5
            busyNavigationBarOptions.gapWidth = 10
            busyNavigationBarOptions.speed = 1
            busyNavigationBarOptions.transparentMaskEnabled = true
        }
    }
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        tableHeaderView = TabbedTableHeaderView(frame: CGRectMake(0,0,tableView.frame.width, 40), tabTitles: ["All", "Saved"]) { (selectedTabIndex) -> Void in
            switch selectedTabIndex {
            case 0:
                self.extraQueryConstraints = {_ in }
                self.responseControllerTab = .All
                self.tableView.reloadData()
            default:
                self.responseControllerTab = .Saved
                self.fillSavedResponses()
                self.tableView.reloadData()
            }
        }
        tableHeaderView?.setNumberOfItems(EventResponse.countObjectsInLocalDatastoreForEvent(self.event), inTab: 1)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.tableView.scrollEnabled = false
        tabBarController?.tabBar.hidden = false
        busyNavigationBarOptions = BusyNavigationBarOptions()
        
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (self.responseControllerTab == .All) {
            return event.responses.count + 1
        } else {
            return savedResponses.count + 1
        }
        
    }
    
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? IndividualEventRespondentCardTableViewCell {
                self.topCell = topCell
            }
        }
        var significantCount = event.responses.count
        if (self.responseControllerTab == .Saved) {
            significantCount = savedResponses.count
        }
        if indexPath.row < significantCount {
            if let cell = tableView.dequeueReusableCellWithIdentifier("respondentCard", forIndexPath: indexPath) as? IndividualEventRespondentCardTableViewCell {
                cell.superViewFrame = self.view.frame
                if (self.responseControllerTab == .All) {
                    cell.response = event.responses[indexPath.row]
                } else {
                    cell.response = savedResponses[indexPath.row]
                }
                cell.backgroundImageView.loadInBackground()
                
                let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "didLongTapCell:")
                longPressGestureRecognizer.delegate = self
                cell.addGestureRecognizer(longPressGestureRecognizer)
                
                let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "didSwipeUp:")
                swipeUpGestureRecognizer.direction = .Up
                cell.addGestureRecognizer(swipeUpGestureRecognizer)
                let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "didSwipeDown:")
                swipeDownGestureRecognizer.direction = .Down
                cell.addGestureRecognizer(swipeDownGestureRecognizer)
                let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapCell:")
                if indexPath.row == 0 {
                    self.topCell = cell
                }
                cell.didSaveResponseClosure = {
                    save, event in
                    print("Closure \(save)")
                    if (save) {
                        self.tableHeaderView?.incrementNumberOfItemsInTab(1)
                    } else {
                        self.tableHeaderView?.decrementNumberOfItemsInTab(1)
                    }
                }
                return cell
            }
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("noMorePostsCard", forIndexPath: indexPath) as! NoPostsTableViewCell
        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "didSwipeDown:")
        swipeDownGestureRecognizer.direction = .Down
        cell.addGestureRecognizer(swipeDownGestureRecognizer)
        cell.browseControllerType = .noResponses
        
        return cell
        
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < event.responses.count {
            return view.frame.width
        } else {
            return view.frame.height
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return tableHeaderView
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.alpha = 1
        view.backgroundColor = UIColor.vocaleLightGreyColor()
    }
    
    // MARK: - Database
    
    func fillSavedResponses() {
        let query = EventResponse.query()
        query?.whereKey("parentEvent", equalTo: self.event)
        query?.fromLocalDatastore()
        query?.whereKey("savedLocally", equalTo: true)
        query?.findObjectsInBackgroundWithBlock({ (results: [PFObject]?, error: NSError?) -> Void in
            if let error = error {
                ErrorManager.handleError(error)
            } else {
                if let results = results as? [EventResponse] {
                    self.savedResponses = results
                    self.tableView.reloadData()
                }
            }
        })
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let responseCard = cell as? EventResponseCardTableViewCell {
            responseCard.backgroundImageView.loadInBackground()
            if firstAnimate {
                let frame = cell.frame
                cell.frame = CGRectMake(cell.frame.origin.x + cell.frame.width, cell.frame.origin.y, cell.frame.width, cell.frame.height)
                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    cell.frame = frame
                    }, completion: { (completed: Bool) -> Void in
                        
                })
                firstAnimate = false
            }
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < event.responses.count {
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
            if let respondent = event.responses[indexPath.row].repsondent.objectId {
                alert.addAction(UIAlertAction(title: "Respond", style: .Default, handler: { (action: UIAlertAction) -> Void in
                    
                    let messageBox = UIAlertController(title: "Message to \(self.event.responses[indexPath.row].repsondent.firstName)", message: "", preferredStyle: UIAlertControllerStyle.Alert)
                    messageBox.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
                        
                    })
                    messageBox.addAction(UIAlertAction(title: "Send", style: .Default, handler: { (action: UIAlertAction) -> Void in
                        if let layerClient = AppDelegate.layerClient, let text = messageBox.textFields?.first?.text {
                            do {
                                let conversation = try layerClient.newConversationWithParticipants([respondent], options: [LYRConversationOptionsDistinctByParticipantsKey : false])
                                let message = try layerClient.newMessageWithParts([LYRMessagePart(text:text)], options: nil)
                                try conversation.sendMessage(message)
                                
                                let pushQuery = PFInstallation.query()
                                pushQuery?.whereKey("user", equalTo: self.event.responses[indexPath.row].repsondent)
                                let push = PFPush()
                                push.setMessage("\(PFUser.currentUser()!.firstName): \(text)")
                                push.setQuery(pushQuery)
                                push.sendPushInBackground()
                                
                                self.navigationController?.popToRootViewControllerAnimated(true)
                            } catch {
                                print(error)
                            }
                            
                        }
                    }))
                    messageBox.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                        
                    }))
                    self.presentViewController(messageBox, animated: true) { () -> Void in }
                }))
            }
            alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { (action: UIAlertAction) -> Void in
                let respondent = self.event.responses[indexPath.row].repsondent.firstName
                KGStatusBar.showErrorWithStatus("Deleting \(respondent)'s Response...")
                
                self.event.removeObject(self.event.responses[indexPath.row], forKey: "responses")
                self.event.saveEventually()
                self.tableView.reloadData()
                self.event.saveInBackgroundWithBlock({ (deleted: Bool, error: NSError?) -> Void in
                    if (deleted) {
                        KGStatusBar.showSuccessWithStatus("Deleted \(respondent)'s Response.")
                    }
                    if let error = error {
                        SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                    }
                })
            }))
            alert.addAction(UIAlertAction(title: "Report", style: .Destructive, handler: { (action: UIAlertAction) -> Void in
                let messageBox = UIAlertController(title: "Report post", message: "Hear something you didn't like?  Tell us.", preferredStyle: .Alert)
                messageBox.addTextFieldWithConfigurationHandler({ (textField: UITextField) -> Void in
                    
                })
                messageBox.addAction(UIAlertAction(title: "Send", style: .Default, handler: { (action: UIAlertAction) -> Void in
                    if let text = messageBox.textFields?.first?.text {
                        let reportCase = PFObject(className: "ReportCase")
                        reportCase["message"] = text
                        reportCase["claimant"] = PFUser.currentUser()
                        if self.event.responses.count < indexPath.row {
                            reportCase["eventResponse"] = self.event.responses[indexPath.row]
                            reportCase["defendant"] = self.event.responses[indexPath.row].repsondent
                        }
                        reportCase.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                            if let error = error {
                                ErrorManager.handleError(error)
                            } else {
                                SVProgressHUD.showSuccessWithStatus("The case has been reported.")
                            }
                        })
                    }
                }))
                messageBox.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                    
                }))
                self.presentViewController(messageBox, animated: true) { () -> Void in }
                
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        }
    }
    
    // MARK: - Scroll view delegate
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        let offsetY = self.tableView.contentOffset.y
        if let cells = (self.tableView.visibleCells as? [EventResponseCardTableViewCell]) {
            for cell in cells {
                let x = cell.backgroundImageView.frame.origin.x
                let w = cell.backgroundImageView.bounds.width
                let h = cell.backgroundImageView.bounds.height
                let y = ((offsetY - cell.frame.origin.y) / h) * 25
                cell.backgroundImageView.frame = CGRectMake(x, y, w, h)
            }
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
    
    
    var voiceNoteRecorder: VoiceNoteRecorder?
    
    func didSwipeUp(sender: AnyObject?) {
        print("SwipeUp")
        print(topCell)
        if let cell = topCell, indexPath = tableView.indexPathForCell(cell) {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                cell.frame.origin.y = cell.frame.origin.y - cell.frame.height
                }, completion: { (completed: Bool) -> Void in
            })
            if let secondCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)) as? IndividualEventRespondentCardTableViewCell {
                topCell = secondCell
                
            }
            UIView.animateWithDuration(0.5, delay: 0.15, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section), atScrollPosition: .Top, animated: false)
                }, completion: { (completed: Bool) -> Void in
                    if (completed) {
                        cell.frame.origin.y = cell.frame.origin.y + cell.frame.height
                    }
            })
        }
    }
    
    func didSwipeDown(sender: AnyObject?) {
        if let cell = topCell, indexPath = tableView.indexPathForCell(cell) {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                //cell.frame.origin.y = cell.frame.origin.y + cell.frame.height
                }, completion: { (completed: Bool) -> Void in
            })
            if let secondCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)) as? IndividualEventRespondentCardTableViewCell {
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
    
    @IBAction func didLongTapCell(sender: AnyObject) {
        if let sender = sender as? UILongPressGestureRecognizer, cell = sender.view as? IndividualEventRespondentCardTableViewCell, response = cell.response {
            if sender.state == UIGestureRecognizerState.Began {
                if let user = PFUser.currentUser() where PFAnonymousUtils.isLinkedWithUser(user) {
                    SVProgressHUD.showErrorWithStatus("Please log in using Facebook")
                    tabBarController?.selectedIndex = 3
                } else {
                    
                    if let indexPath = tableView.indexPathForCell(cell) {
                        topCell = cell
                        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
                        cell.recordingMode = true
                        if let nextCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)) as? IndividualEventRespondentCardTableViewCell {
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
                }
            } else if sender.state == UIGestureRecognizerState.Ended {
                var willUpload = true
                if let button = (voiceNoteRecorder?.hitTest(sender.locationOfTouch(sender.numberOfTouches()-1, inView: voiceNoteRecorder), withEvent: nil)) as? UIButton {
                    if button.tag == voiceNoteRecorder!.cancelButton.tag {
                        voiceNoteRecorder?.cancelTapped({ (success, error) -> Void in
                            willUpload = false
                            if let cell = self.topCell {
                                cell.recordingMode = false
                            }
                            self.removeVoiceNoteRecorderWithAnimation()
                        })
                    }
                } else {
                    stopRecording()
                }
                if willUpload {
                    topCell?.uploadingMode = true
                }
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
    
    func removeVoiceNoteRecorderWithAnimation() {
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
                if let cell = cell as? IndividualEventRespondentCardTableViewCell {
                    cell.uploadingMode = false
                }
            })
        }
        self.voiceNoteRecorder = nil
    }
    
    func stopRecording() {
        if let voiceNoteRecorder = voiceNoteRecorder {
            voiceNoteRecorder.stopRecording({ (success, error, url) -> Void in
                if let success = success {
                    if let url = url, topCell = self.topCell, indexPath = self.tableView.indexPathForCell(topCell) where indexPath.row < self.event.responses.count {
                        topCell.recordingMode = false
                        print("!")
                        let dataDictionary = ["title": "VoiceNote"]
                        do {
                            print("!")
                            let dataDictionaryJSON = try NSJSONSerialization.dataWithJSONObject(dataDictionary, options: NSJSONWritingOptions.PrettyPrinted)
                            let dataMessagePart = LYRMessagePart(MIMEType: "application/json+voicenoteobject", data: dataDictionaryJSON)
                            let cellInfoDictionary = ["height": "90"]
                            let cellInfoDictionaryJSON = try NSJSONSerialization.dataWithJSONObject(cellInfoDictionary, options: NSJSONWritingOptions.PrettyPrinted)
                            let cellInfoMessagePart = LYRMessagePart(MIMEType: "application/json+voicenoteobject", data: cellInfoDictionaryJSON)
                            if let data = NSData(contentsOfURL: url) {
                                print("!")
                                let dataType = "application/json+voicenoteobject"
                                let voiceNotePart = LYRMessagePart(MIMEType: dataType, data: data)
                                
                                if let message = try AppDelegate.layerClient?.newMessageWithParts([dataMessagePart,cellInfoMessagePart, voiceNotePart], options: nil), let receiverID = topCell.response?.repsondent.objectId {
                                    print("!")
                                    do {
                                        if let conversation = try AppDelegate.layerClient?.newConversationWithParticipants([receiverID], options: nil) {
                                            print("!")
                                            try conversation.sendMessage(message)
                                            
                                        }
                                    } catch {
                                        if let conversations = try AppDelegate.layerClient?.conversationsForParticipants([receiverID]), conversation = conversations.first {
                                            
                                            try conversation.sendMessage(message)
                                            KGStatusBar.showSuccessWithStatus("Message Sent.")
                                        }
                                    }
                                }
                            }
                        } catch {
                            SVProgressHUD.showErrorWithStatus("An error occurred.  Please try again")
                        }
                    }
                }
                if let error = error {
                    ErrorManager.handleError(error)
                }
            })
            
        }
        self.removeVoiceNoteRecorderWithAnimation()
    }
    
    func distanceBetween(point p1:CGPoint, andPoint p2:CGPoint) -> CGFloat {
        return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2))
    }
    
    
    
    
    
}
