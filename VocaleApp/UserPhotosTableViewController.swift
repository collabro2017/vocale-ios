//
//  UserPhotosTableViewController.swift
//
//
//  Created by Rayno Willem Mostert on 2015/12/20.
//
//

import UIKit

@objc protocol UserPhotosDelegate: class {
    func profileImageChanged(image: UIImage)
}

class UserPhotosTableViewController: UITableViewController, UINavigationControllerDelegate, OLFacebookImagePickerControllerDelegate {

    var delegate: UserPhotosDelegate?
    @IBOutlet weak var nextButtonButton: UIBarButtonItem!
    var photos = [NSURL]()
    var selectedButton: UIButton?
    var buttonToExchangeWith: UIButton?
    var imageViews = [UIImageView]()
    var associatedButtonAccessories: [UIButton: UIButton]
    var imageBitMap = [Int]()
    var tempImage: UIImage?
    
    var isEditProfile:Bool = false {
        didSet {

        }
    }
    
    @IBOutlet weak var tooltipLabel: UILabel! {
        didSet {
            tooltipLabel.text = "Add photos from your Facebook account.  Tap on 2 photos to swap around their order.  You must add at least 1 picture to use Vocale."
        }
    }
    
    @IBOutlet weak var placeholder1: UIImageView!
    @IBOutlet weak var placeholder2: UIImageView!
    @IBOutlet weak var placeholder3: UIImageView!
    @IBOutlet weak var placeholder4: UIImageView!
    @IBOutlet weak var placeholder5: UIImageView!
    @IBOutlet weak var placeholder6: UIImageView!
    @IBOutlet weak var placeholderMain: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var photoButtonMain: UIButton! {
        didSet {
            photoButtonMain.layer.borderWidth = 1
            //photoButtonMain.layer.cornerRadius = 9
            photoButtonMain.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            photoButtonMain.tag = 0
        }
    }
    
    @IBOutlet weak var photoButton1: UIButton! {
        didSet {
            photoButton1.layer.borderWidth = 1
            //photoButton1.layer.cornerRadius = 9
            photoButton1.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            photoButton1.tag = 1;
        }
    }
    @IBOutlet weak var photoButton2: UIButton! {
        didSet {
            photoButton2.layer.borderWidth = 1
            //photoButton2.layer.cornerRadius = 9
            photoButton2.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            photoButton2.tag = 2;
        }
    }
    @IBOutlet weak var photoButton3: UIButton! {
        didSet {
            photoButton3.layer.borderWidth = 1
            //photoButton3.layer.cornerRadius = 9
            photoButton3.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            photoButton3.tag = 3;
        }
    }
    @IBOutlet weak var photoButton4: UIButton! {
        didSet {
            photoButton4.layer.borderWidth = 1
            //photoButton4.layer.cornerRadius = 9
            photoButton4.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            photoButton4.tag = 4;
        }
    }
    @IBOutlet weak var photoButton5: UIButton! {
        didSet {
            photoButton5.layer.borderWidth = 1
            //photoButton5.layer.cornerRadius = 9
            photoButton5.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            photoButton5.tag = 5;
        }
    }
    @IBOutlet weak var photoButton6: UIButton! {
        didSet {
            photoButton6.layer.borderWidth = 1
            //photoButton6.layer.cornerRadius = 9
            photoButton6.layer.borderColor = UIColor(netHex:0xEEEEEE).CGColor
            photoButton6.tag = 6;
        }
    }

    @IBOutlet weak var accessoryButton1: UIButton! {
        didSet {
            setAccessoryButton(accessoryButton1)
        }
    }
    @IBOutlet weak var accessoryButton2: UIButton! {
        didSet {
            setAccessoryButton(accessoryButton2)
        }
    }
    @IBOutlet weak var accessoryButton3: UIButton! {
        didSet {
            setAccessoryButton(accessoryButton3)
        }
    }
    @IBOutlet weak var accessoryButton4: UIButton! {
        didSet {
            setAccessoryButton(accessoryButton4)
        }
    }
    @IBOutlet weak var accessoryButton5: UIButton! {
        didSet {
            setAccessoryButton(accessoryButton5)
        }
    }
    @IBOutlet weak var accessoryButton6: UIButton! {
        didSet {
            setAccessoryButton(accessoryButton6)
        }
    }
    
