 //
//  BrowseEventsTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/27.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import AVFoundation
import CoreLocation
import LayerKit
import MapKit
import UIKit

class BrowseEventsTableViewController: UITableViewController, CLLocationManagerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UIGestureRecognizerDelegate, EventCellManagerDelegate, FilterDelegate, UINavigationControllerDelegate, SavedPostDelegate, StateAnimationDelegate {
    
    enum StateType {
        case Loading
        case NoPosts
        case Searching
    }
    
    var stateType = StateType.Loading
    var animationFinished = false
    var reloadNeeded = false
    var allEvents = [Event]()
    var loadingStarted = false

    static var lastSavedLocation = PFGeoPoint()
    var locationAcquired = false

    var nextShown: Bool?
    var loginShown = false
    var createdPostTapped = false
    var permissionAsked = false
    var messagesButtonItem: CounterButtonView?
    var postsButtonItem: CounterButtonView?
    var searchConstraintsButton: UIButton?
    var voiceNoteRecorder: VoiceNoteRecorder?
    var events = [Event]()
    var selectedEvent = Event()
    var hasQueried = false
    var filterButton: UIButton?
    var backToBrowseButton: UIButton?
    var browseControllerTab: NoPostsTableViewCell.BrowseType = .All
    var recording = false
    var recordingView: UILabel?
    var pushedPosts = false
    var pushedChats = false
    var toChatScreen = false
    var toFilterScreen = false
    var interactionView: UIView?
    var tutorialViewTapGesture: UITapGestureRecognizer?
    var tooltipPosts: UIView?
    var postsLine: UIImageView?
    var tooltipChats: UIView?
    var chatsLine: UIImageView?
    var tooltipAddNew: UIView?
    var addNewLine: UIImageView?
    var tooltipFilter: UIView?
    var filterLine: UIImageView?
    var tooltipMenu: UIView?
    var menuLine: UIView?
    var tooltipSearch: UIView?
    var searchLine: UIImageView?
    var tooltipSavedPosts: UIView?
    var savedPostsLine: UIImageView?
    var tutorialSteps = 0
    var blackOverlay: UIView?
    var selectedSavedPostIndexPath: NSIndexPath?
    
    var noPostCellShown = false;
    private var pScope = PermissionScope()
    private var tableHeaderView: TabbedTableHeaderView?
    private var locationManager = CLLocationManager()
    private var shouldFetch = true
    private var shouldQuery = true
    private var query: PFQuery?
    private var queryIsBusy = false {
        didSet {
            tableHeaderView?.disabled = queryIsBusy
        }
    }
    private var extraQueryConstraints: (query: PFQuery?) -> Void = {_ in }
    private var activityIndicatorView = DGActivityIndicatorView(type: .BallClipRotatePulse, tintColor: UIColor.vocaleRedColor(), size: 140)
    private var topCell: EventCardTableViewCell? {
        willSet {
            topCell?.isFocusedCell = false
        }
        didSet {
            topCell?.isFocusedCell = true
        }
    }

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        //self.navigationController?.delegate = self
        
        self.navigationController?.toolbarHidden = false
        self.navigationController?.toolbar.frame = CGRectMake(0, self.navigationController!.view.frame.height-40, self.view.frame.width, 40)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleHeaderBackgroundGreyColor()
        self.navigationController?.toolbar.translucent = false
        self.navigationController?.toolbar.opaque = false

        locationManager.delegate = self

