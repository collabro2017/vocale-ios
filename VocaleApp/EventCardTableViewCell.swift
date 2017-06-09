//
//  EventCardTableViewCell.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/27.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import MapKit

protocol EventCellManagerDelegate: class {
    func showUplodingView()
    func showSentView()
    func showCancelView()
}

class EventCardTableViewCell: UITableViewCell, UIScrollViewDelegate, EventCardManagerDelegate {

    weak var delegate: EventCellManagerDelegate?
    @IBOutlet weak var scrollViewContentView: UIView! {
        didSet {
            scrollViewContentView.backgroundColor = UIColor.clearColor()
        }
    }
    var shouldSwipeRight = true
    
    @IBOutlet weak var redBackgroundView: UIView!
    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var timeStampImageView: UIImageView!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var backgroundImageView: PFImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var eventDescriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var flagButton: UIButton! {
        didSet {
            flagButton.setImage(UIImage(named: "ic_flag")!, forState: UIControlState.Normal)
            flagButton.setTitle("", forState: .Normal)
            flagButton.addTarget(self, action: #selector(EventCardTableViewCell.flagTapped), forControlEvents: .TouchUpInside)
        }
    }

    var recordTapped = {}
    var isPrototypeLocal = false
    var messageMode = false
    var eventCardManager: EventCardManager? {
        didSet {
            self.eventCardManager?.delegate = self
        }
    }
    var eventDescriptionView: UIView?
    var lowerUserNameLabel: UILabel?
    var lowerLocationLabel: UILabel?
    var messageCardManager: MessageControlButtonGroup?
    var dismissEventClosure = {}
    var savedMode = false
    var managerButtonCenters = CGFloat(0.5)
    var imageViews = [PFImageView]()
    var completionHandler = {}
    var showingProfileInformationHandler: (showing: Bool) -> Void = {
        _ in
    }
    var lastPage = 0
    var didSaveEventClosure: (save: Bool, event: Event) -> Void = {_,_ in}
    var bookmarkEventClosure: () -> Void  = {
    }
    var flagTappedWithCompletion = {}
    var topRightButton = BookmarkButton() {
        didSet {
            if !isFocusedCell {
                topRightButton.alpha = 0
            }
            topRightButton.frame = CGRectMake(self.frame.width - 55, 15, 40, 40)
            topRightButton.addTarget(self, action: #selector(EventCardTableViewCell.topRightButtonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }
    }
//    var woutReturnButton = false {
//        didSet {
//            if newValue = true {
//                self.topRightButton.hidden = true
//            }
//        }
//    }
    var isFocusedCell = false {
        didSet {
            if isFocusedCell {
                UIImageView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in

                    self.profilePicImageView.alpha = 1
                    self.backgroundImageView.alpha = 0.7
                    self.topRightButton.alpha = 1
                    }, completion: { (completed: Bool) -> Void in

                })
            } else {
                UIImageView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in

                    self.profilePicImageView.alpha = 0.4
                    self.backgroundImageView.alpha = 0.4
                    self.topRightButton.alpha = 1

                    }, completion: { (completed: Bool) -> Void in
                })
            }
        }
    }
    var recordingLabel = UILabel() {
        didSet {
            recordingLabel.text = "Recording"
            recordingLabel.font = UIFont(name: "Raleway-Regular", size: 16)!
            recordingLabel.textColor = UIColor.blackColor()
            recordingLabel.alpha = 0
            recordingLabel.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
            recordingLabel.textAlignment = .Center
        }
    }

    var didScrollToScrollViewPageAtIndex: (index: Int) -> Void = {
        _ in
    }
    var originalBackgroundImage: UIImage?
    var superViewFrame: CGRect?
    var scrollView = UIScrollView() {
        didSet {
            scrollView.pagingEnabled = true
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.delegate = self
            scrollView.backgroundColor = UIColor.clearColor()
        }
    }

    var recordingMode = false {
        didSet {
            if recordingMode {
                recordingLabel = UILabel(frame: CGRect(x: 0, y: self.frame.width - 20, width: self.frame.width, height: 20))
                self.addSubview(recordingLabel)
                if self.originalBackgroundImage == nil {
                    self.originalBackgroundImage = self.backgroundImageView.image
                }
                
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    //self.backgroundColor = UIColor.redColor()
                    print(self)
                    self.redBackgroundView.hidden = false
                    
//                    self.locationImageView.hidden = true
//                    self.timeStampImageView.hidden = true
//                    self.locationLabel.hidden = true
//                    self.timeStampLabel.hidden = true
//                    self.flagButton.hidden = true
                    self.recordingLabel.hidden = false
                    self.backgroundImageView.image = self.self.backgroundImageView.image?.blurredImage(0.5)
                })
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.backgroundColor = UIColor.vocaleBackgroundGreyColor()
                    self.redBackgroundView.hidden = true
//                    self.locationImageView.hidden = false
//                    self.timeStampImageView.hidden = false
//                    self.locationLabel.hidden = false
//                    self.timeStampLabel.hidden = false
//                    self.flagButton.hidden = false
                    self.recordingLabel.hidden = true
                    self.backgroundImageView.image = self.originalBackgroundImage
                    self.originalBackgroundImage = nil

                    }, completion: { (completed: Bool) -> Void in
                        if completed {
                            self.recordingLabel.removeFromSuperview()
                        }
                })
            }
        }
    }

    var uploadingMode = false {
        didSet {
            if uploadingMode {
                UIView.animateWithDuration(0.4, animations: { () -> Void in
                    self.recordingLabel.textColor = UIColor.whiteColor()
                    self.recordingLabel.backgroundColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
                    self.recordingLabel.text = "Sending Message"
                    }, completion: { (completed: Bool) -> Void in

                })
            }
        }
    }

    var event: Event? {
        didSet {
            if let event = event {
                profilePicImageView.image = UIImage(assetIdentifier: .VocaleClearWhite)
                if event.placeholderImage == nil {
                    event.placeholderImage = UIImage(assetIdentifier: .VocaleGradient)
                }
                self.backgroundImageView.file = event.backgroundImage

                let myLocation = CLLocation(latitude: BrowseEventsTableViewController.lastSavedLocation.latitude, longitude: BrowseEventsTableViewController.lastSavedLocation.longitude)
                let eventLocation = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)

                let formatter = MKDistanceFormatter()
                formatter.unitStyle = .Abbreviated
                let mutableMapPin = NSMutableAttributedString()
                var distance = myLocation.distanceFromLocation(eventLocation)
                if distance < 1000 {
                    distance = 1000
                } else {
                    distance = round(distance/1000)*1000
                }
                mutableMapPin.appendAttributedString(NSAttributedString(string: " \(formatter.stringFromDistance(distance))"))
                self.locationLabel.attributedText = mutableMapPin

                let mutableTimeAgo = NSMutableAttributedString()
                mutableTimeAgo.appendAttributedString(NSAttributedString(string: " \(SORelativeDateTransformer.registeredTransformer().transformedValue(event.eventDate)!)"))
                self.timeStampLabel.attributedText = mutableTimeAgo

                self.eventDescriptionLabel.attributedText = event.attributedEventDescription()
                self.userNameLabel.text = ""
                if event.owner.dataAvailable {
                    if let name = event.owner["name"] as? String {
                        let attString = NSMutableAttributedString(string: name, attributes: [NSFontAttributeName : UIFont(name: "Raleway-SemiBold", size: 17)!, NSForegroundColorAttributeName : UIColor.whiteColor()])
                        self.userNameLabel.numberOfLines = 2
                        self.userNameLabel.attributedText = attString
                        //print("STRING", attString)
                        if let birthDate = event.owner["birthday"] as? String {
                            let df = NSDateFormatter()
                            df.dateFormat = "MM/dd/yyyy"
                            if let date = df.dateFromString(birthDate) {

                                attString.appendAttributedString(NSAttributedString(string: "\n\(date.age)", attributes: [NSFontAttributeName : UIFont(name: "Raleway-Regular", size: 14)!]))
                                self.userNameLabel.attributedText = attString
                                //print("STRING", attString)
                            }

                        }
                    } else {
                        self.userNameLabel.text = event.owner.username
                    }
                    
                    if let file = event.owner["UserImageMain"] as? PFFile  {
                        file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                            if let _ = error {
                            } else if let data = data, let image = UIImage(data: data) {
                                self.profilePicImageView.image = image.circularImageWithBorder()
                            }
                            }, progressBlock: { (progress: Int32) -> Void in
                        })
                    } else if let string = event.owner["FBPictureURL"] as? String, url = NSURL(string: string) {
                        self.profilePicImageView.sd_setImageWithURL(url, completed: { (image: UIImage!, error: NSError!, cacheTyped: SDImageCacheType, url2: NSURL!) -> Void in
                            self.profilePicImageView.image = image.circularImageWithBorder()
                        })
                    }
                    if !self.isPrototypeLocal {
                        self.drawProfileInformation(event.owner)
                    }
                } else {
                    event.owner.fetchIfNeededInBackgroundWithBlock { (user: PFObject?, error: NSError?) -> Void in
                        if let usr = user as? PFUser {
                            if let name = usr["name"] as? String {
                                self.userNameLabel.text = name
                            } else {
                                self.userNameLabel.text = usr.username
                            }
                            
                            if let file = event.owner["UserImageMain"] as? PFFile  {
                                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                                    if let _ = error {
                                    } else if let data = data, let image = UIImage(data: data) {
                                        self.profilePicImageView.image = image.circularImageWithBorder()
                                    }
                                    }, progressBlock: { (progress: Int32) -> Void in
                                })
                            } else if let string = usr["FBPictureURL"] as? String, url = NSURL(string: string) {
                                self.profilePicImageView.sd_setImageWithURL(url, completed: { (image: UIImage!, error: NSError!, cacheTyped: SDImageCacheType, url2: NSURL!) -> Void in
                                    self.profilePicImageView.image = image.circularImageWithBorder()
                                })
                            }
                            if !self.isPrototypeLocal {
                                self.drawProfileInformation(usr)
                            }
                        }
                    }
                }
                self.backgroundImageView.image = event.placeholderImage
            }
        }
    }

    // MARK: UIScrollViewDelegate

    func scrollViewDidScroll(scrollView: UIScrollView) {
//        if shouldSwipeRight == false {
//            if (scrollView.contentOffset.x > frame.width) {
//                scrollView.setContentOffset(CGPoint(x: frame.width, y:scrollView.contentOffset.y), animated: false)
//            }
//        } else {
            let page = scrollView.contentOffset.x / scrollView.frame.size.width
            let pageNumber = Int(page)
            if page == 0 {
                //if shouldSwipeRight == true {
                    setDescriptionViewMode(false)
                    showingProfileInformationHandler(showing: false)
                    if self.savedMode {
                        
                    } else {
                        eventCardManager?.showButtonsWithAnimation(true)
                    }
                //}
                
            } else if page == 1 {
                setDescriptionViewMode(true)
                showingProfileInformationHandler(showing: true)
                if self.savedMode {
                    
                } else {
                    eventCardManager?.hideButtonsWithAnimation(true)
                }
                
            }
            if pageNumber != lastPage {
                
                self.didScrollToScrollViewPageAtIndex(index: pageNumber)
                lastPage = pageNumber
                if (pageNumber == 0) {
                    topRightButton.alpha = 0
                } else {
                    topRightButton.alpha = 1
                    topRightButton.buttonState = .returnState
                }
            }
            if pageNumber - 1 < self.imageViews.count && pageNumber > 0 {
                self.imageViews[pageNumber - 1].loadInBackground()
            }
            if pageNumber - 2 < imageViews.count && pageNumber > 1 {
                imageViews[pageNumber - 2].loadInBackground({ (image: UIImage?, error: NSError?) -> Void in
                    if pageNumber - 1 < self.imageViews.count {
                        self.imageViews[pageNumber - 1].loadInBackground()
                    }
                })
                
            }
            event?.checkContainmentInLocalDatastoreWithCompletion({ (isContained) -> Void in
                if (isContained) {
                    if let events = PFUser.currentUser()?["savedEvents"] as? [Event], let event = self.event where events.contains(event) {
                        self.eventCardManager?.isBookmarked = isContained
                    }
                }
                
            })
        //}
    }
    
    // MARK: - Cell Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    //MARK: - EventCardManagerDelegate
    func uploadingVoiceMessage() {
        self.delegate?.showUplodingView()
    }
    
    func sentVoiceMessage() {
        self.delegate?.showSentView()
    }
    
    func cancelVoiceMessage() {
        self.delegate?.showCancelView()
    }

    // MARK: - Auxiliary Functions

    func updateLocation() {
        if let event = event {
            let myLocation = CLLocation(latitude: BrowseEventsTableViewController.lastSavedLocation.latitude, longitude: BrowseEventsTableViewController.lastSavedLocation.longitude)
            let eventLocation = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
            let formatter = MKDistanceFormatter()
            let mutableMapPin = NSMutableAttributedString()
            var distance = myLocation.distanceFromLocation(eventLocation)
            if distance < 1000 {
                distance = 1000
            } else {
                distance = round(distance/1000)*1000
            }
            mutableMapPin.appendAttributedString(NSAttributedString(string: " \(formatter.stringFromDistance(distance))"))
            self.locationLabel.attributedText = mutableMapPin
        }
    }

    func drawProfileInformation(profile: PFUser) {
        imageViews = [PFImageView]()
        self.backgroundColor = UIColor.vocaleBackgroundGreyColor()
        for subview in subviews {
            subview.removeFromSuperview()
        }
        var imageFiles = [PFFile]()


        for (var i = 1; i < 7; i += 1) {
            if let image = profile["UserImage\(i)"] as? PFFile {
                imageFiles.append(image)
            }

        }

        self.scrollView = UIScrollView(frame: CGRectMake(0,0,self.frame.width, self.frame.width))
//        if shouldSwipeRight == false {
//            self.scrollView.contentSize = CGSize(width: self.frame.width*CGFloat(1 + imageFiles.count), height: self.frame.width)
//        } else {
            self.scrollView.contentSize = CGSize(width: self.frame.width*CGFloat(2 + imageFiles.count), height: self.frame.width)
        //}
        addSubview(scrollView)

        if let superViewFrame = self.superViewFrame {
            self.scrollViewContentView.removeFromSuperview()
            self.scrollViewContentView.translatesAutoresizingMaskIntoConstraints = true
            self.scrollViewContentView.layoutIfNeeded()
            self.scrollView.addSubview(self.scrollViewContentView)
            self.scrollViewContentView.frame = CGRectMake(0,0, frame.width, superViewFrame.width)

//            var secondProfileView = UIView()
//            if shouldSwipeRight == false {
//                secondProfileView = UIView(frame: CGRectMake(0, 0, frame.width, frame.width))
//            } else {
                let secondProfileView = UIView(frame: CGRectMake(frame.width, 0, frame.width, frame.width))
            //}
            secondProfileView.backgroundColor = UIColor.blackColor()
            let backgroundView = UIImageView(frame: CGRectMake(0, 0, frame.width, frame.width))
            backgroundView.alpha = 1
            backgroundView.backgroundColor = UIColor.vocaleBackgroundGreyColor()
            secondProfileView.addSubview(backgroundView)
            
            if let file = profile["UserImageMain"] as? PFFile  {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    if let _ = error {
                    } else if let data = data, let image = UIImage(data: data) {
                        backgroundView.image = image
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                })
            } else if let string = profile["FBPictureURL"] as? String, url = NSURL(string: string) {
                backgroundView.sd_setImageWithURL(url, completed: { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, url: NSURL!) -> Void in
                })
            }
            self.scrollView.addSubview(secondProfileView)
            var count = CGFloat(2)
            for image in imageFiles {
                let imageView = PFImageView(frame: CGRectMake(frame.width*count, CGFloat(0), frame.width, frame.width))
                imageView.file = image
                imageView.contentMode = .ScaleAspectFill
                imageView.image = UIImage(assetIdentifier: .VocaleGradient)
                imageView.backgroundColor = UIColor.blackColor()
                imageViews.append(imageView)
                scrollView.addSubview(imageView)
                count++
            }
            topRightButton = BookmarkButton()

            addSubview(topRightButton)
        }

        if messageMode {
            messageCardManager = MessageControlButtonGroup(frame: CGRectMake(0, self.frame.width, self.frame.width, self.frame.height - self.frame.width))
            messageCardManager?.leftButtonTapped = {
                self.flagTappedWithCompletion()
            }
            messageCardManager?.rightButtonTapped = self.dismissEventClosure
            addSubview(self.messageCardManager!)
        } else {
            if (self.savedMode == true) {
                var constant: CGFloat = 0
                if self.frame.width <= 320 {
                    constant = 20
                }
                eventCardManager = EventCardManager(frame: CGRectMake(0, self.frame.width, self.frame.width, self.frame.height - self.frame.width - constant), screenWidth: self.frame.width)
            } else {
                var constant: CGFloat = 100
                if self.frame.width <= 320 {
                    constant = 20
                    eventCardManager = EventCardManager(frame: CGRectMake(30, self.frame.width + 21, self.frame.width - 60, 70), screenWidth: self.frame.width)
                } else if self.frame.width < 414 {
                    eventCardManager = EventCardManager(frame: CGRectMake(30, self.frame.width + 37, self.frame.width - 60, 88), screenWidth: self.frame.width)
                    if (UIScreen.mainScreen().nativeScale == 2.8) { //ZOOMED MODE
                        eventCardManager = EventCardManager(frame: CGRectMake(30, self.frame.width + 52, self.frame.width - 60, 88), screenWidth: self.frame.width)
                    }
                } else {
                    eventCardManager = EventCardManager(frame: CGRectMake(30, self.frame.width + 52, self.frame.width - 60, 88), screenWidth: self.frame.width)
                }
            }
            
            eventCardManager?.event = event
        }

        if (self.savedMode == true) {
            eventCardManager?.savedMode = true
        } else {
            setManagerButtonCentersTo(managerButtonCenters)
        }
        //print(eventCardManager)
        //print(eventCardManager?.removeEventClosure)
        eventCardManager?.removeEventClosure = {
            PFUser.currentUser()?.removeObject(self.event!, forKey: "savedEvents")
            PFUser.currentUser()?.saveEventually()
            self.event?.saveEventually()
            self.event?.unpinInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                if completed {
                    self.didSaveEventClosure(save: false, event: self.event!)
                    self.event?.hasLocalCopy = false
                    UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

                        }, completion: { (completed: Bool) -> Void in

                    })
                } else {
                    ErrorManager.handleError(error)
                }
            })
        }
        if let eventCardManager = eventCardManager {
            self.addSubview(eventCardManager)
        }
        eventCardManager?.recordTapped = {
            self.recordingMode = true
            self.scrollView.scrollRectToVisible(CGRectMake(0, 0, self.scrollView.frame.width, self.scrollView.frame.height), animated: true)
            self.scrollView.scrollEnabled = false
            self.recordTapped()
        }
        eventCardManager?.bookmarkEventClosure = {
            if let event = self.event, let savedEvents = PFUser.currentUser()?["savedEvents"] as? [PFObject] where savedEvents.contains(event) {
                PFUser.currentUser()!.removeObject(event, forKey: "savedEvents")

                self.event?.saveEventually()
                self.event?.unpinInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                    if completed {

                        self.didSaveEventClosure(save: false, event: self.event!)
                        self.event?.hasLocalCopy = false
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in

                            }, completion: { (completed: Bool) -> Void in

                        })
                    } else {
                        ErrorManager.handleError(error)
                    }
                })
            } else {

                self.event?.pinInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                    if completed {
                        PFUser.currentUser()!.addUniqueObject(self.event!, forKey: "savedEvents")
                        PFUser.currentUser()?.saveEventually()
                        self.event?.saveEventually()
                        self.didSaveEventClosure(save: true, event: self.event!)
                        self.event?.hasLocalCopy = true
                    } else {
                        ErrorManager.handleError(error)
                    }
                })
            }
        }
        eventCardManager?.dismissEventClosure = dismissEventClosure
        eventCardManager?.cancelHandler = {
            self.recordingMode = false
            self.scrollView.scrollEnabled = true
            self.completionHandler()
        }
        eventCardManager?.completionHandler = {
            success, error, url in
            self.completionHandler()
            if let url = url, let event = self.event {
                let eventResponse = EventResponse()
                eventResponse.parentEvent = event
                if let user = PFUser.currentUser() {
                    eventResponse.repsondent = user
                }
                eventResponse.timeStamp = NSDate()

                if let data = NSData(contentsOfURL: url) {
                    if let file = PFFile(name: url.lastPathComponent, data: data) {
                        eventResponse.voiceNote = file
                    }
                }
                self.uploadingMode = true
                eventResponse.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                    if let error = error {
                        ErrorManager.handleError(error)
                        self.showUploadCompletion(false)
                    } else {
                        //print("EVENT REPSONSES ---- ", event.responses)
                        //print("RESPONSE", eventResponse)
                        event.responses.append(eventResponse)
                        //print("EVENT REPSONSES ---- ", event.responses)
                        event.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                            if let error = error {
                                print("\n\nERROR - SAVING\n\n")
                            }
                        })
                        self.eventCardManager?.completeUploadWithAnimation()
                        self.showUploadCompletion(true)
                        self.scrollView.scrollEnabled = true
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            self.recordingMode = false
                            self.uploadingMode = false
                            self.dismissEventClosure()
                        }

                    }
                })

            }
        }
        if let events = PFUser.currentUser()?["savedEvents"] as? [Event], let event = event where events.contains(event) {
            self.eventCardManager?.isBookmarked = true
        }
    }

    func showUploadCompletion(success: Bool) {
        if success {
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.backgroundColor = UIColor.vocaleBackgroundGreyColor()
                self.recordingLabel.textColor = UIColor.whiteColor()
                self.recordingLabel.backgroundColor = UIColor(red: 0.2, green: 1, blue: 0.2, alpha: 0.5)
                self.recordingLabel.text = "Message Sent"
                }, completion: { (completed: Bool) -> Void in

            })
        } else {
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.backgroundColor = UIColor.vocaleBackgroundGreyColor()
                self.recordingLabel.textColor = UIColor.whiteColor()
                self.recordingLabel.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
                self.recordingLabel.text = "An Error Occurred"

                }, completion: { (completed: Bool) -> Void in
            })
        }
        UIView.animateWithDuration(0.4, delay: 0.4, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.recordingLabel.alpha = 0
            }) { (completed: Bool) -> Void in

        }
    }

    func topRightButtonTapped(sender: AnyObject) {
        if let sender = sender as? BookmarkButton {
            if sender.buttonState == .bookmarkState {
                self.event?.pinInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                    if completed {
                        PFUser.currentUser()!.addUniqueObject(self.event!, forKey: "savedEvents")
                        PFUser.currentUser()?.saveEventually()
                        self.didSaveEventClosure(save: true, event: self.event!)
                        self.event?.hasLocalCopy = true
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                            sender.buttonState = .bookmarkedState

                            }, completion: { (completed: Bool) -> Void in

                        })
                    } else {
                        ErrorManager.handleError(error)
                    }
                })

            } else if sender.buttonState == .bookmarkedState {
                PFUser.currentUser()?.removeObject(self.event!, forKey: "savedEvents")
                PFUser.currentUser()?.saveEventually()
                self.event?.saveEventually()
                self.event?.unpinInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                    if completed {
                        self.didSaveEventClosure(save: false, event: self.event!)
                        self.event?.hasLocalCopy = false
                        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
                            sender.buttonState = .bookmarkState

                            }, completion: { (completed: Bool) -> Void in

                        })
                    } else {
                        ErrorManager.handleError(error)
                    }
                })
            } else {
                self.scrollView.scrollRectToVisible(CGRectMake(0, 0, scrollView.frame.width, scrollView.frame.height), animated: true)
            }
        }
    }

    func dismissCardWithAnimation() {
        UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
            self.scrollView.frame.origin = CGPointMake(0, 0 - self.scrollView.frame.height)
            }) { (completed: Bool) -> Void in

        }
    }

    func presentCardWithAnimation() {
//        let originalFrame = CGRectMake(0,0,self.scrollView.frame.width,self.scrollView.frame.width)
//        self.backgroundImageView.frame = CGRectMake(self.frame.width/2,self.frame.width/2,0,0)
//        self.timeStampLabel.alpha = 0
//        self.locationLabel.alpha = 0
//        self.flagButton.alpha = 0
//        self.profilePicImageView.alpha = 0
//        self.userNameLabel.alpha = 0
//        self.eventDescriptionLabel.alpha = 0
        self.scrollViewContentView.transform = CGAffineTransformMakeScale(0.01, 0.01)
        self.scrollViewContentView.alpha = 0.0

        UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
            self.scrollViewContentView.transform = CGAffineTransformMakeScale(1, 1)
            self.scrollViewContentView.alpha = 1.0

//            self.backgroundImageView.frame = originalFrame
//            self.timeStampLabel.alpha = 1
//            self.locationLabel.alpha = 1
//            self.flagButton.alpha = 1
//            self.profilePicImageView.alpha = 1
//            self.userNameLabel.alpha = 1
//            self.eventDescriptionLabel.alpha = 1

            }) { (completed: Bool) -> Void in

        }
    }

    func showCardWithAnimation(shouldAnimate: Bool) {
        if (shouldAnimate) {
            //let originalFrame = CGRectMake(0,0,self.scrollView.frame.width,self.scrollView.frame.width)
            
//            self.backgroundImageView.frame = CGRectMake(self.frame.width/2,self.frame.width/2,0,0)
//            self.timeStampLabel.alpha = 0
//            self.locationLabel.alpha = 0
//            self.flagButton.alpha = 0
//            self.profilePicImageView.alpha = 0
//            self.userNameLabel.alpha = 0
//            self.eventDescriptionLabel.alpha = 0
            self.scrollViewContentView.transform = CGAffineTransformMakeScale(0.01, 0.01)
            self.scrollViewContentView.alpha = 0.0

            eventCardManager?.showButtonsWithAnimation(true)
            UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                //self.scrollView.alpha = 1

                self.scrollViewContentView.transform = CGAffineTransformMakeScale(1, 1)
                self.scrollViewContentView.alpha = 1.0
//                self.locationImageView.frame = originalLocationImageViewFrame
//                self.timeStampImageView.frame = originalTimeImageViewFrame
//                self.backgroundImageView.frame = originalFrame
//                self.timeStampLabel.alpha = 1
//                self.locationLabel.alpha = 1
//                self.flagButton.alpha = 1
//                self.profilePicImageView.alpha = 1
//                self.userNameLabel.alpha = 1
//                self.eventDescriptionLabel.alpha = 1

                }) { (completed: Bool) -> Void in

            }
        } else {
            scrollView.alpha = 1
            eventCardManager?.showButtonsWithAnimation(false)
        }
    }

    func hideCardWithAnimation(shouldAnimate: Bool) {
        if (shouldAnimate) {
            eventCardManager?.hideButtonsWithAnimation(true)

            let originalLocationImageViewFrame = self.locationImageView.frame
            let originalTimeImageViewFrame = self.timeStampImageView.frame
            UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                self.scrollViewContentView.transform = CGAffineTransformMakeScale(0.01, 0.01)
                self.scrollViewContentView.alpha = 0.0
                
                //self.backgroundImageView.frame = CGRectMake(self.frame.width/2,self.frame.width/2,0,0)
//                self.timeStampLabel.alpha = 0
//                self.locationLabel.alpha = 0
//                self.flagButton.alpha = 0
//                self.profilePicImageView.alpha = 0
//                self.userNameLabel.alpha = 0
//                self.eventDescriptionLabel.alpha = 0
                }) { (completed: Bool) -> Void in
//                    self.locationImageView.frame = originalLocationImageViewFrame
//                    self.timeStampImageView.frame = originalTimeImageViewFrame
//                    self.locationImageView.transform = CGAffineTransformIdentity
//                    self.timeStampImageView.transform = CGAffineTransformIdentity
                    self.scrollViewContentView.transform = CGAffineTransformMakeScale(1, 1)
                    //self.scrollViewContentView.alpha = 1.0
            }
        } else {
            scrollView.alpha = 0
            eventCardManager?.hideButtonsWithAnimation(false)
        }
    }

    func setDescriptionViewMode(descriptionMode: Bool) {
        if descriptionMode {

            //eventDescriptionView?.removeFromSuperview()
            if eventDescriptionView == nil {
                eventDescriptionView = UIView(frame: CGRectMake(0, self.frame.width, self.frame.width, self.frame.height - self.frame.width))
                eventDescriptionView?.alpha = 0
                eventDescriptionView?.backgroundColor = UIColor.vocaleBackgroundGreyColor()
                
                let lowerUserNameLabel = UILabel(frame: CGRectMake(0, 1, eventDescriptionView!.frame.width, 40))
                lowerUserNameLabel.textAlignment = .Center
                lowerUserNameLabel.textColor = UIColor(netHex:0x211E23)
                lowerUserNameLabel.backgroundColor = UIColor(netHex: 0xEEEEEE)
                self.lowerUserNameLabel = lowerUserNameLabel
                
                let lowerLocationLabel = UILabel(frame: CGRectMake(0, lowerUserNameLabel.frame.size.height + lowerUserNameLabel.frame.origin.y, eventDescriptionView!.frame.width, 20))
                self.lowerLocationLabel = lowerLocationLabel
                lowerLocationLabel.textAlignment = .Center
                lowerLocationLabel.textColor = UIColor(netHex: 0x848485)
                lowerLocationLabel.backgroundColor = UIColor(netHex: 0xEEEEEE)
                lowerLocationLabel.font = UIFont(name: "Raleway-SemiBold", size: 12)
                if let location = event!.owner["location"] as? String {
                    lowerLocationLabel.text = location.uppercaseString
                } else {
                    lowerLocationLabel.text = ""
                }
                
                let lowerDescriptionLabel = UILabel(frame: CGRectMake(0, lowerUserNameLabel.frame.origin.y + lowerUserNameLabel.frame.size.height, eventDescriptionView!.frame.width, eventDescriptionView!.frame.height*3.5/5))
                lowerDescriptionLabel.text = ""
                lowerDescriptionLabel.textColor = UIColor(netHex:0xEEEEEE)
                lowerDescriptionLabel.textAlignment = .Center
                lowerDescriptionLabel.numberOfLines = 9
                lowerDescriptionLabel.font = UIFont(name: "Raleway-Regular", size: 17)
                
                lowerUserNameLabel.textColor = UIColor(netHex:0x211E23)
                if let birthdate = event!.owner["birthday"] as? String, let name = event!.owner["name"] as? String {
                    
                    let df = NSDateFormatter()
                    df.dateFormat = "MM/dd/yyyy"
                    if let date = df.dateFromString(birthdate) {
                        
                        //lowerUserNameLabel.text = "\(name), \(date.age)"
                        
                        let messageText1 = "\(name), \(date.age)"
                        let range = (messageText1 as NSString).rangeOfString("\(date.age)")
                        let range2 = (messageText1 as NSString).rangeOfString("\(name)")
                        let attributedString = NSMutableAttributedString(string:messageText1)
                        attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Medium", size: 23)!], range: range)
                        attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 23)!], range: range2)
                        lowerUserNameLabel.attributedText = attributedString
                        
                        //lowerUserNameLabel.font = UIFont(name: "Raleway-Bold", size: 23)
                    }
                } else if let name = event!.owner["name"] as? String {
                    lowerUserNameLabel.text = "\(name)"
                    lowerUserNameLabel.font = UIFont(name: "Raleway-Bold", size: 23)
                }
                
                if let about = event!.owner["AboutMe"] as? String {
                    lowerDescriptionLabel.text = "\(about)"
                }
                
                eventDescriptionView!.addSubview(lowerDescriptionLabel)
                eventDescriptionView!.addSubview(lowerUserNameLabel)
                //eventDescriptionView!.addSubview(lowerLocationLabel)
                self.addSubview(eventDescriptionView!)
                
                self.lowerLocationLabel?.transform = CGAffineTransformMakeTranslation(0, -30)
                self.lowerUserNameLabel?.transform = CGAffineTransformMakeTranslation(0, -30)
                self.lowerUserNameLabel?.alpha = 0
                self.lowerLocationLabel?.alpha = 0
                //self.eventDescriptionLabel.alpha = 0
                UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 20, options: .CurveEaseInOut, animations: { () -> Void in
                    self.eventDescriptionView?.alpha = 1
                    self.eventCardManager?.alpha = 0
                    self.messageCardManager?.alpha = 0
                    self.lowerUserNameLabel?.alpha = 1
                    self.lowerLocationLabel?.alpha = 1
                    self.lowerLocationLabel?.transform = CGAffineTransformMakeTranslation(0, 0)
                    self.lowerUserNameLabel?.transform = CGAffineTransformMakeTranslation(0, 0)
                }) { (completed: Bool) -> Void in
                    
                }
            }
        } else {
            UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 20, options: .CurveEaseInOut, animations: { () -> Void in
                self.eventCardManager?.alpha = 1
                self.eventDescriptionView?.alpha = 0
                self.messageCardManager?.alpha = 1
                }) { (completed: Bool) -> Void in
                    self.eventDescriptionView?.removeFromSuperview()
                    self.eventDescriptionView = nil
            }
        }
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        print(scrollView.contentOffset.x)
        let translation = scrollView.panGestureRecognizer.translationInView(scrollView.superview)
        
        if translation.x > 0 {
            if scrollView.contentOffset.x == self.contentView.frame.size.width {
                UIView.animateWithDuration(0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 20, options: .CurveEaseInOut, animations: { () -> Void in
                    self.eventDescriptionView?.alpha = 0
                    self.lowerLocationLabel?.transform = CGAffineTransformMakeTranslation(0, -30)
                    self.lowerUserNameLabel?.transform = CGAffineTransformMakeTranslation(0, -30)
                }) { (completed: Bool) -> Void in
                    
                }
            }
        }
        
        print(scrollView.contentOffset)
        print(scrollView.contentSize)
    }
    
    func setManagerButtonCentersTo(center: CGFloat) {
        managerButtonCenters = center
        self.eventCardManager?.setButtonCentersTo(center)
    }

    func flagTapped() {
        flagTappedWithCompletion()
    }

}
