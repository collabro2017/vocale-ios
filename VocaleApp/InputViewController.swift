//
//  InputViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 6/28/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit
import Foundation

class InputViewController: UIViewController, UITextViewDelegate, PFLogInViewControllerDelegate {

    var currentText = 0
    var isEdit = false
    var createPostTapped = false
    var registerFlow = false
    var confirmationText: String?
    var confirmationDescription: String?
    var inputTooltipText = ""
    var existingText = "" {
        didSet {
            if existingText != "" {
                doneButton?.enabled = true
                textView.text = existingText
            }
        }
    }
    var didFinishTypingWithText: (input: String) -> Void = {
        _ in
    }
    var heightKeyboard: CGFloat?
    var animateTimer: NSTimer?
    var shouldTrackDescription = true // This is used by Mixpanel
    
    @IBOutlet weak var upperLabel: UILabel!
    @IBOutlet weak var lowerLabel: UILabel!
    @IBOutlet weak var startTypingView: UIView!
    var doneButton: UIBarButtonItem?
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
        {
        didSet {
            textView.delegate = self
            let keyboardToolbar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
            UIToolbar.appearance().barTintColor = UIColor(netHex: 0xEEEEEE)
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yellowColor(), NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 18)!], forState: .Disabled)
            doneButton = UIBarButtonItem(title: "Next", style: .Done, target: self, action: #selector(nextTapped))
            keyboardToolbar.setItems([flexibleSpace, doneButton!, flexibleSpace], animated: false)
            doneButton?.enabled = false
            textView.inputAccessoryView = keyboardToolbar
            textView.autocorrectionType = UITextAutocorrectionType.Yes
            textView.keyboardAppearance = .Dark
        }
    }
    @IBOutlet weak var lowerLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var counterLabelBottomConstraint: NSLayoutConstraint!
    
    var eventInCreation = Event() {
        didSet {
            
        }
    }
    
    var infoLabelsArray = [NSAttributedString]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        animateTimer = NSTimer.scheduledTimerWithTimeInterval(4, target: self, selector: Selector("animateInfoLabel"), userInfo: nil, repeats: true)

        // Do any additional setup after loading the view.
        if eventInCreation.timeframe == 0 {
            doneButton?.enabled = false
        } else {
            doneButton?.enabled = true
        }
        textView.editable = true
        self.counterLabel.alpha = 0
        textView.alpha = 0
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name:UIKeyboardWillHideNotification, object: nil)
        
        self.navigationItem.hidesBackButton = true
        LoginViewController.performFBGraphRequestWithUser(PFUser.currentUser()!)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        
        upperLabel.alpha = 0
        lowerLabel.alpha = 0
        startTypingView.alpha = 0
        
        if eventInCreation.eventDescription.characters.count > 1 {
            textView.text = eventInCreation.eventDescription
        }
        
        let highlightedColor = UIColor(netHex: 0xEEEEEE)
        let messageText1 = "E.g. “Lets have a #picnic in #CentralPark this\nafternoon?”"
        let range11 = (messageText1 as NSString).rangeOfString("E.g.")
        let range12 = (messageText1 as NSString).rangeOfString("#picnic")
        let range13 = (messageText1 as NSString).rangeOfString("#CentralPark")
        let attributedString1 = NSMutableAttributedString(string:messageText1)
        attributedString1.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range11)
        attributedString1.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range12)
        attributedString1.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range13)
        
        let messageText2 = "E.g. “Looking for a #Tennis partner to play with in #GreenPoint once a week.” #Sports"
        let range21 = (messageText2 as NSString).rangeOfString("E.g.")
        let range22 = (messageText2 as NSString).rangeOfString("#Tennis")
        let range23 = (messageText2 as NSString).rangeOfString("#GreenPoint")
        let range24 = (messageText2 as NSString).rangeOfString("#Sports")
        let attributedString2 = NSMutableAttributedString(string:messageText2)
        attributedString2.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range21)
        attributedString2.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range22)
        attributedString2.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range23)
        attributedString2.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range24)
        
        let messageText3 = "E.g. “Anyone interested in exploring a few #Art galleries this afternoon?” #Culture"
        let range31 = (messageText3 as NSString).rangeOfString("E.g.")
        let range32 = (messageText3 as NSString).rangeOfString("#Art")
        let range33 = (messageText3 as NSString).rangeOfString("#Culture")
        let attributedString3 = NSMutableAttributedString(string:messageText3)
        attributedString3.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range31)
        attributedString3.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range32)
        attributedString3.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range33)
        
        let messageText4 = "E.g. “I’m feeling like #Sushi at #KyotoGardens tonight.” #Dinner"
        let range41 = (messageText4 as NSString).rangeOfString("E.g.")
        let range42 = (messageText4 as NSString).rangeOfString("#Sushi")
        let range43 = (messageText4 as NSString).rangeOfString("#KyotoGardens")
        let range44 = (messageText4 as NSString).rangeOfString("#Dinner")
        let attributedString4 = NSMutableAttributedString(string:messageText4)
        attributedString4.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range41)
        attributedString4.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range42)
        attributedString4.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range43)
        attributedString4.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range44)
        
        let messageText5 = "E.g. “Just got to #Malibu and would love to do some #Surfing tomorrow.”\n"
        let range51 = (messageText5 as NSString).rangeOfString("E.g.")
        let range52 = (messageText5 as NSString).rangeOfString("#Malibu")
        let range53 = (messageText5 as NSString).rangeOfString("#Surfing")
        let attributedString5 = NSMutableAttributedString(string:messageText5)
        attributedString5.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range51)
        attributedString5.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range52)
        attributedString5.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 13)!], range: range53)
        
        infoLabelsArray.append(attributedString1)
        infoLabelsArray.append(attributedString2)
        infoLabelsArray.append(attributedString3)
        infoLabelsArray.append(attributedString4)
        infoLabelsArray.append(attributedString5)
        currentText = 0
        lowerLabel.attributedText = attributedString1
        
        if registerFlow == true {
            if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                delegate.firstPostCreation = true
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = "New Post"
        //textView.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        textView.becomeFirstResponder()
        if eventInCreation.eventDescription.characters.count > 1 {
//            textView.text = eventInCreation.eventDescription
            self.counterLabel.text = "\(textView.text.characters.count) / 160"
            UIView.animateWithDuration(0.6, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.textView.alpha = 1
                self.counterLabel.alpha = 1
                }, completion: { (completed: Bool) -> Void in
                    
            })
        } else {
            self.upperLabel.transform = CGAffineTransformMakeTranslation(0, 20)
            self.lowerLabel.transform = CGAffineTransformMakeTranslation(0, 80)
            UIView.animateWithDuration(0.6, delay: 0.6, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                self.lowerLabel.alpha = 1
                self.lowerLabel.transform = CGAffineTransformMakeTranslation(0, 0)
                }, completion: { (finished) in
                    
            })
            UIView.animateWithDuration(0.6, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.upperLabel.alpha = 1
                self.upperLabel.transform = CGAffineTransformMakeTranslation(0, 0)
                self.startTypingView.alpha = 1
                }, completion: { (completed: Bool) -> Void in
                    
            })
        }

    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.title = ""
        animateTimer?.invalidate()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func animateInfoLabel() {
        currentText = currentText + 1
        if currentText == 4 {
            currentText = 0
        }
        if self.textView.text == "" {
            UIView.animateWithDuration(0.6, animations: {
                self.lowerLabel.transform = CGAffineTransformMakeTranslation(0, 80)
                self.lowerLabel.alpha = 0
            }) { (finished) in
                self.lowerLabel.attributedText = self.infoLabelsArray[self.currentText]
                UIView.animateWithDuration(0.6, delay: 0.15, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .CurveEaseInOut, animations: {
                    self.lowerLabel.alpha = 1
                    self.lowerLabel.transform = CGAffineTransformMakeTranslation(0, 0)
                    }, completion: { (finished) in
                        
                })
            }
        }
    }

    //MARK - UITextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = inputTooltipText
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        //print("RANGE", range)
        //print("REPLACEMENT", text)
        do {
            let regex = try NSRegularExpression(pattern: "#(\\w+)", options: NSRegularExpressionOptions.CaseInsensitive)
            let nsString = textView.text as NSString
            let results = regex.matchesInString(textView.text, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
            let centerParagraphStyle = NSMutableParagraphStyle()
            centerParagraphStyle.alignment = .Center
            let attributedString = NSMutableAttributedString(string: textView.text, attributes: [NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 17)!, NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: centerParagraphStyle])
            
            //print(results)
            for match in results {
                attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-SemiBold", size: 17)!, NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: centerParagraphStyle], range: match.range)
            }
            textView.attributedText = attributedString
            textView.textAlignment = .Center
            
            if results.count == 4 {
            } else {
            }
        } catch {
            
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        self.counterLabel.text = "\(textView.text.characters.count) / 160"
        if (textView.text.characters.count > 160) {
            textView.text = String(textView.text.characters.dropLast(textView.text.characters.count-160))
            self.counterLabel.text = "\(textView.text.characters.count) / 160"
        }
        
        if (textView.text.characters.count > 0 && !(textView.text.characters.count > 159)) {
            self.doneButton?.enabled = true
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.textView.alpha = 1
                self.upperLabel.alpha = 0
                self.startTypingView.alpha = 0
                self.lowerLabel.alpha = 0
                self.counterLabel.alpha = 1
                }, completion: { (completed: Bool) -> Void in
                    
            })
        } else if textView.text.characters.count < 160 {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.upperLabel.alpha = 1
                self.startTypingView.alpha = 1
                self.lowerLabel.alpha = 1
                self.counterLabel.alpha = 0
                self.textView.alpha = 0
                }, completion: { (completed: Bool) -> Void in
                    
            })
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        // TODO: change value
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
                heightKeyboard = keyboardSize.height
                //print(heightKeyboard)
                lowerLabelBottomConstraint.constant = heightKeyboard! - 32
                counterLabelBottomConstraint.constant = heightKeyboard! - 32
            }
        }
        else {
            heightKeyboard = 0
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        heightKeyboard = 0
    }
    
    // MARK: - PFLoginController Delegate
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        self.tabBarController?.selectedIndex = 0
    }
    
    func logInViewControllerDidCancelLogIn(logInController: PFLogInViewController) {
        self.tabBarController?.selectedIndex = 0
    }
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        
        PFInstallation.currentInstallation().setObject(user, forKey: "user")
        PFInstallation.currentInstallation().saveInBackground()
        NSUserDefaults.standardUserDefaults().setObject(user.objectId, forKey: "currentUser")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        if let client = AppDelegate.layerClient {
            if let _ = client.authenticatedUserID {
                
            } else {
                let userIDString = user.objectId
                
                self.authenticateLayerWithUserID(userIDString!, completion: { (success, error) -> Void in
                    if let error = error {
                        SVProgressHUD.showSuccessWithStatus(error.localizedDescription)
                    }
                })
            }
        } else {
            let appID = NSURL(string: "layer:///apps/staging/45f026f2-a10f-11e5-8f8b-4e4f000000ac")
            AppDelegate.layerClient = LYRClient(appID: appID!)
            
            AppDelegate.layerClient?.connectWithCompletion({ (success: Bool, error: NSError?) -> Void in
                if let error = error {
                    SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                } else {
                    let userIDString = user.objectId
                    
                    self.authenticateLayerWithUserID(userIDString!, completion: { (success, error) -> Void in
                        if !success {
                        }
                    })
                    
                }
            })
        }
        
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "picture,id,birthday,email,first_name,last_name,gender"])
        request.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            if let error = error {
                SVProgressHUD.showErrorWithStatus(error.localizedDescription)
            } else {
                if let userData = result as? NSDictionary {
                    let facebookID = userData["id"]
                    let name = userData["first_name"]
                    let gender = userData["gender"]
                    let birthday = userData["birthday"]
                    
                    if let USR = PFUser.currentUser() {
                        if let NAME = name {
                            USR["name"] = NAME
                        }
                        if let FACEBOOKID = facebookID {
                            USR["facebookID"] = FACEBOOKID
                            USR["FBPictureURL"] = "https://graph.facebook.com/\(FACEBOOKID)/picture?type=square&height=350&width=350"
                        }
                        if let GENDER = gender {
                            USR["gender"] = GENDER
                        }
                        if let BIRTHDAY = birthday {
                            USR["birthday"] = BIRTHDAY
                        }
                        USR.saveEventually()
                    }
                }
            }
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
            })
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let USR = PFUser.currentUser() {
            self.eventInCreation.owner = USR
        }
        self.eventInCreation.location = BrowseEventsTableViewController.lastSavedLocation
        eventInCreation.eventDescription = textView.text
        eventInCreation.isGroupEvent = Event.detectGroupTag(textView.text)
        if let nextVC = segue.destinationViewController as? TimePickerViewController {
            nextVC.eventInCreation = eventInCreation
            nextVC.registerFlow = self.registerFlow
            nextVC.createPostTapped = self.createPostTapped
        }
        
        if let nextVC = segue.destinationViewController as? CreatedEventConfirmationTableViewController {
            nextVC.eventInCreation = eventInCreation
            nextVC.registerFlow = self.registerFlow
            nextVC.createPostTapped = self.createPostTapped
            nextVC.isEdit = isEdit
        }
    }
    
    // MARK: - Layer Authentication Methods
    
    private func authenticateLayerWithUserID(userID: String, completion :(success: Bool, error: NSError?) -> Void) {
        if let _ = AppDelegate.layerClient!.authenticatedUserID {
            completion(success:true, error:nil)
        } else {
            AppDelegate.layerClient!.requestAuthenticationNonceWithCompletion({(nonce, error) in
                if let nonce = nonce, let user = PFUser.currentUser(), let userId = user.objectId {
                    PFCloud.callFunctionInBackground("generateToken", withParameters: ["nonce": nonce, "userID":userId], block: { (token: AnyObject?, error: NSError?) -> Void in
                        if let token = token as? NSString {
                            AppDelegate.layerClient?.authenticateWithIdentityToken(String(token), completion: { (string: String?, error: NSError?) -> Void in
                                if let error = error {
                                    //KGStatusBar.showWithStatus(error.localizedDescription)
                                }
                            })
                        }
                    })
                } else {
                    completion(success:false, error:error)
                }
            })
        }
        return
    }
    
    private func authenticationTokenWithUserId(userID: String, completion :(success: Bool?, error: NSError?) -> Void) {
        AppDelegate.layerClient?.requestAuthenticationNonceWithCompletion({ (nonce: String?, error: NSError?) -> Void in
            if nonce == nil {
                completion(success: false, error: error)
                return
            }
            if let nonce = nonce {
                if let user = PFUser.currentUser(), let userId = user.objectId {
                    PFCloud.callFunctionInBackground("generateToken", withParameters: ["nonce": nonce, "userID":userId], block: { (token: AnyObject?, error: NSError?) -> Void in
                        if let token = token as? NSString {
                            AppDelegate.layerClient?.authenticateWithIdentityToken(String(token), completion: { (string: String?, error: NSError?) -> Void in
                                
                            })
                        }
                    })
                }
            }
        })
    }
    
    // MARK: Actions
    
    func nextTapped() {
        eventInCreation.tags = Event.detectHashtags(textView.text)
        
        if eventInCreation.tags.count > 0 && eventInCreation.tags.count < 4 {
            
            Mixpanel.sharedInstance().track("New Post - Start new post",
                                          properties: ["tags" : eventInCreation.tags])
            
            var banHashtags = [String]()
            if let banWords = NSUserDefaults.standardUserDefaults().objectForKey("BanWords") as? [String] {
                for string in eventInCreation.tags {
                    for word in banWords {
                        if string.lowercaseString == word.lowercaseString {
                            banHashtags.append(word.lowercaseString)
                        }
                    }
                }
            }
            
            if banHashtags.count > 0 {
                var hashtagString = ""
                for word in banHashtags {
                    hashtagString = hashtagString + " " + "#" + word
                }
                let alert = UIAlertController(title: "Warning", message: "Posts cannot contain obscene, profane, offensive or abusive content. Please remove the following from your post:" + hashtagString, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                    
                }))
                self.presentViewController(alert, animated: true) { () -> Void in }
            } else {
                if shouldTrackDescription {
                    shouldTrackDescription = false
                    
                    Mixpanel.sharedInstance().track("New Post - Description added")
                }
                
                let overlay = UIView(frame: UIScreen.mainScreen().bounds)
                overlay.backgroundColor = UIColor.vocaleBackgroundGreyColor()
                overlay.alpha = 0
                self.view.addSubview(overlay)
                textView.resignFirstResponder()
                UIView.animateWithDuration(0.3, animations: {
                    overlay.alpha = 1
                    }, completion: { (finished) in
                        overlay.removeFromSuperview()
                        self.performSegueWithIdentifier("toEventCreation2", sender: self)
                })
            }
        } else if eventInCreation.tags.count == 0 {
            SVProgressHUD.showErrorWithStatus("Your post needs a hashtag.")
        } else {
            SVProgressHUD.showErrorWithStatus("Posts only allow 3 hashtags.")
        }
    }
    
    func closeTapped() {
        if registerFlow == true {
            let alert = UIAlertController(title: "Quit Setup?", message: "Are you sure you want to quit signing up? You will be logged out and your details will not be saved.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SetupCancelled")
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.upperLabel.alpha = 0
                    self.startTypingView.alpha = 0
                    self.lowerLabel.alpha = 0
                    self.counterLabel.alpha = 0
                    self.textView.alpha = 0
                    }, completion: { (completed: Bool) -> Void in
                        self.navigationController?.popToRootViewControllerAnimated(false)
                })
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        } else {
            let alert = UIAlertController(title: "Cancel Confirmation", message: "Are you sure you want to cancel creating this post?", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
                Mixpanel.sharedInstance().track("New Post - Canceled", properties: ["screen" : "First screen"])
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.upperLabel.alpha = 0
                    self.startTypingView.alpha = 0
                    self.lowerLabel.alpha = 0
                    self.counterLabel.alpha = 0
                    self.textView.alpha = 0
                    }, completion: { (completed: Bool) -> Void in
                        self.navigationController?.popToRootViewControllerAnimated(false)
                })
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        }
    }
}
