//
//  CreatedEventConfirmationTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/28.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class CreatedEventConfirmationTableViewController: UITableViewController, LoadingScreenDelegate {

    var createPostTapped = false
    var registerFlow = false
    @IBOutlet weak var filterDescriptionLabel: UILabel!
    var filterDescription: String?
    var postFilterDescriptionLabel: UILabel?
    var eventInCreation = Event()
    var filterRequest: PFObject?
    var whoText: String?
    var ageText: String?
    var withinText: String?
    var imageURL: NSURL?
    var postImage: UIImage?
    var isEdit = false
    var timer: NSTimer?
    var timerIsFinished = false
    var postInfoEdit = false
    var isEditExisting = false
    
    // MARK: - View Controller Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.hidden = false
        self.navigationController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: #selector(CreatedEventConfirmationTableViewController.saveEvent))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        
        if eventInCreation.timeframe == 0 {
            eventInCreation.eventDate = NSDate().dateByAddingDays(6)
            eventInCreation.timeframe = 24*6
        } else {
            isEditExisting = true
        }
        
        if isEdit == false && postInfoEdit == false {
            getPhotosRequest()
        }
        
        self.whoText = "All"
        self.ageText = "18 - 100"
        self.withinText = "200 mi"
        
        if let filter = PFUser.currentUser()!["userFilter"] as? PFObject {
            filter.fetchIfNeededInBackgroundWithBlock {
                (filter: PFObject?, error: NSError?) -> Void in
                if let filter = filter {
                    var sexualityString = ""
                    if let bool = filter["allowStraight"] as? Bool where bool {
                        if sexualityString.characters.count > 1 {
                            sexualityString += " or "
                        }
                        sexualityString += "straight"
                    }
                    if let bool = filter["allowBi"] as? Bool where bool {
                        if sexualityString.characters.count > 1 {
                            sexualityString += " or "
                        }
                        sexualityString += "bisexual"
                    }
                    if let bool = filter["allowGay"] as? Bool where bool {
                        if sexualityString.characters.count > 1 {
                            sexualityString += " or "
                        }
                        sexualityString += "gay"
                    }
                    
                    var genderString = ""
                    if let bool = filter["allowMale"] as? Bool where bool {
                        genderString += "Males"
                        self.whoText = "M"
                    }
                    if let bool = filter["allowFemale"] as? Bool where bool {
                        if genderString.characters.count > 1 {
                            genderString += " or females"
                            self.whoText = "All"
                        } else {
                            genderString += "Females"
                            self.whoText = "F"
                        }
                    }
                    if let bool = filter["allowBi"] as? Bool where bool {
                        if genderString.characters.count > 1 {
                            //genderString += " or males"
                        } else {
                            genderString += "Males"
                        }
                    }
                    
                    var relationshipString = ""
                    if let bool = filter["allowSingles"] as? Bool where bool {
                        if relationshipString.characters.count > 1 {
                            relationshipString += " or "
                        }
                        relationshipString += "single"
                        
                    }
                    if let bool = filter["allowTaken"] as? Bool where bool {
                        if relationshipString.characters.count > 1 {
                            relationshipString += " or "
                        }
                        relationshipString += "taken"
                        
                    }
                    var anyone = false
                    if let bool = filter["anyone"] as? Bool where bool {
                        anyone = true
                    }
                    var maxKms = 200
                    if let max = filter["lastLocationRadius"] as? Double {
                        maxKms = Int(max)
                    }
                    var birthUpperBound = 18
                    if let upper = filter["birthdateUpperBound"] as? Double {
                        birthUpperBound = Int(upper)
                    }
                    var birthLowerBound = 100
                    if let lower = filter["birthdateLowerBound"] as? Double {
                        birthLowerBound = Int(lower)
                    }
                    
                    self.ageText = "\(birthLowerBound)" + " - " + "\(birthUpperBound)"
                    self.withinText = "\(maxKms)" + " mi"
                    
                    self.filterDescription = "\(genderString) between \(birthLowerBound) and \(birthUpperBound) who are \(sexualityString), \(relationshipString) and within \(maxKms) miles of you."
                    if anyone {
                        self.filterDescription = "Anyone on Vocale."
                    }
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: false)
        self.navigationItem.title = "Review"
        self.tableView.reloadData()
        if self.view.frame.width > 320 {
            self.tableView.scrollEnabled = false;
        }
        
        if postInfoEdit == false && isEditExisting == false {
            if let loadingScreen = self.storyboard?.instantiateViewControllerWithIdentifier("LoadingNavCon") as? UINavigationController {
                if let root = loadingScreen.topViewController as? LoadingViewController {
                    root.delegate = self
                }
                self.presentViewController(loadingScreen, animated: false, completion: {
                    
                })
            }
        }
        
        timer = NSTimer.scheduledTimerWithTimeInterval(1.8, target: self, selector: #selector(self.timerFinished), userInfo: nil, repeats: false)

    }
    
    func loadingScreenDissmissed() {
        let overlay = UIView(frame: UIScreen.mainScreen().bounds)
        print(overlay.frame)
        overlay.backgroundColor = UIColor.vocaleBackgroundGreyColor()
        self.navigationController?.view.addSubview(overlay)
        UIView.animateWithDuration(3.0, delay: 0.4, options: .CurveEaseInOut, animations: {
            overlay.alpha = 0
            }) { (finished) in
                overlay.removeFromSuperview()
        }
    }
    
    func timerFinished() {
        if postImage != nil {
            NSNotificationCenter.defaultCenter().postNotificationName("PostImageDonwloadedNotification", object: self)
//            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.4 * Double(NSEC_PER_SEC)))
//            dispatch_after(when, dispatch_get_main_queue()) {
//                self.tableView.reloadData()
//            }

        }
        timerIsFinished = true
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.topItem?.title = ""
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (indexPath.section == 0) {
            if let cell = tableView.dequeueReusableCellWithIdentifier("eventCard", forIndexPath: indexPath) as? EventCardTableViewCell {
                cell.isPrototypeLocal = true
                cell.event = eventInCreation
                if postInfoEdit == false && isEditExisting == false {
                    cell.backgroundImageView.image = postImage
                } else {
                    cell.backgroundImageView.loadInBackground()
                }
                cell.isFocusedCell = true
                return cell
            }
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("rightDetailCell", forIndexPath: indexPath) as! FilterDescriptionTableViewCell
        cell.headerView.alpha = 0
        cell.editButton.alpha = 0
        cell.whoValueLabel.text = whoText
        cell.ageValueLabel.text = ageText
        cell.withinValueLabel.text = withinText
        
        if self.view.frame.size.width <= 320 {
            //cell.filterButtonHeightConstraint.constant = 16
            //cell.filterButtonWidthConstraint.constant = 56
            //cell.editButton.setImage(UIImage(named: "editButton_small"), forState: .Normal)
            cell.middleViewHeight.constant = 80
            cell.headerLabelTopConstraint.constant = 14
            cell.headerViewHeightConstraint.constant = 37
            
            cell.whoLabel.font = UIFont(name: "Raleway-Regular", size: 11)
            cell.ageLabel.font = UIFont(name: "Raleway-Regular", size: 11)
            cell.withinLabel.font = UIFont(name: "Raleway-Regular", size: 11)
            
            cell.whoValueLabel.font = UIFont(name: "Raleway-Regular", size: 18)
            cell.ageValueLabel.font = UIFont(name: "Raleway-Regular", size: 18)
            cell.withinValueLabel.font = UIFont(name: "Raleway-Regular", size: 18)
            
            cell.headerLabel.font = UIFont(name: "Raleway-SemiBold", size: 16)
        }
//        if filterDescription == nil {
//            cell.filterDescriptionLabel.text = "Everyone on Vocale"
//        } else {
//            cell.filterDescriptionLabel.text = filterDescription
//        }
        
//        if self.view.frame.size.width <= 320 {
//            cell.filterButtonWidthConstraint.constant = 37
//            cell.filterButtonHeightConstraint.constant = 38
////            cell.headerLabel.font = UIFont(name: "Raleway-Regular", size: 18)
////            cell.filterDescriptionLabel.font = UIFont(name: "Raleway-Regular", size: 12)
//        }
        return cell
        
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.section == 0) {
            return self.view.frame.width
        }
        
        //if createPostTapped == true {
        if self.view.frame.width <= 320 && filterDescription != "Everyone on Vocale" {
            return tableView.frame.height - self.view.frame.width
        } else {
            return tableView.frame.height - self.view.frame.width
        }
//        } else {
//            return tableView.frame.height - self.view.frame.width - (navigationController?.navigationBar.frame.height)!
//        }
    }

    // MARK: - TableView Delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == 1 {
            if let filterVC = self.storyboard?.instantiateViewControllerWithIdentifier("FilterVC") as? FilterViewController {
                self.navigationController?.pushViewController(filterVC, animated: true)
                editFilter(filterVC)
            }
        }
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let h = cell.bounds.height
        let y = ((cell.frame.origin.y + UIApplication.sharedApplication().statusBarFrame.height + (navigationController?.navigationBar.frame.height)!) / h) * cell.frame.height
        cell.alpha = 0
        UIView.animateWithDuration(0.5, delay: 0.8*Double(y/tableView.frame.height), usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            cell.alpha = 1
            }, completion: { (completed: Bool) -> Void in

        })
        
        if let cell = cell as? FilterDescriptionTableViewCell {
//            cell.headerView.alpha = 1
//            cell.editButton.alpha = 1
//            
//            cell.whoLabel.alpha = 0
//            cell.whoValueLabel.alpha = 0
//            cell.ageLabel.alpha = 0
//            cell.ageValueLabel.alpha = 0
//            cell.withinLabel.alpha = 0
//            cell.withinValueLabel.alpha = 0
//            cell.whoLabel.transform = CGAffineTransformMakeTranslation(0, 20)
//            cell.whoValueLabel.transform = CGAffineTransformMakeTranslation(0, 35)
//            cell.ageLabel.transform = CGAffineTransformMakeTranslation(0, 20)
//            cell.ageValueLabel.transform = CGAffineTransformMakeTranslation(0, 35)
//            cell.withinLabel.transform = CGAffineTransformMakeTranslation(0, 20)
//            cell.withinValueLabel.transform = CGAffineTransformMakeTranslation(0, 35)
//            UIView.animateWithDuration(0.5, delay: 0.5, options: .CurveEaseInOut, animations: {
//                cell.whoLabel.alpha = 1
//                cell.whoValueLabel.alpha = 1
//                cell.ageLabel.alpha = 1
//                cell.ageValueLabel.alpha = 1
//                cell.withinLabel.alpha = 1
//                cell.withinValueLabel.alpha = 1
//                cell.whoLabel.transform = CGAffineTransformMakeTranslation(0, 0)
//                cell.whoValueLabel.transform = CGAffineTransformMakeTranslation(0, 0)
//                cell.ageLabel.transform = CGAffineTransformMakeTranslation(0, 0)
//                cell.ageValueLabel.transform = CGAffineTransformMakeTranslation(0, 0)
//                cell.withinLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            //                cell.withinValueLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            //                }, completion: { (finished) in
            //
            //            })
            cell.buttonView.alpha = 0
            cell.buttonView.transform = CGAffineTransformMakeTranslation(0, 30)
            dispatch_async(dispatch_get_main_queue(), {
                UIView.animateWithDuration(0.5, delay: 0.5, options: .CurveEaseInOut, animations: {
                    cell.buttonView.alpha = 1
                    cell.buttonView.transform = CGAffineTransformMakeTranslation(0, 0)
                    }, completion: { (finished) in
                        
                })
            })
        }
    }
    
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {

    }
    

    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let nextVC = segue.destinationViewController as? TimePickerViewController {
            nextVC.eventInCreation = eventInCreation
            nextVC.registerFlow = self.registerFlow
            nextVC.createPostTapped = self.createPostTapped
        }
        
        if let nextVC = segue.destinationViewController as? HamzaImagePickerCollectionViewController {
            nextVC.event = eventInCreation
            nextVC.registerFlow = self.registerFlow
            nextVC.tags = eventInCreation.tags
            nextVC.createPostTapped = self.createPostTapped
        }
    }

    func editFilter(destinationController: FilterViewController) {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
            destinationController.createFilter = true
            destinationController.didSelectFilterWithCompletion = {
                filter in
                self.eventInCreation["filterRequest"] = filter
                if let filter = filter {
                    print("FILTER", filter)
                    var sexualityString = ""
                    if let bool = filter["allowStraight"] as? Bool where bool {
                        if sexualityString.characters.count > 1 {
                            sexualityString += " or "
                        }
                        sexualityString += "straight"
                    }
                    if let bool = filter["allowBi"] as? Bool where bool {
                        if sexualityString.characters.count > 1 {
                            sexualityString += " or "
                        }
                        sexualityString += "bisexual"
                    }
                    if let bool = filter["allowGay"] as? Bool where bool {
                        if sexualityString.characters.count > 1 {
                            sexualityString += " or "
                        }
                        sexualityString += "gay"
                    }

                    var genderString = ""
                    if let bool = filter["allowMale"] as? Bool where bool {
                        genderString += "Males"
                        self.whoText = "M"
                    }
                    if let bool = filter["allowFemale"] as? Bool where bool {
                        if genderString.characters.count > 1 {
                            genderString += " or females"
                            self.whoText = "All"
                        } else {
                            genderString += "Females"
                            self.whoText = "F"
                        }
                    }
                    if let bool = filter["anyone"] as? Bool where bool {
                        self.whoText = "All"
                    }
                    
                    if let bool = filter["allowBi"] as? Bool where bool {
                        if genderString.characters.count > 1 {
                            //genderString += " or males"
                        } else {
                            genderString += "Males"
                        }
                    }

                    var relationshipString = ""
                    if let bool = filter["allowSingles"] as? Bool where bool {
                        if relationshipString.characters.count > 1 {
                            relationshipString += " or "
                        }
                        relationshipString += "single"

                    }
                    if let bool = filter["allowTaken"] as? Bool where bool {
                        if relationshipString.characters.count > 1 {
                            relationshipString += " or "
                        }
                        relationshipString += "taken"

                    }
                    var anyone = false
                    if let bool = filter["anyone"] as? Bool where bool {
                        anyone = true
                    }
                    var maxKms = 200
                    if let max = filter["lastLocationRadius"] as? Double {
                        maxKms = Int(max)
                    }
                    var birthUpperBound = 65
                    if let upper = filter["birthdateUpperBound"] as? Double {
                        birthUpperBound = Int(upper)
                    }
                    var birthLowerBound = 65
                    if let lower = filter["birthdateLowerBound"] as? Double {
                        birthLowerBound = Int(lower)
                    }
                    
                    self.ageText = "\(birthLowerBound)" + " - " + "\(birthUpperBound)"
                    self.withinText = "\(maxKms)" + " mi"
                    
                    self.filterDescription = "\(genderString) between \(birthLowerBound) and \(birthUpperBound) who are \(sexualityString), \(relationshipString) and within \(maxKms) miles of you."
                    if anyone {
                        self.filterDescription = "Anyone on Vocale."
                    }
                    
                    Mixpanel.sharedInstance().track("New Post - Set Filter", properties:["modified": true, "gender": self.whoText!, "age": self.ageText!, "distance": self.withinText!])
                    self.tableView.reloadData()
                }
            }
            navigationController?.setToolbarHidden(true, animated: true)
    }

    // MARK: Actions
    func getPhotosRequest() {
        if (eventInCreation.tags.count > 0) {
            FlickrKit.sharedFlickrKit().initializeWithAPIKey("10f43c5cfb44e9e2fad1bc17ebad0bb9", sharedSecret: "a5269697d8ec1f8b")
            FlickrKit.sharedFlickrKit().call("flickr.photos.search", args: ["tags":eventInCreation.tags.joinWithSeparator(","), "sort":"interestingness-desc", "safe_search":"1", "per_page":"1"]) { (response: [NSObject : AnyObject]!, error: NSError!) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    SVProgressHUD.dismiss()
                })
                
                print("RESPONSE ", response)
                if let dict1 = response["photos"]?["photo"] as? [[String: AnyObject]] {
                    if dict1.count == 0 {
                        SVProgressHUD.showErrorWithStatus("No photos match your hashtags.Try changing them.")
                    }
                    for photo in dict1 {
                        if let farm = photo["farm"], let serverID = photo["server"], let secret = photo["secret"], let id = photo["id"] {
                            
                            let urlString = "https://farm\(farm).staticflickr.com/\(serverID)/\(id)_\(secret).jpg"
                            let url = NSURL(string:urlString)
                            let request: NSURLRequest = NSURLRequest(URL: url!)
                            NSURLConnection.sendAsynchronousRequest(
                                request, queue: NSOperationQueue.mainQueue(),
                                completionHandler: {(response: NSURLResponse?,data: NSData?,error: NSError?) -> Void in
                                    if error == nil {
                                        if let image = UIImage(data:data!) {
                                            if let data = UIImageJPEGRepresentation(image, 1.0), let file = PFFile(name: "backgroundImage.jpg", data: data) {
                                                self.eventInCreation.backgroundImage =  file
                                                self.eventInCreation.placeholderImage = image
                                                self.postImage = image
                                                if self.timerIsFinished == true {
                                                    NSNotificationCenter.defaultCenter().postNotificationName("PostImageDonwloadedNotification", object: self)
                                                    dispatch_async(dispatch_get_main_queue(),{
                                                        self.tableView.reloadData()
                                                    })
                                                }
                                            }
                                        }
                                    }
                            })
//                            let data = NSData(contentsOfURL:url!)
//                            if data != nil {
//                                if let image = UIImage(data:data!) {
//                                    if let data = UIImageJPEGRepresentation(image, 1.0), let file = PFFile(name: "backgroundImage.jpg", data: data) {
//                                        self.eventInCreation.backgroundImage =  file
//                                        self.eventInCreation.placeholderImage = image
//                                        self.postImage = image
//                                        if self.timerIsFinished == true {
//                                            NSNotificationCenter.defaultCenter().postNotificationName("PostImageDonwloadedNotification", object: self)
//                                            dispatch_async(dispatch_get_main_queue(),{
//                                                self.tableView.reloadData()
//                                            })
//                                        }
//                                    }
//                                }
//                            }

                            break
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func editButtonTapped(sender: UIButton) {
        if let filterVC = self.storyboard?.instantiateViewControllerWithIdentifier("FilterVC") as? FilterViewController {
            self.navigationController?.pushViewController(filterVC, animated: true)
            editFilter(filterVC)
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
                Mixpanel.sharedInstance().track("New Post - Canceled", properties: ["screen" : "Confirmation", "description": self.self.eventInCreation.eventDescription, "timeframe": self.eventInCreation.timeframe, "tags": self.eventInCreation.tags])
                self.navigationController?.popToRootViewControllerAnimated(true)
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        }
    }

    @IBAction func saveTapped(sender: UIButton) {
        saveEvent()
    }

    @IBAction func openImagePickerScreen(sender: UIButton) {
        postInfoEdit = true
        self.performSegueWithIdentifier("toImagePickerScreen", sender: self)
    }
    
    @IBAction func openTimeFrameScreen(sender: UIButton) {
        postInfoEdit = true
        self.performSegueWithIdentifier("toTimeframeScreen", sender: self)
    }

    func saveEvent() {
        eventInCreation.saveInBackgroundWithBlock { (completed: Bool, error: NSError?) -> Void in
            if let error = error {
                ErrorManager.handleError(error)
            } else {
                //KGStatusBar.showSuccessWithStatus("Event successfully saved")
                self.eventInCreation.pinInBackground()
            }
            
            if let filter = PFUser.currentUser()!["userFilter"] as? PFObject, let max = filter["lastLocationRadius"] as? Double  {
                Mixpanel.sharedInstance().track("New Post - Created", properties:["tags": self.eventInCreation.tags,
                    "location": "\(self.eventInCreation.location.latitude), \(self.eventInCreation.location.longitude)",
                    "range": max,
                    "duration": self.eventInCreation.timeframe,
                    "postID" : self.eventInCreation.objectId!])
                FBSDKAppEvents.logEvent("New Post - Created", parameters:["tags": self.eventInCreation.tags,
                    "location": "\(self.eventInCreation.location.latitude), \(self.eventInCreation.location.longitude)",
                    "range": max,
                    "duration": self.eventInCreation.timeframe,
                    "postID" : self.eventInCreation.objectId!])
            } else {
                Mixpanel.sharedInstance().track("New Post - Created", properties:["tags": self.eventInCreation.tags,
                    "location": "\(self.eventInCreation.location.latitude), \(self.eventInCreation.location.longitude)",
                    "range": "200",
                    "duration": self.eventInCreation.timeframe,
                    "postID" : self.eventInCreation.objectId!])
                FBSDKAppEvents.logEvent("New Post - Created", parameters:["tags": self.eventInCreation.tags,
                    "location": "\(self.eventInCreation.location.latitude), \(self.eventInCreation.location.longitude)",
                    "range": "200",
                    "duration": self.eventInCreation.timeframe,
                    "postID" : self.eventInCreation.objectId!])
            }
            
        }
        NSUserDefaults.standardUserDefaults().removeObjectForKey("SetupCancelled")
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            delegate.registerNotCompleted = false
            if delegate.firstPostCreation == true {
                delegate.firstPostCreation = false
                self.performSegueWithIdentifier("toAllSetScreen", sender: self)
            } else {
                delegate.firstPostCreation = false
                navigationController?.popToRootViewControllerAnimated(true)
            }
        }
    }
}
