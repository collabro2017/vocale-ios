//
//  EventResponseCardTableViewCell.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/29.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import MapKit

class EventResponseCardTableViewCell: UITableViewCell {

    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var counterButtonView: CounterButtonView!
    @IBOutlet weak var backgroundImageView: PFImageView!
    @IBOutlet weak var backgroundImageViewWrapper: UIView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var eventDescriptionLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeStampLabel: UILabel!

    var moreActionTapped = {}
    var gradientView: UIView?
    var event: Event? {
        didSet {
            if let event = event {
                setCount()
                self.backgroundImageView.file = event.backgroundImage
                //                if gradientView == nil {
//                    gradientView = UIView(frame: CGRectMake(0,0, backgroundImageViewWrapper.frame.width, backgroundImageViewWrapper.frame.height))
//                    let gradient: CAGradientLayer = CAGradientLayer()
//                    gradient.frame = gradientView!.bounds
//                    gradient.colors = [UIColor.clearColor().CGColor, UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1).CGColor, UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1).CGColor]
//                    gradient.startPoint = CGPoint(x: 0, y: 0.5)
//                    gradient.endPoint = CGPoint(x: 1, y: 0.5)
//                    gradientView!.layer.insertSublayer(gradient, atIndex: 0)
//                    backgroundImageViewWrapper.addSubview(gradientView!)
//                    backgroundImageViewWrapper.bringSubviewToFront(userNameLabel)
//                    backgroundImageViewWrapper.bringSubviewToFront(eventDescriptionLabel)
//                }

                let myLocation = CLLocation(latitude: BrowseEventsTableViewController.lastSavedLocation.latitude, longitude: BrowseEventsTableViewController.lastSavedLocation.longitude)
                let eventLocation = CLLocation(latitude: event.location.latitude, longitude: event.location.longitude)
                let formatter = MKDistanceFormatter()
                let mutableReplyIcon = NSMutableAttributedString()
                mutableReplyIcon.appendAttributedString(NSAttributedString(string: " \(event.responses.count)"))
                self.locationLabel.attributedText = mutableReplyIcon

                let mutableTimeAgo = NSMutableAttributedString()
                mutableTimeAgo.appendAttributedString(NSAttributedString(string: " \(SORelativeDateTransformer.registeredTransformer().transformedValue(event.eventDate)!)"))
                self.timeStampLabel.attributedText = mutableTimeAgo
                self.eventDescriptionLabel.attributedText = event.attributedEventDescription()

                if event.eventDate.isEarlierThanDate(NSDate()) {
                    self.userNameLabel.text = "ENDED"
                    self.userNameLabel.textColor = UIColor.whiteColor()
                } else {
                    self.userNameLabel.text = "ACTIVE"
                    self.userNameLabel.textColor = UIColor(netHex: 0x1098F7)
                }

                self.backgroundImageView.image = event.placeholderImage
            }
        }
    }

    // MARK: Auxiliary Methods

    func setCount() {
        //print("!")
        if let event = event {
            self.counterButtonView.setCount(event.unreadResponseCount, withFontSize: 16)
            //print("RESPONSES", event.unreadResponseCount)
            if event.unreadResponseCount == 0 {
                self.counterButtonView.hidden = true
            } else {
                self.counterButtonView.hidden = false
            }
        }
    }

    @IBAction func moreButtonTapped(sender: AnyObject) {
        moreActionTapped()
    }
}
