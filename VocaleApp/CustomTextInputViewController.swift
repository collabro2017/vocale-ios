//
//  CustomTextInputViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 7/4/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class CustomTextInputViewController: UIViewController, UITextViewDelegate {
    
    var isReport = false
    var registerProcedure: Bool = false
    @IBOutlet weak var upperLabel: UILabel!
    @IBOutlet weak var lowerLabel: UILabel!
    @IBOutlet weak var blockView: UIView!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var blockLabel: UILabel!
    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.delegate = self
            let keyboardToolbar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
            UIToolbar.appearance().barTintColor = UIColor(netHex: 0xEEEEEE)
            keyboardToolbar.barTintColor = UIColor.darkGrayColor()
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
//            if registerProcedure == true {
//                doneButton = UIBarButtonItem(title: "Next", style: .Plain, target: self, action: #selector(CustomTextInputViewController.doneTapped))
//            } else {
                doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(CustomTextInputViewController.doneTapped))
            //}
            
            keyboardToolbar.setItems([flexibleSpace, doneButton!, flexibleSpace], animated: true)
            doneButton?.enabled = false
            textView.inputAccessoryView = keyboardToolbar
            textView.autocorrectionType = UITextAutocorrectionType.Yes
        }
    }
    @IBOutlet weak var startTypingView: UIView!
    @IBOutlet weak var lowerLabelBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textViewCenterYConstraint: NSLayoutConstraint!
    var confirmationText: String?
    var confirmationDescription: String?
    var doneButton: UIBarButtonItem?
    var inputTooltipText = ""
    var existingText = "" {
        didSet {
            print(existingText)
            if existingText != "" {
                doneButton?.enabled = true
                //textView.text = existingText
            }
        }
    }
    let blockUserText = "You will no longer see this users posts and they will not be able to see your posts or contact you."
    let dontBlockUsertext = "You will still see this users posts and they will be able to see your posts and contact you. "
    var heightKeyboard: CGFloat?
    
    var didFinishTypingWithText: (input: String, isBlocked: Bool) -> Void = {
        _ in
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        doneButton?.enabled = false
        textView.editable = true
        textView.alpha = 0
        upperLabel.text = inputTooltipText
        //lowerLabel.hidden = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name:UIKeyboardWillHideNotification, object: nil)
        
        if registerProcedure == false {
            self.navigationItem.hidesBackButton = true
            self.navigationItem.setHidesBackButton(true, animated: true)
        }
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
        
        upperLabel.alpha = 0
        lowerLabel.alpha = 0
        startTypingView.alpha = 0
        blockView.alpha = 0
        
        lowerLabel.text = blockUserText
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if isReport == false {
            lowerLabel.hidden = true
            blockView.hidden = true
            textViewCenterYConstraint.constant = 4
        }
        
        self.blockButton.selected = true
    }
    
    override func viewDidAppear(animated: Bool) {
        textView.becomeFirstResponder()
        UIView.animateWithDuration(0.6, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            if self.existingText != "" {
                self.doneButton?.enabled = true
                self.textView.text = self.existingText
                self.textView.alpha = 1
                self.blockView.alpha = 1
            } else {
                self.upperLabel.alpha = 1
                self.startTypingView.alpha = 1
                self.lowerLabel.alpha = 1
                self.blockView.alpha = 1
            }
            }, completion: { (completed: Bool) -> Void in
                
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Auxiliary Methods
    
    func showConfirmationAnimationWithCompletion(completion: () -> Void) {
        self.view.endEditing(true)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        let closeButton = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: #selector(CustomTextInputViewController.closeTapped))
        self.navigationController?.toolbar.setItems([flexibleSpace, closeButton, flexibleSpace], animated: false)

        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.textView.alpha = 0
            self.blockLabel.alpha = 0
            self.blockView.alpha = 0
            self.lowerLabel.alpha = 0
        }) { (completed: Bool) -> Void in
            if (completed) {
                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
                imageView.center = CGPointMake(self.view.center.x,self.view.center.y-77)
                imageView.image = UIImage(named: "newConfirmationIcon")
                imageView.alpha = 0
                
                let confirmationTitleLabel = UILabel(frame: CGRectMake(0, imageView.frame.origin.y + imageView.frame.height + 18, self.view.frame.width, 25))
                confirmationTitleLabel.textColor = UIColor(netHex:0xEEEEEE)
                confirmationTitleLabel.font = UIFont(name: "Raleway-Regular", size: 23)
                confirmationTitleLabel.textAlignment = .Center
                //confirmationTitleLabel.
                
                let confirmationDescriptionLabel = UILabel(frame: CGRectMake(0, imageView.frame.origin.y + imageView.frame.height+43, self.view.frame.width, 25))
                confirmationDescriptionLabel.textColor = UIColor(netHex:0xB7B7B7)
                confirmationDescriptionLabel.font = UIFont(name: "Raleway-Regular", size: 15)
                confirmationDescriptionLabel.textAlignment = .Center
                
                if let confirmationDescription = self.confirmationDescription {
                    confirmationDescriptionLabel.text = confirmationDescription
                }
                if let confirmationTitle = self.confirmationText {
                    confirmationTitleLabel.text = confirmationTitle
                }
                
                self.view.addSubview(confirmationDescriptionLabel)
                self.view.addSubview(confirmationTitleLabel)
                self.view.addSubview(imageView)
                
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    
                    self.textView.alpha = 0
                    imageView.alpha = 1
                    confirmationDescriptionLabel.alpha = 1
                    confirmationTitleLabel.alpha = 1
                    
                }) { (completed: Bool) -> Void in
                    if (completed) {
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            completion()
                        }
                    }
                }
            }
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        // TODO: change value
        if let userInfo = notification.userInfo {
            if let keyboardSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.CGRectValue() {
                heightKeyboard = keyboardSize.height
                //print(heightKeyboard)
                lowerLabelBottomConstraint.constant = heightKeyboard! - 32
            }
        }
        else {
            heightKeyboard = 0
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        heightKeyboard = 0
    }

    // MARK: UITextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {

    }
    
    func textViewDidChange(textView: UITextView) {
        if (textView.text.characters.count > 0) {
            self.doneButton?.enabled = true
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.textView.alpha = 1
                self.upperLabel.alpha = 0
                self.startTypingView.alpha = 0
                //self.lowerLabel.alpha = 0
                }, completion: { (completed: Bool) -> Void in
                    
            })
        } else {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.upperLabel.alpha = 1
                self.startTypingView.alpha = 1
                //self.lowerLabel.alpha = 1
                self.textView.alpha = 0
                }, completion: { (completed: Bool) -> Void in
                    
            })
        }
    }
    
    // MARK: Actions
    
    @IBAction func blockButtonTapped(sender: UIButton) {
        self.blockButton.selected = !self.blockButton.selected
        
        if self.blockButton.selected == true {
            self.lowerLabel.text = blockUserText
        } else {
            self.lowerLabel.text = dontBlockUsertext
        }
    }
    
    func closeTapped() {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.upperLabel.alpha = 0
            self.startTypingView.alpha = 0
            self.lowerLabel.alpha = 0
            self.blockButton.alpha = 0
            self.blockLabel.alpha = 0
            self.textView.alpha = 0
            }, completion: { (completed: Bool) -> Void in
                self.navigationController?.popViewControllerAnimated(false)
        })
    }
    
    func doneTapped() {
        if registerProcedure == true {
            if let user = PFUser.currentUser() {
                user["AboutMe"]  = textView.text
                user.saveInBackground()
            }
            //if let newPostVC = self.storyboard?.instantiateViewControllerWithIdentifier("newPostViewController") as? InputViewController {
                Mixpanel.sharedInstance().track("Onboarding - Profile Description Added")
                //newPostVC.registerFlow = true
                //self.navigationController?.pushViewController(newPostVC, animated: false)
                self.navigationController?.popToRootViewControllerAnimated(true)
            //}
        } else {
            if let _ = confirmationText {
                showConfirmationAnimationWithCompletion { () -> Void in
                    self.didFinishTypingWithText(input: self.textView.text, isBlocked: self.blockButton.selected)
                    self.navigationController?.popViewControllerAnimated(true)
                }
            } else {
                self.didFinishTypingWithText(input: self.textView.text, isBlocked: self.blockButton.selected)
                self.navigationController?.popViewControllerAnimated(true)
            }
        }
    }
    
}
