//
//  SetupViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 5/29/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import CoreLocation

class SetupViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var blueDot: UIView! {
        didSet {
        }
    }
    @IBOutlet weak var greenDot: UIView! {
        didSet {
        
        }
    }
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var lineImageView: UIImageView!
    @IBOutlet weak var tooltipLabel: UILabel!
    @IBOutlet weak var tooltipLabelBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var welcomeLabelTopConstraint: NSLayoutConstraint!
    var locationManager: CLLocationManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            delegate.registerNotCompleted = true
        }
        
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        title = "Get Started"
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        
        //print(PFUser.currentUser())
        if let user = PFUser.currentUser(), let name = user["name"] as? String {
            nameLabel.text = name + "."
        } else {
            nameLabel.hidden = true
        }
        
        if let user = PFUser.currentUser(), let profilePictureLink = user["FBPictureURL"] as? String, let url = NSURL(string: profilePictureLink) {
            let request: NSURLRequest = NSURLRequest(URL: url)
            let mainQueue = NSOperationQueue.mainQueue()
            NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                if error == nil {
                    let image = UIImage(data: data!)
                    self.profileImageView.image = image
                }
                else {
                    
                }
            })
        }
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
        
        
//        locationManager = CLLocationManager()
//        locationManager.delegate = self
//        locationManager.requestWhenInUseAuthorization()
//        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            //self.locationManager.requestLocation()
        }
    }
    
    override func viewWillLayoutSubviews() {
    }
    
    override func viewDidLayoutSubviews() {
        setupViews()
        self.animateDotsRotation()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.toolbar.barTintColor = UIColor(netHex: 0xEEEEEE)
        self.navigationController?.toolbar.translucent = false
        
        self.circleView.alpha = 0
        self.blueDot.alpha = 0
        self.greenDot.alpha = 0
        self.profileImageView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        self.tooltipLabel.alpha = 0
        self.welcomeLabel.alpha = 0
        self.nameLabel.alpha = 0
        self.lineImageView.alpha = 0
        //self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        if self.view.frame.size.width <= 320 {
            self.welcomeLabelTopConstraint.constant = 20
            self.tooltipLabelBottomConstraint.constant = 40
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.animateFadeIn()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let nextVC = segue.destinationViewController as? InputViewController {
            nextVC.registerFlow = true
        }
    }

    //MARK - IBActions
    func animateFadeIn() {
        self.welcomeLabel.transform = CGAffineTransformMakeTranslation(0, 20)
        self.nameLabel.transform = CGAffineTransformMakeTranslation(0, 20)
        
        UIView.animateWithDuration(0.6, delay: 0.6, options: .CurveEaseInOut, animations: {
            self.welcomeLabel.alpha = 1
            self.welcomeLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            self.nameLabel.alpha = 1
            self.nameLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            self.lineImageView.alpha = 1
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.3, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 20, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.profileImageView.transform = CGAffineTransformMakeScale(1, 1)
        }) { (success) in
            self.animateDotsRotation()
        }
        
        UIView.animateWithDuration(1.2, delay: 0.6, options: .CurveEaseInOut, animations: {
            self.circleView.alpha = 1
            self.blueDot.alpha = 1
            self.greenDot.alpha = 1
            self.tooltipLabel.alpha = 1
        }) { (success) in

        }
    }
    
    func animateFadeOut() {
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.welcomeLabel.alpha = 0
            self.welcomeLabel.transform = CGAffineTransformMakeTranslation(0, 20)
            self.nameLabel.alpha = 0
            self.nameLabel.transform = CGAffineTransformMakeTranslation(0, 20)
            self.lineImageView.alpha = 0
            self.circleView.alpha = 0
            self.blueDot.alpha = 0
            self.greenDot.alpha = 0
            self.tooltipLabel.alpha = 0
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.3, delay: 0.6, usingSpringWithDamping: 0.7, initialSpringVelocity: 20, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.profileImageView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        }) { (success) in
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SetupCancelled")
            self.navigationController?.popToRootViewControllerAnimated(true)
        }
    }
    
    func closeTapped() {
        let alert = UIAlertController(title: "Quit Setup?", message: "Are you sure you want to quit signing up? You will be logged out and your details will not be saved.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
//            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SetupCancelled")
//            self.navigationController?.popToRootViewControllerAnimated(true)
            self.animateFadeOut()
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
    }
    
    func setupViews() {
//        var circleViewWidth: CGFloat = 155
//        var avatarImageViewWidth: CGFloat = 115
//        if self.contentView.frame.size.width <= 320 {
//            circleViewWidth = 125
//            avatarImageViewWidth = 90
//        }
        blueDot.layer.cornerRadius = blueDot.frame.size.width/2
        greenDot.layer.cornerRadius = blueDot.frame.size.width/2
        
        circleView.layer.cornerRadius = self.circleView.frame.size.width/2
        circleView.layer.borderColor = UIColor.vocaleOrangeColor().CGColor
        circleView.layer.borderWidth = 1
        
        self.profileImageView.layer.cornerRadius = 80
        self.profileImageView.layer.borderColor = UIColor.vocaleFilterTextColor().CGColor
        self.profileImageView.layer.borderWidth = 2
        self.profileImageView.clipsToBounds = true
    }
    
    //Helper methods
    func animateBlueDotRotation(fromValue: NSValue, duration: CFTimeInterval) {
        let rotationPoint = self.circleView.center
        
        var anchorPoint = CGPointMake(6.3, 6.3)
//        if self.contentView.frame.size.width <= 320 {
//            anchorPoint = CGPointMake(4.1, 4.1)
//        }
        blueDot.layer.anchorPoint = anchorPoint
        blueDot.layer.position = rotationPoint;
        
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        if fromValue.CGPointValue() != CGPointZero {
            rotate.fromValue = fromValue
        }
        rotate.toValue = 2*M_PI
        rotate.duration = duration
        rotate.repeatCount = Float.infinity
        blueDot.layer.addAnimation(rotate, forKey: "rotationAnimationBlueDot")
    }
    
    func animateGreenDotRotation(fromValue: NSValue, duration: CFTimeInterval) {
        let rotationPoint = self.circleView.center
        
        var anchorPoint = CGPointMake(6.3, 6.3)
//        if self.contentView.frame.size.width <= 320 {
//            anchorPoint = CGPointMake(4.1, 4.1)
//        }
        greenDot.layer.anchorPoint = anchorPoint
        greenDot.layer.position = rotationPoint;
        
        let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
        if fromValue.CGPointValue() != CGPointZero {
            rotate.fromValue = fromValue
        }
        rotate.toValue = -2*M_PI
        rotate.duration = duration
        rotate.repeatCount = Float.infinity
        greenDot.layer.addAnimation(rotate, forKey: "rotationAnimationGreenDot")
    }
    
    func animateDotsRotation() {
        //self.circleView.layoutIfNeeded()
        self.animateBlueDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
        self.animateGreenDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
    }
}
