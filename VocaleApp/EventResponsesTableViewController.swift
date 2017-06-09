//
//  EventResponsesTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/29.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class EventResponsesTableViewController: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UIViewControllerPreviewingDelegate {

    var queryCompleted = false
    var shouldAnimateCells = true
    var events = [Event]()
    var selectedEvent: Event?
    var selectedCell: UITableViewCell?
    var buttonTapped = false
    var tooltipPost: UIView?

    // MARK: View Controller LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
//        tableView.emptyDataSetSource = self
//        tableView.emptyDataSetDelegate = self
//        if( traitCollection.forceTouchCapability == .Available) {
//            registerForPreviewingWithDelegate(self, sourceView: view)
//        }

        view.backgroundColor = UIColor.vocaleBackgroundGreyColor()

        self.navigationController?.toolbar.barTintColor = UIColor.vocaleHeaderBackgroundGreyColor()
        self.navigationController?.navigationItem.hidesBackButton = true
        
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image:UIImage(named: "backArrowFlipped") , style:UIBarButtonItemStyle.Plain , target: self, action: "backTapped")
        
        Mixpanel.sharedInstance().track("Active Posts Screen")
    }
    
    func backTapped() {
        let transition: CATransition = CATransition()
        let timeFunc : CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        transition.duration = 0.3
        transition.timingFunction = timeFunc
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromRight
        self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
        self.navigationController!.popViewControllerAnimated(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        buttonTapped = false
        queryEvents()
        navigationController?.setToolbarHidden(true, animated: false)
        //animateInCells()
        deactivateProximitySensor()
    }
    
    func addPostsScreenTooltip() {
        //print(view.frame.size)
        let tooltip1 = UIView(frame:  CGRectMake(view.frame.size.width/2 - 65, view.frame.size.height/3 - 50, 140, 82))
        tooltip1.backgroundColor = UIColor.clearColor()
        tooltipPost = tooltip1
        let line1 = UIImageView(frame: CGRectMake(tooltip1.frame.size.width/2 - 13, 0, 26, 12))
        line1.backgroundColor = UIColor.clearColor()
        line1.contentMode = .ScaleAspectFit
        line1.image = UIImage(named: "triangle")
        tooltip1.addSubview(line1)
        let messageView1 = UIView(frame: CGRectMake(0 , 10, tooltip1.frame.size.width, 70))
        messageView1.backgroundColor = UIColor(netHex: 0x211E23)
        messageView1.layer.cornerRadius = 4
        messageView1.layer.borderWidth = 1
        messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView1.clipsToBounds = true
        tooltip1.addSubview(messageView1)
        let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel1.textAlignment = .Center
        titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel1.textColor = UIColor(netHex: 0x211E23)
        titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel1.text = "SWIPE"
        messageView1.addSubview(titleLabel1)
        let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
        messageLabel1.numberOfLines = 2
        messageLabel1.textAlignment = .Center
        messageLabel1.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel1.backgroundColor = UIColor(netHex: 0x1098F7)
        let messageText1 = "Swipe left to see more options"
        messageLabel1.text = messageText1
        messageView1.addSubview(messageLabel1)
        self.view.addSubview(tooltipPost!)
        
        tooltipPost?.alpha = 0
        tooltipPost?.transform = CGAffineTransformMakeTranslation(0, 40)
        UIView.animateWithDuration(0.4, delay: 0.5, options: .CurveEaseInOut, animations: {
            self.tooltipPost?.alpha = 1
            self.tooltipPost?.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (finished) in
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.tooltipPost?.removeFromSuperview()
        navigationController?.setToolbarHidden(false, animated: false)
    }

    // MARK: - Database Handling

    private func queryEvents() {
        let query = Event.query()
        if let user = PFUser.currentUser() where !PFAnonymousUtils.isLinkedWithUser(user) {
            //query?.fromLocalDatastore()
            query?.whereKey("owner", equalTo: user)
            query?.includeKey("responses")
            query?.orderByDescending("lastResponseUpdate")
            query?.addDescendingOrder("eventDate")
            query?.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
                
                if let error = error {
                    ErrorManager.handleError(error)
                } else if let events = objects as? [Event] {
                    if events.count == 0 {
                        self.queryCompleted = true
                        self.tableView.reloadData()
                    }
                    if events.count > 0 {
                        //NSUserDefaults.standardUserDefaults().setBool(false, forKey: "PostsFirstTap")
                        if NSUserDefaults.standardUserDefaults().boolForKey("PostsFirstTap") == false {
                            self.addPostsScreenTooltip()
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "PostsFirstTap")
                            NSUserDefaults.standardUserDefaults().synchronize()
                        }
                    }
                    for event in events {
                        if let query = EventResponse.query() {
                            //query.whereKey("isRead", equalTo: false)
                            query.whereKey("parentEvent", equalTo: event)
                            query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
                                if let error = error {
                                    
                                } else {
                                    if let responses = objects as? [EventResponse] {
                                        var count = 0
                                        for response in responses {
                                            if response.isRead == false {
                                                count = count + 1
                                            }
                                        }
                                        event.unreadResponseCount = count
                                        event.responses = responses
                                        self.events = events
                                        self.queryCompleted = true
                                        self.tableView.reloadData()
                                    }
                                }
                            })
                        }
                    }
                }


//                let networkQuery = Event.query()
//                networkQuery?.whereKey("owner", equalTo: user)
//                networkQuery?.orderByDescending("lastResponseUpdate")
//                networkQuery?.addDescendingOrder("eventDate")
//                networkQuery?.includeKey("responses")
//                networkQuery?.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
//
//                    if let error = error {
//                        ErrorManager.handleError(error)
//                    } else if let events = objects as? [Event] {
//                        PFObject.pinAllInBackground(events)
//                        for event in events {
//                            PFObject.pinAllInBackground(event.responses)
//                            var count = 0
//                            if let responses = event.responses as? [EventResponse] {
//                                for response in responses {
//                                    if !response.isRead {
//                                        count += 1
//                                    }
//                                }
//                            }
//                            event.unreadResponseCount = count
//
//                        }
//                        print("NETWORK - EVENTS", events)
//                        self.events = events
//                        self.tableView.reloadData()
//
//                    }
//                })
            })
        } else {
            SVProgressHUD.showErrorWithStatus("Please log in using Facebook")
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.events.count == 0 {
            self.tableView.scrollEnabled = false
        } else {
            self.tableView.scrollEnabled = true
        }
        
        if events.count > 0 {
            return events.count
        } else {
            if self.queryCompleted == true {
                return 1;
            } else {
                return 0;
            }
            //return 1
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row < events.count {
            if let cell = tableView.dequeueReusableCellWithIdentifier("eventResponseCard", forIndexPath: indexPath) as? EventResponseCardTableViewCell {

                cell.event = events[indexPath.row]
                cell.eventDescriptionLabel.textColor = UIColor(netHex: 0xEEEEEE)
                cell.moreActionTapped = {

                    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

                    if let eventDate = cell.event?.eventDate {
                        if eventDate.isEarlierThan(NSDate()) {
                            alert.addAction(UIAlertAction(title: "Delete Post", style: .Destructive, handler: { (action: UIAlertAction) -> Void in
                                Mixpanel.sharedInstance().track("Active Posts Deleted", properties:["post": cell.event!.objectId!])
                                self.buttonTapped = true
                                SVProgressHUD.showWithStatus("Deleting Post")
                                cell.event?.deleteInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                                    SVProgressHUD.dismiss()
                                    cell.event?.unpinInBackground()
                                    if let error = error {
                                        ErrorManager.handleError(error)
                                    } else {
                                        SVProgressHUD.showSuccessWithStatus("Post Deleted")
                                        self.events.removeAtIndex(indexPath.row)
                                        self.tableView.reloadData()
                                    }
                                })
                            }))
                        } else {
                            alert.addAction(UIAlertAction(title: "End Post", style: .Default, handler: { (action: UIAlertAction) -> Void in
                                Mixpanel.sharedInstance().track("Active Posts Ended", properties:["post": cell.event!.objectId!])
                                self.buttonTapped = true
                                SVProgressHUD.showWithStatus("Ending Post")
                                cell.event?.eventDate = NSDate()
                                cell.event?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                                    SVProgressHUD.dismiss()
                                    if let error = error {
                                        ErrorManager.handleError(error)
                                    } else {
                                        SVProgressHUD.showSuccessWithStatus("Post Ended")
                                        self.tableView.reloadData()
                                    }
                                })
                            }))
                        }
                    }
                    var repostLabel = "Edit Post"
                    if let event = cell.event where event.eventDate.isEarlierThan(NSDate()) {
                        repostLabel = "Repost"
                    }
                    alert.addAction(UIAlertAction(title: repostLabel, style: .Default, handler: { (action: UIAlertAction) -> Void in
                        self.buttonTapped = true
                        if let newPostVC = self.storyboard?.instantiateViewControllerWithIdentifier("newPostViewController") as? InputViewController, let event = cell.event {
                            newPostVC.eventInCreation = event
                            self.navigationController?.pushViewController(newPostVC, animated: true)
                            Mixpanel.sharedInstance().track("Active Posts Edited", properties:["post": cell.event!.objectId!])
                        } else {
                            Mixpanel.sharedInstance().track("Active Posts Reposted", properties:["post": cell.event!.objectId!])
                        SVProgressHUD.showWithStatus("Reposting...")
                        cell.event?.eventDate = NSDate().dateByAddingDays(7)
                        cell.event?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                            SVProgressHUD.dismiss()
                            if let error = error {
                                ErrorManager.handleError(error)
                            } else {
                                SVProgressHUD.showSuccessWithStatus("Reposted")
                                self.tableView.reloadData()
                            }
                        })
                        }
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) -> Void in

                    }))
                    self.presentViewController(alert, animated: true, completion: { () -> Void in

                    })
                }
                cell.backgroundImageView.loadInBackground()
                cell.setCount()
                return cell
            }

            let cell = tableView.dequeueReusableCellWithIdentifier("reuseIdentifier", forIndexPath: indexPath)

            return cell

        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("noMorePostsCard", forIndexPath: indexPath) as! NoPostsTableViewCell