        if (AppDelegate.quickSearchActionWasSelected) {
            AppDelegate.quickSearchActionWasSelected = false
            searchTapped()
        } else {
            if let savedLocation = PFUser.currentUser()?.objectForKey("lastLocation") as? PFGeoPoint {
                BrowseEventsTableViewController.lastSavedLocation = savedLocation
                
                queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
                shouldQuery = false
            } else {
                let savedLocation = PFGeoPoint()
                BrowseEventsTableViewController.lastSavedLocation = savedLocation
                queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
            }
            self.locationManager.requestLocation()
        }
        
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            delegate.firstPostCreation = false
        }

        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self

        tableHeaderView = TabbedTableHeaderView(frame: CGRectMake(0,0, tableView.frame.width, 40), tabTitles: ["ALL", "TODAY", "SAVED"]) { (selectedTabIndex) -> Void in
            switch selectedTabIndex {
            case 0:
                self.showAllEvents()
                self.hasQueried = false
                //state animation changes
//                self.filterButton?.hidden = true
//                if let _ = self.filterButton {
//                    self.filterButton?.hidden = false
//                }
                //-----
                if let _ = self.searchConstraintsButton {
                    if self.events.count != 0 {
                        self.searchConstraintsButton?.hidden = false
                    }
                }
            case 1: self.showTodayEvents()
            self.hasQueried = false
                //state animation changes
                //self.filterButton?.hidden = true
                //------
            default: self.showSavedEvents()
            self.filterButton?.hidden = true
            self.searchConstraintsButton?.hidden = true
            }
        }
        
        self.browseControllerTab = .All

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: #selector(BrowseEventsTableViewController.searchTapped))
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BrowseEventsTableViewController.searchTapped), name: "QuickActionSearchTapped", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(updateMessageCounter), name: "NewPushMessageNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(reportedUser), name: "ReportedUserNotification", object: nil)

        //askForPermissions()
        self.tutorialSteps = 0
    }
    
    func reportedUser() {
        var banUsers = [String]()
        let userQuery = PFQuery(className: "BlockedUsers")
        if let currentUser = PFUser.currentUser() {
            userQuery.whereKey("userId", equalTo: currentUser.objectId!)
        }
        userQuery.getFirstObjectInBackgroundWithBlock {
            (object: PFObject?, error: NSError?) -> Void in
            if error == nil {
                if let user = object {
                    if let blockedUsers = user["blockedUsers"] as? [PFUser] {
                        for blockUser in blockedUsers {
                            banUsers.append(blockUser.objectId!)
                        }
                    }
                }
                NSUserDefaults.standardUserDefaults().setObject(banUsers, forKey: "BanUsers")
                NSUserDefaults.standardUserDefaults().synchronize()
                //self.showAllEvents()
                
            } else {
                //print("Error: \(error!) \(error!.userInfo)")
            }
        }
    }
    
    func tutorialViewTapped() {
        self.tutorialSteps = self.tutorialSteps + 1
        if self.tutorialSteps == 1 {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "FirstLogin")
            NSUserDefaults.standardUserDefaults().synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName("TutorialViewTappedFirstTime", object: self)
            UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: {
                self.topCell?.eventCardManager?.line1?.alpha = 0
                self.topCell?.eventCardManager?.line2?.alpha = 0
                self.topCell?.eventCardManager?.line3?.alpha = 0
            }) { (finished) in
                UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
                    self.topCell?.eventCardManager?.toolTip1?.transform = CGAffineTransformMakeTranslation(0, 40)
                    self.topCell?.eventCardManager?.toolTip1?.alpha = 0
                    self.topCell?.eventCardManager?.toolTip2?.transform = CGAffineTransformMakeTranslation(0, 40)
                    self.topCell?.eventCardManager?.toolTip2?.alpha = 0
                    self.topCell?.eventCardManager?.toolTip3?.transform = CGAffineTransformMakeTranslation(0, 40)
                    self.topCell?.eventCardManager?.toolTip3?.alpha = 0
                }) { (finished) in
                    self.addPostsTooltip()
                }
            }

        } else if self.tutorialSteps == 2 {
            self.interactionView?.userInteractionEnabled = false
            UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: {
                self.postsLine?.alpha = 0
            }) { (finished) in
                UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
                    self.tooltipPosts?.alpha = 0
                    self.tooltipPosts?.transform = CGAffineTransformMakeTranslation(0, 40)
                }) { (finished) in
                    self.interactionView?.userInteractionEnabled = true
                    self.tooltipPosts?.removeFromSuperview()
                    self.addChatsTooltip()
                }
            }

        } else if self.tutorialSteps == 3 {
            self.interactionView?.userInteractionEnabled = false
            UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: {
                self.chatsLine?.alpha = 0
            }) { (finished) in
                UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: {
                    self.tooltipChats?.alpha = 0
                    self.tooltipChats?.transform = CGAffineTransformMakeTranslation(0, 40)
                }) { (finished) in
                    self.interactionView?.userInteractionEnabled = true
                    self.tooltipChats?.removeFromSuperview()
                    self.addLastTooltips()
                }
            }

        } else {
            self.interactionView?.userInteractionEnabled = false
            UIView.animateWithDuration(0.15, delay: 0.0, options: .CurveEaseInOut, animations: {
                self.addNewLine?.alpha = 0
                self.filterLine?.alpha = 0
                self.menuLine?.alpha = 0
                self.searchLine?.alpha = 0
            }) { (finished) in
                UIView.animateWithDuration(0.4, delay: 0.0, options: .CurveEaseInOut, animations: {
                    self.tooltipAddNew?.alpha = 0
                    self.tooltipAddNew?.transform = CGAffineTransformMakeTranslation(0, 40)
                    self.tooltipFilter?.alpha = 0
                    self.tooltipFilter?.transform = CGAffineTransformMakeTranslation(0, 40)
                    self.tooltipSearch?.alpha = 0
                    self.tooltipSearch?.transform = CGAffineTransformMakeTranslation(0, -40)
                    self.tooltipMenu?.alpha = 0
                    self.tooltipMenu?.transform = CGAffineTransformMakeTranslation(0, -40)
                }) { (finished) in
                    self.tooltipAddNew?.removeFromSuperview()
                    self.tooltipFilter?.removeFromSuperview()
                    self.tooltipMenu?.removeFromSuperview()
                    self.tooltipSearch?.removeFromSuperview()
                    self.interactionView?.userInteractionEnabled = true
                    self.interactionView?.removeFromSuperview()
                }
            }
        }
    }
    
    func addPostsTooltip() {
        let tooltip1 = UIView(frame:  CGRectMake(20, (self.navigationController?.view.bounds.size.height)! - 245, 190, 245))
        tooltip1.backgroundColor = UIColor.clearColor()
        tooltipPosts = tooltip1
        let messageView1 = UIView(frame: CGRectMake(0,0,tooltip1.frame.size.width, 95))
        messageView1.backgroundColor = UIColor(netHex: 0x211E23)
        messageView1.layer.cornerRadius = 4
        messageView1.layer.borderWidth = 1
        messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView1.clipsToBounds = true
        tooltip1.addSubview(messageView1)
        let line1 = UIImageView(frame: CGRectMake(8, 100, 2, tooltip1.frame.size.height - 100 - 40))
        //line1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        line1.image = UIImage(named: "dottedLine")
        line1.contentMode = .Top
        line1.clipsToBounds = true
        self.postsLine = line1
        tooltip1.addSubview(line1)
        let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel1.textAlignment = .Center
        titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel1.textColor = UIColor(netHex: 0x211E23)
        titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel1.text = "POSTS"
        messageView1.addSubview(titleLabel1)
        let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
        messageLabel1.numberOfLines = 5
        messageLabel1.textAlignment = .Center
        messageLabel1.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel1.backgroundColor = UIColor(netHex: 0x1098F7)
        messageLabel1.text = "Manage your posts and responses and select who you want to chat with."
//        let messageText1 = "This is the Posts Section. It’s\nwhere you manage your\nposts and responses and\nchoose who you want to\nhave full chats with."
//        let range = (messageText1 as NSString).rangeOfString("Posts Section")
//        let attributedString = NSMutableAttributedString(string:messageText1)
//        attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 14)!, NSForegroundColorAttributeName: UIColor(netHex: 0x86B155)], range: range)
//        messageLabel1.attributedText = attributedString
        messageView1.addSubview(messageLabel1)
        self.interactionView?.addSubview(tooltipPosts!)
        
        tooltipPosts?.alpha = 0
        line1.alpha = 0
        tooltipPosts?.transform = CGAffineTransformMakeTranslation(0, 40)
        self.interactionView?.userInteractionEnabled = false
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
            self.tooltipPosts?.alpha = 1
            self.tooltipPosts?.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (finished) in
        
        }
        UIView.animateWithDuration(0.45, delay: 0, options: .CurveEaseInOut, animations: {
            line1.alpha = 1
        }) { (finished) in
            self.interactionView?.userInteractionEnabled = true
        }
    }
    
    func addChatsTooltip() {
        let tooltip1 = UIView(frame:  CGRectMake((self.navigationController?.view.bounds.size.width)! - 190 - 15, (self.navigationController?.view.bounds.size.height)! - 230, 190, 230))
        tooltip1.backgroundColor = UIColor.clearColor()
        tooltipChats = tooltip1
        let messageView1 = UIView(frame: CGRectMake(0,0,tooltip1.frame.size.width, 80))
        messageView1.backgroundColor = UIColor(netHex: 0x211E23)
        messageView1.layer.cornerRadius = 4
        messageView1.layer.borderWidth = 1
        messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView1.clipsToBounds = true
        tooltip1.addSubview(messageView1)
        let line1 = UIImageView(frame: CGRectMake(tooltip1.frame.size.width - 14, 85, 2, tooltip1.frame.size.height - 85 - 40))
        //line1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        line1.image = UIImage(named: "dottedLine")
        line1.contentMode = .Top
        line1.clipsToBounds = true
        self.chatsLine = line1
        tooltip1.addSubview(line1)
        
        let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel1.textAlignment = .Center
        titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel1.textColor = UIColor(netHex: 0x211E23)
        titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel1.text = "CHATS"
        messageView1.addSubview(titleLabel1)
        
        let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
        messageLabel1.numberOfLines = 4
        messageLabel1.textAlignment = .Center
        messageLabel1.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel1.backgroundColor = UIColor(netHex: 0x1098F7)
        messageLabel1.text = "Have full conversations\nwith people you have selected."
        
//        let messageText1 = "This is the Chats Section. It’s\nwhere you have full chats\nwith the people you have\nchosen."
//        let range = (messageText1 as NSString).rangeOfString("Chats Section")
//        let attributedString = NSMutableAttributedString(string:messageText1)
//        attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 14)!, NSForegroundColorAttributeName: UIColor(netHex: 0x1098F7)], range: range)
//        messageLabel1.attributedText = attributedString
        messageView1.addSubview(messageLabel1)
        self.interactionView?.addSubview(tooltipChats!)
        
        tooltipChats?.alpha = 0
        tooltipChats?.transform = CGAffineTransformMakeTranslation(0, 40)
        line1.alpha = 0
        self.interactionView?.userInteractionEnabled = false
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.tooltipChats?.alpha = 1
            self.tooltipChats?.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (finished) in
            self.interactionView?.userInteractionEnabled = true
        }
        
        UIView.animateWithDuration(0.45, delay: 0.0, options: .CurveEaseInOut, animations: {
            line1.alpha = 1
        }) { (finished) in
            self.interactionView?.userInteractionEnabled = true
        }
    }
    
    func addLastTooltips() {
        let tooltip1 = UIView(frame:  CGRectMake((self.navigationController?.view.bounds.size.width)!/2 - 75, (self.navigationController?.view.bounds.size.height)! - 150, 150, 150))
        tooltip1.backgroundColor = UIColor.clearColor()
        tooltipAddNew = tooltip1
        let messageView1 = UIView(frame: CGRectMake(0,0,tooltip1.frame.size.width, 70))
        messageView1.backgroundColor = UIColor(netHex: 0x211E23)
        messageView1.layer.cornerRadius = 4
        messageView1.layer.borderWidth = 1
        messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView1.clipsToBounds = true
        tooltip1.addSubview(messageView1)
        let line1 = UIImageView(frame: CGRectMake((tooltip1.frame.size.width - 2)/2, 75, 2, tooltip1.frame.size.height - 70 - 40))
        //line1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        line1.image = UIImage(named: "dottedLine")
        line1.contentMode = .Top
        line1.clipsToBounds = true
        self.addNewLine = line1
        tooltip1.addSubview(line1)
        
        let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel1.textAlignment = .Center
        titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel1.textColor = UIColor(netHex: 0x211E23)
        titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel1.text = "CREATE"
        messageView1.addSubview(titleLabel1)
        let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
        messageLabel1.numberOfLines = 2
        messageLabel1.textAlignment = .Center
        messageLabel1.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel1.backgroundColor = UIColor(netHex: 0xFB4B4E)
        let messageText1 = "Create a new post at anytime"
        messageLabel1.text = messageText1
        messageView1.addSubview(messageLabel1)
        self.interactionView?.addSubview(tooltipAddNew!)
        let tooltip2 = UIView(frame:  CGRectMake((self.navigationController?.view.bounds.size.width)! - 8 - 140, (self.filterButton?.frame.origin.y)! - 35 - 80, 140, 130))
        tooltip2.backgroundColor = UIColor.clearColor()
        tooltipFilter = tooltip2
        let messageView2 = UIView(frame: CGRectMake(0,0,tooltip2.frame.size.width, 70))
        messageView2.backgroundColor = UIColor(netHex: 0x211E23)
        messageView2.layer.cornerRadius = 4
        messageView2.layer.borderWidth = 1
        messageView2.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView2.clipsToBounds = true
        tooltip2.addSubview(messageView2)
        let line2 = UIImageView(frame: CGRectMake(tooltip2.frame.size.width - 23 + 8, 75, 2, tooltip2.frame.size.height - 95))
        //line2.backgroundColor = UIColor(netHex: 0xEEEEEE)
        line2.image = UIImage(named: "dottedLine")
        line2.contentMode = .Top
        line2.clipsToBounds = true
        self.filterLine = line2
        tooltip2.addSubview(line2)
        let titleLabel2 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel2.textAlignment = .Center
        titleLabel2.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel2.textColor = UIColor(netHex: 0x211E23)
        titleLabel2.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel2.text = "FILTERS"
        messageView2.addSubview(titleLabel2)
        let messageLabel2 = UILabel(frame: CGRectMake(0, 20, messageView2.frame.size.width, messageView2.frame.size.height - 20))
        messageLabel2.numberOfLines = 2
        messageLabel2.textAlignment = .Center
        messageLabel2.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel2.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel2.backgroundColor = UIColor(netHex: 0x1098F7)
        let messageText2 = "Choose what posts you see"
        messageLabel2.text = messageText2
        messageView2.addSubview(messageLabel2)
        if self.events.count != 0 {
            //self.interactionView?.addSubview(tooltipFilter!)
        }
        
        let tooltip3 = UIView(frame:  CGRectMake(8, 0, 140, 210))
        tooltip3.backgroundColor = UIColor.clearColor()
        tooltipMenu = tooltip3
        let messageView3 = UIView(frame: CGRectMake(0,140,tooltip3.frame.size.width, 70))
        messageView3.backgroundColor = UIColor(netHex: 0x211E23)
        messageView3.layer.cornerRadius = 4
        messageView3.layer.borderWidth = 1
        messageView3.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView3.clipsToBounds = true
        tooltip3.addSubview(messageView3)
        let line3 = UIImageView(frame: CGRectMake(12, 55, 2, tooltip3.frame.size.height - 60 - 70))
        //line3.backgroundColor = UIColor(netHex: 0xEEEEEE)
        line3.contentMode = .Top
        line3.image = UIImage(named: "dottedLine")
        line3.clipsToBounds = true
        self.menuLine = line3
        tooltip3.addSubview(line3)
        let titleLabel3 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel3.textAlignment = .Center
        titleLabel3.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel3.textColor = UIColor(netHex: 0x211E23)
        titleLabel3.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel3.text = "MENU"
        messageView3.addSubview(titleLabel3)
        let messageLabel3 = UILabel(frame: CGRectMake(0, 20, messageView3.frame.size.width, messageView3.frame.size.height-20))
        messageLabel3.numberOfLines = 2
        messageLabel3.textAlignment = .Center
        messageLabel3.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel3.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel3.backgroundColor = UIColor(netHex: 0x1098F7)
        let messageText3 = "Edit profile, help and contact details"
        messageLabel3.text = messageText3
        messageView3.addSubview(messageLabel3)
        self.interactionView?.addSubview(tooltipMenu!)
        
        let tooltip4 = UIView(frame:  CGRectMake((self.navigationController?.view.bounds.size.width)! - 8 - 140, 0, 140, 220))
        tooltip4.backgroundColor = UIColor.clearColor()
        tooltipSearch = tooltip4
        let messageView4 = UIView(frame: CGRectMake(0, 140, tooltip4.frame.size.width, 70))
        messageView4.backgroundColor = UIColor(netHex: 0x211E23)
        messageView4.layer.cornerRadius = 4
        messageView4.layer.borderWidth = 1
        messageView4.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView4.clipsToBounds = true
        tooltip4.addSubview(messageView4)
        let line4 = UIImageView(frame: CGRectMake(tooltip4.frame.size.width - 23 + 8, 58, 2, tooltip4.frame.size.height - 65 - 70))
        line4.contentMode = .Top
        //line4.backgroundColor = UIColor(netHex: 0xEEEEEE)
        line4.image = UIImage(named: "dottedLine")
        line4.clipsToBounds = true
        searchLine = line4
        tooltip4.addSubview(line4)
        let titleLabel4 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel4.textAlignment = .Center
        titleLabel4.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel4.textColor = UIColor(netHex: 0x211E23)
        titleLabel4.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel4.text = "SEARCH"
        messageView4.addSubview(titleLabel4)
        let messageLabel4 = UILabel(frame: CGRectMake(0, 20, messageView4.frame.size.width, messageView4.frame.size.height - 20))
        messageLabel4.numberOfLines = 2
        messageLabel4.textAlignment = .Center
        messageLabel4.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel4.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel4.backgroundColor = UIColor(netHex: 0x1098F7)
        let messageText4 = "Search for specific things e.g. #hiking"
        messageLabel4.text = messageText4
        messageView4.addSubview(messageLabel4)
        self.interactionView?.addSubview(tooltipSearch!)
        
        tooltipAddNew?.alpha = 0
        tooltipAddNew?.transform = CGAffineTransformMakeTranslation(0, 40)
        tooltipFilter?.alpha = 0
        tooltipFilter?.transform = CGAffineTransformMakeTranslation(0, 40)
        tooltipMenu?.alpha = 0
        tooltipMenu?.transform = CGAffineTransformMakeTranslation(0, -40)
        tooltipSearch?.alpha = 0
        tooltipSearch?.transform = CGAffineTransformMakeTranslation(0, -40)
        line1.alpha = 0
        line2.alpha = 0
        line3.alpha = 0
        line4.alpha = 0
        self.interactionView?.userInteractionEnabled = false
        UIView.animateWithDuration(0.3, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.tooltipAddNew?.alpha = 1
            self.tooltipFilter?.alpha = 1
            self.tooltipMenu?.alpha = 1
            self.tooltipSearch?.alpha = 1
            self.tooltipAddNew?.transform = CGAffineTransformMakeTranslation(0, 0)
            self.tooltipFilter?.transform = CGAffineTransformMakeTranslation(0, 0)
            self.tooltipMenu?.transform = CGAffineTransformMakeTranslation(0, 0)
            self.tooltipSearch?.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (finished) in

        }
        UIView.animateWithDuration(0.45, delay: 0.0, options: .CurveEaseInOut, animations: {
            line1.alpha = 1
            line2.alpha = 1
            line3.alpha = 1
            line4.alpha = 1
        }) { (finished) in
            self.interactionView?.userInteractionEnabled = true
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func viewWillAppear(animated: Bool) {

        let cells = tableView.visibleCells
        if let cell = cells.last {
            if let indexPath = tableView.indexPathForCell(cell) {
                dispatch_async(dispatch_get_main_queue(), { 
                    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
                })
            }
        }
        
        var banUsers = [String]()
        let userQuery = PFQuery(className: "BlockedUsers")
        if let currentUser = PFUser.currentUser() {
            if let objectId = currentUser.objectId {
                userQuery.whereKey("userId", equalTo: objectId)
                userQuery.getFirstObjectInBackgroundWithBlock {
                    (object: PFObject?, error: NSError?) -> Void in
                    if error == nil {
                        if let user = object {
                            if let blockedUsers = user["blockedUsers"] as? [PFUser] {
                                for blockUser in blockedUsers {
                                    banUsers.append(blockUser.objectId!)
                                }
                            }
                        }
                        NSUserDefaults.standardUserDefaults().setObject(banUsers, forKey: "BanUsers")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                    } else {
                        //print("Error: \(error!) \(error!.userInfo)")
                    }
                }
            }
        }
        
        navigationController?.toolbar.barTintColor = UIColor(netHex: 0x333134)
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.None)
        
        if NSUserDefaults.standardUserDefaults().boolForKey("FirstLogin") == false {
            self.animationFinished = false
            self.stateType = .Loading
            self.events = [Event]()
            self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
        }
        
        //State animation changes
        //if noPostCellShown == false && toChatScreen == true {
            self.tableView.reloadData()
        //}
        
        if (self.blackOverlay == nil) {
            self.blackOverlay = UIView(frame: (self.navigationController?.view.frame)!)
            self.blackOverlay?.backgroundColor = UIColor.vocaleBackgroundGreyColor()
            self.navigationController?.view.addSubview(self.blackOverlay!)
        }
        
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            self.navigationItem.leftBarButtonItem?.enabled = false
            if let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as? UINavigationController {
                self.presentViewController(loginVC, animated: false, completion: nil)
                self.locationAcquired = false
                self.loginShown = true
                self.nextShown = false
            }
        } else if (NSUserDefaults.standardUserDefaults().boolForKey("GeoFenceActivated") == true) {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "FirstLogin")
            self.navigationItem.leftBarButtonItem?.enabled = false
            if let loginVC = self.storyboard?.instantiateViewControllerWithIdentifier("LoginVC") as? UINavigationController {
                self.presentViewController(loginVC, animated: false, completion: nil)
                self.locationAcquired = false
                self.loginShown = true
                self.nextShown = false
            }
        } else if let button = self.navigationItem.leftBarButtonItem where button.enabled == false {
            self.navigationItem.leftBarButtonItem?.enabled = true
            self.loginShown = false
            self.blackOverlay?.removeFromSuperview()
            self.blackOverlay = nil
        } else {
            self.loginShown = false
            self.blackOverlay?.removeFromSuperview()
            self.blackOverlay = nil
        }
        
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            
        } else {
            if let user = PFUser.currentUser() {
                //do {
                    PFUser.currentUser()!.fetchInBackground()
//                } catch {
//                }
                if let banned = user["banned"] as? Bool {
                    if banned == true {
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "FirstLogin")
                        if let banVC = self.storyboard?.instantiateViewControllerWithIdentifier("BanVC") {
                            self.presentViewController(banVC, animated: false, completion: nil)
                        }
                    }
                }
            }
            
            //NSUserDefaults.standardUserDefaults().setBool(false, forKey: "FirstLogin")
            if NSUserDefaults.standardUserDefaults().boolForKey("FirstLogin") == false {
                self.interactionView = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height))
                self.interactionView?.backgroundColor = UIColor.clearColor()
                let window = UIApplication.sharedApplication().keyWindow!
                window.addSubview(self.interactionView!)
                
                self.browseControllerTab = .All
                //self.showAllEvents()
                self.tutorialSteps = 0
                self.tutorialViewTapGesture = UITapGestureRecognizer(target: self, action: "tutorialViewTapped")
                self.interactionView?.addGestureRecognizer(self.tutorialViewTapGesture!)
            }
            
            //if permissionAsked == false {
                //askForPermissions()
                let userNotificationTypes = UIUserNotificationType.Alert.union(UIUserNotificationType.Badge).union(UIUserNotificationType.Sound).union(UIUserNotificationType.Alert)
                let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
                UIApplication.sharedApplication().registerUserNotificationSettings(settings)
                UIApplication.sharedApplication().registerForRemoteNotifications()
