//
//  IndividualEventRespondentCardTableViewCell.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/30.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import MapKit
import AVFoundation
import LayerKit

protocol IndividualEventCellManagerDelegate: class {
    func individualShowUplodingView()
    func individualShowSentView()
    func individualShowCancelView()
    func individualRecordTapped()
    func individualRecordUploaded()
    func individualDeleteButtonTapped()
}

class IndividualEventRespondentCardTableViewCell: UITableViewCell, UIScrollViewDelegate, IndividualEventCardManagerDelegate {

    weak var delegate: IndividualEventCellManagerDelegate?
    @IBOutlet weak var flagButton: UIButton! {
        didSet {
            flagButton.setImage(UIImage(named: "flag")!, forState: UIControlState.Normal)
            flagButton.setTitle("", forState: .Normal)
            flagButton.addTarget(self, action: #selector(IndividualEventRespondentCardTableViewCell.flagTapped), forControlEvents: .TouchUpInside)
        }
    }
    @IBOutlet weak var userNameLabel: UILabel! {
        didSet {
            self.userNameLabel.text = ""
        }
    }
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var moreButton: UILabel! {
        didSet {
            moreButton.attributedText = FAKIonIcons.moreIconWithSize(19).attributedString()
        }
    }
    @IBOutlet weak var scrollViewContentView: UIView! {
        didSet {
            scrollViewContentView.backgroundColor = UIColor.clearColor()
            self.backgroundColor = UIColor.vocaleBackgroundGreyColor()
        }
    }
    @IBOutlet weak var backgroundImageViewWrapper: UIView!
    @IBOutlet weak var backgroundImageView: PFImageView!

    var individualResponseManager: IndividualResponseManager?
    var lastPage = 0
    var originalBackgroundImage: UIImage?
    var eventDescriptionView: UIView?
    var imageViews = [PFImageView]()
    var dismissEventClosure = {}
    var flagTappedWithCompletion = {}
    var topRightButton = BookmarkButton() {
        didSet {
            if !isFocusedCell {
                topRightButton.alpha = 0
            }
            topRightButton.frame = CGRectMake(self.frame.width - 55, 15, 40, 40)
            topRightButton.addTarget(self, action: #selector(IndividualEventRespondentCardTableViewCell.topRightButtonTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        }
    }
    var isFocusedCell = false {
        didSet {
            if isFocusedCell {
                UIImageView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in

                    self.backgroundImageView.alpha = 0.7
                    self.topRightButton.alpha = 1
                    }, completion: { (completed: Bool) -> Void in

                })
            } else {
                UIImageView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in

                    self.backgroundImageView.alpha = 0.4
                    self.topRightButton.alpha = 0

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
    var superViewFrame: CGRect?
    var scrollView = UIScrollView() {
        didSet {
            scrollView.pagingEnabled = true
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
                    self.backgroundColor = UIColor.redColor()
//                    self.locationLabel.alpha = 0
//                    self.timeStampLabel.alpha = 0
//                    self.moreButton.alpha = 0
                    //self.recordingLabel.alpha = 1
                    //self.flagButton.alpha = 0
                })
            } else {
                UIView.animateWithDuration(0.5, animations: { () -> Void in
                    self.backgroundColor = UIColor.blackColor()
                    self.locationLabel.alpha = 1
                    self.timeStampLabel.alpha = 1
                    self.moreButton.alpha = 1
                    self.flagButton.alpha = 1
                    //self.recordingLabel.alpha = 0
                    self.backgroundImageView.image = self.originalBackgroundImage

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

    var response: EventResponse? {
        didSet {
            if let response = response {
                response.fetchIfNeededInBackgroundWithBlock({ (response: PFObject?, error: NSError?) -> Void in
                    if error == nil {
                        if let response = response as? EventResponse {

                            response.voiceNote.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                                if(error == nil) {
                                    self.individualResponseManager?.showButtonsWithAnimation(true)
                                } else {
                                    SVProgressHUD.showErrorWithStatus(error?.localizedDescription)
                                }
                                }, progressBlock: { (progress: Int32) -> Void in
                                    //print(progress)
                                    self.userNameLabel.text = "Loading: \(progress)%"
                            })

                            response.repsondent.fetchIfNeededInBackgroundWithBlock({ (respondent: PFObject?, error: NSError?) -> Void in
                                if let usr = respondent as? PFUser {
                                    usr.pinInBackground()
                                    
                                    if let file = usr["UserImageMain"] as? PFFile  {
                                        file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                                            if let _ = error {
                                            } else if let data = data, let image = UIImage(data: data) {
                                                self.backgroundImageView.image = image
                                            }
                                            }, progressBlock: { (progress: Int32) -> Void in
                                        })
                                    } else if let string = usr["FBPictureURL"] as? String, url = NSURL(string: string) {
                                        self.backgroundImageView.sd_setImageWithURL(url, placeholderImage: UIImage(assetIdentifier: .redSquare), options: SDWebImageOptions.ContinueInBackground, progress: { (progress: Int, progress2: Int) -> Void in

                                            }, completed: { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, URL: NSURL!) -> Void in
                                        })
                                    }
                                }
                                if let respondentLocation = response.repsondent["lastLocation"] as? PFGeoPoint {
                                    let myLocation = CLLocation(latitude: BrowseEventsTableViewController.lastSavedLocation.latitude, longitude: BrowseEventsTableViewController.lastSavedLocation.longitude)
                                    let respondentLocationCL = CLLocation(latitude: respondentLocation.latitude, longitude: respondentLocation.longitude)

                                    let formatter = MKDistanceFormatter()

                                    let mutableMapPin = NSMutableAttributedString(string: "\u{e901}", attributes: [NSFontAttributeName : UIFont(name: "icomoon", size: 16)!, NSForegroundColorAttributeName : UIColor.whiteColor()])
                                    mutableMapPin.appendAttributedString(NSAttributedString(string: " \(formatter.stringFromDistance(myLocation.distanceFromLocation(respondentLocationCL)))"))
                                    self.locationLabel.attributedText = mutableMapPin
                                } else {
                                    let mutableMapPin = NSMutableAttributedString(string: "\u{e901}", attributes: [NSFontAttributeName : UIFont(name: "icomoon", size: 16)!])
                                    self.locationLabel.attributedText = mutableMapPin
                                }

                            })
                            let mutableTimeAgo = NSMutableAttributedString(string: "\u{e900}", attributes: [NSFontAttributeName : UIFont(name: "icomoon", size: 16)!])
                            mutableTimeAgo.appendAttributedString(NSAttributedString(string: " \(response.timeStamp.timeAgo())"))
                            self.timeStampLabel.attributedText = mutableTimeAgo
                            response.repsondent.fetchIfNeededInBackgroundWithBlock { (user: PFObject?, error: NSError?) -> Void in
                                if let error = error {
                                    SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                                }
                                self.drawProfileInformation(response.repsondent)
                            }
                        }
                    }
                })
            }
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
            //print("UserImage\(i)")
            if let image = profile["UserImage\(i)"] as? PFFile {
                imageFiles.append(image)
            }
        }

        self.scrollView = UIScrollView(frame: CGRectMake(0,0,self.frame.width, self.frame.width))
        self.scrollView.contentSize = CGSize(width: self.frame.width*CGFloat(2 + imageFiles.count), height: self.frame.width)
        addSubview(scrollView)

        if let superViewFrame = self.superViewFrame {
            self.scrollViewContentView.removeFromSuperview()
            self.scrollViewContentView.translatesAutoresizingMaskIntoConstraints = true
            self.scrollViewContentView.layoutIfNeeded()
            self.scrollView.addSubview(self.scrollViewContentView)
            self.scrollViewContentView.frame = CGRectMake(0,0, frame.width, superViewFrame.width)

            let secondProfileView = UIView(frame: CGRectMake(frame.width, 0, frame.width, frame.width))
            secondProfileView.backgroundColor = UIColor.vocaleBackgroundGreyColor()
            let backgroundView = UIImageView(frame: CGRectMake(0, 0, frame.width, frame.width))
            secondProfileView.addSubview(backgroundView)
            backgroundView.alpha = 1.0

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
                imageView.image = UIImage(assetIdentifier: .VocaleClearWhite)
                imageView.backgroundColor = UIColor.blackColor()
                imageViews.append(imageView)
                scrollView.addSubview(imageView)
                count++
            }
            topRightButton = BookmarkButton()
            self.response?.checkIsContainedInLocalDatastoreWithCompletion({ (contained) -> Void in
                if contained {
                    self.topRightButton.buttonState = .bookmarkedState
                } else {
                    self.topRightButton.buttonState = .bookmarkState
                }
            })
            addSubview(topRightButton)
        }

        individualResponseManager = IndividualResponseManager(frame: CGRectMake(0, self.frame.width, self.frame.width, self.frame.height - self.frame.width))
        individualResponseManager?.delegate = self
        self.addSubview(individualResponseManager!)
        individualResponseManager?.alpha = 0
        individualResponseManager?.recordTapped = {
            self.recordingMode = true
            self.delegate?.individualRecordTapped()
        }
        individualResponseManager?.cancelHandler = {
            self.recordingMode = false
        }
        individualResponseManager?.dismissEventClosure = {
            self.response?.unpinInBackground()
            self.dismissEventClosure()
        }
        individualResponseManager?.completionHandler = {
            success, error, url in
            if let url = url {
                self.recordingMode = false
                let dataDictionary = ["title": "VoiceNote"]
                do {
                    //print("!")
                    let dataDictionaryJSON = try NSJSONSerialization.dataWithJSONObject(dataDictionary, options: NSJSONWritingOptions.PrettyPrinted)
                    let dataMessagePart = LYRMessagePart(MIMEType: "application/json+voicenoteobject", data: dataDictionaryJSON)
                    let cellInfoDictionary = ["height": "90"]
                    let cellInfoDictionaryJSON = try NSJSONSerialization.dataWithJSONObject(cellInfoDictionary, options: NSJSONWritingOptions.PrettyPrinted)
                    let cellInfoMessagePart = LYRMessagePart(MIMEType: "application/json+voicenoteobject", data: cellInfoDictionaryJSON)
                    if let data = NSData(contentsOfURL: url) {
                        //print("!")
                        let dataType = "application/json+voicenoteobject"
                        let voiceNotePart = LYRMessagePart(MIMEType: dataType, data: data)
                        
                        let defaultConfiguration = LYRPushNotificationConfiguration()
                        defaultConfiguration.alert = "You have new voice message"
                        let options = [LYRMessageOptionsPushNotificationConfigurationKey: defaultConfiguration]

                        if let message = try AppDelegate.layerClient?.newMessageWithParts([dataMessagePart, cellInfoMessagePart, voiceNotePart], options: options), let receiverID = self.response?.repsondent.objectId, let senderID = NSUserDefaults.standardUserDefaults().objectForKey("currentUser") as? String {
                            do {
                                print("RECEIVER", receiverID)
                                print("CURRENT", senderID)
                                print(AppDelegate.layerClient?.authenticatedUserID)
                                if let conversation = try AppDelegate.layerClient?.newConversationWithParticipants([receiverID, senderID], options: nil) {
                                    var sent = false

//                                    print(conversation)
//                                    print(conversation.participants)
//                                    print(message)
                                    try conversation.sendMessage(message)
                                    self.individualResponseManager?.completeUploadWithAnimation()
                                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                                        self.dismissEventClosure()
                                    }
                                }
                            } catch {
                                if let conversations = try AppDelegate.layerClient?.conversationsForParticipants([receiverID]), conversation = conversations.first {
                                    try conversation.sendMessage(message)
                                    self.individualResponseManager?.completeUploadWithAnimation()
                                    let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                                    dispatch_after(delayTime, dispatch_get_main_queue()) {
                                        self.dismissEventClosure()
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    SVProgressHUD.showErrorWithStatus("An error occurred.  Please try again")
                }
            }

        }

        response?.voiceNote.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
            if(error == nil) {
                if let data = data {
                    self.individualResponseManager?.audioData = data
                    self.response?.isRead = true
                    self.response?.saveEventually()
                    self.individualResponseManager?.alpha = 1
                    self.moreButton.alpha = 0
                    self.userNameLabel.alpha = 0
                }
            } else {
                //print(error)
                SVProgressHUD.showErrorWithStatus(error?.localizedDescription)
            }
            }, progressBlock: { (progress: Int32) -> Void in
                //print(progress)
                self.userNameLabel.text = "Loading: \(progress)%"
        })

    }


    func showUploadCompletion(success: Bool) {
        if success {
            UIView.animateWithDuration(0.4, animations: { () -> Void in
                self.recordingLabel.textColor = UIColor.whiteColor()
                self.recordingLabel.backgroundColor = UIColor(red: 0.2, green: 1, blue: 0.2, alpha: 0.5)
                self.recordingLabel.text = "Message Sent"
                }, completion: { (completed: Bool) -> Void in

            })
        } else {
            UIView.animateWithDuration(0.4, animations: { () -> Void in
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

    func scrollViewDidScroll(scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x / scrollView.frame.size.width
        let pageNumber = Int(page)
        if page == 0 {
            setDescriptionViewMode(false)
        } else if page == 1 {
            setDescriptionViewMode(true)
        }
        if pageNumber != lastPage {
            lastPage = pageNumber
            lastPage = pageNumber
            if (pageNumber == 0) {
                topRightButton.alpha = 0
            } else {
                topRightButton.alpha = 1
                topRightButton.buttonState = .returnState
            }
        }
        if pageNumber - 1 < self.imageViews.count && pageNumber > 0 {
            print("Load page \(pageNumber - 1)")
            self.imageViews[pageNumber - 1].loadInBackground()
        }
        if pageNumber - 2 < imageViews.count && pageNumber > 1 {
            imageViews[pageNumber - 2].loadInBackground({ (image: UIImage?, error: NSError?) -> Void in
                if pageNumber - 1 < self.imageViews.count {
                    self.imageViews[pageNumber - 1].loadInBackground()
                }
            })

        }

    }

    func setDescriptionViewMode(descriptionMode: Bool) {
        if descriptionMode {
            if let eventCardManager = individualResponseManager {

                eventDescriptionView?.removeFromSuperview()
                eventDescriptionView = UIView(frame: CGRectMake(0, self.frame.width, self.frame.width, self.frame.height - self.frame.width))
                eventDescriptionView?.alpha = 1
                eventDescriptionView!.backgroundColor = eventCardManager.backgroundColor

                let lowerUserNameLabel = UILabel(frame: CGRectMake(0, 0, eventDescriptionView!.frame.width, eventDescriptionView!.frame.height/5))
                lowerUserNameLabel.textAlignment = .Center
                lowerUserNameLabel.textColor = UIColor(netHex:0xEEEEEE)


                let lowerDescriptionLabel = UILabel(frame: CGRectMake(0, eventDescriptionView!.frame.height*1.5/5, eventDescriptionView!.frame.width, eventDescriptionView!.frame.height*3.5/5))
                lowerDescriptionLabel.text = ""
                lowerDescriptionLabel.textColor = UIColor(netHex:0xEEEEEE)
                lowerDescriptionLabel.textAlignment = .Center
                lowerDescriptionLabel.numberOfLines = 9
                lowerDescriptionLabel.font = UIFont(name: "Raleway-Regular", size: 17)

                //print(response)
                //print(response?.repsondent)
                let lowerLocationLabel = UILabel(frame: CGRectMake(0, eventDescriptionView!.frame.height*1/7, eventDescriptionView!.frame.width, eventDescriptionView!.frame.height/5))
                if let birthdate = response?.repsondent["birthday"] as? String, let location = response?.repsondent["location"] as? String, let name = response?.repsondent["name"] as? String {

                    lowerLocationLabel.textAlignment = .Center
                    lowerLocationLabel.textColor = UIColor(netHex: 0xB7B7B7)
                    lowerLocationLabel.text = location.uppercaseString
                    lowerLocationLabel.font = UIFont(name: "Raleway-Regular", size: 12)

                    let df = NSDateFormatter()
                    df.dateFormat = "MM/dd/yyyy"
                    if let date = df.dateFromString(birthdate) {

                        lowerUserNameLabel.text = "\(name), \(date.age)"
                        lowerUserNameLabel.font = UIFont(name: "Raleway-Medium", size: 23)
                    }
                } else if let name = response?.repsondent["name"] as? String {
                    lowerUserNameLabel.text = "\(name)"
                    lowerUserNameLabel.font = UIFont(name: "Raleway-Regular", size: 23)
                }
                
                
                if let about = response?.repsondent["AboutMe"] as? String {
                    lowerDescriptionLabel.text = "\(about)"
                }

                eventDescriptionView!.addSubview(lowerDescriptionLabel)
                eventDescriptionView!.addSubview(lowerUserNameLabel)
                eventDescriptionView!.addSubview(lowerLocationLabel)
                self.addSubview(eventDescriptionView!)
            }
            UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                self.individualResponseManager?.alpha = 0
                self.eventDescriptionView?.alpha = 1
                }) { (completed: Bool) -> Void in

            }
        } else {
            UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                self.individualResponseManager?.alpha = 1
                self.eventDescriptionView?.alpha = 0
                }) { (completed: Bool) -> Void in

            }
        }
    }

    func topRightButtonTapped(sender: AnyObject) {
        self.scrollView.scrollRectToVisible(CGRectMake(0, 0, scrollView.frame.width, scrollView.frame.height), animated: true)
    }

    func deactivateProximitySensor() {
        individualResponseManager?.deactivateProximitySensor()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        individualResponseManager?.stopPlayback()
    }

    func flagTapped() {
        flagTappedWithCompletion()
    }
    
    //MARK: - IndividualEventCardManagerDelegate
    func individualUploadingVoiceMessage() {
        self.delegate?.individualShowUplodingView()
    }
    
    func individualSentVoiceMessage() {
        self.delegate?.individualShowSentView()
    }
    
    func individualCancelVoiceMessage() {
        self.delegate?.individualShowCancelView()
    }
    
    func individualUploadedVoiceMessage() {
        self.delegate?.individualRecordUploaded()
    }
    
    func deleteButtonPressed() {
        self.delegate?.individualDeleteButtonTapped()
    }

}
