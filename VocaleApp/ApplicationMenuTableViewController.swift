//
//  ApplicationMenuTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/09.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import MessageUI
import CoreImage

class ApplicationMenuTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profileBackgroundImageView: UIImageView!
    @IBOutlet weak var profilePictureImageView: UIImageView!
    var buttonTapped = false
    var loadingSpinner: UIImageView?

    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
        //self.navigationItem.hidesBackButton = true
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image:UIImage(named: "backArrowFlipped") , style:UIBarButtonItemStyle.Plain , target: self, action: "backTapped")
        self.tableView.scrollEnabled = false
        Mixpanel.sharedInstance().track("Settings (Settings)")
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

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 288
        } else {
            var height = CGFloat(0)
            if let navHeight = navigationController?.navigationBar.frame.height, let toolBarHeight = self.navigationController?.toolbar.frame.height {
                height = navHeight + toolBarHeight + UIApplication.sharedApplication().statusBarFrame.height
            }
            return (self.view.frame.height - 288)/4
        }
    }
    
    
    func blurImage(image: UIImage) -> UIImage {
        let imageToBlur = CIImage(image: image)
        var blurredImage = UIImage()
        if let blurfilter = CIFilter(name: "CIGaussianBlur") {
            blurfilter.setValue(10, forKey: "inputRadius")
            blurfilter.setValue(imageToBlur, forKey: "inputImage")
            let resultImage = blurfilter.valueForKey("outputImage") as! CIImage
            blurredImage = UIImage(CIImage: resultImage)
        }

        return blurredImage
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.loadingSpinner?.removeFromSuperview()

        buttonTapped = false
        navigationController?.setToolbarHidden(false, animated: false)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
        if let user = PFUser.currentUser(), name = user["name"] as? String {
            profileNameLabel.text = name
        } else {
            profileNameLabel.text = "Vocale"
        }
        
        if let user = PFUser.currentUser(), file = user["UserImageMain"] as? PFFile  {
            file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                if let _ = error {
                    self.profileBackgroundImageView.image = UIImage(assetIdentifier: .VocaleGradient)
                    self.profilePictureImageView.image = UIImage(assetIdentifier: .VocaleClearWhite)
                } else if let data = data, let image = UIImage(data: data) {
                    self.profileBackgroundImageView.image = self.blurImage(image)
                    self.profileBackgroundImageView.contentMode = .ScaleAspectFill
                    self.profilePictureImageView.image = image
                }
                }, progressBlock: { (progress: Int32) -> Void in
            })
        } else {
            if let user = PFUser.currentUser(), profilePictureLink = user["FBPictureURL"] as? String, url = NSURL(string: profilePictureLink) {
                UIImageView().sd_setImageWithURL(url, completed: { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, url: NSURL!) -> Void in
                    self.profileBackgroundImageView.image = self.blurImage(image)
                    self.profileBackgroundImageView.contentMode = .ScaleAspectFill
                })
                profilePictureImageView.sd_setImageWithURL(url)
            } else {
                profileBackgroundImageView.image = UIImage(assetIdentifier: .VocaleGradient)
                profilePictureImageView.image = UIImage(assetIdentifier: .VocaleClearWhite)
            }
        }
        
        self.view.layoutIfNeeded()
        profilePictureImageView.applyCircularMask()
        
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.profileBackgroundImageView.bounds
        blurEffectView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        
        self.profileBackgroundImageView.addSubview(blurEffectView)
    }
    
