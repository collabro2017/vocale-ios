//
//  UserAboutTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/09.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class UserAboutTableViewController: UITableViewController, UITextViewDelegate {
    
    var shouldShowTextEditor = true
    
    @IBOutlet weak var singleLabel: UILabel! {
        didSet {
            singleLabel.text = "I'm\nSingle"
        }
    }
    @IBOutlet weak var relationshipLabel: UILabel! {
        didSet {
            relationshipLabel.text = "In a\nRelationship"
        }
    }
    
    @IBOutlet weak var aboutMeTextView: UITextView! {
        didSet {
            aboutMeTextView.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            aboutMeTextView.layer.borderWidth = 1
            aboutMeTextView.delegate = self
            if let user = PFUser.currentUser(),  let aboutMeText =  user["AboutMe"] as? String {
                aboutMeTextView.text = aboutMeText
            } else {
                aboutMeTextView.text = "\n\n Tap here to write an about me section."
            }
        }
    }
    
    @IBOutlet weak var sexualityRadioButtons: DLRadioButton!
    
    @IBOutlet weak var gaySexualityButton: DLRadioButton! {
        didSet {
            //gaySexualityButton.iconColor = UIColor.lightTextColor()
            gaySexualityButton.iconSize = 30
            //gaySexualityButton.indicatorColor = UIColor.vocaleRedColor()
            gaySexualityButton.titleLabel?.text = "Gay / Lesbian"
            
            if let user = PFUser.currentUser(),  let isGay =  user["isGay"] as? Bool {
                if (isGay) {
                    gaySexualityButton.setSelected(true)
                }
            }
        }
    }
    
    @IBOutlet weak var bisexualSexualityButton: DLRadioButton! {
        didSet {
//            bisexualSexualityButton.iconColor = UIColor.lightTextColor()
//            bisexualSexualityButton.indicatorColor = UIColor.vocaleRedColor()
            bisexualSexualityButton.iconSize = 30
            bisexualSexualityButton.titleLabel?.text = "Bisexual"
            
            if let user = PFUser.currentUser(),  let isBi =  user["isBi"] as? Bool {
                if (isBi) {
                    bisexualSexualityButton.setSelected(true)
                }
            }
        }
    }
    
    @IBOutlet weak var straightSexualityButton: DLRadioButton! {
        didSet {
//            straightSexualityButton.iconColor = UIColor.lightTextColor()
//            straightSexualityButton.indicatorColor = UIColor.vocaleRedColor()
            straightSexualityButton.iconSize = 30
            straightSexualityButton.titleLabel?.text = "Straight"
            
            if let user = PFUser.currentUser(),  let isStraight =  user["isStraight"] as? Bool {
                if (isStraight) {
                    straightSexualityButton.setSelected(true)
                }
            }
        }
    }
    
    @IBOutlet weak var InARelatiohsipStatusButton: DLRadioButton!{
        didSet {
//            InARelatiohsipStatusButton.iconColor = UIColor.lightTextColor()
//            InARelatiohsipStatusButton.indicatorColor = UIColor.vocaleRedColor()
            InARelatiohsipStatusButton.iconSize = 30
            InARelatiohsipStatusButton.titleLabel?.text = "In A Relationship"
            
            if let user = PFUser.currentUser(),  let hasRelationshipStatus =  user["hasRelationshipStatus"] as? Bool,  let hasSingleStatus =  user["hasSingleStatus"] as? Bool {
                if (hasRelationshipStatus && !hasSingleStatus) {
                    InARelatiohsipStatusButton.setSelected(true)
                }
            }
        }
    }
    
    @IBOutlet weak var singleStatusButton: DLRadioButton!{
        didSet {
//            singleStatusButton.iconColor = UIColor.lightTextColor()
//            singleStatusButton.indicatorColor = UIColor.vocaleRedColor()
            singleStatusButton.iconSize = 30
            singleStatusButton.titleLabel?.text = "Single"
            
            if let user = PFUser.currentUser(),  let hasRelationshipStatus =  user["hasRelationshipStatus"] as? Bool,  let hasSingleStatus =  user["hasSingleStatus"] as? Bool {
                if (!hasRelationshipStatus && hasSingleStatus) {
                    singleStatusButton.setSelected(true)
                }
            }
        }
    }
    
    @IBOutlet weak var itsComplicatedStatusButton: DLRadioButton!{
        didSet {
//            itsComplicatedStatusButton.iconColor = UIColor.lightTextColor()
//            itsComplicatedStatusButton.indicatorColor = UIColor.vocaleRedColor()
            itsComplicatedStatusButton.iconSize = 30
            itsComplicatedStatusButton.titleLabel?.text = "It's Complicated..."
            
            if let user = PFUser.currentUser(),  let hasRelationshipStatus =  user["hasRelationshipStatus"] as? Bool,  let hasSingleStatus =  user["hasSingleStatus"] as? Bool {
                if (!hasRelationshipStatus && !hasSingleStatus) {
                    itsComplicatedStatusButton.setSelected(true)
                }
            }
        }
    }
    
    @IBOutlet weak var userAboutPhotosSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var nextBarButton: UIBarButtonItem!
    
    //  Mark: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        LoginViewController.performFBGraphRequestWithUser(PFUser.currentUser()!)
        self.edgesForExtendedLayout = UIRectEdge.None
        if let user = PFUser.currentUser() {
            
            var image1Downloaded = false
            var image2Downloaded = false
            var image3Downloaded = false
            
            let completionBlock = {
                if image1Downloaded && image2Downloaded && image3Downloaded {
                }
            }
            
            if let file = user["UserImage1"] as? PFFile {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    image1Downloaded = true
                    completionBlock()
                    if let error = error {
                        
                       // KGStatusBar.showErrorWithStatus(error.localizedDescription)
                    } else if data != nil {
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                })
            } else {
                image1Downloaded = true
            }
            if let file = user["UserImage2"] as? PFFile {
                image2Downloaded = true
                completionBlock()
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    if let error = error {
                        
                        //KGStatusBar.showErrorWithStatus(error.localizedDescription)
                    } else if let data = data {
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                })
            } else {
                image2Downloaded = true
            }
            if let file = user["UserImage3"] as? PFFile {
                image3Downloaded = true
                completionBlock()
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    if let error = error {
                        
                        //KGStatusBar.showErrorWithStatus(error.localizedDescription)
                    } else if let data = data {
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                })
            } else {
                image3Downloaded = true
            }
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.endEditing(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //  Mark: - RadioButtons
    
    @IBAction func didSelectSexualityRadioButtons(sender: AnyObject) {
        if let sender = sender as? DLRadioButton, let user = PFUser.currentUser() {
            user["isGay"] = false
            user["isBi"] = false
            user["isStraight"] = false
            
            switch sender.selectedButton() {
            case gaySexualityButton:
                user["isGay"] = true
                user["sexuality"] = "gay"
            case bisexualSexualityButton:
                user["isBi"] = true
                user["sexuality"] = "bisexual"
            case straightSexualityButton:
                user["isStraight"] = true
                //user["straight"] = "gay"
                user["sexuality"] = "straight"
            default:
                break
            }
            user.saveEventually()
        }
    }
    
    @IBAction func didSelectRelationshipStatusRadioButtons(sender: AnyObject) {
        if let sender = sender as? DLRadioButton, let user = PFUser.currentUser() {
            user["hasSingleStatus"] = false
            user["hasRelationshipStatus"] = false
            
            switch sender.selectedButton() {
            case InARelatiohsipStatusButton:
                user["hasRelationshipStatus"] = true
                user["relationshipStatus"] = "taken"
            case singleStatusButton:
                user["hasSingleStatus"] = true
                user["relationshipStatus"] = "single"
            case itsComplicatedStatusButton:
                break
            default:
                break
            }
            user.saveEventually()
        }
    }
    
    //  Mark: - Text View Delegate
    
    func textViewDidEndEditing(textView: UITextView) {
        if textView == aboutMeTextView && textView.text != "Tap here to write an about me section." {
            if let user = PFUser.currentUser() {
                //print(aboutMeTextView.text)
                user["AboutMe"]  = aboutMeTextView.text
                user.saveInBackground()
            }
        }
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if shouldShowTextEditor {
            self.shouldShowTextEditor = false
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
            controller.inputTooltipText = "Tell people a little more about who you are and what you like."
            controller.navigationItem.title = "About You"
            controller.didFinishTypingWithText = {
                text, isBlocked in
                textView.text = text
                let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
                dispatch_after(delayTime, dispatch_get_main_queue()) {
                    
                    if let user = PFUser.currentUser() {
                        user["AboutMe"]  = text
                        user.saveInBackground()
                    }
//                    self.aboutMeTextView.resignFirstResponder()
//                    self.view.endEditing(true)
                    self.shouldShowTextEditor = true
                }
                
            }
            self.navigationController?.pushViewController(controller, animated: false)
        }
        textView.resignFirstResponder()
        self.view.endEditing(true)
        
    }
    
    // Mark: IBActions
    
    @IBAction func userAboutPhotosSegmentedControlChanged(sender: AnyObject) {
        if let sender = sender as? UISegmentedControl {
            switch sender.selectedSegmentIndex {
            case 1: self.performSegueWithIdentifier("toUserPhotosSegue", sender: self)
            default: break
            }
        }
    }
    
    @IBAction func nextBarButtonTapped(sender: AnyObject) {
        //if checkIfAllInfoIsEntered() == true {
            if let createdAt = PFUser.currentUser()?.createdAt where createdAt.timeIntervalSinceNow > -2000 {
                //self.performSegueWithIdentifier("toPostProcessSegue", sender: self)
                if let newPostVC = self.storyboard?.instantiateViewControllerWithIdentifier("newPostViewController") as? InputViewController {
                    self.navigationController?.pushViewController(newPostVC, animated: false)
                }
            } else {
                self.navigationController?.popToRootViewControllerAnimated(true)
                NSNotificationCenter.defaultCenter().postNotificationName("PostCreationLastStepNotification", object: self)
            }
//        } else {
//            let alert = UIAlertController(title: "Warning", message: "For us to deliver the best experience, users must make a selection for each category.", preferredStyle: UIAlertControllerStyle.Alert)
//            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
//                
//            }))
//            self.presentViewController(alert, animated: true) { () -> Void in
//                
//            }
//        }
        //print(PFUser.currentUser()?.createdAt!.timeIntervalSinceNow, terminator: "")
        
    }
    
    // Mark: Actions
    
    func SegueToUserProfile() {
        if let controller = storyboard?.instantiateViewControllerWithIdentifier("profileTableViewController") as? UserProfileTableViewController, user = PFUser.currentUser() {
            controller.profile = user
            navigationController?.pushViewController(controller, animated: true)
        }
        
    }
    
    func logoutTapped() {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Sign Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
            
            PFUser.logOutInBackgroundWithBlock { (error: NSError?) -> Void in
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
    }
    
    // MARK: Auxiliary Methods
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        self.aboutMeTextView.endEditing(true)
    }
    
    func checkIfAllInfoIsEntered() -> Bool {
        var sexualitySelected = false
        var relationshipSelected = false
        
        if let straightCheckbox = straightSexualityButton as? DLRadioButton {
            if let _ = straightCheckbox.selectedButton() {
                sexualitySelected = true
            }
        }
        
        if let singleCheckbox = singleStatusButton as? DLRadioButton {
            if let _ = singleCheckbox.selectedButton() {
                relationshipSelected = true
            }
        }
        
        if sexualitySelected == true && relationshipSelected == true {
            return true
        } else {
            return false
        }
    }
    
    func closeTapped() {
        let alert = UIAlertController(title: "Quit Setup?", message: "Are you sure you want to quit signing up? You will be logged out and your details will not be saved.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SetupCancelled")
            NSUserDefaults.standardUserDefaults().synchronize()
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
    }
}
