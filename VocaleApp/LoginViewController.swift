//
//  LoginViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 5/20/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

//import FBSDKLoginKit
//import SwiftyJSON

import UIKit
import LayerKit
import MediaPlayer

class LoginViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, CLLocationManagerDelegate {

    @IBOutlet weak var movieView: UIView!
    var moviePlayer: MPMoviePlayerController!
    var firstLogin = false
    static var firstTry = true
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            //loginButton.alpha = 0
        }
    }
    
    @IBOutlet weak var facebookLabel: UILabel!
    @IBOutlet weak var conditionsLabel: UILabel!
    @IBOutlet weak var andLabel: UILabel!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    
    var firstText = "Do the things you love.\nFind people to join you."
    var secondText = "Everyone first connects,\nwith a voice note."
    var thirdText = "There is always something to do\nand someone to do it with."
    var forthText = "All you have to do is ask yourself,\n“What do I feel like doing right\nnow?”"
    var conditionsText = "By continuing you agree to our Terms of Service and Privacy Policy."
    var firstAttributedString: NSMutableAttributedString?
    var secondAttributedString: NSMutableAttributedString?
    var thirdAttributedString: NSMutableAttributedString?
    var forthAttributedString: NSMutableAttributedString?
    var conditionsAttributedString: NSMutableAttributedString?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let path = NSBundle.mainBundle().pathForResource("vocalevid", ofType:"mp4")
        let url = NSURL.fileURLWithPath(path!)
        self.moviePlayer = MPMoviePlayerController(contentURL: url)
        if let player = self.moviePlayer {
            player.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.width)
            player.view.sizeToFit()
            player.scalingMode = MPMovieScalingMode.AspectFill
            player.fullscreen = true
            player.controlStyle = MPMovieControlStyle.None
            player.movieSourceType = MPMovieSourceType.File
            player.repeatMode = MPMovieRepeatMode.One
            player.play()
            //self.view.insertSubview(self.moviePlayer.view, belowSubview: self.collectionView)
            self.movieView.addSubview(self.moviePlayer.view)
        }
        self.view.bringSubviewToFront(self.collectionView)
        
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        if !PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            
        }
        
        if self.view.frame.size.width <= 320 {
            self.facebookLabel.font = UIFont(name: "Raleway-Regular", size: 11)
            self.conditionsLabel.font = UIFont(name: "Raleway-Regular", size: 9)
            self.andLabel.font = UIFont(name: "Raleway-Regular", size: 9)
            self.termsButton.titleLabel?.font = UIFont(name: "Raleway-Regular", size: 9)
            self.privacyButton.titleLabel?.font = UIFont(name: "Raleway-Regular", size: 9)
        } else {
            self.facebookLabel.font = UIFont(name: "Raleway-Regular", size: 13)
            self.conditionsLabel.font = UIFont(name: "Raleway-Regular", size: 11)
            self.andLabel.font = UIFont(name: "Raleway-Regular", size: 11)
            self.termsButton.titleLabel?.font = UIFont(name: "Raleway-Regular", size: 11)
            self.privacyButton.titleLabel?.font = UIFont(name: "Raleway-Regular", size: 11)
        }
        
        firstAttributedString = NSMutableAttributedString(string: firstText);
        firstAttributedString?.setColorForStr("Find people to join you.", color: UIColor(netHex: 0x848485))
        secondAttributedString = NSMutableAttributedString(string: secondText);
        secondAttributedString?.setColorForStr("with a voice note.", color: UIColor(netHex: 0x848485))
        thirdAttributedString = NSMutableAttributedString(string: thirdText);
        thirdAttributedString?.setColorForStr("and someone to do it with.", color: UIColor(netHex: 0x848485))
        forthAttributedString = NSMutableAttributedString(string: forthText);
        forthAttributedString?.setColorForStr("“What do I feel like doing right\nnow?”", color: UIColor(netHex: 0x848485))
        