//    override func viewWillDisappear(animated: Bool) {
//        if buttonTapped == false {
//            let transition: CATransition = CATransition()
//            let timeFunc : CAMediaTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
//            transition.duration = 0.3
//            transition.timingFunction = timeFunc
//            transition.type = kCATransitionPush
//            transition.subtype = kCATransitionFromRight
//            self.navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
//            self.navigationController!.popViewControllerAnimated(false)
//        }
//
//        super.viewWillAppear(animated)
//
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        buttonTapped = true
        if indexPath.row == 1 {
            let event = Event()
            event.owner = PFUser.currentUser()!
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            if let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("ProfileDetails") as? ProfileDetailViewController {
                if let name = event.owner["name"] as? String {
                    nextVC.name = name
                }
                
                if let birthdate = event.owner["birthday"] as? String {
                    let df = NSDateFormatter()
                    df.dateFormat = "MM/dd/yyyy"
                    if let date = df.dateFromString(birthdate) {
                        nextVC.age = "\(date.age)"
                    }
                }
                
                if let about = event.owner["AboutMe"] as? String {
                    nextVC.profileDescription = about
                }
                
                if loadingSpinner == nil {
                    let loadingSpinner = UIImageView(frame: CGRectMake(self.view.frame.size.width/2 - 20, self.view.frame.size.height/2 - 20, 40, 40))
                    loadingSpinner.image = UIImage(named: "spinner")
                    self.view.addSubview(loadingSpinner)
                    self.loadingSpinner = loadingSpinner
                    let rotate = CABasicAnimation(keyPath: "transform.rotation")
                    rotate.fromValue = 0
                    rotate.toValue = 2*M_PI
                    rotate.duration = 1
                    rotate.repeatCount = Float.infinity
                    self.loadingSpinner?.layer.addAnimation(rotate, forKey: "10")
                }
                
                var imageFiles = [PFFile]()
                var downloadedImages = [UIImage]()
                var profileImage: UIImage?
                
                for (var i = 1; i < 7; i += 1) {
                    if let image = event.owner["UserImage\(i)"] as? PFFile {
                        imageFiles.append(image)
                    }
                }
                
                var currentCount = 0
                if imageFiles.count > 0 {
                    for file in imageFiles {
                        file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                            self.loadingSpinner?.removeFromSuperview()
                            if let _ = error {
                                
                            } else if let data = data, let image = UIImage(data: data) {
                                currentCount = currentCount + 1
                                downloadedImages.append(image)
                                if currentCount == (imageFiles.count + 1) {
                                    nextVC.images = downloadedImages
                                    nextVC.profileImage = profileImage
                                    self.navigationController?.pushViewController(nextVC, animated: true)
                                }
                            }
                            }, progressBlock: { (progress: Int32) -> Void in
                        })
                    }
                }
                
                if let file = event.owner["UserImageMain"] as? PFFile  {
                    file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                        self.loadingSpinner?.removeFromSuperview()
                        if let _ = error {
                        } else if let data = data, let image = UIImage(data: data) {
                            profileImage = image
                            currentCount = currentCount + 1
                            if currentCount == (imageFiles.count + 1) {
                                nextVC.profileImage = image
                                nextVC.images = downloadedImages
                                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
                                dispatch_after(when, dispatch_get_main_queue()) {
                                    self.navigationController?.pushViewController(nextVC, animated: true)
                                }
                            }
                        }
                        }, progressBlock: { (progress: Int32) -> Void in
                    })
                } else if let string = event.owner["FBPictureURL"] as? String, url = NSURL(string: string) {
                    let request: NSURLRequest = NSURLRequest(URL: url)
                    let mainQueue = NSOperationQueue.mainQueue()
                    NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                        if error == nil {
                            // Convert the downloaded data in to a UIImage object
                            currentCount = currentCount + 1
                            let image = UIImage(data: data!)
                            profileImage = image
                            if currentCount == (imageFiles.count + 1) {
                                nextVC.profileImage = image
                                nextVC.images = downloadedImages
                                let when = dispatch_time(DISPATCH_TIME_NOW, Int64(0.25 * Double(NSEC_PER_SEC)))
                                dispatch_after(when, dispatch_get_main_queue()) {
                                    self.navigationController?.pushViewController(nextVC, animated: true)
                                }
                            }
                        }
                        else {
                            
                        }
                    })
                }
            }
        }
        
        if indexPath.row == 2 {

            //UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            if let settings = self.storyboard?.instantiateViewControllerWithIdentifier("Settings") {
                self.navigationController?.pushViewController(settings, animated: true)
            }
        }
        if indexPath.row == 3 {
            loadAndPresentHelpController()
        }
        if indexPath.row == 4 {
            loadAndPresentFeedbackController()
        }
    }

    // MARK: IBActions

    @IBAction func logoutTapped(sender: AnyObject) {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in

        }))
        alert.addAction(UIAlertAction(title: "Sign Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in

            PFUser.logOutInBackgroundWithBlock { (error: NSError?) -> Void in
                AppDelegate.layerClient?.deauthenticateWithCompletion({ (done: Bool, error: NSError?) in
                    self.navigationController?.popToRootViewControllerAnimated(false)
//                    if let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as? LoginViewController {
//                        self.presentViewController(loginVC, animated: false, completion: nil)
//                    }
                    
                    Mixpanel.sharedInstance().track("Settings (Logout)")
                })
            }
        }))
        self.presentViewController(alert, animated: true) { () -> Void in

        }
    }

    // MARK: Auxiliary Methods

    func loadAndPresentFeedbackController() {
//        let picker = MFMailComposeViewController()
//        picker.mailComposeDelegate = self
//        picker.setCcRecipients(["feedback@vocale.io"])
//        picker.setSubject("Feedback")
//        picker.setMessageBody("", isHTML: true)
//        presentViewController(picker, animated: true, completion: nil)
        
        let report = PFObject(className: "ReportCase")
        report["claimant"] = PFUser.currentUser()
//        report["response"] = self.response
//        report["accused"] = self.response.repsondent
        let reportController = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
        reportController.inputTooltipText = "Have thoughts or ideas about Vocale? Let us know."
        reportController.navigationItem.title = "Feedback"
        reportController.confirmationText = "Message sent."
        reportController.confirmationDescription = "Thank you for your feedback."
        reportController.didFinishTypingWithText = {
            text, isBlocked in
            report["message"] = text
            var message = ""
            var mail = "feedback@vocale.io"
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
            
            message = message + "\n" + "MESSAGE: " + text
            EmailManager.sharedInstance.sendMail(mail, to: "feedback@vocale.io", subject: "Feeback", message: message)
            report.saveEventually()
            Mixpanel.sharedInstance().track("Settings (Feedback)", properties: ["text" : message])
        }
        self.navigationController?.pushViewController(reportController, animated: false)
    }

    func loadAndPresentHelpController() {
//        let picker = MFMailComposeViewController()
//        picker.mailComposeDelegate = self
//        picker.setCcRecipients(["feedback@vocale.io"])
//        picker.setSubject("Help")
//        picker.setMessageBody("", isHTML: true)
//
//        presentViewController(picker, animated: true, completion: nil)
        
        let report = PFObject(className: "ReportCase")
        report["claimant"] = PFUser.currentUser()
//        report["response"] = self.response
//        report["accused"] = self.response.repsondent
        let reportController = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
        reportController.inputTooltipText = "Need assistance with something? Get in touch."
        reportController.navigationItem.title = "Help"
        reportController.confirmationText = "Message sent."
        reportController.confirmationDescription = "We’ll get back to you shortly."
        reportController.didFinishTypingWithText = {
            text, isBlocked in
            report["message"] = text
            var message = ""
            var mail = "help@vocale.io"
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
            
            message = message + "\n" + "MESSAGE: " + text
            EmailManager.sharedInstance.sendMail(mail, to: "help@vocale.io", subject: "Help", message: message)
            report.saveEventually()
            Mixpanel.sharedInstance().track("Settings (Help)", properties: ["text" : message])
        }
        self.navigationController?.pushViewController(reportController, animated: false)
    }

    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true) { () -> Void in

        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    // MARK: UINavigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EditProfileIdentifier" {
            if let editProfileController = segue.destinationViewController as? UserPhotosTableViewController {
                editProfileController.isEditProfile = true
                
                Mixpanel.sharedInstance().track("Settings (Edit Profile)")
            }
        }
    }
}
