//
//  AllSetViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 11/9/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class AllSetViewController: UIViewController {
    
    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var blueDot: UIView! {
        didSet {
            blueDot.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var greenDot: UIView! {
        didSet {
            greenDot.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var mainTitleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var goToBrowseButton: UIButton!
    @IBOutlet weak var editProfileButton: UIButton!
    @IBOutlet weak var mainTitleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var editProfileButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var circleViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var subTitleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subTitleLabelLeadingConstrint: NSLayoutConstraint!
    @IBOutlet weak var goToBrowseButtonTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupViews()
        
        self.navigationItem.hidesBackButton = true
        
        if let user = PFUser.currentUser(), let profilePictureLink = user["FBPictureURL"] as? String, let url = NSURL(string: profilePictureLink) {
            let request: NSURLRequest = NSURLRequest(URL: url)
            let mainQueue = NSOperationQueue.mainQueue()
            NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                if error == nil {
                    let image = UIImage(data: data!)
                    self.avatarImageView.image = image
                }
                else {
                    
                }
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.circleView.alpha = 0
        self.blueDot.alpha = 0
        self.greenDot.alpha = 0
        self.avatarImageView.alpha = 0
        self.mainTitleLabel.alpha = 0
        self.subTitleLabel.alpha = 0
        self.goToBrowseButton.alpha = 0
        self.editProfileButton.alpha = 0
        
        self.title = "Vocale"
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        animateShow()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.topItem?.title = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK - Actions
    @IBAction func goToBrowseButtonTapped(sender: UIButton) {
        animateHide()
    }
    
    @IBAction func editProfileButtonTapped(sender: UIButton) {
        
    }
    
    //MARK - UI setup
    func setupViews() {
        var circleViewWidth: CGFloat = 155
        var avatarImageViewWidth: CGFloat = 115
        if self.view.frame.size.width <= 320 {
//            circleViewWidth = 125
//            avatarImageViewWidth = 90
            circleViewTopConstraint.constant = 16
            mainTitleTopConstraint.constant = 16
            editProfileButtonTopConstraint.constant = 22
            subTitleLabelLeadingConstrint.constant = 22
            subTitleLabelTrailingConstraint.constant = 22
            goToBrowseButtonTopConstraint.constant = 10
            self.view.layoutIfNeeded()
        }
        circleView.layer.cornerRadius = circleViewWidth/2
        circleView.layer.borderColor = UIColor.vocaleOrangeColor().CGColor
        circleView.layer.borderWidth = 1
        
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewWidth/2
        avatarImageView.layer.borderColor = UIColor.vocaleFilterTextColor().CGColor
        avatarImageView.layer.borderWidth = 2
    }
    
    func animateShow() {
        self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 30)
        self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 30)
        self.goToBrowseButton.transform = CGAffineTransformMakeTranslation(0, 30)
        self.editProfileButton.transform = CGAffineTransformMakeTranslation(0, 30)
        
        UIView.animateWithDuration(0.45, delay: 0.45, options: .CurveEaseInOut, animations: {
            self.mainTitleLabel.alpha = 1
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.45, delay: 0.6, options: .CurveEaseInOut, animations: {
            self.subTitleLabel.alpha = 1
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.45, delay: 0.75, options: .CurveEaseInOut, animations: {
            self.editProfileButton.alpha = 1
            self.editProfileButton.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.45, delay: 0.9, options: .CurveEaseInOut, animations: {
            self.goToBrowseButton.alpha = 1
            self.goToBrowseButton.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        self.avatarImageView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        
        UIView.animateWithDuration(0.3, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 20, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.circleView.alpha = 1
            self.blueDot.alpha = 1
            self.greenDot.alpha = 1
        }) { (success) in
            self.animateBlueDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
            self.animateGreenDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 5.6)
        }
        
        UIView.animateWithDuration(0.45, delay: 0.3, options: .CurveEaseInOut, animations: {
            self.avatarImageView.alpha = 1
            self.avatarImageView.transform = CGAffineTransformMakeScale(1, 1)
        }) { (success) in
            
        }
    }
    
    func animateHide() {
        
        UIView.animateWithDuration(0.6, delay: 0.45, options: .CurveEaseInOut, animations: {
            self.mainTitleLabel.alpha = 0
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 90)
        }) { (success) in

        }
        
        UIView.animateWithDuration(0.6, delay: 0.30, options: .CurveEaseInOut, animations: {
            self.subTitleLabel.alpha = 0
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 70)
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.6, delay: 0.15, options: .CurveEaseInOut, animations: {
            self.editProfileButton.alpha = 0
            self.editProfileButton.transform = CGAffineTransformMakeTranslation(0, 50)
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.goToBrowseButton.alpha = 0
            self.goToBrowseButton.transform = CGAffineTransformMakeTranslation(0, 30)
        }) { (success) in
            self.blueDot.alpha = 0
            self.greenDot.alpha = 0
        }
        
        UIView.animateWithDuration(0.6, delay: 0.6, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.avatarImageView.alpha = 0
            self.circleView.alpha = 0

            self.circleView.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height/2 - self.circleView.frame.origin.y - self.circleView.frame.size.height/2)
            self.avatarImageView.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height/2 - self.avatarImageView.frame.origin.y - self.avatarImageView.frame.size.height/2)
        }) { (success) in
            self.navigationController?.popToRootViewControllerAnimated(false)
        }
    }
    
    //MARK: Helpers
    func animateBlueDotRotation(fromValue: NSValue, duration: CFTimeInterval) {
        let rotationPoint = self.circleView.center
        
        var anchorPoint = CGPointMake(5, 5)
//        if self.view.frame.size.width <= 320 {
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
        
        var anchorPoint = CGPointMake(5, 5)
//        if self.view.frame.size.width <= 320 {
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
        self.animateBlueDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 1.4)
        self.animateGreenDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
    }

}