    @IBOutlet weak var accessoryButtonMain: UIButton! {
        didSet {
            setAccessoryButton(accessoryButtonMain)
        }
    }
    

    @IBOutlet weak var userAboutPhotosSegmentedControl: UISegmentedControl!

    // MARK: Init

    required init?(coder aDecoder: NSCoder) {
        associatedButtonAccessories = [UIButton(): UIButton()]
        super.init(coder: aDecoder)
    }

    // MARK: UITableViewDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.scrollEnabled = false
        LoginViewController.performFBGraphRequestWithUser(PFUser.currentUser()!)
        associatedButtonAccessories = [photoButtonMain: accessoryButtonMain, photoButton1: accessoryButton1, photoButton2: accessoryButton2, photoButton3: accessoryButton3, photoButton4: accessoryButton4, photoButton5: accessoryButton5, photoButton6: accessoryButton6]

        var image1Downloaded = false
        var image2Downloaded = false
        var image3Downloaded = false
        var image4Downloaded = false
        var image5Downloaded = false
        var image6Downloaded = false
        var imageMainDownloaded = false

        let completionBlock = {
            if image1Downloaded && image2Downloaded && image3Downloaded && image4Downloaded && image5Downloaded && image6Downloaded && imageMainDownloaded{
            }
        }
        
        let n: Int! = self.navigationController?.viewControllers.count
        print("ARRAY %@", self.navigationController?.viewControllers)
//        if n > 1 {
//            if let _ = self.navigationController?.viewControllers[n-5] as? SetupViewController {
//                if let user = PFUser.currentUser(), profilePictureLink = user["FBPictureURL"] as? String, url = NSURL(string: profilePictureLink) {
//                    let request: NSURLRequest = NSURLRequest(URL: url)
//                    let mainQueue = NSOperationQueue.mainQueue()
//                    NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
//                        if error == nil {
//                            let image = UIImage(data: data!)
//                            self.photoButtonMain.setTitle("", forState: .Normal)
//                            self.photoButtonMain.setImage(image, forState: .Normal)
//                            self.photoButtonMain.contentMode = .ScaleAspectFit
//                            self.photoButtonMain.imageView?.contentMode = .ScaleAspectFit
//                            self.accessoryButtonMain.selected = true
//                            self.saveImagesForButtons([self.photoButtonMain])
//                        }
//                        else {
//                            
//                        }
//                    })
//                }
//            }
//        }

