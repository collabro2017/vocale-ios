//
//  HamzaImagePickerCollectionViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/03/19.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import Foundation

private let reuseIdentifier = "hamzaImageCell"

class HamzaImagePickerCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {

    var createPostTapped = false
    var registerFlow = false
    var event = Event()
    var flickrPhotos = [String]()
    var selectedCell: HamzaImageCollectionViewCell?
    var tagButtons = [UIButton]()
    var tags = ["tree"]
    var originalTags = [String]()
    
    var shouldTrackHashtags = true // This is used by Mixpanel
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!

    @IBOutlet weak var nextButton: UIBarButtonItem! {
        didSet {
            nextButton.enabled = false
        }
    }

    // MARK: View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.contentInset = UIEdgeInsetsMake(10, 10, 10, 10)
        collectionView.dataSource = self
        collectionView.delegate = self

        var hashtags = [String]()
        for tag in tags {
            hashtags.append(("#" + tag))
        }
        originalTags = tags
        searchTextField.text = hashtags.joinWithSeparator(", ")
        
        getPhotosRequest()
        
        nextButton.enabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit"), style:UIBarButtonItemStyle.Plain, target: self, action: "closeTapped")
        
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Post Picture"
    }
    
    override func viewWillDisappear(animated: Bool) {
        SVProgressHUD.dismiss()
        for tag in self.tagButtons {
            tag.removeFromSuperview()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func getPhotosRequest() {
        //print("tags", tags)
        
        if (tags.count > 0) {
            
            var banHashtags = [String]()
            if let banWords = NSUserDefaults.standardUserDefaults().objectForKey("BanWords") as? [String] {
                for string in tags {
                    for word in banWords {
                        if string.lowercaseString == word.lowercaseString {
                            banHashtags.append(word.lowercaseString)
                        }
                    }
                }
            }
            
            if banHashtags.count > 0 {
                var hashtagString = ""
                for word in banHashtags {
                    hashtagString = hashtagString + " " + "#" + word
                }
                let alert = UIAlertController(title: "Warning", message: "Posts cannot contain obscene, profane, offensive or abusive content. Please search for different images.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                    
                }))
                self.presentViewController(alert, animated: true) { () -> Void in }
            } else {
                SVProgressHUD.showWithStatus("Searching...")
                FlickrKit.sharedFlickrKit().initializeWithAPIKey("10f43c5cfb44e9e2fad1bc17ebad0bb9", sharedSecret: "a5269697d8ec1f8b")
                FlickrKit.sharedFlickrKit().call("flickr.photos.search", args: ["tags":tags.joinWithSeparator(","), "sort":"interestingness-desc", "safe_search":"1"]) { (response: [NSObject : AnyObject]!, error: NSError!) -> Void in
                    //                NSLog("Request DONE")
                    //                print("Response: \(response)")
                    //                print("Error: \(error)")
                    dispatch_async(dispatch_get_main_queue(), {
                        SVProgressHUD.dismiss()
                    })
                    
                    self.flickrPhotos.removeAll()
                    
                    if let dict1 = response["photos"]?["photo"] as? [[String: AnyObject]] {
                        if dict1.count == 0 {
                            SVProgressHUD.showErrorWithStatus("No photos match your hashtags.  Try changing them.")
                        }
                        for photo in dict1 {
                            if let farm = photo["farm"], let serverID = photo["server"], let secret = photo["secret"], let id = photo["id"] {
                                
                                let url = "https://farm\(farm).staticflickr.com/\(serverID)/\(id)_\(secret).jpg"
                                self.flickrPhotos.append(url)
                            }
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.collectionView?.reloadData()
                        })
                    }
                }
                //drawTags()
                
            }
        } else {
//            SVProgressHUD.showErrorWithStatus("You need at least one tag.")
//            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
//            dispatch_after(delayTime, dispatch_get_main_queue()) {
//                self.navigationController?.popViewControllerAnimated(true)
//            }
            let alert = UIAlertController(title: "Warning", message: "Please enter at least one keyword to search for.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                self.tags = self.originalTags
                var hashtags = [String]()
                for tag in self.originalTags {
                    hashtags.append(("#" + tag))
                }
                self.searchTextField.text = hashtags.joinWithSeparator(", ")
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        }
    }

    func drawTags() {
        for tag in self.tagButtons {
            tag.removeFromSuperview()
        }
        var i = 0
        var xPosition = self.view.frame.width
        for tag in tags {
            let closeIcon = FAKIonIcons.androidCloseIconWithSize(18)
            closeIcon.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor())
            closeIcon.addAttribute(NSBackgroundColorAttributeName, value: UIColor.grayColor())
            let graySpace = NSAttributedString(string: " ", attributes: [NSBackgroundColorAttributeName: UIColor.grayColor()])
            let attributedTitle = NSMutableAttributedString()
            attributedTitle.appendAttributedString(NSAttributedString(string: "#"+tag+"  "))
            attributedTitle.setAttributes([NSForegroundColorAttributeName: UIColor.whiteColor()], range: NSRange.init(location: 0, length: attributedTitle.length))
            attributedTitle.appendAttributedString(graySpace)
            attributedTitle.appendAttributedString(closeIcon.attributedString())
            attributedTitle.appendAttributedString(graySpace)
            let width = attributedTitle.size().width*1.5
            xPosition -= width+5
            let tagsButton = UIButton(frame: CGRectMake(xPosition, self.view.frame.height-80, width+5, 40))
            tagsButton.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
            tagsButton.setAttributedTitle(attributedTitle, forState: .Normal)
            tagsButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
            tagsButton.tag = i
            tagsButton.addTarget(self, action: #selector(HamzaImagePickerCollectionViewController.removeTagTapped(_:)), forControlEvents: .TouchUpInside)
            tagButtons.append(tagsButton)

            self.navigationController!.view.addSubview(tagsButton)
            i = i+1
        }
    }

    // MARK: UICollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flickrPhotos.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! HamzaImageCollectionViewCell
        cell.imageURL = NSURL(string: self.flickrPhotos[indexPath.item])!
        cell.cellSelected = false
        return cell
    }

    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSizeMake(self.view.frame.width/CGFloat(2)-15, self.view.frame.width/CGFloat(2)-15)
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? HamzaImageCollectionViewCell {
            cell.loadImage()
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? HamzaImageCollectionViewCell, let image = cell.image {
            selectedCell?.cellSelected = false
            selectedCell = cell
            cell.cellSelected = true
            if let data = UIImageJPEGRepresentation(image, 1.0), let file = PFFile(name: "backgroundImage.jpg", data: data) {
                self.event.backgroundImage =  file
                //print(file)
                self.event.placeholderImage = image
                //print(image)
                self.navigationItem.rightBarButtonItem?.enabled = true
                self.nextButton.enabled = true
            }

        }
    }

    // MARK: - IBActions

    @IBAction func nextTapped(sender: AnyObject) {
        if shouldTrackHashtags {
            shouldTrackHashtags = false
            Mixpanel.sharedInstance().track("New Post - Picture added",
                                      properties: ["tags" : tags])
        }
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        //self.performSegueWithIdentifier("toPostConfirmation", sender: self)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func searchButtonTapped(sender: UIButton) {
        tags.removeAll()
        tags = Event.detectHashtags(searchTextField.text!)
        searchTextField.resignFirstResponder()
        getPhotosRequest()
    }

    // MARK: - Actions
    func closeTapped() {
        if registerFlow == true {
            let alert = UIAlertController(title: "Quit Setup?", message: "Are you sure you want to quit signing up? You will be logged out and your details will not be saved.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SetupCancelled")
                self.navigationController?.popToRootViewControllerAnimated(true)
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        } else {
            let alert = UIAlertController(title: "Cancel Confirmation", message: "Are you sure you want to cancel creating this post?", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
                
            }))
            alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
                Mixpanel.sharedInstance().track("New Post - Canceled", properties: ["screen" : "Image picker", "tags" : self.tags])
                self.navigationController?.popToRootViewControllerAnimated(true)
            }))
            self.presentViewController(alert, animated: true) { () -> Void in
                
            }
        }
    }

    func removeTagTapped(sender: UIButton) {
        if sender.tag < tags.count {
            tags.removeAtIndex(sender.tag)
            drawTags()
            getPhotosRequest()
        }
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Navigation

//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if let destinationVC = segue.destinationViewController as? CreatedConfirmationTableViewController {
//            destinationVC.eventInCreation = event
//            destinationVC.registerFlow = self.registerFlow
//            destinationVC.createPostTapped = self.createPostTapped
//        }
//    }

}