//                permissionAsked = true
            //}
            if var events = PFUser.currentUser()?["savedEvents"] as? [Event] {
                for event in events {
                    event.fetchIfNeededInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
                        if let error = error {
                            if error.code == 101 {
                                PFUser.currentUser()?.removeObject(event, forKey: "savedEvents")
                                PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                                    if let error = error {
                                        //ErrorManager.handleError(error)
                                    } else {
                                        self.tableHeaderView?.decrementNumberOfItemsInTab(2)
                                    }
                                })
                            }
                        } else {
                            if event.eventDate.isEarlierThanDate(NSDate()) {
                                PFUser.currentUser()?.removeObject(event, forKey: "savedEvents")
                                PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                                    if let error = error {
                                        //ErrorManager.handleError(error)
                                    } else {
                                        self.tableHeaderView?.decrementNumberOfItemsInTab(2)
                                    }
                                })
                            }
                        }
                    })
                }
            }
        }
        
        var y: CGFloat = 0;
        if let navigationController = navigationController {
            let height = navigationController.view.frame.height - navigationController.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - view.frame.width - 40
            y = navigationController.view.frame.height - height
        }
        
        if filterButton == nil {
            filterButton = UIButton()
            if self.view.frame.width <= 320 {
                filterButton?.setImage(UIImage(named:"newFilterIcon_small"), forState: .Normal)
                filterButton?.frame = CGRectMake(self.view.frame.width - 32, y, 32, 32)
            } else {
                filterButton?.setImage(UIImage(named:"newFilterIcon"), forState: .Normal)
                filterButton?.frame = CGRectMake(self.view.frame.width - 40, y, 40, 40)
            }
            //filterButton?.backgroundColor = UIColor.blueColor()
            filterButton?.addTarget(self, action: #selector(BrowseEventsTableViewController.filterTapped), forControlEvents: UIControlEvents.TouchUpInside)
            
            if let vc = self.navigationController?.topViewController as? BrowseEventsTableViewController {
                //navigationController?.view.addSubview(filterButton!)
            }
        }
        
        self.navigationController?.toolbarHidden = false

        Event.countBookmarkedObjectsWithCompletion { (count) -> Void in
            self.tableHeaderView?.setNumberOfItems(count, inTab: 2)
        }

        let postsButtonItem = CounterButtonView(frame: CGRect(x: 0, y: 0, width: 25, height: 25), posts: true)
        postsButtonItem.count = 0
        postsButtonItem.addTarget(self, action: #selector(BrowseEventsTableViewController.postsBarButtonItemTapped), forControlEvents: UIControlEvents.TouchUpInside)
        self.postsButtonItem = postsButtonItem

        let messagesButtonItem = CounterButtonView(frame: CGRect(x: 0, y: 0, width: 25, height: 25), posts: false)
        messagesButtonItem.count = 0
        messagesButtonItem.addTarget(self, action: #selector(BrowseEventsTableViewController.messagesBarButtonItemTapped), forControlEvents: .TouchUpInside)
        self.messagesButtonItem = messagesButtonItem

        let addPostButtonItem = CounterButtonView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        //addPostButtonItem.showsPlus = true
        addPostButtonItem.addTarget(self, action: #selector(BrowseEventsTableViewController.addPostBarButtonItemTapped), forControlEvents: .TouchUpInside)

        postsButtonItem.count = NSUserDefaults.standardUserDefaults().integerForKey("postCount")
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) == false {
            EventResponse.countUnreadObjectsWithCompletion { (count) -> Void in
                postsButtonItem.count = count
                NSUserDefaults.standardUserDefaults().setInteger(count, forKey: "postCount")
                
                let badgeCount = postsButtonItem.count + messagesButtonItem.count
                NSUserDefaults.standardUserDefaults().setInteger(badgeCount, forKey: "badgeCount")
                NSUserDefaults.standardUserDefaults().synchronize()
                if self.loginShown == true {
                    NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "badgeCount")
                }
                UIApplication.sharedApplication().applicationIconBadgeNumber = NSUserDefaults.standardUserDefaults().integerForKey("badgeCount")
            }
        }

        messagesButtonItem.count = UIApplication.sharedApplication().applicationIconBadgeNumber
        self.countUnreadMessagesWithCompletion { (count: Int) in
            messagesButtonItem.count = count
            
            let badgeCount = postsButtonItem.count + messagesButtonItem.count
            NSUserDefaults.standardUserDefaults().setInteger(badgeCount, forKey: "badgeCount")
            NSUserDefaults.standardUserDefaults().synchronize()
            if self.loginShown == true {
                NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "badgeCount")
            }
            UIApplication.sharedApplication().applicationIconBadgeNumber = NSUserDefaults.standardUserDefaults().integerForKey("badgeCount")
        }

        self.navigationController?.setToolbarHidden(false, animated: false)
        if (self.navigationController?.toolbar.items) != nil {
            let postsBarButtonItem = UIBarButtonItem(customView: postsButtonItem)
            let messagesBarButtonItem = UIBarButtonItem(customView: messagesButtonItem)
            let addPostBarButtonItem = UIBarButtonItem(image: UIImage(named: "plusBarButtonIcon"), style: .Plain, target: self, action: #selector(BrowseEventsTableViewController.addPostBarButtonItemTapped))
            addPostBarButtonItem.tintColor = UIColor(netHex: 0xEEEEEE)
            setToolbarItems([postsBarButtonItem, UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: Selector("")), addPostBarButtonItem, UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: ""), messagesBarButtonItem], animated: true)
        }
        if browseControllerTab == .Saved {
            showSavedEvents()
        }
        
        self.recordingView = UILabel()
        self.recordingView?.textColor = UIColor(netHex: 0xEEEEEE)
        self.recordingView?.textAlignment = NSTextAlignment.Center
        self.recordingView?.font = UIFont(name: "Raleway-Bold", size: 16)
        self.recordingView?.text = "REC"
        self.recordingView?.frame = CGRectMake(0, self.navigationController!.view.frame.height-44, self.view.frame.width, 44)
        self.recordingView?.backgroundColor = UIColor.whiteColor()
        self.navigationController?.view.addSubview(self.recordingView!)
        self.recordingView?.hidden = true
        
        if filterButton != nil && browseControllerTab != .Saved {
            filterButton?.alpha = 1
            filterButton?.hidden = false
        }
        
        if self.events.count == 0 {
            self.filterButton?.hidden = true
        }
        
        if locationAcquired == false {
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestLocation()
            locationAcquired = true
        }
        
        self.backToBrowseButton?.hidden = true
        