        if let user = PFUser.currentUser() {
            if let file = user["UserImageMain"] as? PFFile {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    imageMainDownloaded = true
                    completionBlock()
                    if let error = error {
                        self.photoButtonMain.setTitle("\(error)", forState: .Normal)
                        ErrorManager.handleError(error)
                    } else if let data = data {
                        self.photoButtonMain.setTitle("", forState: .Normal)
                        self.photoButtonMain.setImage(UIImage(data: data), forState: .Normal)
                        self.photoButtonMain.contentMode = .ScaleAspectFit
                        self.photoButtonMain.imageView?.contentMode = .ScaleAspectFit
                        self.accessoryButtonMain.selected = true
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                        self.photoButtonMain.setTitle("\(progress)%", forState: .Normal)
                })
            } else {
                if let user = PFUser.currentUser(), profilePictureLink = user["FBPictureURL"] as? String, url = NSURL(string: profilePictureLink) {
                    let request: NSURLRequest = NSURLRequest(URL: url)
                    let mainQueue = NSOperationQueue.mainQueue()
                    NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                        if error == nil {
                            let image = UIImage(data: data!)
                            self.photoButtonMain.setTitle("", forState: .Normal)
                            self.photoButtonMain.setImage(image, forState: .Normal)
                            self.photoButtonMain.contentMode = .ScaleAspectFit
                            self.photoButtonMain.imageView?.contentMode = .ScaleAspectFit
                            self.accessoryButtonMain.selected = true
                            self.saveImagesForButtons([self.photoButtonMain])
                        }
                        else {
                            
                        }
                    })
                }
            }
            if let file = user["UserImage1"] as? PFFile {


                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    image1Downloaded = true
                    completionBlock()
                    if let error = error {
                        self.photoButton1.setTitle("\(error)", forState: .Normal)
                        ErrorManager.handleError(error)
                    } else if let data = data {
                        self.photoButton1.setTitle("", forState: .Normal)
                        self.photoButton1.setImage(UIImage(data: data), forState: .Normal)
                        self.photoButton1.contentMode = .ScaleAspectFit
                        self.photoButton1.imageView?.contentMode = .ScaleAspectFit
                        self.accessoryButton1.selected = true
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                        self.photoButton1.setTitle("\(progress)%", forState: .Normal)
                })
            }
            if let file = user["UserImage2"] as? PFFile {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    image2Downloaded = true
                    completionBlock()
                    if let error = error {
                        self.photoButton2.setTitle("\(error)", forState: .Normal)
                        ErrorManager.handleError(error)
                    } else if let data = data {
                        self.photoButton2.setTitle("", forState: .Normal)
                        self.photoButton2.setImage(UIImage(data: data), forState: .Normal)
                        self.photoButton2.contentMode = .ScaleAspectFit
                        self.photoButton2.imageView?.contentMode = .ScaleAspectFit
                        self.accessoryButton2.selected = true
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                        self.photoButton2.setTitle("\(progress)%", forState: .Normal)
                })
            }
            if let file = user["UserImage3"] as? PFFile {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    image3Downloaded = true
                    completionBlock()
                    if let error = error {
                        self.photoButton3.setTitle("\(error)", forState: .Normal)
                        ErrorManager.handleError(error)
                    } else if let data = data {
                        self.photoButton3.setTitle("", forState: .Normal)
                        self.photoButton3.setImage(UIImage(data: data), forState: .Normal)
                        self.photoButton3.contentMode = .ScaleAspectFit
                        self.photoButton3.imageView?.contentMode = .ScaleAspectFit
                        self.accessoryButton3.selected = true
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                        self.photoButton3.setTitle("\(progress)%", forState: .Normal)
                })
            }
            if let file = user["UserImage4"] as? PFFile {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    image4Downloaded = true
                    completionBlock()
                    if let error = error {
                        self.photoButton4.setTitle("\(error)", forState: .Normal)
                        ErrorManager.handleError(error)
                    } else if let data = data {
                        self.photoButton4.setTitle("", forState: .Normal)
                        self.photoButton4.setImage(UIImage(data: data), forState: .Normal)
                        self.photoButton4.contentMode = .ScaleAspectFit
                        self.photoButton4.imageView?.contentMode = .ScaleAspectFit
                        self.accessoryButton4.selected = true
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                        self.photoButton4.setTitle("\(progress)%", forState: .Normal)
                })
            }
            if let file = user["UserImage5"] as? PFFile {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    image5Downloaded = true
                    completionBlock()
                    if let error = error {
                        self.photoButton5.setTitle("\(error)", forState: .Normal)
                        ErrorManager.handleError(error)
                    } else if let data = data {
                        self.photoButton5.setTitle("", forState: .Normal)
                        self.photoButton5.setImage(UIImage(data: data), forState: .Normal)
                        self.photoButton5.contentMode = .ScaleAspectFit
                        self.photoButton5.imageView?.contentMode = .ScaleAspectFit
                        self.accessoryButton5.selected = true
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                        self.photoButton5.setTitle("\(progress)%", forState: .Normal)
                })
            }
            if let file = user["UserImage6"] as? PFFile {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    image6Downloaded = true
                    completionBlock()
                    if let error = error {
                        self.photoButton6.setTitle("\(error)", forState: .Normal)
                        ErrorManager.handleError(error)
                    } else if let data = data {
                        self.photoButton6.setTitle("", forState: .Normal)
                        self.photoButton6.setImage(UIImage(data: data), forState: .Normal)
                        self.photoButton6.contentMode = .ScaleAspectFit
                        self.photoButton6.imageView?.contentMode = .ScaleAspectFit
                        self.accessoryButton6.selected = true
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                        self.photoButton6.setTitle("\(progress)%", forState: .Normal)
                })
            }
        }
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
        if n > 1 {
            title = "Add Photos"
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(image:UIImage(named: "ic_exit") , style:UIBarButtonItemStyle.Plain , target: self, action: "closeTappedSetup")
        } else {
            title = "Edit Photos"
            nextButtonButton.title = "Done"
            UIToolbar.appearance().barTintColor = UIColor(netHex: 0xEEEEEE)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let n: Int! = self.navigationController?.viewControllers.count
        if n > 1 {

        } else {
            self.photoButton1.alpha = 0;
            self.photoButton2.alpha = 0;
            self.photoButton3.alpha = 0;
            self.photoButton4.alpha = 0;
            self.photoButton5.alpha = 0;
            self.photoButton6.alpha = 0;
            
            self.placeholder1.alpha = 0;
            self.placeholder2.alpha = 0;
            self.placeholder3.alpha = 0;
            self.placeholder4.alpha = 0;
            self.placeholder5.alpha = 0;
            self.placeholder6.alpha = 0;
            self.placeholderMain.alpha = 0;
            
            self.accessoryButton1.alpha = 0;
            self.accessoryButton2.alpha = 0;
            self.accessoryButton3.alpha = 0;
            self.accessoryButton4.alpha = 0;
            self.accessoryButton5.alpha = 0;
            self.accessoryButton6.alpha = 0;
            
            self.infoLabel.alpha = 0;

            [UIView .animateWithDuration(0.45, animations: {
                self.photoButton1.alpha = 1;
                self.photoButton2.alpha = 1;
                self.photoButton3.alpha = 1;
                self.photoButton4.alpha = 1;
                self.photoButton5.alpha = 1;
                self.photoButton6.alpha = 1;
                
                self.accessoryButton1.alpha = 1;
                self.accessoryButton2.alpha = 1;
                self.accessoryButton3.alpha = 1;
                self.accessoryButton4.alpha = 1;
                self.accessoryButton5.alpha = 1;
                self.accessoryButton6.alpha = 1;
                
                self.placeholder1.alpha = 1;
                self.placeholder2.alpha = 1;
                self.placeholder3.alpha = 1;
                self.placeholder4.alpha = 1;
                self.placeholder5.alpha = 1;
                self.placeholder6.alpha = 1;
                self.placeholderMain.alpha = 1;
                
                self.infoLabel.alpha = 1;
                }, completion: { (finished) in
                    
            })];
        }

        if tempImage != nil {
            let tempImageView = UIImageView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width))
            tempImageView.image = self.tempImage
            self.view.addSubview(tempImageView)
            
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.3, animations: {
                tempImageView.frame = CGRectMake(self.photoButtonMain.frame.origin.x, self.photoButtonMain.frame.origin.y, self.photoButtonMain.frame.size.width, self.photoButtonMain.frame.size.height)
            }) { (finished) in
                tempImageView.removeFromSuperview()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        saveImagesForButtons(Array(self.associatedButtonAccessories.keys))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.row == 0) {
            return view.frame.width + 80
        } else {
            let n: Int! = self.navigationController?.viewControllers.count
            if n > 1 {
                return view.frame.height - view.frame.width - 120
            }
            return view.frame.height - view.frame.width - 120
        }
    }

    // MARK: OLFacebookImagePickerControllerDelegate

    func facebookImagePicker(imagePicker: OLFacebookImagePickerController!, didFinishPickingImages images: [AnyObject]!) {
        dismissViewControllerAnimated(true) { () -> Void in
        }
        if images != nil {
            let n: Int! = self.navigationController?.viewControllers.count
            if n > 1 {
                if let _ = self.navigationController?.viewControllers[n-5] as? SetupViewController {
                    Mixpanel.sharedInstance().track("Onboarding - Profile Photo Added")
                }
            }
            if let images = images as? [OLFacebookImage] {
                imageBitMap.removeAll()
                for button in [photoButtonMain, photoButton1, photoButton2, photoButton3, photoButton4, photoButton5, photoButton6] {
                    if button.currentImage != nil {
                         imageBitMap.append(1)
                    } else {
                        imageBitMap.append(0)
                    }
                }
                allocateImages(images)
            }

        }
        refreshAccessoryButtons()

    }

    func facebookImagePickerDidCancelPickingImages(imagePicker: OLFacebookImagePickerController!) {
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }

    func facebookImagePicker(imagePicker: OLFacebookImagePickerController!, shouldSelectImage image: OLFacebookImage!) -> Bool {
        if imagePicker.selected == nil {
            return true
        }
        var count = 0
        for button in [photoButton1, photoButton2, photoButton3, photoButton4, photoButton5, photoButton6, photoButtonMain] {
            if button.currentImage == nil {
                count += 1
            }
        }
        if selectedButton?.currentImage != nil {
            count += 1
        }
        return imagePicker.selected.count < count
    }

    func facebookImagePicker(imagePicker: OLFacebookImagePickerController!, didFailWithError error: NSError!) {
        ErrorManager.handleError(error)
    }

    // MARK: Actions

    func closeTapped() {
        navigationController?.popToRootViewControllerAnimated(true)
    }

    func logoutTapped() {
        let alert = UIAlertController(title: "Sign Out", message: "Are you sure you want to sign out?", preferredStyle: UIAlertControllerStyle.ActionSheet)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in

        }))
        alert.addAction(UIAlertAction(title: "Sign Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in

            PFUser.logOutInBackgroundWithBlock { (error: NSError?) -> Void in
                self.navigationController?.popToRootViewControllerAnimated(true)
            }
        }))
        self.presentViewController(alert, animated: true) { () -> Void in

        }
    }

    // MARK: IBActions

    @IBAction func didTapAccessoryButton(sender: AnyObject) {
        if let sender = sender as? UIButton {
            let removeImageForButton: (button: UIButton) -> Void = {
                button in
                button.setImage(nil, forState: UIControlState.Normal)
            }
            if sender.selected {
                sender.selected = false
                switch sender {
                case accessoryButton1: removeImageForButton(button: photoButton1)
                case accessoryButton2: removeImageForButton(button: photoButton2)
                case accessoryButton3: removeImageForButton(button: photoButton3)
                case accessoryButton4: removeImageForButton(button: photoButton4)
                case accessoryButton5: removeImageForButton(button: photoButton5)
                case accessoryButton6: removeImageForButton(button: photoButton6)
                case accessoryButtonMain: removeImageForButton(button: photoButtonMain)
                default: break
                }
            } else {
                sender.selected = true
                let keys = (self.associatedButtonAccessories as NSDictionary).allKeysForObject(sender) as! [UIButton]
                self.addImageTapped(keys.first!)
            }
        }
    }

    @IBAction func addImageTapped(sender: AnyObject) {
        if let sender = sender as? UIButton {
            selectedButton = sender
            if sender.imageForState(.Normal) == nil {
                let picker = OLFacebookImagePickerController()
                picker.view.backgroundColor = UIColor.vocaleBackgroundGreyColor()
                picker.navigationBar.barTintColor = UIColor.vocaleBackgroundGreyColor()
                picker.delegate = self

                self.presentViewController(picker, animated: true) { () -> Void in

                }
            } else {
                if sender.selected {
                    sender.selected = false
                    sender.layer.borderColor = UIColor.whiteColor().CGColor

                } else {
                    if let buttonToExchangeWith = buttonToExchangeWith {
                        let image = buttonToExchangeWith.imageForState(UIControlState.Normal)
                        buttonToExchangeWith.setImage(sender.imageForState(.Normal), forState: UIControlState.Normal)
                        buttonToExchangeWith.layer.borderColor = UIColor.whiteColor().CGColor
                        sender.setImage(image, forState: .Normal)
                        self.buttonToExchangeWith = nil
                    } else {
                        buttonToExchangeWith = sender
                        sender.selected = true
                        sender.layer.borderWidth = 2
                        sender.layer.borderColor = UIColor.vocaleRedColor().CGColor
                    }
                }
            }
        }
        refreshAccessoryButtons()
    }

    @IBAction func userAboutPhotosSegmentedControlChanged(sender: AnyObject) {
        if let sender = sender as? UISegmentedControl {
            switch sender.selectedSegmentIndex {
            case 0: self.dismissViewControllerAnimated(true, completion: { () -> Void in
            })
            default: break
            }
        }
    }
    
    @IBAction func nextButtonTapped(sender: UIBarButtonItem) {
        let n: Int! = self.navigationController?.viewControllers.count
        if n > 1 {
            let controller = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
            controller.registerProcedure = true
            controller.inputTooltipText = "Tell people a little more about who you are and what you like."
            controller.navigationItem.title = "About You"
            controller.didFinishTypingWithText = {
                text in
                //            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.0 * Double(NSEC_PER_SEC)))
                //            dispatch_after(delayTime, dispatch_get_main_queue()) {
                //
                //                if let user = PFUser.currentUser() {
                //                    user["AboutMe"]  = text
                //                    user.saveInBackground()
                //                }
                //            }
                
            }
            self.navigationController?.pushViewController(controller, animated: false)
        } else {
            self.navigationController?.setToolbarHidden(true, animated: true)
            self.dismissViewControllerAnimated(true, completion: nil)
            let tempImageView = UIImageView(frame: CGRectMake(self.photoButtonMain.frame.origin.x, self.photoButtonMain.frame.origin.y, self.photoButtonMain.frame.size.width, self.photoButtonMain.frame.size.height))
            if let image = self.photoButtonMain.imageView?.image {
                tempImageView.image = image
                self.delegate?.profileImageChanged(image)
            }

            self.view.addSubview(tempImageView)
            
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(0.25, animations: {
                tempImageView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)
            }) { (finished) in
                //tempImageView.removeFromSuperview()
            }
            
            [UIView .animateWithDuration(0.3, animations: {
                self.photoButton1.alpha = 0;
                self.photoButton2.alpha = 0;
                self.photoButton3.alpha = 0;
                self.photoButton4.alpha = 0;
                self.photoButton5.alpha = 0;
                self.photoButton6.alpha = 0;
                
                self.accessoryButton1.alpha = 0;
                self.accessoryButton2.alpha = 0;
                self.accessoryButton3.alpha = 0;
                self.accessoryButton4.alpha = 0;
                self.accessoryButton5.alpha = 0;
                self.accessoryButton6.alpha = 0;
                
                self.placeholder1.alpha = 0;
                self.placeholder2.alpha = 0;
                self.placeholder3.alpha = 0;
                self.placeholder4.alpha = 0;
                self.placeholder5.alpha = 0;
                self.placeholder6.alpha = 0;
                self.placeholderMain.alpha = 0;
                
                self.infoLabel.alpha = 0;
                }, completion: { (finished) in
                    
            })];
        }
    }

    @IBAction func doneTapped(sender: AnyObject) {
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }

    @IBAction func cancelTapped(sender: AnyObject) {
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }

    // MARK: Auxiliary Methods

    func saveImagesForButtons(buttons: [UIButton]) {
        for button in buttons {
            if let image = button.imageForState(.Normal) {
                if let image = button.imageForState(.Normal), let data = UIImageJPEGRepresentation(image.squareImage(), 0.9), let file = PFFile(name: "UserImage", data: data), let currentUser = PFUser.currentUser() {
                    switch button {
                    case self.photoButtonMain:
                        currentUser["UserImageMain"] = file
                    case self.photoButton1:
                        currentUser["UserImage1"] = file
                    case self.photoButton2:
                        currentUser["UserImage2"] = file
                    case self.photoButton3:
                        currentUser["UserImage3"] = file
                    case self.photoButton4:
                        currentUser["UserImage4"] = file
                    case self.photoButton5:
                        currentUser["UserImage5"] = file
                    default:
                        currentUser["UserImage6"] = file
                    }
                }
            } else {
                if let currentUser = PFUser.currentUser() {
                    switch button {
                    case self.photoButtonMain:
                        currentUser.removeObjectForKey("UserImageMain")
                    case self.photoButton1:
                        currentUser.removeObjectForKey("UserImage1")
                    case self.photoButton2:
                        currentUser.removeObjectForKey("UserImage2")
                    case self.photoButton3:
                        currentUser.removeObjectForKey("UserImage3")
                    case self.photoButton4:
                        currentUser.removeObjectForKey("UserImage4")
                    case self.photoButton5:
                        currentUser.removeObjectForKey("UserImage5")
                    default:
                        currentUser.removeObjectForKey("UserImage6")
                    }
                }
            }
        }
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
            if let error = error {
                ErrorManager.handleError(error)
            } else {
            }
        })
    }

    func allocateImages(var images: [OLFacebookImage]) {
        if images.count > 0 {
            if let image = images.first {
                if let currentButton = self.selectedButton {
                    let imageView = UIImageView()
                    imageBitMap[currentButton.tag] = 1

                    imageView.sd_setImageWithURL(image.fullURL, placeholderImage: UIImage(), options: .HighPriority, progress: { (progress: Int, second: Int) -> Void in
                        }, completed: { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, url: NSURL!) -> Void in


                            currentButton.setImage(image.squareImage(), forState: .Normal)
                            self.refreshAccessoryButtons()
                            currentButton.selected = false
                            self.selectedButton?.contentMode = .ScaleAspectFit
                            self.selectedButton?.imageView?.contentMode = .ScaleAspectFit

                            if let data = image.squareImage().compressedImageData(), let file = PFFile(name: "UserImage", data: data), let currentUser = PFUser.currentUser() {
                                switch currentButton {
                                case self.photoButtonMain:
                                    currentUser["UserImageMain"] = file
                                case self.photoButton1:
                                    currentUser["UserImage1"] = file
                                case self.photoButton2:
                                    currentUser["UserImage2"] = file
                                case self.photoButton3:
                                    currentUser["UserImage3"] = file
                                case self.photoButton4:
                                    currentUser["UserImage4"] = file
                                case self.photoButton5:
                                    currentUser["UserImage5"] = file
                                default:
                                    currentUser["UserImage6"] = file
                                }
                                currentUser.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                                    if let error = error {
                                        ErrorManager.handleError(error)
                                    } else {
                                    }
                                })
                            }
                    })
                    imageViews.append(imageView)
                    photos.append(image.fullURL)
                    images.removeFirst()
                    for button in [photoButton1, photoButton2, photoButton3, photoButton4, photoButton5, photoButton6, photoButtonMain] {
                        //print("\n\nCURRENT BUTTON - ", currentButton.tag)
                        //print("BUTTON -", button.tag)
                        if  button != currentButton {
                            //print("IMAGE - ", button.currentImage)
                            if imageBitMap[button.tag] == 0 {
                                self.selectedButton = button
                                break
                            }
                        }
                    }
                }
                //print(imageBitMap)
                allocateImages(images)
            }
        }
    }

    func refreshAccessoryButtons() {
        for (button, accessory) in associatedButtonAccessories {
            if button.imageForState(.Normal) == nil {
                accessory.selected = false
            } else {
                accessory.selected = true
            }
        }
    }

    func setAccessoryButton(button: UIButton) {
        button.setImage(UIImage(named: ""), forState: .Normal)
        button.setImage(UIImage(named: "crossIcon"), forState: UIControlState.Selected)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func closeTappedSetup() {
        let alert = UIAlertController(title: "Quit Setup?", message: "Are you sure you want to quit signing up? You will be logged out and your details will not be saved.", preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Continue", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) -> Void in
            
        }))
        alert.addAction(UIAlertAction(title: "Log Out", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) -> Void in
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SetupCancelled")
            NSUserDefaults.standardUserDefaults().synchronize()
            self.navigationController?.popToRootViewControllerAnimated(true)
        }))
        self.presentViewController(alert, animated: true) { () -> Void in
            
        }
    }
}
