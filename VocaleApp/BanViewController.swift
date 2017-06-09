//
//  BanViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 7/29/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import MessageUI

class BanViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var contactUsButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor(netHex:0xEEEEEE), NSFontAttributeName: UIFont(name: "Raleway-SemiBold", size: 23)!]
        self.title = "Notice"

        let string = "contact us."
        let underlineAttributedString = NSMutableAttributedString(string: string)
        underlineAttributedString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: NSRange(location: 0, length: underlineAttributedString.length))
        underlineAttributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(netHex:0xEEEEEE), range: NSRange(location: 0, length: underlineAttributedString.length))
        contactUsButton .setAttributedTitle(underlineAttributedString, forState: UIControlState.Normal)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func closeTapped(sender: UIButton) {
        PFUser.logOutInBackgroundWithBlock { (error: NSError?) -> Void in
            AppDelegate.layerClient?.deauthenticateWithCompletion({ (done: Bool, error: NSError?) in
                self.dismissViewControllerAnimated(false, completion: nil)
            })
        }
    }
    
    @IBAction func contactUsButtonTapped(sender: UIButton) {
        sendEmail()
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["appeals@vocale.io"])
            
            presentViewController(mail, animated: true, completion: nil)
        } else {
            // show failure alert
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