//        self.animationFinished = false
//        self.events = [Event]()
//        self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
    }

    override func viewDidAppear(animated: Bool) {
        //topCell?.showCardWithAnimation(true)
        if noPostCellShown == false && toChatScreen == false && toFilterScreen == false {
            //self.tableView.reloadData()
        }
        toChatScreen = false
        toFilterScreen = false
        
        UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            if let frame = self.navigationController?.toolbar.frame, let navFrame = self.navigationController?.view.frame {
                self.navigationController?.toolbar.frame = CGRectMake(0, navFrame.height-frame.height, frame.width, frame.height)
            }
//            if let searchButton = self.searchConstraintsButton {
//                //self.searchConstraintsButton?.frame = CGRectMake(6, searchButton.frame.origin.y, searchButton.frame.size.width, searchButton.frame.size.height)
//                searchButton.hidden = false
//                searchButton.transform = CGAffineTransformMakeTranslation(0, 0)
//            }
        }) { (completed: Bool) -> Void in
        }
        
        if let searchButton = self.searchConstraintsButton {
            searchButton.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0)
            //self.backToBrowseButton?.hidden = false
        }
        UIView.animateWithDuration(0.3, delay: 0.4, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            if let searchButton = self.searchConstraintsButton {
                if self.events.count != 0 {
                    searchButton.hidden = false
                }
                searchButton.transform = CGAffineTransformMakeTranslation(0, 0)
                if self.events.count == 0 {
                    self.filterButton?.hidden = true
                    self.backToBrowseButton?.hidden = false
                }
            }
        }) { (completed: Bool) -> Void in
        }
    }

    override func viewWillDisappear(animated: Bool) {
        print(filterButton)
        filterButton?.hidden = true
        backToBrowseButton?.hidden = true
        //topCell?.hideCardWithAnimation(true)
        tooltipSavedPosts?.removeFromSuperview()
        //self.navigationController?.setToolbarHidden(true, animated: false)
        //self.navigationController?.toolbar.hidden = true
//        UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
//            if let frame = self.navigationController?.toolbar.frame {
//                self.navigationController?.toolbar.frame = CGRectMake(frame.origin.x, frame.origin.y + frame.height, frame.width, frame.height)
//            }
//            }) { (completed: Bool) -> Void in
//        }
    }

    override func viewDidDisappear(animated: Bool) {
        SVProgressHUD.dismiss()
        pushedChats = false
        pushedPosts = false
//        UIView.animateWithDuration(0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
//            if let frame = self.navigationController?.toolbar.frame, let navFrame = self.navigationController?.view.frame {
//                self.navigationController?.toolbar.frame = CGRectMake(0, navFrame.height-frame.height, frame.width, frame.height)
//            }
//            }) { (completed: Bool) -> Void in
//        }
    }
    
    //MARK: Notifications
    func updateMessageCounter(notification: NSNotification) {
        if let _ = notification.userInfo!["layer"] as? [NSObject: AnyObject]{
            if (NSUserDefaults.standardUserDefaults().boolForKey("notificationSwitchChat") == true) {
                if let aps = notification.userInfo!["aps"] as? [NSObject: AnyObject] {
                    if let badge = aps["badge"] as? Int {
                        self.messagesButtonItem?.count = badge
                        let badgeCount = (self.postsButtonItem?.count)! + (self.messagesButtonItem?.count)!
                        NSUserDefaults.standardUserDefaults().setInteger(badgeCount, forKey: "badgeCount")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        UIApplication.sharedApplication().applicationIconBadgeNumber = NSUserDefaults.standardUserDefaults().integerForKey("badgeCount")
                    }
                }
            }
        } else {
            if (NSUserDefaults.standardUserDefaults().boolForKey("notificationSwitchResponses") == true) {
                EventResponse.countUnreadObjectsWithCompletion { (count) -> Void in
                    self.postsButtonItem?.count = count
                    NSUserDefaults.standardUserDefaults().setInteger(count, forKey: "postCount")
                    let badgeCount = (self.postsButtonItem?.count)! + (self.messagesButtonItem?.count)!
                    NSUserDefaults.standardUserDefaults().setInteger(badgeCount, forKey: "badgeCount")
                    NSUserDefaults.standardUserDefaults().synchronize()
                    UIApplication.sharedApplication().applicationIconBadgeNumber = NSUserDefaults.standardUserDefaults().integerForKey("badgeCount")
                }
            }
        }
    }

    // MARK: - Database Handling

    func queryEventsBy(location: PFGeoPoint, fromLocalDatastore: Bool) {
        if recording {
            return
        }
        
        let innerQuery = PFQuery(className: "PastEvent")
        if let currentUser = PFUser.currentUser() {
            if let objectId = currentUser.objectId {
                innerQuery.whereKey("user", equalTo: objectId)
            }
        }
        
        let query = Event.query()
        if fromLocalDatastore {
            query?.fromLocalDatastore()
        }
        if self.browseControllerTab == .Saved {
            query?.whereKey("isBookmarked", equalTo: true)
        }
        self.extraQueryConstraints(query: query)
        query?.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
        if let currentUser = PFUser.currentUser() {
            if let admin = currentUser["admin"] as? Bool {
                if admin == true {
                    query?.whereKey("location", nearGeoPoint: location, withinMiles: 1000000)
                } else {
                    query?.whereKey("objectId", doesNotMatchKey: "event", inQuery: innerQuery)
                    //query?.whereKey("location", nearGeoPoint: location, withinMiles: 200)
                }
            } else {
//                query?.whereKey("objectId", doesNotMatchKey: "event", inQuery: innerQuery)
                query?.whereKey("objectId", doesNotMatchKey: "event", inQuery: innerQuery)
                query?.whereKey("location", nearGeoPoint: location, withinMiles: 200)
            }
        }
        query?.limit = 100

        queryIsBusy = true
        query?.includeKey("owner")
        query?.includeKey("filterRequest")
        query?.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
            if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {

            } else {
                LoginViewController.performFBGraphRequestWithUser(PFUser.currentUser()!)
            }
            SVProgressHUD.dismiss()
            self.hasQueried = true
            self.queryIsBusy = false
            if error == nil {
                if let events = objects as? [Event] {
                    var list = [Event]()
                    //print(events)
                    for event in events {
                        if let filter = event["filterRequest"] as? PFObject {
                            
                            var years = false
                            var genderBool = false
                            
                            if let male = filter["allowMale"] as? Bool, let gender = PFUser.currentUser()!["gender"] as? String {
                                if gender == "male" && male == true {
                                    genderBool = true
                                }
                            }
                            
                            if let female = filter["allowFemale"] as? Bool, let gender = PFUser.currentUser()!["gender"] as? String {
                                if gender == "female" && female == true {
                                    genderBool = true
                                }
                            }
                            
                            if let lowerBound = filter["birthdateLowerBound"] as? Int, let birthday = PFUser.currentUser()!["birthdate"] as? NSDate {
                                let lowerDate = NSDate().dateByAddingYears(-lowerBound)
                                if birthday.compare(lowerDate) == .OrderedAscending {
                                    years = false
                                } else {
                                    years = true
                                }
                            }
                            
                            if let upperBound = filter["birthdateUpperBound"] as? Int, let birthday = PFUser.currentUser()!["birthdate"] as? NSDate {
                                let upperDate = birthday.dateByAddingYears(upperBound)
                                if NSDate().compare(upperDate) == .OrderedDescending {
                                    years = false
                                } else {
                                    years = true
                                }
                            }
                            
//                            if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//                                if let appliedFilter = delegate.appliedFilter {
//                                    
//                                    years = false
//                                    genderBool = false
//                                    
//                                    if let male = appliedFilter["allowMale"] as? Bool, let gender = event.owner["gender"] as? String {
//                                        if gender == "male" && male == true {
//                                            genderBool = true
//                                        }
//                                    }
//                                    
//                                    if let female = appliedFilter["allowFemale"] as? Bool, let gender = event.owner["gender"] as? String {
//                                        if gender == "female" && female == true {
//                                            genderBool = true
//                                        }
//                                    }
//                                    
//                                    if let anyone = appliedFilter["anyone"] as? Bool {
//                                        if anyone == true {
//                                            genderBool = true
//                                        }
//                                    }
//                                    
//                                    if let lowerBound = appliedFilter["birthdateLowerBound"] as? Int, let birthday = event.owner["birthdate"] as? NSDate {
//                                        let lowerDate = NSDate().dateByAddingYears(-lowerBound)
//                                        if birthday.compare(lowerDate) == .OrderedAscending {
//                                            years = true
//                                        } else {
//                                            years = false
//                                        }
//                                    }
//                                    
//                                    if let upperBound = appliedFilter["birthdateUpperBound"] as? Int, let birthday = event.owner["birthdate"] as? NSDate {
//                                        let upperDate = birthday.dateByAddingYears(upperBound)
//                                        if NSDate().compare(upperDate) == .OrderedDescending {
//                                            years = false
//                                        } else {
//                                            years = true
//                                        }
//                                    }
//                                }
//                            }
                            
                            if genderBool == true && years == true {
                                //list.append(event)
                                let user = event.owner
                                if let userID = user.objectId, savedUserID = NSUserDefaults.standardUserDefaults().objectForKey("currentUser") as? String{
                                    if let banUsersIds = NSUserDefaults.standardUserDefaults().objectForKey("BanUsers") as? [String] {
                                        var shouldInclude = true
                                        for banUserId in banUsersIds {
                                            if banUserId == userID {
                                                shouldInclude = false
                                            }
                                        }
                                        if userID != savedUserID && shouldInclude == true {
                                            list.append(event)
                                        }
                                    } else {
                                        if userID != savedUserID {
                                            list.append(event)
                                        }
                                    }

                                } else {
                                    list.append(event)
                                }
                            }
                            
                        } else {
                            
//                            if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//                                if let appliedFilter = delegate.appliedFilter {
//                                    
//                                    var years = false
//                                    var genderBool = false
//                                    
//                                    if let male = appliedFilter["allowMale"] as? Bool, let gender = event.owner["gender"] as? String {
//                                        if gender == "male" && male == true {
//                                            genderBool = true
//                                        }
//                                    }
//                                    
//                                    if let female = appliedFilter["allowFemale"] as? Bool, let gender = event.owner["gender"] as? String {
//                                        if gender == "female" && female == true {
//                                            genderBool = true
//                                        }
//                                    }
//                                    
//                                    if let anyone = appliedFilter["anyone"] as? Bool {
//                                        if anyone == true {
//                                            genderBool = true
//                                        }
//                                    }
//                                    
//                                    if let lowerBound = appliedFilter["birthdateLowerBound"] as? Int, let birthday = event.owner["birthdate"] as? NSDate {
//                                        let lowerDate = NSDate().dateByAddingYears(-lowerBound)
//                                        if birthday.compare(lowerDate) == .OrderedAscending {
//                                            years = false
//                                        } else {
//                                            years = true
//                                        }
//                                    }
//                                    
//                                    if let upperBound = appliedFilter["birthdateUpperBound"] as? Int, let birthday = event.owner["birthdate"] as? NSDate {
//                                        let upperDate = birthday.dateByAddingYears(upperBound)
//                                        if NSDate().compare(upperDate) == .OrderedDescending {
//                                            years = false
//                                        } else {
//                                            years = true
//                                        }
//                                    }
//                                    
//                                    if genderBool == true && years == true {
//                                        let user = event.owner
//                                        if let userID = user.objectId, savedUserID = NSUserDefaults.standardUserDefaults().objectForKey("currentUser") as? String {
//                                            if let banUsersIds = NSUserDefaults.standardUserDefaults().objectForKey("BanUsers") as? [String] {
//                                                var shouldInclude = true
//                                                for banUserId in banUsersIds {
//                                                    if banUserId == userID {
//                                                        shouldInclude = false
//                                                    }
//                                                }
//                                                if userID != savedUserID && shouldInclude == true {
//                                                    list.append(event)
//                                                }
//                                            } else {
//                                                if userID != savedUserID {
//                                                    list.append(event)
//                                                }
//                                            }
//                                        } else {
//                                            list.append(event)
//                                        }
//                                    }
//                                }
//                            } else {
                                let user = event.owner
                                if let userID = user.objectId, savedUserID = NSUserDefaults.standardUserDefaults().objectForKey("currentUser") as? String {
                                    if let banUsersIds = NSUserDefaults.standardUserDefaults().objectForKey("BanUsers") as? [String] {
                                        var shouldInclude = true
                                        for banUserId in banUsersIds {
                                            if banUserId == userID {
                                                shouldInclude = false
                                            }
                                        }
                                        if userID != savedUserID && shouldInclude == true {
                                            list.append(event)
                                        }
                                    } else {
                                        if userID != savedUserID {
                                            list.append(event)
                                        }
                                    }
                                } else {
                                    list.append(event)
                                }
                            //}
                        }
                    }
                    
                    self.query = query
                    self.events = list
                    if let currentUser = PFUser.currentUser() {
                        if let admin = currentUser["admin"] as? Bool {
                            if admin == true {
                                self.events = events
                            }
                        } else {
                            //self.events = events
                        }
                    }
//                    if let currentUser = PFUser.currentUser(), let admin = currentUser["admin"] as? Bool where admin == true {
//                        self.events = events
//                    }

                    if self.animationFinished == false {
                        print("QUERY - animationFinished - false")
                        self.reloadNeeded = true
                        if self.stateType == .Searching {
                            if self.events.count == 0 {
                                self.stateType = .NoPosts
                            }
                            self.tableView.reloadData()
                        }
                    } else {
                        print("QUERY - animationFinished - true")
                        self.reloadNeeded = true
                        self.loadingAnimationFinished()
                        //self.tableView.reloadData()
                    }

                    //state animation changes
//                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
//                    if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
//                        self.topCell = topCell
//
//                        self.topCell?.presentCardWithAnimation()
//                        if self.browseControllerTab == .All {
//                            self.filterButton?.alpha = 1
//                            self.filterButton?.hidden = false
//                        }
//                    }
                    //-----
                    if events.count < query?.limit {
                        self.shouldFetch = false
                    } else {
                        self.shouldFetch = true
                    }
                }
            } else {
                //ErrorManager.handleError(error)
            }
        })
    }

    func addEventsFromQuery(query: PFQuery?) {
        if recording {
            return
        }
        
        if (events.count > 0) {
            query?.skip = events.count
            queryIsBusy = true
            query?.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
                self.queryIsBusy = false
                if error == nil {
                    if let events = objects as? [Event] {
                        let lastCell = self.events.removeLast()
                        self.events.appendContentsOf(events)
                        self.events.append(lastCell)
                        self.tableView.reloadData()
                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
                        if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
                            self.topCell = topCell
                            self.topCell?.presentCardWithAnimation()
                        }
                        if events.count < query?.limit {
                            self.shouldFetch = false
                        } else {
                            self.shouldFetch = true
                        }
                    }
                } else {
                    //ErrorManager.handleError(error)
                }
            })
        }
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if browseControllerTab == .Saved {
            if events.count > 0 {
                return events.count
            } else {
                return 1
            }
        }
        
        var y: CGFloat = 0;
        if let navigationController = navigationController {
            let height = navigationController.view.frame.height - navigationController.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - view.frame.width - 40
            y = navigationController.view.frame.height - height
        }
        if events.count == 0 {
            if self.searchConstraintsButton?.titleLabel?.text != nil && self.events.count == 0 {
                
            } else {
                self.filterButton?.hidden = false
            }
            self.filterButton?.hidden = true
            self.filterButton?.alpha = 1
            if self.view.frame.width <= 320 {
                filterButton?.frame = CGRectMake((self.view.frame.width - 49)/2, y + 30, 37, 38)
            } else {
                filterButton?.frame = CGRectMake((self.view.frame.width - 49)/2, y + 30, 49, 50)
            }
            filterButton?.setImage(UIImage(named:"filterIcon"), forState: .Normal)
        } else {
//            if self.noPostCellShown == true {
//                filterButton?.frame = CGRectMake((self.view.frame.width - 38)/2, y + 70, 38, 30)
//            } else {
            if self.view.frame.width <= 320 {
                filterButton?.setImage(UIImage(named:"newFilterIcon_small"), forState: .Normal)
                filterButton?.frame = CGRectMake(self.view.frame.width - 32, y, 32, 32)
            } else {
                filterButton?.setImage(UIImage(named:"newFilterIcon"), forState: .Normal)
                filterButton?.frame = CGRectMake(self.view.frame.width - 40, y, 40, 40)
            }
            //}
        }
        return events.count + 1
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row < events.count {
            if self.browseControllerTab == .Saved {
                if events.count > 0 {
                    self.tableView.scrollEnabled = true

                    let cell = tableView.dequeueReusableCellWithIdentifier("savedEventCard", forIndexPath: indexPath) as! SavedEventCardTableViewCell
                    self.noPostCellShown = false
                    cell.selectionStyle = .None
                    cell.event = events[indexPath.row]
                    
                    cell.flagTappedWithCompletion = {

//                        let report = PFObject(className: "ReportCase")
//                        report["claimant"] = PFUser.currentUser()
//                        report["event"] = self.events[indexPath.row]
//                        report["accused"] = self.events[indexPath.row].owner
//                        let reportController = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! RWTextInputTableViewController
//                        reportController.inputTooltipText = "See something you didn’t like? Tell us more."
//                        reportController.navigationItem.title = "Report"
//                        reportController.confirmationText = "Message sent."
//                        reportController.confirmationDescription = "Thank you for your report."
//                        reportController.didFinishTypingWithText = {
//                            text in
//                            report["message"] = text
//                            report.saveEventually()
//                            //self.didSwipeUp(nil)
//                        }
//                        self.navigationController?.pushViewController(reportController, animated: false)
                        let report = PFObject(className: "ReportCase")
                        report["claimant"] = PFUser.currentUser()
                        report["event"] = self.events[indexPath.row]
                        report["accused"] = self.events[indexPath.row].owner
                        
                        let reportController = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
                        reportController.inputTooltipText = "See something you didn’t like? Tell us more."
                        reportController.navigationItem.title = "Report"
                        reportController.confirmationText = "Message sent."
                        reportController.confirmationDescription = "Thank you for your report."
                        reportController.isReport = true
                        reportController.didFinishTypingWithText = {
                            text, isBlocked in
                            report["message"] = text
                            var message = ""
                            var mail = "report@vocale.io"
                            if let user = PFUser.currentUser() {
                                if let name = user["name"] as? String {
                                    message = "NAME: " + name
                                }
                                if let userID = user["username"] as? String {
                                    message = message + "\n" + "ID: " + userID
                                }
                                if let email = user["email"] as? String {
                                    message = message + "\n" + "EMAIL: " + email
                                    mail = email
                                }
                            }
                            
                            let event = self.events[indexPath.row]
                            message = message + "\n\n" + "POST ID: " + event.objectId!
                            
                            let owner = self.events[indexPath.row].owner
                            if let name = owner["name"] as? String {
                                message = message + "\nREPORTED USER NAME: " + name
                            }
                            if let userID = owner["username"] as? String {
                                message = message + "\n" + "REPORTED USER ID: " + userID
                            }
                            if let email = owner["email"] as? String {
                                message = message + "\n" + "REPORTED USER EMAIL: " + email
                            }
                            
                            message = message + "\n" + "MESSAGE: " + text
                            EmailManager.sharedInstance.sendMail(mail, to: "report@vocale.io", subject: "Report", message: message)
                            report.saveEventually()
                            Mixpanel.sharedInstance().track("Flag Post", properties:["post": cell.event!.objectId!])
                            
                            if isBlocked == true {
                                if let currentUser = PFUser.currentUser() {
                                    let blockedUser = self.events[indexPath.row].owner
                                    
                                    let userQuery = PFQuery(className:"BlockedUsers")
                                    userQuery.whereKey("userId", equalTo: currentUser.objectId!)
                                    userQuery.getFirstObjectInBackgroundWithBlock {
                                        (object: PFObject?, error: NSError?) -> Void in
                                        if let error = error {
                                            if error.code == 101 {
                                                let user = PFObject(className:"BlockedUsers")
                                                user["userId"] = currentUser.objectId
                                                user["name"] = currentUser.firstName
                                                user.addUniqueObject(blockedUser, forKey:"blockedUsers")
                                                user.saveInBackground()
                                            }
                                        } else {
                                            if let user = object {
                                                let user = user
                                                user.addUniqueObject(blockedUser, forKey:"blockedUsers")
                                                user.saveInBackground()
                                            }
                                        }
                                    }
                                    
                                    let blockedUserQuery = PFQuery(className:"BlockedUsers")
                                    blockedUserQuery.whereKey("userId", equalTo: blockedUser.objectId!)
                                    blockedUserQuery.getFirstObjectInBackgroundWithBlock {
                                        (object: PFObject?, error: NSError?) -> Void in
                                        if let error = error {
                                            if error.code == 101 {
                                                let user = PFObject(className:"BlockedUsers")
                                                user["userId"] = blockedUser.objectId
                                                user["name"] = blockedUser.firstName
                                                user.addUniqueObject(currentUser, forKey:"blockedUsers")
                                                user.saveInBackgroundWithBlock {
                                                    (success: Bool, error: NSError?) -> Void in
                                                    if (success) {
                                                        // The object has been saved.
                                                        self.showSavedEvents()
                                                    } else {
                                                        // There was a problem, check error.description
                                                    }
                                                }
                                            }
                                        } else {
                                            if let user = object {
                                                let user = user
                                                user.addUniqueObject(currentUser, forKey:"blockedUsers")
                                                user.saveInBackgroundWithBlock {
                                                    (success: Bool, error: NSError?) -> Void in
                                                    if (success) {
                                                        // The object has been saved.
                                                        self.showSavedEvents()
                                                    } else {
                                                        // There was a problem, check error.description
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        self.navigationController?.pushViewController(reportController, animated: false)
                    }
                    
                    cell.didTapMoreButton = {
                        let alert = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertControllerStyle.ActionSheet)
                        alert.addAction(UIAlertAction(title: "Delete Post", style: UIAlertActionStyle.Destructive, handler: { (action: UIAlertAction) in
                            PFUser.currentUser()?.removeObject(self.events[indexPath.row], forKey:"savedEvents")
                            PFUser.currentUser()?.saveEventually()
                            self.tableHeaderView?.decrementNumberOfItemsInTab(2)
                            self.showSavedEvents()

                        }))
                        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action: UIAlertAction) in

                        }))
                        
                        self.presentViewController(alert, animated: true, completion: {

                        })

                    }
                    cell.backgroundImageView.loadInBackground()
                    return cell
                } else {
                    let noMorePostsCell = tableView.dequeueReusableCellWithIdentifier("noMorePostsCard", forIndexPath: indexPath) as! NoPostsTableViewCell
                    self.noPostCellShown = true
                    noMorePostsCell.selectionStyle = .None
                    let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(BrowseEventsTableViewController.didSwipeDown(_:)))
                    swipeDownGestureRecognizer.direction = .Down
                    noMorePostsCell.addGestureRecognizer(swipeDownGestureRecognizer)
                    if !(hasQueried) {
                        noMorePostsCell.browseControllerType = .loadingPosts
                    } else {
                        if self.searchConstraintsButton?.titleLabel?.text != nil && self.events.count == 0 && browseControllerTab != .Saved {
                            noMorePostsCell.browseControllerType = .noResults
                            let message = "For posts that contain " + (self.searchConstraintsButton?.titleLabel?.text)!
                            let range = (message as NSString).rangeOfString((self.searchConstraintsButton?.titleLabel?.text)!)
                            let attributedString = NSMutableAttributedString(string:message)
                            attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 15)!, NSForegroundColorAttributeName: UIColor(netHex: 0xEEEEEE)], range: range)
                            noMorePostsCell.noPostsExplanationLabel.attributedText = attributedString
                        } else {
                            noMorePostsCell.browseControllerType = self.browseControllerTab
                        }
                    }
                    return noMorePostsCell
                }
            } else {
                self.tableView.scrollEnabled = false
                let cell = tableView.dequeueReusableCellWithIdentifier("eventCard", forIndexPath: indexPath) as! EventCardTableViewCell
                
                self.noPostCellShown = false
                cell.delegate = self;
                cell.selectionStyle = .None
                cell.dismissEventClosure = {
                    cell.showingProfileInformationHandler = {_ in }
                    self.didSwipeUp(nil)
                }
                cell.showingProfileInformationHandler = {
                    showing in
                    if showing {
                        self.navigationController?.setToolbarHidden(true, animated: true)
                    } else {
                        self.navigationController?.setToolbarHidden(false, animated: true)
                    }
                }
                cell.superViewFrame = self.view.frame
                cell.setManagerButtonCentersTo(CGFloat(0.4))
                cell.event = events[indexPath.row]
                cell.isFocusedCell = true
                cell.backgroundImageView.loadInBackground()
                cell.recordTapped = {

                    self.recording = true
                    self.tableView.scrollEnabled = false
                    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
                    UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        self.toolbarItems?.first?.enabled = false
                        self.toolbarItems?[2].enabled = false
                        self.toolbarItems?.last?.enabled = false
                        self.tableHeaderView?.setTabTitlesHidden(true)
                        self.navigationController?.setToolbarHidden(true, animated: false)
                        
                        self.recordingView?.hidden = false
                        self.recordingView?.backgroundColor = UIColor(netHex: 0x333134)
                        let attachment = NSTextAttachment()
                        attachment.image = UIImage(named: "redDot")
                        let attachmentString = NSAttributedString(attachment: attachment)
                        let myString = NSMutableAttributedString(string: " REC", attributes: [NSForegroundColorAttributeName: UIColor(netHex:0xEEEEEE)])
                        //let myString = NSMutableAttributedString(string: " REC")
                        myString.insertAttributedString(attachmentString, atIndex: 0)
                        self.recordingView?.attributedText = myString
                        
                        self.filterButton?.hidden = true
                        }, completion: { (completed: Bool) -> Void in})
                }
                cell.completionHandler = {
                    //self.recordingView?.hidden = true
                    self.recording = false
                    self.tableView.scrollEnabled = true
                    UIView.animateWithDuration(0.25, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        self.toolbarItems?.first?.enabled = true
                        self.toolbarItems?[2].enabled = true
                        self.toolbarItems?.last?.enabled = true
                        self.tableHeaderView?.setTabTitlesHidden(false)
                        //self.navigationController?.setToolbarHidden(false, animated: true)
//                        self.tableView.setContentOffset(CGPoint(x: 0, y:0), animated: true)
                        //self.filterButton?.hidden = false
                        }, completion: { (completed: Bool) -> Void in

                    })
                }

                let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(BrowseEventsTableViewController.didSwipeUp(_:)))
                swipeUpGestureRecognizer.direction = .Up
                cell.addGestureRecognizer(swipeUpGestureRecognizer)
                cell.didSaveEventClosure = {
                    save, event in
                    self.didSwipeUp(nil)
                    let dict = ["saved": "true"]
                    AGPushNoteView.showWithNotificationMessage(dict)
                    Event.countBookmarkedObjectsWithCompletion { (count) -> Void in
                        self.tableHeaderView?.setNumberOfItems(count, inTab: 2)
                    }
                }
                cell.flagTappedWithCompletion = {
                    
                    let report = PFObject(className: "ReportCase")
                    report["claimant"] = PFUser.currentUser()
                    report["event"] = self.events[indexPath.row]
                    report["accused"] = self.events[indexPath.row].owner
                    let reportController = self.storyboard?.instantiateViewControllerWithIdentifier("TextInputVC") as! CustomTextInputViewController
                    reportController.inputTooltipText = "See something you didn’t like? Tell us more."
                    reportController.navigationItem.title = "Report"
                    reportController.confirmationText = "Message sent."
                    reportController.confirmationDescription = "Thank you for your report."
                    reportController.isReport = true
                    reportController.didFinishTypingWithText = {
                        text, isBlocked in
                        report["message"] = text
                        var message = ""
                        var mail = "report@vocale.io"
                        if let user = PFUser.currentUser() {
                            if let name = user["name"] as? String {
                                message = "NAME: " + name
                            }
                            if let userID = user["username"] as? String {
                                message = message + "\n" + "ID: " + userID
                            }
                            if let email = user["email"] as? String {
                                message = message + "\n" + "EMAIL: " + email
                                mail = email
                            }
                        }
                        
                        let event = self.events[indexPath.row]
                        message = message + "\n\n" + "POST ID: " + event.objectId!
                        
                        let owner = self.events[indexPath.row].owner
                        if let name = owner["name"] as? String {
                            message = message + "\nREPORTED USER NAME: " + name
                        }
                        if let userID = owner["username"] as? String {
                            message = message + "\n" + "REPORTED USER ID: " + userID
                        }
                        if let email = owner["email"] as? String {
                            message = message + "\n" + "REPORTED USER EMAIL: " + email
                        }
                        
                        message = message + "\n" + "MESSAGE: " + text
                        EmailManager.sharedInstance.sendMail(mail, to: "report@vocale.io", subject: "Report", message: message)
                        report.saveEventually()
                        Mixpanel.sharedInstance().track("Flag Post", properties:["post": cell.event!.objectId!])
                        if isBlocked == true {
                            
                            if let currentUser = PFUser.currentUser() {
                                let blockedUser = self.events[indexPath.row].owner
                                
                                let userQuery = PFQuery(className:"BlockedUsers")
                                userQuery.whereKey("userId", equalTo: currentUser.objectId!)
                                userQuery.getFirstObjectInBackgroundWithBlock {
                                    (object: PFObject?, error: NSError?) -> Void in
                                    if let error = error {
                                        if error.code == 101 {
                                            let user = PFObject(className:"BlockedUsers")
                                            user["userId"] = currentUser.objectId
                                            user["name"] = currentUser.firstName
                                            user.addUniqueObject(blockedUser, forKey:"blockedUsers")
                                            user.saveInBackground()
                                        }
                                    } else {
                                        if let user = object {
                                            let user = user
                                            user.addUniqueObject(blockedUser, forKey:"blockedUsers")
                                            user.saveInBackground()
                                        }
                                    }
                                }
                                
                                let blockedUserQuery = PFQuery(className:"BlockedUsers")
                                blockedUserQuery.whereKey("userId", equalTo: blockedUser.objectId!)
                                blockedUserQuery.getFirstObjectInBackgroundWithBlock {
                                    (object: PFObject?, error: NSError?) -> Void in
                                    if let error = error {
                                        if error.code == 101 {
                                            let user = PFObject(className:"BlockedUsers")
                                            user["userId"] = blockedUser.objectId
                                            user["name"] = blockedUser.firstName
                                            user.addUniqueObject(currentUser, forKey:"blockedUsers")
                                            user.saveInBackgroundWithBlock {
                                                (success: Bool, error: NSError?) -> Void in
                                                if (success) {
                                                    // The object has been saved.
//                                                    self.showAllEvents()
                                                } else {
                                                    // There was a problem, check error.description
                                                }
                                            }
                                        }
                                    } else {
                                        if let user = object {
                                            let user = user
                                            user.addUniqueObject(currentUser, forKey:"blockedUsers")
                                            user.saveInBackgroundWithBlock {
                                                (success: Bool, error: NSError?) -> Void in
                                                if (success) {
                                                    // The object has been saved.
//                                                    self.showAllEvents()
                                                    
                                                } else {
                                                    // There was a problem, check error.description
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    self.navigationController?.pushViewController(reportController, animated: false)
                    
                }
                cell.didScrollToScrollViewPageAtIndex = {
                    index in
                    if index == 0 {
                        self.filterButton?.alpha = 1
                    } else {
                        self.filterButton?.alpha = 0
                    }
                }
                
                if let searchButton = self.searchConstraintsButton {
                    searchButton.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width, 0)
                    UIView.animateWithDuration(0.3, delay: 0.4, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        if let searchButton = self.searchConstraintsButton {
                            if self.events.count != 0 {
                                searchButton.hidden = false
                            }
                            searchButton.transform = CGAffineTransformMakeTranslation(0, 0)
                        }
                    }) { (completed: Bool) -> Void in
                    }
                }
                
                return cell
            }
        } else {
            if self.browseControllerTab != .Saved && self.searchConstraintsButton?.titleLabel?.text == nil {
                let noMorePostsAnimatedCell = tableView.dequeueReusableCellWithIdentifier("NoPostAnimatedCell", forIndexPath: indexPath) as! NoPostAnimatedTableViewCell
                noMorePostsAnimatedCell.selectionStyle = .None
                noMorePostsAnimatedCell.delegate = self
                
                if let user = PFUser.currentUser() {
                    if let file = user["UserImageMain"] as? PFFile  {
                        file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                            if let _ = error {
                            } else if let data = data, let image = UIImage(data: data) {
                                noMorePostsAnimatedCell.avatarImageView.image = image
                            }
                            }, progressBlock: { (progress: Int32) -> Void in
                        })
                    } else if let string = user["FBPictureURL"] as? String, url = NSURL(string: string) {
                        let request: NSURLRequest = NSURLRequest(URL: url)
                        let mainQueue = NSOperationQueue.mainQueue()
                        NSURLConnection.sendAsynchronousRequest(request, queue: mainQueue, completionHandler: { (response, data, error) -> Void in
                            if error == nil {
                                // Convert the downloaded data in to a UIImage object
                                let image = UIImage(data: data!)
                                noMorePostsAnimatedCell.avatarImageView.image = image
                            }
                            else {
                                
                            }
                        })
                    }
                }
                
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
//                })
                
                if nextShown == true {
                    nextShown = false
                    self.stateType = .NoPosts
                }
                
                print("Cell for now")
                if self.stateType == .Loading {
                    if self.loadingStarted == false {
                        print("CELL - LOADING")
                        noMorePostsAnimatedCell.loadingShowAnimation()
                        self.loadingStarted = true
                    }
                } else if self.stateType == .NoPosts {
                    noMorePostsAnimatedCell.noPostsShowAnimation()
                }
                
                return noMorePostsAnimatedCell
            }
            
            let noMorePostsCell = tableView.dequeueReusableCellWithIdentifier("noMorePostsCard", forIndexPath: indexPath) as! NoPostsTableViewCell
            //self.filterButton?.hidden = true
            self.noPostCellShown = true
            noMorePostsCell.selectionStyle = .None
            let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(BrowseEventsTableViewController.didSwipeDown(_:)))
            swipeDownGestureRecognizer.direction = .Down
            noMorePostsCell.addGestureRecognizer(swipeDownGestureRecognizer)
            if !(hasQueried) {
                noMorePostsCell.browseControllerType = .loadingPosts
                self.filterButton?.hidden = true
            } else {
                var y: CGFloat = 0;
                if let navigationController = navigationController {
                    let height = navigationController.view.frame.height - navigationController.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - view.frame.width - 40
                    y = navigationController.view.frame.height - height
                }
                if self.view.frame.width <= 320 {
                    filterButton?.frame = CGRectMake((self.view.frame.width - 49)/2, y + 30, 37, 38)
                } else {
                    filterButton?.frame = CGRectMake((self.view.frame.width - 49)/2, y + 30, 49, 50)
                }
                filterButton?.setImage(UIImage(named:"filterIcon"), forState: .Normal)
            
                //NO RESULTS from first search
                if self.searchConstraintsButton?.titleLabel?.text != nil && self.events.count == 0 && browseControllerTab != .Saved {
                    //NO RESULTS from first search
                    noMorePostsCell.browseControllerType = .noResults
                    if self.stateType == .Searching {
                        noMorePostsCell.noPostsLabel.text = "SEARCHING"
                    } else {
                        noMorePostsCell.noPostsLabel.text = "NO RESULTS"
                    }
                    let message = "For posts that contain " + (self.searchConstraintsButton?.titleLabel?.text)!
                    let range = (message as NSString).rangeOfString((self.searchConstraintsButton?.titleLabel?.text)!)
                    let attributedString = NSMutableAttributedString(string:message)
                    attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 15)!, NSForegroundColorAttributeName: UIColor(netHex: 0xEEEEEE)], range: range)
                    noMorePostsCell.noPostsExplanationLabel.attributedText = attributedString
                } else if self.searchConstraintsButton?.titleLabel?.text != nil && self.events.count > 0 && browseControllerTab != .Saved {
                    //NO RESULTS when there some results first
                    noMorePostsCell.browseControllerType = .noResults
                    noMorePostsCell.noPostsLabel.text = "NO MORE RESULTS"
                    let message = "For posts that contain " + (self.searchConstraintsButton?.titleLabel?.text)!
                    let range = (message as NSString).rangeOfString((self.searchConstraintsButton?.titleLabel?.text)!)
                    let attributedString = NSMutableAttributedString(string:message)
                    attributedString.setAttributes([NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 15)!, NSForegroundColorAttributeName: UIColor(netHex: 0xEEEEEE)], range: range)
                    noMorePostsCell.noPostsExplanationLabel.attributedText = attributedString
                } else {
                    noMorePostsCell.browseControllerType = self.browseControllerTab
                }
            }
            return noMorePostsCell
        }

    }
    
    func logPastEvent(indexPath: NSIndexPath) {
        let pastEvent = PFObject(className:"PastEvent")
        if let currentUser = PFUser.currentUser() {
            pastEvent["user"] = currentUser.objectId
        }
        pastEvent["event"] = self.events[indexPath.row].objectId
        pastEvent.saveInBackground()
        
        let event = self.events[indexPath.row]
        Mixpanel.sharedInstance().track("Stream Post Viewed", properties:["post": event.objectId!, "user": event.owner.objectId!])
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        var toolbarHeight = CGFloat(0)
        if let height = self.navigationController?.toolbar.frame.height {
            toolbarHeight = height
        }

        if self.browseControllerTab == .Saved {
            if events.count > 0 {
                return view.frame.height/3
            } else {
                return view.frame.height
            }
        } else if indexPath.row < events.count {
//            print("NORMAL SIZE: ", view.frame.height - self.tableView(tableView, heightForHeaderInSection: indexPath.section) + toolbarHeight)
            return view.frame.height - self.tableView(tableView, heightForHeaderInSection: indexPath.section) + toolbarHeight
        }
        else {
//            print("NO POSTS CELL SIZE: ", view.frame.height - self.tableView(tableView, heightForHeaderInSection: indexPath.section))
            //return view.frame.height
            return view.frame.height - self.tableView(tableView, heightForHeaderInSection: indexPath.section)
        }
    }


    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        return tableHeaderView
    }

    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        view.alpha = 1
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if let savedCell = tableView.cellForRowAtIndexPath(indexPath) as? SavedEventCardTableViewCell {
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .CurveEaseInOut, animations: { () -> Void in
                if let savedPoststooltip = self.tooltipSavedPosts {
                    savedPoststooltip.alpha = 0
                    savedPoststooltip.transform = CGAffineTransformMakeTranslation(0, 40)
                }
            }) { (completed: Bool) -> Void in
                self.tooltipSavedPosts?.removeFromSuperview()
            }

            return true
        } else {
            return false
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        if let savedCell = tableView.cellForRowAtIndexPath(indexPath) as? SavedEventCardTableViewCell {
            
            let deleteAction = UITableViewRowAction(style: .Normal, title: "DELETE",
                                                    handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) in
                                                        SVProgressHUD.showWithStatus("Deleting Post")
                                                        SVProgressHUD.dismiss()
                                                        if let event = savedCell.event {
                                                            PFUser.currentUser()?.removeObject(event, forKey: "savedEvents")
                                                            PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                                                                if let error = error {
                                                                    ErrorManager.handleError(error)
                                                                } else {
                                                                    SVProgressHUD.showSuccessWithStatus("Post Deleted")
                                                                    self.events.removeAtIndex(indexPath.row)
                                                                    self.tableHeaderView?.decrementNumberOfItemsInTab(2)
                                                                    self.tableView.reloadData()
                                                                }
                                                            })
                                                        }
                                                        
                }
            );
            deleteAction.backgroundColor = UIColor(netHex: 0xFB4B4E)
            
            return[deleteAction]
        } else {
            return nil
        }
    }

    // MARK: - Table view delegate

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if recording {
            return
        }
        self.navigationController?.setToolbarHidden(false, animated: true)
        self.recordingView?.hidden = true
        if let vc = self.navigationController?.topViewController as? BrowseEventsTableViewController { //filterButton other screens visibility bug
            self.filterButton?.hidden = false
        }
        topCell?.presentCardWithAnimation()
        if let cell = cell as? SavedEventCardTableViewCell {
            let h = cell.bounds.height
            let y = ((cell.frame.origin.y + UIApplication.sharedApplication().statusBarFrame.height + (navigationController?.navigationBar.frame.height)!) / h) * cell.frame.height
            cell.alpha = 0
            UIView.animateWithDuration(0.6, delay: 0.3*Double(y/tableView.frame.height), usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                cell.alpha = 1
                }, completion: { (completed: Bool) -> Void in

            })
        }
        if let eventcard = cell as? EventCardTableViewCell {
            eventcard.backgroundImageView.loadInBackground()

        }