//        conditionsAttributedString = NSMutableAttributedString(string: conditionsText);
//        conditionsAttributedString?.setColorForStr("Terms of Service", color: UIColor(netHex: 0xB7B7B7))
//        conditionsAttributedString?.setColorForStr("Privacy Policy", color: UIColor(netHex: 0xB7B7B7))
//        conditionsLabel.attributedText = conditionsAttributedString
        
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(profileCreated), name: "PostCreationLastStepNotification", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.None)
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewWillAppear(animated)
        if firstLogin == true && NSUserDefaults.standardUserDefaults().objectForKey("SetupCancelled") == nil {
            self.dismissViewControllerAnimated(false, completion: nil)
        }
        
        if NSUserDefaults.standardUserDefaults().objectForKey("SetupCancelled") != nil {
            PFUser.currentUser()?.deleteInBackground()
        }
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "badgeCount")
        
        self.movieView.alpha = 0
        self.collectionView.alpha = 0
        self.facebookLabel.alpha = 0
        self.loginButton.alpha = 0
        self.bottomView.alpha = 0
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseInOut, animations: { 
            self.movieView.alpha = 1
            self.collectionView.alpha = 1
            self.facebookLabel.alpha = 1
            self.loginButton.alpha = 1
            self.bottomView.alpha = 1
            }) { (finished) in
                
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Notification
    func profileCreated(notification: NSNotification) {
        self.dismissViewControllerAnimated(false, completion: nil)
    }
    
    //MARK: - UICollectionViewDataSource
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("LoginCell", forIndexPath: indexPath) as! LoginCollectionViewCell;
        if indexPath.row == 0 {
            cell.topImageView.image = UIImage(named: "doMore")
            cell.dotsImageView.image = UIImage(named: "firstDot")
            cell.infoLabel.attributedText = firstAttributedString
        } else if indexPath.row == 1 {
            cell.topImageView.image = UIImage(named: "sayMore")
            cell.dotsImageView.image = UIImage(named: "secondDot")
            cell.infoLabel.attributedText = secondAttributedString
        } else if indexPath.row == 2 {
            cell.topImageView.image = UIImage(named: "findMore")
            cell.dotsImageView.image = UIImage(named: "thirdDot")
            cell.infoLabel.attributedText = thirdAttributedString
        } else if indexPath.row == 3 {
            cell.topImageView.image = UIImage(named: "liveMore")
            cell.dotsImageView.image = UIImage(named: "forthDot")
            cell.infoLabel.attributedText = forthAttributedString
        }
        return cell;
    }
    
    //MARK: - UICollectionViewDelegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(self.view.frame.size.width, self.view.frame.size.height - loginButton.frame.size.height - 48);
    }
    
    //MARK: - IBActions
    @IBAction func loginButtonTapped(sender: UIButton) {
        Mixpanel.sharedInstance().track("Onboarding - Registration started",
                                      properties: ["type" : "facebook"])
        
        SVProgressHUD.showWithStatus("Logging you in...")
        let loginManager = FBSDKLoginManager()


        loginManager.loginBehavior = FBSDKLoginBehavior.SystemAccount
        loginManager.logInWithReadPermissions(["public_profile", "email", "user_friends", "user_photos"], fromViewController: self, handler: { (result, error) -> Void in
            if result.isCancelled {
                SVProgressHUD.dismiss()
//                if FBSDKAccessToken.current() != nil {
//                    FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "locale, location"]).start(completionHandler: { (connection, result, error) in
//                        if error == nil {
//                            let json = JSON(result!)
//                            print(json)
//                            User.cureentUser.setUser(json)
//                            
//                            complation()
//                        }
//                    })
//                }
                return
            }
            print("Token: \(result.token)")
        
            PFFacebookUtils.logInWithFacebookId(FBSDKAccessToken.currentAccessToken().userID, accessToken: FBSDKAccessToken.currentAccessToken().tokenString, expirationDate: FBSDKAccessToken.currentAccessToken().expirationDate) {
                (user: PFUser?, error: NSError?) -> Void in
                if let user = user {
                    
                    PFInstallation.currentInstallation().setObject(user, forKey: "user")
                    PFInstallation.currentInstallation().saveInBackground()
                    NSUserDefaults.standardUserDefaults().setObject(user.objectId, forKey: "currentUser")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    
                    SVProgressHUD.showWithStatus("Checking your details...")
                    LoginViewController.performFBGraphRequestWithUser(user)
                    
                    if let client = AppDelegate.layerClient {
                        if let _ = client.authenticatedUserID {
                            SVProgressHUD.dismiss()
                            self.performSegueWithUser(user)
                        } else {
                            let userIDString = user.objectId
                            
                            self.authenticateLayerWithUserID(userIDString!, completion: { (success, error) -> Void in
                                if let error = error {
                                    ErrorManager.handleError(error)
                                }
                                SVProgressHUD.dismiss()
                                self.performSegueWithUser(user)
                            })
                        }
                    } else {
                        let appID = NSURL(string: "layer:///apps/staging/45f026f2-a10f-11e5-8f8b-4e4f000000ac")
                        AppDelegate.layerClient = LYRClient(appID: appID!)
                        
                        AppDelegate.layerClient?.connectWithCompletion({ (success: Bool, error: NSError?) -> Void in
                            if let error = error {
                                ErrorManager.handleError(error)
                            } else {
                                let userIDString = user.objectId
                                
                                self.authenticateLayerWithUserID(userIDString!, completion: { (success, error) -> Void in
                                    if !success {
                                        ErrorManager.handleError(error)
                                    }
                                    SVProgressHUD.dismiss()
                                    self.performSegueWithUser(user)
                                })
                                
                            }
                            
                        })
                    }
                } else {
                    print("Uh oh. The user cancelled the Facebook login.", terminator: "")
                }
            }
        })
    }
    
    @IBAction func termsAndConditionsButtonTapped(sender: UIButton) {
        let webVC = self.storyboard?.instantiateViewControllerWithIdentifier("WebVC") as! WebViewController
        webVC.isTermsAndCondtions = true
        webVC.fromLogin = true
        self.presentViewController(webVC, animated: true, completion: nil)
    }
    
    @IBAction func privacyButtonTapped(sender: UIButton) {
        let webVC = self.storyboard?.instantiateViewControllerWithIdentifier("WebVC") as! WebViewController
        webVC.isPrivacyPolicy = true
        webVC.fromLogin = true
        self.presentViewController(webVC, animated: true, completion: nil)
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
                                    
                                    completion(success:false, error:error)
                                } else {
                                    
                                    completion(success:true, error:error)
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
    
    // MARK: Auxiliary Methods
    
    static func performFBGraphRequestWithUser(user: PFUser) {
//        print(FBSDKAccessToken.currentAccessToken())
//        print(FBSDKAccessToken.currentAccessToken().tokenString)
        
        let facebookGraphRequest = {
            
            let tokenString = FBSDKAccessToken.currentAccessToken().tokenString
            let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "picture,id,birthday,email,first_name,last_name,gender"], tokenString:tokenString, version:nil, HTTPMethod:"GET")
            print("Token \(tokenString) ---- Request: \(request)")
            request.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                if let error = error {
                    print("Error: \(error)")
                    if (self.firstTry) {
                        self.firstTry = false
                        self.performFBGraphRequestWithUser(user)
                    } else {
                        ErrorManager.discreetlyHandleError(error)
                    }
                } else {
                    print("Result: \(result)")
                    if let userData = result as? NSDictionary {
                        let facebookID = userData["id"]
                        let email = userData["email"]
                        let name = userData["first_name"]
                        let gender = userData["gender"]
                        let birthday = userData["birthday"]
                        
                        if let USR = PFUser.currentUser() {
                            //print("USER", USR)
                            if let EMAIL = email {
                                USR["email"] = EMAIL
                            }
                            
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
                                let df = NSDateFormatter()
                                df.dateFormat = "MM/dd/yyyy"
                                if let birthday = BIRTHDAY as? String, date = df.dateFromString(birthday) {
                                    USR["birthdate"] = date
                                }
                            }
                            USR.saveInBackgroundWithBlock(nil)
                        }
                    }
                }
            }
        }
        
        facebookGraphRequest()
    }
    
    
    
    func performSegueWithUser(user: PFUser) {
        if (user["userRegistered"]) != nil {
            if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
                delegate.registerNotCompleted = false
            }
            self.dismissViewControllerAnimated(false, completion: nil)
        } else {
            //print(user)
            Mixpanel.sharedInstance().track("Onboarding - Registration completed",
                                          properties: ["type" : "facebook"])
            
            if let currentUser = PFUser.currentUser() {
                if let admin = currentUser["admin"] as? Bool {
                    if admin == true {
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "GeoFenceActivated")
                        showBrowseScreen(user)
                        return
                    }
                }
            }
            
            if CLLocationManager.locationServicesEnabled() {
                switch(CLLocationManager.authorizationStatus()) {
                case .NotDetermined, .Restricted, .Denied:
                    NSUserDefaults.standardUserDefaults().setBool(true, forKey: "GeoFenceActivated")
                    if let geoFenceVC = self.storyboard?.instantiateViewControllerWithIdentifier("GeoFenceVC") as? GeoFenceViewController {
                        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
                        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
                        self.navigationController?.pushViewController(geoFenceVC, animated: true)
                    }
                case .AuthorizedAlways, .AuthorizedWhenInUse:
                    let locationManager = CLLocationManager()
                    GeoFenceManager.sharedInstance.userLocation = locationManager.location
                    GeoFenceManager.sharedInstance.geoLocationCheck({ (inRange) in
                        if inRange == true {
                            self.showBrowseScreen(user)
                        } else {
                            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "GeoFenceActivated")
                            if let geoFenceVC = self.storyboard?.instantiateViewControllerWithIdentifier("GeoFenceVC") as? GeoFenceViewController {
                                UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
                                self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
                                self.navigationController?.pushViewController(geoFenceVC, animated: true)
                            }
                        }
                    })
                }
            } else {
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "GeoFenceActivated")
                if let geoFenceVC = self.storyboard?.instantiateViewControllerWithIdentifier("GeoFenceVC") as? GeoFenceViewController {
                    UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
                    self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
                    self.navigationController?.pushViewController(geoFenceVC, animated: true)
                }
            }
        }
    }
    
    func showBrowseScreen(user: PFUser) {
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "GeoFenceActivated")
        if let birthday = user["birthdate"] as? NSDate {
            let upperDate = birthday.dateByAddingYears(18)
            //print(upperDate)
            if NSDate().compare(upperDate) == .OrderedAscending {
                let alert = UIAlertController(title: "Login unsuccessful!", message: "Sorry, you need to be at least 18 years old to use Vocale.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                    PFUser.currentUser()?.deleteInBackground()
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }))
                self.presentViewController(alert, animated: true) { () -> Void in
                    
                }
                
            } else {
                self.navigationController?.setToolbarHidden(false, animated: false)
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
                self.performSegueWithIdentifier("toLoginProcessSegue", sender: self)
                self.firstLogin = true
                PFUser.currentUser()?["userRegistered"] = true
                PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                    if let error = error {
                        ErrorManager.handleError(error)
                    } else {
                        
                    }
                })
            }
        } else {
            self.navigationController?.setToolbarHidden(false, animated: false)
            self.navigationController?.setNavigationBarHidden(false, animated: false)
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
            self.performSegueWithIdentifier("toLoginProcessSegue", sender: self)
            self.firstLogin = true
            PFUser.currentUser()?["userRegistered"] = true
            PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                if let error = error {
                    ErrorManager.handleError(error)
                } else {
                    
                }
            })
        }
    }
    // MARK: - Navigation
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        
//        if let nextVC = segue.destinationViewController as? SetupViewController {
//            nextVC.registerFlow = true
//        }
//    }
    
}


extension NSMutableAttributedString {
    
    func setColorForStr(textToFind: String, color: UIColor) {
        
        let range = self.mutableString.rangeOfString(textToFind, options:NSStringCompareOptions.CaseInsensitiveSearch);
        if range.location != NSNotFound {
            self.addAttribute(NSForegroundColorAttributeName, value: color, range: range);
        }
        
    }
}
