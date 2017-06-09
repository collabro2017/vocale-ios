//
//  RWTextInputTableViewController.swift
//
//
//  Created by Rayno Willem Mostert on 2016/03/18.
//
//

import UIKit

class RWTextInputTableViewController: UITableViewController, UITextViewDelegate {

    var confirmationText: String?
    var confirmationDescription: String?
    var doneButton: UIBarButtonItem?
    var inputTooltipText = ""
    var existingText = "" {
        didSet {
            if existingText != "" {
                doneButton?.enabled = true
                textInputView.text = existingText
            }
        }
    }
    var didFinishTypingWithText: (input: String) -> Void = {
        _ in
    }

    @IBOutlet weak var textInputView: UITextView! {
        didSet {
            textInputView.delegate = self
            let keyboardToolbar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
            keyboardToolbar.barTintColor = UIColor.darkGrayColor()
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            doneButton = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(RWTextInputTableViewController.doneTapped))

            keyboardToolbar.setItems([flexibleSpace, doneButton!, flexibleSpace], animated: true)
            doneButton?.enabled = false
            textInputView.inputAccessoryView = keyboardToolbar
            textInputView.autocorrectionType = UITextAutocorrectionType.Yes
        }
    }
    @IBOutlet weak var lowerLabel: UILabel!

    // MARK: View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.vocaleBackgroundGreyColor()
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain ,target: self, action: #selector(RWTextInputTableViewController.closeTapped))
        self.navigationItem.setHidesBackButton(true, animated: true)
    }

    override func viewDidAppear(animated: Bool) {
        textInputView.becomeFirstResponder()
    }

    // MARK: Auxiliary Methods

    func showConfirmationAnimationWithCompletion(completion: () -> Void) {
        self.view.endEditing(true)
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.textInputView.alpha = 0
        }) { (completed: Bool) -> Void in
            if (completed) {

                let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
                imageView.center = CGPointMake(self.view.center.x,self.view.center.y-77)
                imageView.image = UIImage(named: "ConfirmationIcon")
                imageView.alpha = 0

                let confirmationTitleLabel = UILabel(frame: CGRectMake(0, imageView.frame.origin.y+imageView.frame.height+15, self.view.frame.width, 40))
                confirmationTitleLabel.textColor = UIColor(netHex:0xB7B7B7)
                confirmationTitleLabel.font = UIFont(name: "Raleway-Light", size: 23)
                confirmationTitleLabel.textAlignment = .Center
                //confirmationTitleLabel.

                let confirmationDescriptionLabel = UILabel(frame: CGRectMake(0, imageView.frame.origin.y+imageView.frame.height+40, self.view.frame.width, 40))
                confirmationDescriptionLabel.textColor = UIColor(netHex:0xEEEEEE)
                confirmationDescriptionLabel.font = UIFont(name: "Raleway-Light", size: 17)
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

                    self.textInputView.alpha = 0
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

    // MARK: UITextViewDelegate

    func textViewDidBeginEditing(textView: UITextView) {
        if textView.text == "" {
            textView.text = inputTooltipText
        }
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if textView.text == inputTooltipText {
            textView.text = ""
            textView.font = UIFont(name: "Raleway-Light", size: 17)
            doneButton?.enabled = true
            lowerLabel.alpha = 0
        }
        return true
    }

    // MARK: Actions

    func closeTapped() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    func doneTapped() {
        didFinishTypingWithText(input: textInputView.text)
        if let _ = confirmationText {
            showConfirmationAnimationWithCompletion { () -> Void in
                self.navigationController?.popViewControllerAnimated(true)
            }
        } else {
            self.navigationController?.popViewControllerAnimated(true)
        }
    }

}
