//
//  savedEventCardTableViewCell.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/26.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class SavedEventCardTableViewCell: UITableViewCell {

    @IBOutlet weak var backgroundImageViewWrapper: UIView!
    @IBOutlet weak var timeStampLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var profilePicImageView: UIImageView!
    @IBOutlet weak var eventDescriptionLabel: UILabel!
    @IBOutlet weak var backgroundImageView: PFImageView!
    @IBOutlet weak var flagButton: UIButton! {
        didSet {
            flagButton.setImage(UIImage(named: "ic_flag")!, forState: UIControlState.Normal)
            flagButton.setTitle("", forState: .Normal)
            flagButton.addTarget(self, action: #selector(SavedEventCardTableViewCell.flagTapped), forControlEvents: .TouchUpInside)
        }
    }
    
    var flagTappedWithCompletion = {}

    var didTapMoreButton = {}
    var event: Event? {
        didSet {
            if let event = event {


                profilePicImageView.image = UIImage(assetIdentifier: .VocaleClearWhite)
                if event.placeholderImage == nil {
                    event.placeholderImage = UIImage(assetIdentifier: .VocaleGradient)
                }
                
                event.fetchIfNeededInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
                    //print(error)
                    if let event = object as? Event {
                        self.backgroundImageView.file = event.backgroundImage
                        
                        let myLocation = CLLocation(latitude: BrowseEventsTableViewController.lastSavedLocation.latitude, longitude: BrowseEventsTableViewController.lastSavedLocation.longitude)
                        let eventLocation = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
                        
                        let formatter = MKDistanceFormatter()
                        
                        let mutableMapPin = NSMutableAttributedString()
                        mutableMapPin.appendAttributedString(NSAttributedString(string: " \(formatter.stringFromDistance(myLocation.distanceFromLocation(eventLocation)))"))
                        self.locationLabel.attributedText = mutableMapPin
                        
                        let mutableTimeAgo = NSMutableAttributedString()
                        mutableTimeAgo.appendAttributedString(NSAttributedString(string: " \(SORelativeDateTransformer.registeredTransformer().transformedValue(event.eventDate)!)"))
                        self.timeStampLabel.attributedText = mutableTimeAgo
                        
                        self.eventDescriptionLabel.attributedText = event.attributedEventDescription()
                        if event.owner.dataAvailable {
                            if let _ = event.owner["name"] as? String {
                            } else {
                            }
                            if let file = event.owner["UserImageMain"] as? PFFile  {
                                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                                    if let _ = error {
                                    } else if let data = data, let image = UIImage(data: data) {
                                        self.profilePicImageView.image = image
                                        self.profilePicImageView.applyCircularMask2()
                                    }
                                    }, progressBlock: { (progress: Int32) -> Void in
                                })
                            } else if let string = event.owner["FBPictureURL"] as? String, url = NSURL(string: string) {
                                self.profilePicImageView.sd_setImageWithURL(url)
                                self.profilePicImageView.applyCircularMask2()
                            }
                        } else {
                            event.owner.fetchIfNeededInBackgroundWithBlock { (user: PFObject?, error: NSError?) -> Void in
                                if let usr = user as? PFUser {
                                    if let _ = usr["name"] as? String {
                                    } else {
                                    }
                                    if let file = usr["UserImageMain"] as? PFFile  {
                                        file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                                            if let _ = error {
                                            } else if let data = data, let image = UIImage(data: data) {
                                                self.profilePicImageView.image = image
                                                self.profilePicImageView.applyCircularMask2()
                                            }
                                            }, progressBlock: { (progress: Int32) -> Void in
                                        })
                                    } else if let string = usr["FBPictureURL"] as? String, url = NSURL(string: string) {
                                        self.profilePicImageView.sd_setImageWithURL(url)
                                        self.profilePicImageView.applyCircularMask2()
                                    }
                                }
                            }
                        }
                        self.backgroundImageView.image = event.placeholderImage

                    }
                    
                })
            }
        }
    }

    @IBAction func moreButtonTapped(sender: AnyObject) {
        didTapMoreButton()
    }
    
    func flagTapped() {
        flagTappedWithCompletion()
    }
}
