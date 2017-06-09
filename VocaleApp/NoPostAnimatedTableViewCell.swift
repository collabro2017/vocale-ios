//
//  NoPostAnimatedTableViewCell.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 8/11/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

protocol StateAnimationDelegate {
    func loadingAnimationFinished()
    func loadingToNoPostAnimationFinished()
    func loadingToPostAnimationFinished()
    func noPostsToLoadingAnimationFinished()
    func noPostsAnimationFinished()
    func refreshButtonTapped()
    func filterButtonTapped()
    func shareButtonTapped()
}

class NoPostAnimatedTableViewCell: UITableViewCell {
    
    var delegate: StateAnimationDelegate?
    @IBOutlet weak var circleView: UIView! {
        didSet {

        }
    }
    @IBOutlet weak var avatarImageView: UIImageView! {
        didSet {

        }
    }
    
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
    @IBOutlet weak var circleViewYConstraint: NSLayoutConstraint!
    var blueDotRotationAnimation: CABasicAnimation?
    var greenDotRotationAnimation: CABasicAnimation?
    @IBOutlet weak var buttonsView: UIView!
    @IBOutlet weak var circleViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var avatarImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var subTitleLabelTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var subTitleLabelLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorLineHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var shareButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var refreshButtonTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var filtersButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor(red: 33/255, green: 30/255, blue: 35/255, alpha: 1)
    }
    
    override func layoutSubviews() {
        if self.contentView.frame.size.width <= 320 {
            self.circleViewWidthConstraint.constant = 125
            self.avatarImageViewWidthConstraint.constant = 90
            self.buttonViewHeightConstraint.constant = 48
            self.subTitleLabelLeadingConstraint.constant = 16
            self.subTitleLabelTrailingConstraint.constant = 16
            self.buttonsViewBottomConstraint.constant = 22
            self.refreshButtonTrailingConstraint.constant = 52
            self.shareButtonLeadingConstraint.constant = 52
            self.separatorLineHeightConstraint.constant = 40
            //self.contentView.layoutIfNeeded()
            //self.contentView.updateConstraintsIfNeeded()
            self.refreshButton.setImage(UIImage(named: "refreshButtonIconSmall"), forState: UIControlState.Normal)
//            self.filtersButton.setImage(UIImage(named: "filtersButtonIconSmall"), forState: UIControlState.Normal)
            self.shareButton.setImage(UIImage(named: "shareButtonIconSmall"), forState: UIControlState.Normal)
            self.subTitleLabel.font = UIFont(name: "Raleway-Regular", size: 14)
        }
        self.setupViews()
    }
    
    func setupViews() {
        var circleViewWidth: CGFloat = 155
        var avatarImageViewWidth: CGFloat = 115
        if self.contentView.frame.size.width <= 320 {
            circleViewWidth = 125
            avatarImageViewWidth = 90
        }
        circleView.layer.cornerRadius = circleViewWidth/2
        circleView.layer.borderColor = UIColor.vocaleOrangeColor().CGColor
        circleView.layer.borderWidth = 1
        
        avatarImageView.layer.masksToBounds = true
        avatarImageView.layer.cornerRadius = avatarImageViewWidth/2
        avatarImageView.layer.borderColor = UIColor.vocaleFilterTextColor().CGColor
        avatarImageView.layer.borderWidth = 2
    }
    
    //IBActions
    @IBAction func refreshButtonTapped(sender: UIButton) {
        self.delegate?.refreshButtonTapped()
    }
    
    @IBAction func filtersButtonTapped(sender: UIButton) {
        self.delegate?.filterButtonTapped()
    }
    
    @IBAction func shareButtonTapped(sender: UIButton) {
        self.delegate?.shareButtonTapped()
    }
    
    //Helper methods
    func animateBlueDotRotation(fromValue: NSValue, duration: CFTimeInterval) {
        let rotationPoint = self.circleView.center
        
        var anchorPoint = CGPointMake(5, 5)
        if self.contentView.frame.size.width <= 320 {
            anchorPoint = CGPointMake(4.1, 4.1)
        }
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
        if self.contentView.frame.size.width <= 320 {
            anchorPoint = CGPointMake(4.1, 4.1)
        }
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
    
    //MAIN ANIMATIONS
    
    //LOADING SHOW
    func loadingShowAnimation() {
        self.buttonsView.hidden = true
        self.avatarImageView.hidden = false
        self.circleViewYConstraint.constant = -60
        self.contentView.layoutIfNeeded()
        self.mainTitleLabel.alpha = 0
        self.subTitleLabel.alpha = 0
        self.mainTitleLabel.text = "LOADING POSTS"
        self.subTitleLabel.text = "Please wait while we get the latest posts from around you."
        self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 30)
        self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 50)
        
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.mainTitleLabel.alpha = 1
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.6, delay: 0.15, options: .CurveEaseInOut, animations: {
            self.subTitleLabel.alpha = 1
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        self.circleView.alpha = 0
        self.blueDot.alpha = 0
        self.greenDot.alpha = 0
        self.avatarImageView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        
        UIView.animateWithDuration(0.3, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 20, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.avatarImageView.transform = CGAffineTransformMakeScale(1, 1)
            }) { (success) in
                self.animateDotsRotation()
        }
        
        UIView.animateWithDuration(1.2, delay: 0.6, options: .CurveEaseInOut, animations: {
            self.circleView.alpha = 1
            self.blueDot.alpha = 1
            self.greenDot.alpha = 1
            }) { (success) in
                print("DELEGATE - LOADING")
                self.delegate?.loadingAnimationFinished()
        }
    }
    
    //NO POSTS SHOW
    func noPostsShowAnimation() {
        self.buttonsView.alpha = 0
        self.buttonsView.hidden = false
        var constant:CGFloat = -155
        if self.contentView.frame.size.width <= 320 {
            constant = -125
        }
        self.circleViewYConstraint.constant = constant
        self.contentView.layoutIfNeeded()
        self.mainTitleLabel.alpha = 0
        self.subTitleLabel.alpha = 0
        self.mainTitleLabel.text = "NO POSTS"
        self.subTitleLabel.text = "Vocale is brand new and we are just getting started! \n\nCheck back later or tap refresh to see if any new posts have been added. \n\nYou can also share Vocale with friends to help grow the community."
        self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 30)
        self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 50)
        
        UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.mainTitleLabel.alpha = 1
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.6, delay: 0.15, options: .CurveEaseInOut, animations: {
            self.subTitleLabel.alpha = 1
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (success) in
            
        }
        
        self.circleView.alpha = 0
        self.blueDot.alpha = 0
        self.greenDot.alpha = 0
        self.avatarImageView.hidden = false
        self.avatarImageView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        
        UIView.animateWithDuration(0.3, delay: 0.3, usingSpringWithDamping: 0.7, initialSpringVelocity: 20, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.avatarImageView.transform = CGAffineTransformMakeScale(1, 1)
        }) { (success) in
            self.animateBlueDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
            self.animateGreenDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 5.6)
        }
        
        UIView.animateWithDuration(1.2, delay: 0.6, options: .CurveEaseInOut, animations: {
            self.circleView.alpha = 1
            self.blueDot.alpha = 1
            self.greenDot.alpha = 1
        }) { (success) in
            
        }
        
        UIView.animateWithDuration(0.6, delay: 0.9, options: .CurveEaseInOut, animations: {
            self.buttonsView.alpha = 1
        }) { (success) in
            
        }
    }
    
    //LOADING TO POST
    func loadingToPostTransition() {
        self.buttonsView.hidden = true
        UIView.animateWithDuration(1.2, delay: 0, options: .CurveEaseInOut, animations: {
            self.circleView.alpha = 0
            self.blueDot.alpha = 0
            self.greenDot.alpha = 0
        }) { (success) in
            self.blueDot.layer.removeAllAnimations()
            self.greenDot.layer.removeAllAnimations()
        }
        
        UIView.animateWithDuration(0.6, delay: 0.4, usingSpringWithDamping: 1.0, initialSpringVelocity: 20, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.avatarImageView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        }) { (success) in
            self.avatarImageView.hidden = true
        }
        
        UIView.animateWithDuration(0.6, delay: 0.45, options: .CurveEaseInOut, animations: {
            self.subTitleLabel.alpha = 0
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 50)
        }) { (success) in

        }
        
        UIView.animateWithDuration(0.6, delay: 0.6, options: .CurveEaseInOut, animations: {
            self.mainTitleLabel.alpha = 0
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 30)
        }) { (success) in
            self.delegate?.loadingToPostAnimationFinished()
        }
    }
    
    //LOADING TO NO POSTS
    func loadingToNoPostsTransition() {
        var constant:CGFloat = -155
        if self.contentView.frame.size.width <= 320 {
            constant = -125
        }
        self.circleViewYConstraint.constant = constant
        self.buttonsView.alpha = 0
        self.buttonsView.hidden = false
        
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseInOut, animations: {
            self.blueDot.alpha = 0
            self.greenDot.alpha = 0
        }) { (success) in
            self.blueDot.layer.removeAllAnimations()
            self.greenDot.layer.removeAllAnimations()
        }
        
        UIView.animateWithDuration(0.4, delay: 0.2, options: .CurveEaseInOut, animations: {
            self.contentView.layoutIfNeeded()
            self.mainTitleLabel.alpha = 0
            self.subTitleLabel.alpha = 0
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 130)
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 150)
        }) { (success) in
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            self.mainTitleLabel.text = "NO POSTS"
            self.subTitleLabel.text = "Vocale is brand new and we are just getting started! \n\nCheck back later or tap refresh to see if any new posts have been added. \n\nYou can also share Vocale with friends to help grow the community."
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 30)
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 50)
            UIView.animateWithDuration(0.6, delay: 0.0, options: .CurveEaseInOut, animations: {
                self.mainTitleLabel.alpha = 1
                self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            }) { (success) in
                
            }
            
            UIView.animateWithDuration(0.6, delay: 0.15, options: .CurveEaseInOut, animations: {
                self.subTitleLabel.alpha = 1
                self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            }) { (success) in
                
            }
            
            UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseInOut, animations: {

            }) { (success) in
                self.blueDot.alpha = 1
                self.greenDot.alpha = 1
                self.animateBlueDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
                self.animateGreenDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 5.6)
            }
            
            UIView.animateWithDuration(0.6, delay: 0.9, options: .CurveEaseInOut, animations: {
                self.buttonsView.alpha = 1
            }) { (success) in
                
            }
        }
    }
    
    //NO POSTS TO LOADING
    func noPostsToLoadingTransition() {
        UIView.animateWithDuration(0.6, delay: 0, options: .CurveEaseInOut, animations: {
            self.subTitleLabel.alpha = 0
            self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 50)
        }) { (success) in
            self.subTitleLabel.text = "Please wait while we get the latest posts from around you."
            UIView.animateWithDuration(0.6, delay: 0.35, options: .CurveEaseInOut, animations: {
                self.subTitleLabel.alpha = 1
                self.subTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            }) { (success) in
                self.delegate?.noPostsToLoadingAnimationFinished()
            }
        }
        
        UIView.animateWithDuration(0.6, delay: 0.15, options: .CurveEaseInOut, animations: {
            self.mainTitleLabel.alpha = 0
            self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 30)
        }) { (success) in
            self.mainTitleLabel.text = "LOADING POSTS"
            UIView.animateWithDuration(0.6, delay: 0.05, options: .CurveEaseInOut, animations: {
                self.mainTitleLabel.alpha = 1
                self.mainTitleLabel.transform = CGAffineTransformMakeTranslation(0, 0)
            }) { (success) in
                
            }
        }
        
        UIView.animateWithDuration(0.6, delay: 0.3, options: .CurveEaseInOut, animations: {
            self.buttonsView.alpha = 0
        }) { (success) in
            self.buttonsView.hidden = true
        }
        
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseInOut, animations: {
            self.blueDot.alpha = 0
            self.greenDot.alpha = 0
        }) { (success) in
            self.blueDot.layer.removeAllAnimations()
            self.greenDot.layer.removeAllAnimations()
        }
        
        self.circleViewYConstraint.constant = -60
        UIView.animateWithDuration(0.4, delay: 0.5, options: .CurveEaseInOut, animations: {
            self.contentView.layoutIfNeeded()
        }) { (success) in
                self.blueDot.alpha = 1
                self.greenDot.alpha = 1
                self.animateBlueDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 1.4)
                self.animateGreenDotRotation(NSValue.init(CGPoint: CGPointZero), duration: 2.8)
        }
    }
    
    //TEMPORARY
    @IBAction func nextButtonTapped(sender: UIButton) {
        loadingToNoPostsTransition()
    }
    
    @IBAction func backButtonTapped(sender: UIButton) {
        noPostsToLoadingTransition()
        //loadingToPostTransition()
    }
    
    //--------

}
