//
//  SearchTableViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/02/04.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class SearchTableViewController: UITableViewController, UITextViewDelegate {

    @IBOutlet weak var searchTermTextView: UITextView! {
        didSet {
            searchTermTextView.delegate = self
            let keyboardToolbar = UIToolbar(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, 44))
            keyboardToolbar.barTintColor = UIColor.darkGrayColor()
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
            let nextButton = UIBarButtonItem(title: "Go", style: .Plain, target: self, action: "searchTapped")
            keyboardToolbar.setItems([flexibleSpace, nextButton, flexibleSpace], animated: true)
            searchTermTextView.inputAccessoryView = keyboardToolbar
        }
    }
    @IBOutlet weak var startTypingLabel: UILabel!

    var searchTappedClosure: (results: [String]) -> Void = { results in
    }

    // MARK: View Controller LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        searchTermTextView.becomeFirstResponder()
        searchTermTextView.text = searchTermTextView.text + "#"
        
        self.title = "Search"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTapped")
        super.viewDidLoad()
        navigationController?.setToolbarHidden(false, animated: false)
        self.navigationItem.setHidesBackButton(true, animated: true)

    }

    // MARK: - UITextView Delegate

    func textViewDidChange(textView: UITextView) {

        if (textView.text.characters.count > 0) {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.startTypingLabel.alpha = 0
                }, completion: { (completed: Bool) -> Void in

            })
        } else {
            UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                self.startTypingLabel.alpha = 1
                }, completion: { (completed: Bool) -> Void in

            })
        }
    }

    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == " ") {
            textView.text = textView.text + " #"
            return false
        }
        return true
    }

    // MARK: Actions

    func searchTapped() {
        do {
            let regex = try NSRegularExpression(pattern: "#(\\w+)",
                                                options: NSRegularExpressionOptions.CaseInsensitive)
            let nsString = self.searchTermTextView.text as NSString
            let results = regex.matchesInString(self.searchTermTextView.text, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
            var array = [String]()
            let resultArray = results.map() { nsString.substringWithRange($0.range)}
            for var result in resultArray {
                result = String(result.characters.dropFirst())
                result.replaceRange(result.startIndex...result.startIndex, with: String(result[result.startIndex]).capitalizedString)
                array.append(result)
            }
            searchTappedClosure(results: array)
            navigationController?.popToRootViewControllerAnimated(true)
        } catch {

        }
    }
    
    func closeTapped() {
        navigationController?.popToRootViewControllerAnimated(true)
    }

}
