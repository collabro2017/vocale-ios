//
//  GeoFenceViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 5/8/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import Foundation
import CoreLocation

class GeoFenceViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var inviteFriendsButton: UIButton!
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    var updatedLocation = false
    let locationManager = CLLocationManager()
    @IBOutlet weak var tapHereButton: UIButton!
    @IBOutlet weak var warningLabel: UILabel!
    var fromSettings: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
        
        let underlineAttribute = [NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue]
        let underlineAttributedString = NSAttributedString(string: "TAP HERE", attributes: underlineAttribute)
        tapHereButton.setAttributedTitle(underlineAttributedString, forState: .Normal)
    }
    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
//    }
//    
//    override func viewDidAppear(animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
//        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
//    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .NotDetermined, .Restricted, .Denied:
                //show settings link
                self.tapHereButton.hidden = false
                self.warningLabel.hidden = false
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                self.tapHereButton.hidden = true
                self.warningLabel.hidden = true
                locationManager.delegate = self
                if let location = locationManager.location {
                    checkIfInRegion()
                } else {
                    locationManager.delegate = self
                }
            }
        } else {
            //show settings link
            self.tapHereButton.hidden = false
            self.warningLabel.hidden = false
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GeoFenceViewController.locationCheck) , name: UIApplicationDidBecomeActiveNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func locationCheck() {
        if CLLocationManager.locationServicesEnabled() {
            switch(CLLocationManager.authorizationStatus()) {
            case .NotDetermined, .Restricted, .Denied:
                //show settings link
                self.tapHereButton.hidden = false
                self.warningLabel.hidden = false
            case .AuthorizedAlways, .AuthorizedWhenInUse:
                self.tapHereButton.hidden = true
                self.warningLabel.hidden = true
                locationManager.delegate = self
                if let location = locationManager.location {
                    self.fromSettings = true
                    checkIfInRegion()
                } else {
                    locationManager.delegate = self
                }
            }
        } else {
            //show settings link
            self.tapHereButton.hidden = false
            self.warningLabel.hidden = false
        }
    }
    
    func checkIfInRegion() {
        GeoFenceManager.sharedInstance.userLocation = locationManager.location
        GeoFenceManager.sharedInstance.geoLocationCheck({ (inRange) in
            if self.fromSettings == true {
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    //MARK: IBActions
    @IBAction func inviteFriendsButtonTapped(sender: UIButton) {
        let textToShare = "Check out Vocale - The hot new app that lets you have new experiences and meet new people, right now. It's pretty awesome!"
        
        if let myWebsite = NSURL(string: "http://www.vocale.io/") {
            let objectsToShare = [textToShare, myWebsite]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            
            activityVC.excludedActivityTypes = [UIActivityTypeAirDrop,
                                                UIActivityTypePrint,
                                                UIActivityTypeAssignToContact,
                                                UIActivityTypeSaveToCameraRoll,
                                                UIActivityTypeAddToReadingList,
                                                UIActivityTypePostToVimeo]
            
            activityVC.popoverPresentationController?.sourceView = sender
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func logoutButtonTapped(sender: UIBarButtonItem) {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    
    @IBAction func tapHereButtonTapped(sender: UIButton) {
        AppManager.sharedInstance.openSettings()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !updatedLocation {
            updatedLocation = true
            checkIfInRegion()
        }
    }
    
}
