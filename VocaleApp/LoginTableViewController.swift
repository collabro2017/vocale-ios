//
//  LoginTableViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/02/06.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit
import AVFoundation

class LoginTableViewController: UITableViewController {

    static var firstTry = true
    var myPlayer: AVPlayer?
    var animationImageView = UIImageView()

    @IBOutlet weak var videoCell: UITableViewCell!

    @IBOutlet weak var loginButton: UIButton! {
        didSet {
            loginButton.alpha = 0

            loginButton.imageView?.contentMode = .ScaleAspectFit
        }
    }

    // MARK: View Controller LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
        self.navigationController?.setToolbarHidden(true, animated: false)
        if !PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {

        }
    }

    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setToolbarHidden(false, animated: true)
    }

    override func viewWillAppear(animated: Bool) {
        let images = [UIImage(named: "DoMore")!, UIImage(named: "SeeMore")!, UIImage(named: "LiveMore")!, UIImage(named: "VocaleLogo")!]
        var showImageAnimated: (images: [UIImage]) -> Void = {_ in
        }
        showImageAnimated = {
            images in
            var images = images
            let imageView = UIImageView(frame: CGRectMake(self.videoCell.frame.width/2,self.videoCell.frame.height/2, 0, 0))
            self.videoCell.addSubview(imageView)
            imageView.image = images.removeFirst()
            imageView.contentMode = .ScaleAspectFit
            UIView.animateWithDuration(1, delay: 0, usingSpringWithDamping: 0.96, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                imageView.frame = CGRectMake(self.videoCell.frame.width/4,self.videoCell.frame.height/4, self.videoCell.frame.width/2, self.videoCell.frame.width/2)
                }, completion: { (completed: Bool) -> Void in
                    if images.count > 0 {
                        imageView.removeFromSuperview()
                        showImageAnimated(images: images)
                    } else {
                        UIImageView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                            self.loginButton.alpha = 1
                            }, completion: { (completed: Bool) -> Void in
                                if (completed) {
                                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
                                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                                        imageView.removeFromSuperview()
                                        let images = [UIImage(named: "DoMore")!, UIImage(named: "SeeMore")!, UIImage(named: "LiveMore")!, UIImage(named: "VocaleLogo")!]
                                        showImageAnimated(images: images)
                                    }

                                }
                        })
                    }
            })
        }

        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            showImageAnimated(images: images)
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return self.view.frame.width
        }
        return self.tableView.frame.height-self.view.frame.width+4
    }

    @IBAction func loginTapped(sender: AnyObject) {
        SVProgressHUD.showWithStatus("Logging you in...")
        PFFacebookUtils.logInWithPermissions(["public_profile", "email", "user_friends", "user_photos"]) {
            (user: PFUser?, error: NSError?) -> Void in
            if let user = user {

                PFInstallation.currentInstallation().setObject(user, forKey: "user")
                PFInstallation.currentInstallation().saveInBackground()
                NSUserDefaults.standardUserDefaults().setObject(user.objectId, forKey: "currentUser")
                NSUserDefaults.standardUserDefaults().synchronize()

                SVProgressHUD.showWithStatus("Checking your details...")
                LoginTableViewController.performFBGraphRequestWithUser(user)

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
        let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "picture,id,birthday,email,first_name,last_name,gender"])

        request.startWithCompletionHandler { (connection: FBSDKGraphRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            if let error = error {
                if (self.firstTry) {
                    self.firstTry = false
                    self.performFBGraphRequestWithUser(user)
                } else {
                    ErrorManager.discreetlyHandleError(error)
                }
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
                            let df = NSDateFormatter()
                            df.dateFormat = "MM/dd/yyyy"
                            if let birthday = BIRTHDAY as? String, date = df.dateFromString(birthday) {
                                USR["birthdate"] = date
                            }
                        }
                        USR.saveEventually()
                    }
                }
            }
        }
    }

    func showImageAnimated(image: UIImage) {
        animationImageView.removeFromSuperview()
        animationImageView = UIImageView(frame: CGRectMake(self.view.frame.width/2,self.view.frame.width/2, 0, 0))
        self.view.addSubview(animationImageView)
        animationImageView.backgroundColor = UIColor.whiteColor()
        animationImageView.image = image
        animationImageView.contentMode = .ScaleAspectFit
        UIView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.96, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            CGRectMake(self.view.frame.width/4,self.view.frame.width/4, self.view.frame.width/2, self.view.frame.width/2)
            }, completion: { (completed: Bool) -> Void in
                if (completed) {
                    UIImageView.animateWithDuration(0.6, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        self.loginButton.alpha = 1
                        }, completion: { (completed: Bool) -> Void in

                    })

                }
        })

    }

    func restartVideoFromBeginning() {
        let seconds: Int64 = 0
        let preferredTimeScale: Int32 = 1
        let seekTime: CMTime = CMTimeMake(seconds, preferredTimeScale)

        myPlayer!.seekToTime(seekTime)

        myPlayer!.play()

    }

    func performSegueWithUser(user: PFUser) {
        if (user["AboutMe"]) != nil {
            self.navigationController?.popToRootViewControllerAnimated(true)
        } else {
            self.performSegueWithIdentifier("toLoginProcessSegue", sender: self)
        }
    }

}
