//
//  EventCreationFirstStepTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/27.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit

class EventCreationFirstStepTableViewController: UITableViewController, PFLogInViewControllerDelegate, UITextViewDelegate {

    var createPostTapped = false
    @IBOutlet weak var lowerDescriptionLabel: UILabel! {
        didSet {
            lowerDescriptionLabel.text = "Post must contain at least one #.\nAdd up to 3 #'s to appear in more results."
            lowerDescriptionLabel.textColor = UIColor(netHex:0xEEEEEE)
            lowerDescriptionLabel.font = UIFont(name: "Raleway-Light", size: 15)
        }
    }
    @IBOutlet weak var startTypingLabel: UILabel!

    var eventInCreation = Event() {
        didSet {

        }
    }

    @IBOutlet weak var descriptionTextView: UITextView! {
        didSet {
            descriptionTextView.delegate = self
            let keyboardToolbar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
            keyboardToolbar.barTintColor = UIColor.darkGrayColor()
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let nextButton = UIBarButtonItem(title: "Next", style: .Plain, target: self, action: "nextTapped")
            keyboardToolbar.setItems([flexibleSpace, nextButton, flexibleSpace], animated: true)
            descriptionTextView.inputAccessoryView = keyboardToolbar
        }
    }

    @IBOutlet weak var characterCount: UILabel! {
        didSet {
            characterCount.textColor = UIColor.vocaleRedColor()
            characterCount.textAlignment = .Right
        }
    }

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        LoginViewController.performFBGraphRequestWithUser(PFUser.currentUser()!)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
    }

    override func viewWillAppear(animated: Bool) {
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            presentLoginController()
        } else {
            descriptionTextView.becomeFirstResponder()
        }
        if eventInCreation.eventDescription.characters.count > 1 {
            descriptionTextView.text = eventInCreation.eventDescription
        }
    }

    // MARK: - IBActions

    @IBAction func didCancel(sender: AnyObject) {
        self.navigationController?.popToRootViewControllerAnimated(true)
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

    // MARK: - UITextView Delegate

    func textViewDidChange(textView: UITextView) {
        self.characterCount.text = "\(textView.text.characters.count) / 160"
        if (textView.text.characters.count > 160) {
            textView.text = String(textView.text.characters.dropLast(textView.text.characters.count-160))
            self.characterCount.text = "\(textView.text.characters.count) / 160"

            startTypingLabel.text = "You've reached the character limit."
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.startTypingLabel.alpha = 1
                self.lowerDescriptionLabel.alpha = 1
                }, completion: { (completed: Bool) -> Void in

            })
        } else {
        }
        if (textView.text.characters.count > 0 && !(textView.text.characters.count > 159)) {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.startTypingLabel.alpha = 0
                self.lowerDescriptionLabel.alpha = 0
                }, completion: { (completed: Bool) -> Void in

            })
        } else {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.startTypingLabel.alpha = 1
                self.lowerDescriptionLabel.alpha = 1
                }, completion: { (completed: Bool) -> Void in

            })
        }
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView.text == "Create a post about anything you need or feel like doing." {
            textView.text = ""
            textView.font = UIFont(name: "Raleway-Regular", size: 17)
        }
        if (text == "\n") {
            textView.resignFirstResponder()
            nextTapped()
        }

        do {
            let regex = try NSRegularExpression(pattern: "#(\\w+)", options: NSRegularExpressionOptions.CaseInsensitive)
            let nsString = textView.text as NSString
            let results = regex.matchesInString(textView.text, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
            let centerParagraphStyle = NSMutableParagraphStyle()
            centerParagraphStyle.alignment = .Center
            let attributedString = NSMutableAttributedString(string: textView.text, attributes: [NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 17)!, NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: centerParagraphStyle])

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

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let USR = PFUser.currentUser() {
            self.eventInCreation.owner = USR
        }
        self.eventInCreation.location = BrowseEventsTableViewController.lastSavedLocation
        eventInCreation.eventDescription = descriptionTextView.text
        eventInCreation.isGroupEvent = Event.detectGroupTag(descriptionTextView.text)
        if let nextVC = segue.destinationViewController as? TimePickerViewController {
            nextVC.eventInCreation = eventInCreation
            nextVC.createPostTapped = self.createPostTapped
        }
    }

    // MARK: - Auxiliary Functions

    private func presentLoginController() {
        let logInController = PFLogInViewController()
        logInController.delegate = self
        logInController.fields = [PFLogInFields.Facebook, PFLogInFields.DismissButton, PFLogInFields.UsernameAndPassword, PFLogInFields.LogInButton]
        logInController.logInView?.logo!.frame.size = CGSizeMake(logInController.logInView!.logo!.frame.width, logInController.logInView!.logo!.frame.width*2)
        logInController.logInView?.logo = UIImageView(image: UIImage(assetIdentifier: .VocaleClearBlack))
        (logInController.logInView?.logo as! UIImageView).contentMode = UIViewContentMode.ScaleAspectFit
        logInController.facebookPermissions = ["public_profile", "email", "user_friends", "user_photos"]
        let label = UILabel(frame: CGRectMake(self.view.frame.origin.x, self.view.center.y, self.view.frame.width, 200))
        label.numberOfLines = 2
        label.textAlignment = NSTextAlignment.Center
        label.text = " "
        logInController.view.addSubview(label)

        self.presentViewController(logInController, animated: true, completion: { () -> Void in

        })
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
        eventInCreation.tags = Event.detectHashtags(descriptionTextView.text)
        if eventInCreation.tags.count > 0 && eventInCreation.tags.count < 4 {
            self.performSegueWithIdentifier("toEventCreation2", sender: self)
        } else if eventInCreation.tags.count == 0 {
            SVProgressHUD.showErrorWithStatus("Your post needs a hashtag.")
        } else {
            SVProgressHUD.showErrorWithStatus("Posts only allow 3 hashtags.")
        }
    }
    
    func closeTapped() {
        let alert = UIAlertController(title: "Cancel Confirmation", message: "Are you sure you want to cancel creating this post?", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
    }
    
}
