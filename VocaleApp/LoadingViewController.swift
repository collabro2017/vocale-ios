//
//  LoadingViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 11/14/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

protocol LoadingScreenDelegate: class {
    func loadingScreenDissmissed()
}

class LoadingViewController: UIViewController {

    weak var delegate: LoadingScreenDelegate?
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var circleView: UIView!
    var avatarImage: UIImage?
    @IBOutlet weak var greenDot: UIView! {
        didSet {
            greenDot.layer.cornerRadius = 6
        }
    }
    @IBOutlet weak var blueDot: UIView! {
        didSet {
            blueDot.layer.cornerRadius = 6
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupViews()
        
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("dismiss"), name: "PostImageDonwloadedNotification", object: nil)
    }
    
    func dismiss() {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: { 
            self.circleView.alpha = 0
            self.blueDot.alpha = 0
            self.greenDot.alpha = 0
            self.avatarImageView.alpha = 0
            }) { (finished) in
                self.delegate?.loadingScreenDissmissed()
                self.dismissViewControllerAnimated(false, completion: nil)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.circleView.alpha = 0
        self.blueDot.alpha = 0
        self.greenDot.alpha = 0
        self.avatarImageView.alpha = 0
        
        self.title = "New Post"
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        animateShow()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupViews() {
        var circleViewWidth: CGFloat = 155
        var avatarImageViewWidth: CGFloat = 115
        circleView.layer.cornerRadius = circleViewWidth/2
        circleView.layer.borderColor = UIColor.vocaleOrangeColor().CGColor
        circleView.layer.borderWidth = 1
        
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewWidth/2
        avatarImageView.layer.borderColor = UIColor.vocaleFilterTextColor().CGColor
        avatarImageView.layer.borderWidth = 2
    }
    
    func animateShow() {
        
        //self.avatarImageView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        
        UIView.animateWithDuration(0.3, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 20, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.circleView.alpha = 1
            self.blueDot.alpha = 1
            self.greenDot.alpha = 1
        }) { (success) in
            self.animateBlueDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 1.4)
            self.animateGreenDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
        }
        
        UIView.animateWithDuration(0.45, delay: 0.3, options: .CurveEaseInOut, animations: {
            self.avatarImageView.alpha = 1
            //self.avatarImageView.transform = CGAffineTransformMakeScale(1, 1)
        }) { (success) in
            
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
