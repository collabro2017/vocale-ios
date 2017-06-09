//
//  EditUserViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 5/8/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import Foundation

class EditUserViewController: UIViewController {
    
    @IBOutlet weak var photosButton: UIButton!
    @IBOutlet weak var aboutButton: UIButton!
    @IBOutlet weak var photosContainer: UIView!
    @IBOutlet weak var aboutContainer: UIView!
    var loadingSpinner: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "profile") , style:UIBarButtonItemStyle.Plain ,target: self, action: #selector(EditUserViewController.profileButtonTapped(_:)))
        
        //aboutContainer.hidden = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
        
        title = "Your Profile"
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }
    
    @IBAction func photosButtonTapped(sender: UIButton) {
        navigationController?.setToolbarHidden(true, animated: false)
        aboutButton.enabled = true
        photosButton.enabled = false
        photosContainer.hidden = false
        aboutContainer.hidden = true
    }
    
    @IBAction func aboutButtonTapped(sender: UIButton) {
//        navigationController?.setToolbarHidden(true, animated: false)
//        aboutButton.enabled = false
//        photosButton.enabled = true
//        photosContainer.hidden = true
//        aboutContainer.hidden = false
        let controller = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
        controller.inputTooltipText = "Tell people a little more about who you are and what you like."
        controller.navigationItem.title = "About You"
        controller.didFinishTypingWithText = {
            text, isBlocked in
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                
                if let user = PFUser.currentUser() {
                    user["AboutMe"]  = text
                    user.saveInBackground()
                }
            }
            
        }
        if let user = PFUser.currentUser() {
            if let existingText = user["AboutMe"] as? String {
                controller.existingText = existingText
            }
        }
        self.navigationController?.pushViewController(controller, animated: false)
    }
    
    func profileButtonTapped(sender: UIBarButtonItem) {
        let event = Event()
        event.owner = PFUser.currentUser()!
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
//        if let vc = self.storyboard?.instantiateViewControllerWithIdentifier("messageEventController") as? MessageEventTableViewController {
//            vc.profileViewMode = true
//            vc.event = event
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
        if let nextVC = self.storyboard?.instantiateViewControllerWithIdentifier("ProfileDetails") as? ProfileDetailViewController {
            if let name = event.owner["name"] as? String {
                nextVC.name = name
            }
            
            if let birthdate = event.owner["birthday"] as? String {
                let df = NSDateFormatter()
                df.dateFormat = "MM/dd/yyyy"
                if let date = df.dateFromString(birthdate) {
                    print(date.age)
                    nextVC.age = "\(date.age)"
                }
            }
            
            if let about = event.owner["AboutMe"] as? String {
                nextVC.profileDescription = about
            }
            
            if loadingSpinner == nil {
                let loadingSpinner = UIImageView(frame: CGRectMake(self.view.frame.size.width/2 - 20, self.view.frame.size.height/2 - 20, 40, 40))
                loadingSpinner.image = UIImage(named: "spinner")
                self.view.addSubview(loadingSpinner)
                self.loadingSpinner = loadingSpinner
                let rotate = CABasicAnimation(keyPath: "transform.rotation")
                rotate.fromValue = 0
                rotate.toValue = 2*M_PI
                rotate.duration = 1
                rotate.repeatCount = Float.infinity
                self.loadingSpinner?.layer.addAnimation(rotate, forKey: "10")
            }
            
            var imageFiles = [PFFile]()
            var downloadedImages = [UIImage]()
            
            for (var i = 1; i < 7; i += 1) {
                if let image = event.owner["UserImage\(i)"] as? PFFile {
                    imageFiles.append(image)
                }
            }
            
            var currentCount = 0
            if imageFiles.count > 0 {
                for file in imageFiles {
                    file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                        self.loadingSpinner?.removeFromSuperview()
                        if let _ = error {
                            
                        } else if let data = data, let image = UIImage(data: data) {
                            currentCount = currentCount + 1
                            downloadedImages.append(image)
                            if currentCount == (imageFiles.count + 1) {
                                nextVC.images = downloadedImages
                                self.navigationController?.pushViewController(nextVC, animated: true)
                            }
                        }
                        }, progressBlock: { (progress: Int32) -> Void in
                    })
                }
            }
            
            if let file = event.owner["UserImageMain"] as? PFFile  {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    self.loadingSpinner?.removeFromSuperview()
                    if let _ = error {
                    } else if let data = data, let image = UIImage(data: data) {
                        currentCount = currentCount + 1
                        if currentCount == (imageFiles.count + 1) {
                            nextVC.profileImage = image
                            nextVC.images = downloadedImages
                            self.navigationController?.pushViewController(nextVC, animated: true)
                        }
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                })
            } else if let string = event.owner["FBPictureURL"] as? String, url = NSURL(string: string) {
                let request: NSURLRequest = NSURLRequest(URL: url)
                let mainQueue = NSOperationQueue.mainQueue()
                NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                    if error == nil {
                        // Convert the downloaded data in to a UIImage object
                        currentCount = currentCount + 1
                        let image = UIImage(data: data!)
                        if currentCount == (imageFiles.count + 1) {
                            nextVC.profileImage = image
                            nextVC.images = downloadedImages
                            self.navigationController?.pushViewController(nextVC, animated: true)
                        }
                    }
                    else {

                    }
                })
            }
        }
    }
}


