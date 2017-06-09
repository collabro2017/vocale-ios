//
//  SearchViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 7/1/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var upperLabel: UILabel!
    @IBOutlet weak var startTypingView: UIView!
    @IBOutlet weak var lowerLabel: UILabel!
    var doneButton: UIBarButtonItem?
    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.delegate = self
            let keyboardToolbar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
            UIToolbar.appearance().barTintColor = UIColor(netHex: 0xEEEEEE)
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
            UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.yellowColor(), NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 18)!], forState: .Disabled)
            doneButton = UIBarButtonItem(title: "Go", style: .Done, target: self, action: #selector(nextTapped))
            keyboardToolbar.setItems([flexibleSpace, doneButton!, flexibleSpace], animated: false)
            doneButton?.enabled = false
            textView.inputAccessoryView = keyboardToolbar
            textView.autocorrectionType = UITextAutocorrectionType.Yes
            textView.keyboardAppearance = .Dark
        }
    }
    
    @IBOutlet weak var lowerLabelBottomConstraint: NSLayoutConstraint!
    
    var searchTappedClosure: (results: [String]) -> Void = { results in
    
    }
    
    var heightKeyboard: CGFloat?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        doneButton?.enabled = false
        textView.editable = true
        textView.alpha = 0
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShow), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillHide), name:UIKeyboardWillHideNotification, object: nil)
        
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        upperLabel.alpha = 0
        lowerLabel.alpha = 0
        startTypingView.alpha = 0
        
        textView.text = textView.text + "#"
        
        Mixpanel.sharedInstance().track("Search (Screen)")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = "Search"
    }
    
    override func viewDidAppear(animated: Bool) {
        textView.becomeFirstResponder()
        UIView.animateWithDuration(0.6, delay: 0.3, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.upperLabel.alpha = 1
            self.startTypingView.alpha = 1
            self.lowerLabel.alpha = 1
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
    
    //MARK - UITextViewDelegate
    func textViewDidBeginEditing(textView: UITextView) {

    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == " ") {
            textView.text = textView.text + " #"
            return false
        }
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        if (textView.text.characters.count > 0) {
            self.doneButton?.enabled = true
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.textView.alpha = 1
                self.upperLabel.alpha = 0
                self.startTypingView.alpha = 0
                self.lowerLabel.alpha = 0
                }, completion: { (completed: Bool) -> Void in
                    
            })
        } else {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.upperLabel.alpha = 1
                self.startTypingView.alpha = 1
                self.lowerLabel.alpha = 1
                self.textView.alpha = 0
                }, completion: { (completed: Bool) -> Void in
                    textView.text = textView.text + "#"
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
            }
        }
        else {
            heightKeyboard = 0
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        heightKeyboard = 0
    }
    
    // MARK: Actions
    
    func nextTapped() {
        do {
            let regex = try NSRegularExpression(pattern: "#(\\w+)",
                                                options: NSRegularExpressionOptions.CaseInsensitive)
            let nsString = self.textView.text as NSString
            let results = regex.matchesInString(self.textView.text, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
            var array = [String]()
            let resultArray = results.map() { nsString.substringWithRange($0.range)}
            for var result in resultArray {
                result = String(result.characters.dropFirst())
                result.replaceRange(result.startIndex...result.startIndex, with: String(result[result.startIndex]).capitalizedString)
                array.append(result)
            }
            
            var banHashtags = [String]()
            if let banWords = NSUserDefaults.standardUserDefaults().objectForKey("BanWords") as? [String] {
                for hashtag in array {
                    for word in banWords {
                        if hashtag.lowercaseString == word.lowercaseString {
                            banHashtags.append(word.lowercaseString)
                        }
                    }
                }
            }
            
            if banHashtags.count > 0 {
                let alert = UIAlertController(title: "Warning", message: "Posts cannot contain obscene, profane, offensive or abusive content. Please search for different images.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                    
                }))
                self.presentViewController(alert, animated: true) { () -> Void in }
            } else {
                Mixpanel.sharedInstance().track("Search (Action)", properties: ["hashtags": array])
                searchTappedClosure(results: array)
                UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                    self.upperLabel.alpha = 0
                    self.startTypingView.alpha = 0
                    self.lowerLabel.alpha = 0
                    self.textView.alpha = 0
                    }, completion: { (completed: Bool) -> Void in
                        self.navigationController?.popViewControllerAnimated(false)
                })
            }
        } catch {
            
        }
    }
    
    func closeTapped() {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.upperLabel.alpha = 0
            self.startTypingView.alpha = 0
            self.lowerLabel.alpha = 0
            self.textView.alpha = 0
            }, completion: { (completed: Bool) -> Void in
                self.navigationController?.popViewControllerAnimated(false)
        })
    }
}