//            let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "didSwipeDown:")
//            swipeDownGestureRecognizer.direction = .Down
//            cell.addGestureRecognizer(swipeDownGestureRecognizer)
            cell.browseControllerType = .noPosts

            return cell
        }
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row < events.count {
            return view.frame.width/2
        } else {
            return view.frame.height
        }
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let eventCell = cell as? EventResponseCardTableViewCell {

            /*
             eventCell.backgroundImageView.loadInBackground()
             eventCell.setCount()
             eventCell.event?.fetchIfNeededInBackgroundWithBlock({ (event: PFObject?, error: NSError?) -> Void in
            if let error = error {
            ErrorManager.handleError(error)
            } else if let event = event as? Event {
            for response in event.responses {
            response.fetchInBackground()
            }
            }
            })*/
        }
        if(shouldAnimateCells) {
            let h = cell.bounds.height
            let y = ((cell.frame.origin.y + UIApplication.sharedApplication().statusBarFrame.height + (navigationController?.navigationBar.frame.height)!) / h) * cell.frame.height
            cell.alpha = 0
            UIView.animateWithDuration(0.3, delay: 0.2*Double(y/tableView.frame.height), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                cell.alpha = 1
                }, completion: { (completed: Bool) -> Void in
                    self.shouldAnimateCells = false
            })
        }
        if !(events.count > indexPath.row+1) && events.count > 0 {
            shouldAnimateCells = false
        }
        
        if let noPostCell = cell as? NoPostsTableViewCell {
            noPostCell.noPostsExplanationLabel.alpha = 0
            noPostCell.noPostsLabel.alpha = 0
            noPostCell.noPostsImageView.alpha = 0
            UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                noPostCell.noPostsExplanationLabel.alpha = 1
                noPostCell.noPostsLabel.alpha = 1
                noPostCell.noPostsImageView.alpha = 1
                }, completion: { (completed) in
                    
            })
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let eventCell = tableView.cellForRowAtIndexPath(indexPath) as? EventResponseCardTableViewCell {
            selectedCell = eventCell
            self.selectedEvent = eventCell.event
            self.animateAwayCells({ () -> Void in
                self.performSegueWithIdentifier("toEventRespondents", sender: self)
            })
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if events.count > 0 {
            return true
        }
        return false
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
            if let toolTipPost = self.tooltipPost {
                toolTipPost.alpha = 0
                toolTipPost.transform = CGAffineTransformMakeTranslation(0, 40)
            }
        }) { (completed: Bool) -> Void in
            self.tooltipPost?.removeFromSuperview()
        }
        
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! EventResponseCardTableViewCell
        //cell.event = events[indexPath.row]

        let editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: " EDIT     ", handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            self.buttonTapped = true
            if let newPostVC = self.storyboard?.instantiateViewControllerWithIdentifier("newPostViewController") as? InputViewController, let event = cell.event {
                newPostVC.eventInCreation = event
                newPostVC.isEdit = true
                self.navigationController?.pushViewController(newPostVC, animated: true)
            }
        })
        editAction.backgroundColor = UIColor(netHex: 0x848485)
        
        let endAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: " END      ", handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            SVProgressHUD.showWithStatus("Ending Post")
            cell.event?.eventDate = NSDate()
            cell.event?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                SVProgressHUD.dismiss()
                if let error = error {
                    ErrorManager.handleError(error)
                } else {
                    SVProgressHUD.showSuccessWithStatus("Post Ended")
                    self.tableView.reloadData()
                }
            })
        })
        endAction.backgroundColor = UIColor(netHex: 0xB7B7B7)
        
        let repostAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "REPOST", handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            SVProgressHUD.showWithStatus("Reposting...")
            if let timeframe = cell.event?.timeframe {
                cell.event?.eventDate = NSDate().dateByAddingHours(timeframe)
            }
            cell.event?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                SVProgressHUD.dismiss()
                if let error = error {
                    ErrorManager.handleError(error)
                } else {
                    SVProgressHUD.showSuccessWithStatus("Reposted")
                    self.tableView.reloadData()
                }
            })
        })
        repostAction.backgroundColor = UIColor(netHex: 0xB7B7B7)
        
        let deleteAction = UITableViewRowAction(style: .Normal, title: "DELETE",
                                                handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
                                                    SVProgressHUD.showWithStatus("Deleting Post")
                                                    cell.event?.deleteInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                                                        SVProgressHUD.dismiss()
                                                        cell.event?.unpinInBackground()
                                                        if let error = error {
                                                            ErrorManager.handleError(error)
                                                        } else {
                                                            SVProgressHUD.showSuccessWithStatus("Post Deleted")
                                                            self.events.removeAtIndex(indexPath.row)
                                                            self.tableView.reloadData()
                                                        }
                                                    })
            }
        );
        deleteAction.backgroundColor = UIColor(netHex: 0xFB4B4E)
        
        var actions = [UITableViewRowAction]()
        if let eventDate = cell.event?.eventDate {
            if eventDate.isEarlierThan(NSDate()) {
                //ENDED
                actions.append(deleteAction)
                actions.append(repostAction)
            } else {
                //ACTIVE
                actions.append(deleteAction)
                actions.append(endAction)
                actions.append(editAction)
            }
        }
        return actions
            //[deleteAction, endAction, editAction]
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {

        }
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        buttonTapped = true
        
        if segue.identifier == "toEventRespondents" {
            if let nextVC = segue.destinationViewController as? IndividualEventResponseCollectionViewController, selectedEvent = selectedEvent {
                nextVC.event = selectedEvent
            }
        }
    }

    // MARK: - DZN EmptyDataSet

    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        if let originalImage = UIImage(assetIdentifier: .VocaleClearWhite), let cgImage = originalImage.CGImage {
            return UIImage(CGImage: cgImage, scale: originalImage.scale*2, orientation: originalImage.imageOrientation)
        } else {
            return UIImage()
        }
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
        let text = "This is the Responses View."
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18), NSForegroundColorAttributeName: UIColor.whiteColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }

    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "This is where your posts will be displayed.  From here you can see who is interested."

        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        paragraph.alignment = .Center

        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: text, attributes: attributes)
    }

    // MARK: Auxiliary Methods

    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView?.indexPathForRowAtPoint(location) else { return nil }
        guard let cell = tableView?.cellForRowAtIndexPath(indexPath) else { return nil }
        guard let detailVC = storyboard?.instantiateViewControllerWithIdentifier("individualEventResponseCollectionVC") as? IndividualEventResponseCollectionViewController else { return nil }
        detailVC.event = events[indexPath.row]
        previewingContext.sourceRect = cell.frame
        return detailVC
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        showViewController(viewControllerToCommit, sender: self)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    func deactivateProximitySensor() {
        let device = UIDevice.currentDevice()
        if device.proximityMonitoringEnabled {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: "UIDeviceProximityStateDidChangeNotification", object: device)
            device.proximityMonitoringEnabled = false
        }
    }

    // MARK: Actions

    func animateAwayCells(completion: () -> Void) {
        var count = 1
        var i = 0.0
        if tableView.visibleCells.count > 0 {
            for cell in tableView.visibleCells {

                UIView.animateWithDuration(0.3, delay: Double(i*0.1), usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    if !(cell == self.selectedCell) {
                        cell.alpha = 0
                    }
                    }, completion: { (completed: Bool) -> Void in
                        if count == self.tableView.visibleCells.count {
                            completion()
                        }
                        count++
                })
                i++

            }
        } else {
            completion()
        }
    }

    func animateInCells() {
        var count = 1
        var i = 0.0
        if tableView.visibleCells.count > 0 {
            for cell in tableView.visibleCells {

                UIView.animateWithDuration(0.3, delay: Double(i*0.1), usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    cell.alpha = 1

                    }, completion: { (completed: Bool) -> Void in
                        if count == self.tableView.visibleCells.count {

                        }
                        count++
                })
                i++

            }
        }
    }

}