//        if events.count - indexPath.row < 5 {
//            if shouldFetch && !queryIsBusy {
//                addEventsFromQuery(query)
//                shouldFetch = false
//            }
//        }
        if events.count > indexPath.row + 2 {
            events[indexPath.row+1].fetchIfNeededInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
                if let event = object as? Event {
                    event.backgroundImage.getDataInBackground()
                }
            })
            
            events[indexPath.row+2].fetchIfNeededInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
                if let event = object as? Event {
                    event.backgroundImage.getDataInBackground()
                }
            })
        }
        
        if let loadingCell = cell as? NoPostsTableViewCell {
            
            if loadingCell.browseControllerType == .loadingPosts || loadingCell.browseControllerType == .noResults {
                self.filterButton?.hidden = true
            }
            if loadingCell.browseControllerType == .noResults && self.searchConstraintsButton?.titleLabel?.text != nil && self.stateType != .Searching {
                self.backToBrowseButton?.hidden = false
                self.searchConstraintsButton?.hidden = true
            } else {
                self.backToBrowseButton?.hidden = true
            }
            loadingCell.noPostsExplanationLabel.alpha = 0
            loadingCell.noPostsLabel.alpha = 0
            loadingCell.noPostsImageView.alpha = 0
            self.filterButton?.alpha = 0
            UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                loadingCell.noPostsExplanationLabel.alpha = 1
                loadingCell.noPostsLabel.alpha = 1
                loadingCell.noPostsImageView.alpha = 1
                }, completion: { (completed) in
                    UIView.animateWithDuration(0.3, delay: 0.3, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                        if loadingCell.browseControllerType != .Saved && loadingCell.browseControllerType != .noResults {
                            self.filterButton?.alpha = 1
                        }
                        }, completion: { (completed) in
                            
                    })
            })
        }
        
        if let _ = cell as? NoPostAnimatedTableViewCell {
            self.filterButton?.hidden = true
            dispatch_async(dispatch_get_main_queue(), {
                self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
            })
        }
    }

    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if recording {
            return
        }
        
        if self.navigationController?.toolbar.hidden == true {
            self.navigationController?.setToolbarHidden(false, animated: true)
        }
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if self.navigationController?.toolbar.hidden == true {
                if self.recordingView?.hidden == true {
                    self.navigationController?.setToolbarHidden(false, animated: false)
                }
            }
        }
        
        if let loadingCell = cell as? NoPostsTableViewCell {
            if loadingCell.browseControllerType == .loadingPosts || loadingCell.browseControllerType == .noResults {
                self.filterButton?.hidden = true
            }
            
            if loadingCell.browseControllerType == .noResults && self.searchConstraintsButton?.titleLabel?.text != nil && self.stateType != .Searching {
                self.backToBrowseButton?.hidden = false
            } else {
                   
                self.backToBrowseButton?.hidden = true
            }
        }
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (browseControllerTab == .Saved) {
            if let _ = tableView.cellForRowAtIndexPath(indexPath) as? SavedEventCardTableViewCell where events.count > 0 && browseControllerTab == .Saved {
                selectedEvent = events[indexPath.row]
                selectedSavedPostIndexPath = indexPath
                performSegueWithIdentifier("toVoiceNoteTableViewController", sender: self)
            }
        }
    }

    // MARK: CLLocationManagerDelegate

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            GeoFenceManager.sharedInstance.userLocation = lastLocation
            BrowseEventsTableViewController.lastSavedLocation = PFGeoPoint(location: lastLocation)
            if (shouldQuery) {
                queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
            }
            PFUser.currentUser()?.setObject(PFGeoPoint(location: lastLocation), forKey: "lastLocation")
            if let eventCells = tableView.visibleCells as? [EventCardTableViewCell] {
                for cell in eventCells {
                    cell.updateLocation()
                }
            }
        }
    }

    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        ErrorManager.handleError(error)
    }
    
    //MARK: - EventCellManagerDelegate
    func showUplodingView() {
        self.recordingView?.backgroundColor = UIColor(netHex: 0x1098F7)
        self.recordingView?.text = "SENDING"
        self.recordingView?.textColor = UIColor(netHex: 0x211E23)
    }
    
    func showSentView() {
        self.recordingView?.backgroundColor = UIColor(netHex: 0x86B155)
        self.recordingView?.text = "SENT"
        self.recordingView?.textColor = UIColor(netHex: 0x211E23)
    }
    
    func showCancelView() {
        self.recordingView?.hidden = true
        self.filterButton?.hidden = false
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    //MARK: - FilterDelegate
    func filterDismissed() {
        if filterButton != nil {
            filterButton?.alpha = 1
            filterButton?.hidden = false
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        searchConstraintsButton?.hidden = true
        backToBrowseButton?.hidden = true
        
        if let postCreationController = segue.destinationViewController as? InputViewController {
            postCreationController.createPostTapped = true
        }
        
        if let voiceNoteVC = segue.destinationViewController as? VoiceNoteTableViewController {
            voiceNoteVC.event = selectedEvent
            voiceNoteVC.delegate = self
        }

        if let searchController = segue.destinationViewController as? SearchViewController {
            searchController.searchTappedClosure = {
                selectedTags in

                self.extraQueryConstraints = { query in
                    var attributedTitle = " "
                    var tagStringArray = [String]()
                    for tag in selectedTags {
                        tagStringArray.append(tag)
                        attributedTitle = attributedTitle + "#" + tag + " "
                    }
                    query?.whereKey("tags", containedIn:tagStringArray)
                    let label = UILabel()
                    label.text = attributedTitle
                    label.sizeToFit()
                    let width = label.frame.size.width
                    let tagsButton = UIButton(frame: CGRectMake(6, self.tableView.frame.width + self.tableHeaderView!.frame.height + 10, width + 20, 20))
                    tagsButton.setImage(UIImage(named:"ic_delete"), forState: .Normal)
                    tagsButton.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
                    tagsButton.titleLabel?.font = UIFont(name: "Raleway-SemiBold", size: 14)
                    tagsButton.setTitle(attributedTitle, forState: . Normal)
                    tagsButton.setTitleColor(UIColor(netHex:0xEEEEEE), forState: .Normal)
                    tagsButton.addTarget(self, action: #selector(BrowseEventsTableViewController.removeSearchConstraintsTapped(_:)), forControlEvents: .TouchUpInside)
                    if self.searchConstraintsButton == nil {
                        self.searchConstraintsButton = tagsButton
                        self.searchConstraintsButton?.hidden = true
                        self.tableView.addSubview(tagsButton)
                    }
                }
                if self.browseControllerTab == .Today {
                    self.showTodayEvents()
                } else {
                    self.showAllEvents()
                }
            }
        }
        
        if let chatVC = segue.destinationViewController as? ConversationListViewController {
            if let client = AppDelegate.layerClient {
                if let _ = client.authenticatedUserID {
                    chatVC.layerClient = client
                }
            } else {
                let appID = NSURL(string: "layer:///apps/staging/45f026f2-a10f-11e5-8f8b-4e4f000000ac")
                AppDelegate.layerClient = LYRClient(appID: appID!)
                
                AppDelegate.layerClient?.connectWithCompletion({ (success: Bool, error: NSError?) -> Void in
                    if let error = error {
                        SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                    } else {
                        let userIDString = PFUser.currentUser()?.objectId
                        
                        self.authenticateLayerWithUserID(userIDString!, completion: { (success, error) -> Void in
                            if !success {
                                
                            } else {
                                if let client = AppDelegate.layerClient {
                                    if let _ = client.authenticatedUserID {
                                        chatVC.layerClient = client
                                    }
                                }
                            }
                        })
                        
                    }
                })
            }

        }
        
        if let menu = segue.destinationViewController as? ApplicationMenuTableViewController {
            nextShown = true
        }
    }

    func removeSearchConstraintsTapped(sender: UIButton) {
        self.searchConstraintsButton?.removeFromSuperview()
        self.searchConstraintsButton = nil
        self.backToBrowseButton?.removeFromSuperview()
        self.backToBrowseButton = nil
        self.extraQueryConstraints = {_ in }
        if self.browseControllerTab == .Today {
            //State animation changes
            //self.showTodayEvents()
            //------
            self.reloadTodayPosts()
        } else {
            //State animation chages
            //self.showAllEvents()
            //------
            self.animationFinished = false
            self.stateType = .Loading
            self.events = [Event]()
            self.tableView.reloadData()
            self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
        }
    }
    
    func openFilter(destinationController: FilterViewController) {
            UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.vocaleLightGreyColor(), NSFontAttributeName: UIFont(name: "Raleway-Regular", size: 16)!], forState: .Normal)
            destinationController.delegate = self
            self.extraQueryConstraints = destinationController.resultingQueryWithConstraints
            destinationController.didFilterWithCompletion = {
                resultingQueryWithConstraints in
                self.extraQueryConstraints = resultingQueryWithConstraints
                self.showAllEvents()
            }
    }

    // MARK: - DZN EmptyDataSet

    func imageForEmptyDataSet(scrollView: UIScrollView!) -> UIImage! {
        let originalImage = UIImage(assetIdentifier: .VocaleClearWhite)
        let image = UIImage(CGImage: originalImage!.CGImage!, scale: originalImage!.scale*2, orientation: originalImage!.imageOrientation)
        return image
    }

    func imageAnimationForEmptyDataSet(scrollView: UIScrollView!) -> CAAnimation! {
        let animation = CABasicAnimation(keyPath: "transform")
        animation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
        animation.toValue = NSValue(CATransform3D: CATransform3DMakeRotation(CGFloat(M_PI_2), 0, 0, 1))
        animation.duration = 0.25
        animation.cumulative = true
        animation.repeatCount = Float.infinity
        return animation
    }

    func titleForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "This is the Browse View."
        let attributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(18), NSForegroundColorAttributeName: UIColor.whiteColor()]
        return NSAttributedString(string: text, attributes: attributes)
    }

    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "This is where posts will be displayed.  From here you can explore and respond to nearby posts."
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .ByWordWrapping
        paragraph.alignment = .Center

        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14), NSForegroundColorAttributeName: UIColor.whiteColor(), NSParagraphStyleAttributeName: paragraph]
        return NSAttributedString(string: text, attributes: attributes)
    }

    // MARK: IBActions

    @IBAction func didLongTapCell(sender: AnyObject) {
        if let sender = sender as? UILongPressGestureRecognizer, cell = sender.view as? EventCardTableViewCell, event = cell.event {
            if sender.state == UIGestureRecognizerState.Began {
                if let user = PFUser.currentUser() where PFAnonymousUtils.isLinkedWithUser(user) {
                    SVProgressHUD.showErrorWithStatus("Please log in using Facebook")
                    tabBarController?.selectedIndex = 3
                } else {

                    if let indexPath = tableView.indexPathForCell(cell) {
                        topCell = cell
                        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
                        cell.recordingMode = true
                        if let nextCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)) as? EventCardTableViewCell {
                            UIView.animateWithDuration(0.5, animations: { () -> Void in
                                nextCell.alpha = 0
                            })
                        }
                    }
                    if voiceNoteRecorder == nil {
                        var height = (self.tabBarController?.tabBar.frame.height)!*2
                        var y = (self.tabBarController?.tabBar.frame.origin.y)! - (self.tabBarController?.tabBar.frame.height)!
                        if let navigationController = navigationController {
                            height = navigationController.view.frame.height - navigationController.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - view.frame.width - 40
                            y = navigationController.view.frame.height - height
                        }
                        voiceNoteRecorder = VoiceNoteRecorder(frame: CGRectMake(0, y, self.tableView.frame.width, height))
                        if let voiceNoteRecorder = voiceNoteRecorder {

                            self.navigationController?.view.addSubview(voiceNoteRecorder)
                            voiceNoteRecorder.event = event
                            voiceNoteRecorder.startRecording()

                            UIView.animateWithDuration(0.5, animations: { () -> Void in
                                self.tabBarController?.tabBar.alpha = 0
                                }, completion: { (completed: Bool) -> Void in
                                    if completed {
                                        self.tabBarController?.tabBar.hidden = true
                                    }
                            })
                            activityIndicatorView = DGActivityIndicatorView(type: .BallClipRotatePulse, tintColor: UIColor.vocaleRedColor(), size: 140)
                            navigationController!.view.addSubview(activityIndicatorView)

                        }
                    }
                }
            } else if sender.state == UIGestureRecognizerState.Ended {
                var willUpload = true
                if let button = (voiceNoteRecorder?.hitTest(sender.locationOfTouch(sender.numberOfTouches()-1, inView: voiceNoteRecorder), withEvent: nil)) as? UIButton {
                    if button.tag == voiceNoteRecorder!.cancelButton.tag {
                        voiceNoteRecorder?.cancelTapped({ (success, error) -> Void in
                            willUpload = false
                            if let cell = self.topCell {
                                cell.recordingMode = false
                            }
                            self.removeVoiceNoteRecorderWithAnimation()
                        })
                    }
                } else {
                    stopRecording()
                }
                if willUpload {
                    topCell?.uploadingMode = true
                }
                activityIndicatorView.removeFromSuperview()
            }
            if let navigationController = navigationController {
                activityIndicatorView.center = sender.locationOfTouch(sender.numberOfTouches()-1, inView: navigationController.view)
                activityIndicatorView.startAnimating()
                let location = sender.locationOfTouch(sender.numberOfTouches()-1, inView: voiceNoteRecorder)
                if let voiceNoteRecorder = voiceNoteRecorder where distanceBetween(point: location, andPoint: voiceNoteRecorder.cancelButton.center) < view.frame.height/2 {
                    let center = voiceNoteRecorder.cancelButton.center
                    var factor = 1+((view.frame.height/2) - distanceBetween(point: location, andPoint: voiceNoteRecorder.cancelButton.center))/(view.frame.height)
                    factor = factor*factor
                    voiceNoteRecorder.cancelButton.frame.size = CGSizeMake(voiceNoteRecorder.originalCancelButtonSize.width*factor, voiceNoteRecorder.originalCancelButtonSize.height*factor)
                    voiceNoteRecorder.cancelButton.center = center

                }
            }
        }
    }

    // MARK: Actions

    func searchTapped() {
        if let searchVC = self.storyboard?.instantiateViewControllerWithIdentifier("SearchVC") as? SearchViewController {
            searchVC.searchTappedClosure = {
                selectedTags in
                
                self.searchConstraintsButton?.removeFromSuperview()
                self.searchConstraintsButton = nil
                self.extraQueryConstraints = { query in
                    var attributedTitle = " "
                    var tagStringArray = [String]()
                    for tag in selectedTags {
                        tagStringArray.append(tag)
                        attributedTitle = attributedTitle + "#" + tag + " "
                    }
                    query?.whereKey("tags", containedIn:tagStringArray)
                    let label = UILabel()
                    label.text = attributedTitle
                    label.sizeToFit()
                    let width = label.frame.size.width
                    let tagsButton = UIButton(frame: CGRectMake(6, self.tableView.frame.width + self.tableHeaderView!.frame.height + 10, width + 20, 20))
                    tagsButton.setImage(UIImage(named:"ic_delete"), forState: .Normal)
                    tagsButton.setBackgroundColor(UIColor.clearColor(), forState: .Normal)
                    tagsButton.titleLabel?.font = UIFont(name: "Raleway-SemiBold", size: 14)
                    tagsButton.setTitle(attributedTitle, forState: . Normal)
                    tagsButton.setTitleColor(UIColor(netHex:0xEEEEEE), forState: .Normal)
                    tagsButton.addTarget(self, action: #selector(BrowseEventsTableViewController.removeSearchConstraintsTapped(_:)), forControlEvents: .TouchUpInside)
                    if self.searchConstraintsButton == nil {
                        self.searchConstraintsButton = tagsButton
                        self.searchConstraintsButton?.hidden = true
                        self.tableView.addSubview(tagsButton)
                    }
                    if self.backToBrowseButton == nil {
                        var y: CGFloat = 0;
                        if let navigationController = self.navigationController {
                            let height = navigationController.view.frame.height - navigationController.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - self.view.frame.width - 40
                            y = self.navigationController!.view.frame.height - height
                        }
                        self.backToBrowseButton = UIButton()
                        if self.view.frame.width <= 320 {
                            self.backToBrowseButton?.frame = CGRectMake((self.view.frame.width - 115)/2, y + 30, 115, 55)
                        } else {
                            self.backToBrowseButton?.frame = CGRectMake((self.view.frame.width - 115)/2, y + 30, 115, 55)
                        }
                        self.backToBrowseButton?.setImage(UIImage(named:"backToBrowseIcon"), forState: .Normal)
                        self.backToBrowseButton?.addTarget(self, action: #selector(BrowseEventsTableViewController.removeSearchConstraintsTapped(_:)), forControlEvents: UIControlEvents.TouchUpInside)
                        
                        self.navigationController?.view.addSubview(self.backToBrowseButton!)
                        self.backToBrowseButton?.hidden = true
                    }
                }
                self.backToBrowseButton?.hidden = true
                if self.browseControllerTab == .Today {
                    //State animation changes
                    //self.showTodayEvents()
                    //------
                    self.reloadTodayPosts()
                } else {
                    //State animation chages
                    //self.showAllEvents()
                    //------
                    self.browseControllerTab = .All
                    self.tableHeaderView?.switchToAll()
                    self.animationFinished = false
                    self.stateType = .Searching
                    self.events = [Event]()
                    self.tableView.reloadData()
                    self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
                }
            }

            self.navigationController?.pushViewController(searchVC, animated: false)
        }
    }

    func filterTapped() {
        //topCell?.hideCardWithAnimation(true)
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            if let filterVC = self.storyboard?.instantiateViewControllerWithIdentifier("FilterVC") as? FilterViewController {
                self.navigationController?.pushViewController(filterVC, animated: true)
                self.toFilterScreen = true
                filterVC.browseFilterTapped = true
                filterVC.didFilterWithCompletion = {
                    resultingQueryWithConstraints in
                    if self.browseControllerTab == .All {
                        self.animationFinished = false
                        self.stateType = .Loading
                        self.tableView.reloadData()
                        self.events = [Event]()
                        self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
                    } else if (self.browseControllerTab == .Today) {
                        self.animationFinished = false
                        self.stateType = .Loading
                        self.tableView.reloadData()
                        self.events = [Event]()
                        self.reloadTodayPosts()
                    }
                }
            }
        }
    }

    func didSwipeUp(sender: AnyObject?) {
        if recording {
            return
        }
        
//        if self.navigationController?.toolbar.hidden == true {
//            self.navigationController?.setToolbarHidden(false, animated: true)
//        }
        
        if let cell = topCell, indexPath = tableView.indexPathForCell(cell) {
            //PAST EVENT
            if let currentUser = PFUser.currentUser() {
                if let admin = currentUser["admin"] as? Bool {
                    if admin == false {
                        self.logPastEvent(indexPath)
                    }
                } else {
                    self.logPastEvent(indexPath)
                }
            }
            //
            
            //Automatic refresh after last post
//            if browseControllerTab == .All {
//                if indexPath.row == (self.events.count - 1) {
//                    if let currentUser = PFUser.currentUser() {
//                        if let admin = currentUser["admin"] as? Bool {
//                            if admin == false {
//                                self.showAllEvents()
//                            }
//                        } else {
//                            self.showAllEvents()
//                        }
//                    }
//                }
//            }
            //
            
            if let _ = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)) as? EventCardTableViewCell {
                
            } else {
                self.stateType = .NoPosts
            }
            
            cell.dismissCardWithAnimation()
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section), atScrollPosition: .Top, animated: false)
                if let secondCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)) as? EventCardTableViewCell {
                    self.topCell = secondCell
                    self.topCell?.presentCardWithAnimation()
//                    if self.navigationController?.toolbar.hidden == true {
//                        self.navigationController?.setToolbarHidden(false, animated: true)
//                    }
                } else {
                    
                    var y: CGFloat = 0;
                    if let navigationController = self.navigationController {
                        let height = navigationController.view.frame.height - navigationController.navigationBar.frame.height - UIApplication.sharedApplication().statusBarFrame.height - self.view.frame.width - 40
                        y = self.navigationController!.view.frame.height - height
                    }

                    //self.filterButton?.hidden = false
                    self.filterButton?.hidden = true
                    if self.view.frame.width <= 320 {
                        self.filterButton?.frame = CGRectMake((self.view.frame.width - 49)/2, y + 30, 37, 38)
                    } else {
                        self.filterButton?.frame = CGRectMake((self.view.frame.width - 49)/2, y + 30, 49, 50)
                    }
                    self.filterButton?.setImage(UIImage(named:"filterIcon"), forState: .Normal)
                }
            })
        } else {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
            if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
                self.topCell = topCell
                self.didSwipeUp(nil)
            }
        }
    }

    func didSwipeDown(sender: AnyObject?) {
        if recording {
            return
        }
        if let cell = topCell, indexPath = tableView.indexPathForCell(cell) {
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                }, completion: { (completed: Bool) -> Void in
            })
            if let secondCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section)) as? EventCardTableViewCell {
                topCell = secondCell
                UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.AllowUserInteraction, animations: { () -> Void in
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: indexPath.row - 1, inSection: indexPath.section), atScrollPosition: .Top, animated: false)
                    }, completion: { (completed: Bool) -> Void in
                        if (completed) {

                        }
                })
            }
        }
    }
    
    private func showAllEvents() {
        Mixpanel.sharedInstance().track("Tab ALL")
        self.noPostCellShown = false
        selectedSavedPostIndexPath = nil
        self.navigationController?.toolbarHidden = false
        tooltipSavedPosts?.removeFromSuperview()
        if self.browseControllerTab != .All {
            self.animationFinished = false
            self.stateType = .Loading
            self.tableView.reloadData()
            self.events = [Event]()
            self.browseControllerTab = .All
            self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
        }
        
        //        //State animation changes
        //        self.noPostCellShown = false
        //        self.navigationController?.toolbarHidden = false
        //        self.filterButton?.alpha = 0
        //        tooltipSavedPosts?.removeFromSuperview()
        //        animateAwayCells({ () -> Void in
        //            self.browseControllerTab = .All
        //            self.events = [Event]()
        //            self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
        //        })
        //        //-----
    }
    
    private func showSavedEvents() {
        Mixpanel.sharedInstance().track("Tab SAVED")
        self.noPostCellShown = false
        self.navigationController?.toolbarHidden = false
        filterButton?.alpha = 0
        animateAwayCells({ () -> Void in
            self.browseControllerTab = .Saved
            self.events = [Event]()
            self.tableView.reloadData()
            if var events = PFUser.currentUser()?["savedEvents"] as? [Event] {
                SVProgressHUD.dismiss()
                self.hasQueried = true
                self.queryIsBusy = false
                
                self.events = events
                
                if events.count > 0 {
                    //NSUserDefaults.standardUserDefaults().setBool(false, forKey: "SavedPostsFirstTap")
                    if NSUserDefaults.standardUserDefaults().boolForKey("SavedPostsFirstTap") == false {
                        self.addSavedPostsTooltip()
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "SavedPostsFirstTap")
                    }
                }
                self.tableView.reloadData()
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
                if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
                    self.topCell = topCell
                    self.topCell?.presentCardWithAnimation()
                    if self.browseControllerTab == .All {
                        self.filterButton?.alpha = 1
                        self.filterButton?.hidden = true
                    }
                    self.shouldFetch = false
                }
            }
        })
    }

    private func showTodayEvents() {
        Mixpanel.sharedInstance().track("Tab TODAY")
        if self.browseControllerTab == .Today {
            return
        }
        selectedSavedPostIndexPath = nil
        self.allEvents = self.events
        self.noPostCellShown = false
        self.navigationController?.toolbarHidden = false
        //filterButton?.alpha = 1
        self.browseControllerTab = .Today
        self.stateType = .Loading
        self.animationFinished = false
        self.events = [Event]()
        tooltipSavedPosts?.removeFromSuperview()
        animateAwayCells({ () -> Void in
            self.tableView.reloadData()
            self.reloadTodayPosts()
            
        })
    }
    
    func reloadTodayPosts() {
        let innerQuery = PFQuery(className: "PastEvent")
        if let currentUser = PFUser.currentUser() {
            if let objectId = currentUser.objectId {
                innerQuery.whereKey("user", equalTo: objectId)
            }
        }
        
        let query = Event.query()
        query?.limit = 100
        query?.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
        query?.whereKey("location", nearGeoPoint: BrowseEventsTableViewController.lastSavedLocation, withinMiles: 1000000)
        self.extraQueryConstraints(query: query)
        if let currentUser = PFUser.currentUser() {
            if let admin = currentUser["admin"] as? Bool {
                if admin == false {
                    query?.whereKey("objectId", doesNotMatchKey: "event", inQuery: innerQuery)
                }
            } else {
                query?.whereKey("objectId", doesNotMatchKey: "event", inQuery: innerQuery)
            }
        }
        //            if let currentUser = PFUser.currentUser(), let admin = currentUser["admin"] as? Bool where admin == false {
        //                query?.whereKey("objectId", doesNotMatchKey: "event", inQuery: innerQuery)
        //            }
        query?.whereKey("eventDate", lessThanOrEqualTo: NSDate().dateAtStartOfDay().dateByAddingDays(1))
        self.queryIsBusy = true
        query?.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
            self.queryIsBusy = false
            self.hasQueried = true
            if error == nil {
                if let events = objects as? [Event] {
                    var list = [Event]()
                    for event in events {
                        if let filter = event["filterRequest"] as? PFObject {
                            
                            var years = false
                            var genderBool = false
                            if let male = filter["allowMale"] as? Bool, let gender = PFUser.currentUser()!["gender"] as? String {
                                if gender == "male" && male == true {
                                    genderBool = true
                                }
                            }
                            
                            if let female = filter["allowFemale"] as? Bool, let gender = PFUser.currentUser()!["gender"] as? String {
                                if gender == "female" && female == true {
                                    genderBool = true
                                }
                            }
                            
                            if let lowerBound = filter["birthdateLowerBound"] as? Int, let birthday = PFUser.currentUser()!["birthdate"] as? NSDate {
                                let lowerDate = NSDate().dateByAddingYears(-lowerBound)
                                if birthday.compare(lowerDate) == .OrderedAscending {
                                    years = false
                                } else {
                                    years = true
                                }
                            }
                            
                            if let upperBound = filter["birthdateUpperBound"] as? Int, let birthday = PFUser.currentUser()!["birthdate"] as? NSDate {
                                let upperDate = birthday.dateByAddingYears(upperBound)
                                if NSDate().compare(upperDate) == .OrderedDescending {
                                    years = false
                                } else {
                                    years = true
                                }
                            }
                            
                            if genderBool == true && years == true {
                                //list.append(event)
                                let user = event.owner
                                if let userID = user.objectId, savedUserID = NSUserDefaults.standardUserDefaults().objectForKey("currentUser") as? String{
                                    if let banUsersIds = NSUserDefaults.standardUserDefaults().objectForKey("BanUsers") as? [String] {
                                        var shouldInclude = true
                                        for banUserId in banUsersIds {
                                            if banUserId == userID {
                                                shouldInclude = false
                                            }
                                        }
                                        if userID != savedUserID && shouldInclude == true {
                                            list.append(event)
                                        }
                                    } else {
                                        if userID != savedUserID {
                                            list.append(event)
                                        }
                                    }
                                } else {
                                    list.append(event)
                                }
                                
                            }
                            
                        } else {
                            //list.append(event)
                            let user = event.owner
                            if let userID = user.objectId, savedUserID = NSUserDefaults.standardUserDefaults().objectForKey("currentUser") as? String{
                                if let banUsersIds = NSUserDefaults.standardUserDefaults().objectForKey("BanUsers") as? [String] {
                                    var shouldInclude = true
                                    for banUserId in banUsersIds {
                                        if banUserId == userID {
                                            shouldInclude = false
                                        }
                                    }
                                    if userID != savedUserID && shouldInclude == true {
                                        list.append(event)
                                    }
                                } else {
                                    if userID != savedUserID {
                                        list.append(event)
                                    }
                                }
                            } else {
                                list.append(event)
                            }
                        }
                    }
                    
                    self.query = query
                    self.events = list
                    if let currentUser = PFUser.currentUser() {
                        if let admin = currentUser["admin"] as? Bool {
                            if admin == true {
                                self.events = events
                            }
                        } else {
                            //self.events = events
                        }
                    }
                    //                        if let currentUser = PFUser.currentUser(), let admin = currentUser["admin"] as? Bool where admin == true {
                    //                            self.events = events
                    //                        }
                    //self.events = events
                    if self.animationFinished == false {
                        self.reloadNeeded = true
                    } else {
                        self.tableView.reloadData()
                    }
                    
                    //state animation changes
                    //                        self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
                    //                        if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
                    //                            self.topCell = topCell
                    //                            self.topCell?.presentCardWithAnimation()
                    //                        }
                    //------
                    
                    if events.count < query?.limit {
                        self.shouldFetch = false
                    } else {
                        self.shouldFetch = true
                    }
                }
            } else {
                //ErrorManager.handleError(error)
            }
        })
    }
    
    func addSavedPostsTooltip() {
        let tooltip1 = UIView(frame:  CGRectMake(view.frame.size.width/2 - 65, view.frame.size.height/3, 140, 82))
        tooltip1.backgroundColor = UIColor.clearColor()
        tooltipSavedPosts = tooltip1
        let line1 = UIImageView(frame: CGRectMake(tooltip1.frame.size.width/2 - 13, 0, 26, 12))
        line1.backgroundColor = UIColor.clearColor()
        line1.contentMode = .ScaleAspectFit
        line1.image = UIImage(named: "triangle")
        savedPostsLine = line1
        tooltip1.addSubview(line1)
        let messageView1 = UIView(frame: CGRectMake(0 , 10, tooltip1.frame.size.width, 70))
        messageView1.backgroundColor = UIColor(netHex: 0x211E23)
        messageView1.layer.cornerRadius = 4
        messageView1.layer.borderWidth = 1
        messageView1.layer.borderColor = UIColor(netHex: 0xEEEEEE).CGColor
        messageView1.clipsToBounds = true
        tooltip1.addSubview(messageView1)
        let titleLabel1 = UILabel(frame: CGRectMake(0, 0, messageView1.frame.size.width, 20))
        titleLabel1.textAlignment = .Center
        titleLabel1.font = UIFont(name: "Raleway-Bold", size: 16.0)
        titleLabel1.textColor = UIColor(netHex: 0x211E23)
        titleLabel1.backgroundColor = UIColor(netHex: 0xEEEEEE)
        titleLabel1.text = "SWIPE"
        messageView1.addSubview(titleLabel1)
        let messageLabel1 = UILabel(frame: CGRectMake(0, 20, messageView1.frame.size.width, messageView1.frame.size.height - 20))
        messageLabel1.numberOfLines = 2
        messageLabel1.textAlignment = .Center
        messageLabel1.font = UIFont(name: "Raleway-SemiBold", size: 14.0)
        messageLabel1.textColor = UIColor(netHex: 0xEEEEEE)
        messageLabel1.backgroundColor = UIColor(netHex: 0x1098F7)
        let messageText1 = "Swipe left to see more options"
        messageLabel1.text = messageText1
        messageView1.addSubview(messageLabel1)
        self.view.addSubview(tooltipSavedPosts!)
        
        tooltipSavedPosts?.alpha = 0
        tooltipSavedPosts?.transform = CGAffineTransformMakeTranslation(0, 40)
        UIView.animateWithDuration(0.4, delay: 0.5, options: .CurveEaseInOut, animations: {
            self.tooltipSavedPosts?.alpha = 1
            self.tooltipSavedPosts?.transform = CGAffineTransformMakeTranslation(0, 0)
        }) { (finished) in
            
        }
    }

    private func animateAwayCells(completion: () -> Void) {
        var count = 1
        topCell?.hideCardWithAnimation(true)
        var i = 0.0
        for cell in tableView.visibleCells {
            UIView.animateWithDuration(0.6, delay: Double(i*0.2), usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                cell.alpha = 0
                }, completion: { (completed: Bool) -> Void in
                    if count == self.tableView.visibleCells.count {
                        completion()
                    }
                    count += 1
            })
            i += 1
        }

    }

    // MARK: Auxiliary Methods

    func showFacebookLoginProcedure(message: String) {
        let alert = UIAlertController(title: "Please Sign In.", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action: UIAlertAction) in

        }))
        alert.addAction(UIAlertAction(title: "Login", style: UIAlertActionStyle.Default, handler: { (loginAction: UIAlertAction) in
            self.performSegueWithIdentifier("showLoginScreen", sender: self)
        }))
        self.presentViewController(alert, animated: true, completion: {

        })
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

    func countUnreadMessagesWithCompletion(completion: (Int) -> Void) {
        let query = LYRQuery(queryableClass: LYRMessage.self)
        let unreadPredicate = LYRPredicate(property: "isUnread", predicateOperator: LYRPredicateOperator.IsEqualTo, value: true)
        let userPredicate = LYRPredicate(property: "sender.userID", predicateOperator: LYRPredicateOperator.IsNotEqualTo, value: AppDelegate.layerClient?.authenticatedUserID)
        query.predicate = LYRCompoundPredicate(type: .And, subpredicates: [unreadPredicate, userPredicate])
        AppDelegate.layerClient?.countForQuery(query, completion: { (count: UInt, error: NSError?) -> Void in
            if error != nil {
            } else {
                completion(Int(count))
            }
        })
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let navigationController = self.navigationController {
            if activityIndicatorView.isDescendantOfView(navigationController.view) {
                if traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
                    if let touch = touches.first {
                        let force = touch.force/touch.maximumPossibleForce
                        activityIndicatorView.size = 140*(1+force)
                    }
                }
            }
        }
    }

    func removeVoiceNoteRecorderWithAnimation() {
        self.voiceNoteRecorder?.removeFromSuperview()
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.tabBarController?.tabBar.alpha = 1
            }, completion: { (completed: Bool) -> Void in
                if completed {
                    self.tabBarController?.tabBar.hidden = false
                }
        })
        for cell in self.tableView.visibleCells {
            UIView.animateWithDuration(0.5, animations: { () -> Void in
                cell.alpha = 1
                if let cell = cell as? EventCardTableViewCell {
                    cell.uploadingMode = false
                }
            })
        }
        self.voiceNoteRecorder = nil
    }

    func stopRecording() {
        if let voiceNoteRecorder = voiceNoteRecorder {
            voiceNoteRecorder.stopRecording({ (success, error, url) -> Void in
                if let success = success {
                    if let url = url, topCell = self.topCell, indexPath = self.tableView.indexPathForCell(topCell) where indexPath.row < self.events.count {
                        let event = self.events[indexPath.row]
                        let eventResponse = EventResponse()
                        eventResponse.parentEvent = event
                        if let user = PFUser.currentUser() {
                            eventResponse.repsondent = user
                        }
                        eventResponse.timeStamp = NSDate()
                        //KGStatusBar.showErrorWithStatus("Sending voice note...")

                        if let data = NSData(contentsOfURL: url) {
                            if let file = PFFile(name: url.lastPathComponent, data: data) {
                                eventResponse.voiceNote = file
                            }
                        }

                        eventResponse.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                            if let error = error {
                                ErrorManager.handleError(error)
                            } else {
                                voiceNoteRecorder.completeUploadWithAnimation()
                                //KGStatusBar.showSuccessWithStatus("Voice note sent")
                                self.topCell?.showUploadCompletion(success)
                                self.topCell?.recordingMode = false
                                self.didSwipeUp(nil)
                                event.responses.append(eventResponse)
                                event.saveEventually()

                                self.removeVoiceNoteRecorderWithAnimation()
                            }
                        })

                    }

                }
                if let error = error {
                    ErrorManager.handleError(error)
                }
            })

        }
    }

    func distanceBetween(point p1: CGPoint, andPoint p2: CGPoint) -> CGFloat {
        return sqrt(pow((p2.x - p1.x), 2) + pow((p2.y - p1.y), 2))
    }

    private func askForPermissions() {
        pScope.addPermission(LocationWhileInUsePermission(), message: "Approximate location is needed to help users find things around them.")
        //pScope.addPermission(MicrophonePermission(), message: "Microphone access is needed to communicate with other users via voice notes.")
        pScope.show({ (finished, results) -> Void in
            }, cancelled: { (results) -> Void in
                self.locationManager.requestLocation()
        })
    }

    // MARK: Bar Button Actions

    func postsBarButtonItemTapped() {
        nextShown = true
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            showFacebookLoginProcedure("This is where your own posts are kept once you create them, but first you have to log in using Facebook.\nIt's quick and used only to verify your identity.")
        } else {
            //topCell?.hideCardWithAnimation(true)
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.0 * Double(NSEC_PER_SEC)))
            //dispatch_after(delayTime, dispatch_get_main_queue()) {
                if self.pushedPosts == false {
                    self.performSegueWithIdentifier("toPosts", sender: self)
                    self.pushedPosts = true
                    if self.browseControllerTab != .Saved {
//                        self.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: self.events.count, inSection: 0)], withRowAnimation: .None)
                    }
                }
            //}
        }
    }

    func messagesBarButtonItemTapped() {
        nextShown = true
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            showFacebookLoginProcedure("This is where you can message fellow users, but first you have to log in using Facebook.\nIt's quick and used only to verify your identity.")
        } else {
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            } catch {

            }

            if let client = AppDelegate.layerClient {
                self.pushedChats = true
                if let _ = client.authenticatedUserID {
                    let controller = ConversationListViewController(layerClient: client)
                    dispatch_async(dispatch_get_main_queue(), {
                        if self.pushedChats == true {
                            self.performSegueWithIdentifier("MessagesSegue", sender: self)
                            self.toChatScreen = true
                            //self.navigationController?.pushViewController(controller, animated: true)
                        }
                    })
                }
            } else {
                self.pushedChats = true
                let appID = NSURL(string: "layer:///apps/staging/45f026f2-a10f-11e5-8f8b-4e4f000000ac")
                AppDelegate.layerClient = LYRClient(appID: appID!)
                
                AppDelegate.layerClient?.connectWithCompletion({ (success: Bool, error: NSError?) -> Void in
                    if let error = error {
                        SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                    } else {
                        let userIDString = PFUser.currentUser()?.objectId
                        
                        self.authenticateLayerWithUserID(userIDString!, completion: { (success, error) -> Void in
                            if !success {
                                
                            } else {
                                if let client = AppDelegate.layerClient {
                                    if let _ = client.authenticatedUserID {
                                        let controller = ConversationListViewController(layerClient: client)
                                        dispatch_async(dispatch_get_main_queue(), {
                                            if self.pushedChats == false {
                                                //self.performSegueWithIdentifier("MessagesSegue", sender: self)
                                                self.toChatScreen = true
                                                self.navigationController?.pushViewController(controller, animated: true)
                                            }
                                        })
                                    }
                                }
                            }
                        })
                        
                    }
                })
            }
        }
    }
    
    func authenticateLayerWithUserID(userID: String, completion :(success: Bool, error: NSError?) -> Void) {
        if let authenticatedUserID = AppDelegate.layerClient!.authenticatedUserID {
            completion(success:true, error:nil)
        } else {
            AppDelegate.layerClient!.requestAuthenticationNonceWithCompletion({(nonce, error) in
                if let nonce = nonce {
                    //print("nonce \(nonce)")
                    
                    if let user = PFUser.currentUser(), let userId = user.objectId {
                        PFCloud.callFunctionInBackground("generateToken", withParameters: ["nonce": nonce, "userID":userId], block: { (token: AnyObject?, error: NSError?) -> Void in
                            if let token = token as? NSString {
                                AppDelegate.layerClient?.authenticateWithIdentityToken(String(token), completion: { (string: String?, error: NSError?) -> Void in
                                    
                                })
                            }
                        })
                    }
                    
                } else {
                    completion(success:false, error:error)
                }
            })
        }
        return
    }


    func addPostBarButtonItemTapped() {
        nextShown = true
        if PFAnonymousUtils.isLinkedWithUser(PFUser.currentUser()) {
            showFacebookLoginProcedure("This is where you can create your own posts, but first you have to log in using Facebook.\nIt's quick and used only to verify your identity.")
        } else {
            //topCell?.hideCardWithAnimation(true)
            //self.filterButton?.alpha = 0
            self.navigationItem.hidesBackButton = true
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.0 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                self.createdPostTapped = true
                if let newPostVC = self.storyboard?.instantiateViewControllerWithIdentifier("newPostViewController") as? InputViewController {
                    self.navigationController?.pushViewController(newPostVC, animated: false)
                }
                //self.performSegueWithIdentifier("toNewPost", sender: self)
            }
        }
    }
    
    //MARK: - SavedPostDelegate
    func savedPostDeleted() {
        self.tableHeaderView?.decrementNumberOfItemsInTab(2)
    }
    
    func savedPostResponded(event: Event) {
        PFUser.currentUser()?.removeObject(event, forKey: "savedEvents")
        PFUser.currentUser()?.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
            if let error = error {
                ErrorManager.handleError(error)
            } else {
                if let indexPath = self.selectedSavedPostIndexPath {
                    self.events.removeAtIndex(indexPath.row)
                }
                self.tableHeaderView?.decrementNumberOfItemsInTab(2)
                //self.tableView.reloadData()
            }
        })
    }
    
    func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if toVC.isKindOfClass(EventResponsesTableViewController) || toVC.isKindOfClass(ApplicationMenuTableViewController) {
            let animator = CustomPushTransition()
            animator.appearing = true
            return animator
        } else if fromVC.isKindOfClass(EventResponsesTableViewController) || fromVC.isKindOfClass(ApplicationMenuTableViewController) {
            let animator = CustomPushTransition()
            animator.appearing = false
            return animator
        } else {
            return nil
        }
    }
    
    //MARK: - StateAnimationDelegate
    func loadingAnimationFinished() {
        print("Loading Finished - true")
        self.animationFinished = true
        self.loadingStarted = false
        let cells = self.tableView.visibleCells
        if self.events.count > 0 && self.reloadNeeded == true {
            if let cell = cells.first as? NoPostAnimatedTableViewCell {
                print("Loading to Post")
                cell.loadingToPostTransition()
            }
        }
        
        if self.events.count == 0 && self.reloadNeeded == true {
            if let cell = cells.first as? NoPostAnimatedTableViewCell {
                print("Loading to No Post")
                cell.loadingToNoPostsTransition()
            }
        }
    }
    
    func loadingToPostAnimationFinished() {
        self.animationFinished = true
        if self.reloadNeeded == true {
            self.tableView.reloadData()
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
            if let topCell = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? EventCardTableViewCell {
                self.topCell = topCell
                
                self.topCell?.presentCardWithAnimation()
                if self.browseControllerTab == .All {
                    self.filterButton?.alpha = 1
                    if let vc = self.navigationController?.topViewController as? BrowseEventsTableViewController { //filterButton other screens visibility bug
                        self.filterButton?.hidden = false
                    }
                }
            }
        }
    }
    
    func loadingToNoPostAnimationFinished() {
        
    }
    
    func noPostsAnimationFinished() {
        
    }
    
    func noPostsToLoadingAnimationFinished() {
        self.animationFinished = true
        let cells = self.tableView.visibleCells
        if self.events.count > 0 && self.reloadNeeded == true {
            for cell in cells {
                if let cell = cell as? NoPostAnimatedTableViewCell {
                    print("NOPOST - LOADING")
                    cell.loadingToPostTransition()
                    break
                }
            }
        }
        
        if self.events.count == 0 && self.reloadNeeded == true {
            for cell in cells {
                if let cell = cell as? NoPostAnimatedTableViewCell {
                    print("NOPOST - NOPOST")
                    cell.loadingToNoPostsTransition()
                    break
                }
            }
        }
    }
    
    func refreshButtonTapped() {
        let cells = self.tableView.visibleCells
        for cell in cells {
            if let cell = cell as? NoPostAnimatedTableViewCell {
                cell.noPostsToLoadingTransition()
                self.stateType = .Loading
                self.animationFinished = false
                var banUsers = [String]()
                let userQuery = PFQuery(className: "BlockedUsers")
                if let currentUser = PFUser.currentUser() {
                    if let objectId = currentUser.objectId {
                        userQuery.whereKey("userId", equalTo: objectId)
                        userQuery.getFirstObjectInBackgroundWithBlock {
                            (object: PFObject?, error: NSError?) -> Void in
                            if error == nil {
                                if let user = object {
                                    if let blockedUsers = user["blockedUsers"] as? [PFUser] {
                                        for blockUser in blockedUsers {
                                            banUsers.append(blockUser.objectId!)
                                        }
                                    }
                                }
                                NSUserDefaults.standardUserDefaults().setObject(banUsers, forKey: "BanUsers")
                                NSUserDefaults.standardUserDefaults().synchronize()
                                
                            } else {
                                //print("Error: \(error!) \(error!.userInfo)")
                            }
                        }
                    }
                }
                if browseControllerTab == .All {
                    self.events = [Event]()
                    self.queryEventsBy(BrowseEventsTableViewController.lastSavedLocation, fromLocalDatastore: false)
                } else if (browseControllerTab == .Today) {
                    self.reloadTodayPosts()
                }
                break
            }
        }
    }
    
    func filterButtonTapped() {
        nextShown = true
        self.filterTapped()
    }
    
    func shareButtonTapped() {
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
            
            //activityVC.popoverPresentationController?.sourceView = sender
            self.presentViewController(activityVC, animated: true, completion: nil)
        }
    }
 }
