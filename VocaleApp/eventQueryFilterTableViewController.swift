//
//  eventQueryFilterTableViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/02/11.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class eventQueryFilterTableViewController: UITableViewController, BEMCheckBoxDelegate, TTRangeSliderDelegate {

    var createFilter = false
    weak var delegate: FilterDelegate?
    var resultingQueryWithConstraints: (query: PFQuery?) -> Void = {_ in }
    var didFilterWithCompletion: (resultingQueryWithConstraints: (query: PFQuery?) -> Void) -> Void = {queryWithConstraints in}
    var didSelectFilterWithCompletion: (resultingFilter: PFObject?) -> Void = {_ in }
    var resultingFilterRequest: PFObject = PFObject(className: "FilterRequest")
    var eventInCreation: PFObject?
    var currentUserFilter = PFObject(className: "Filter") {
        didSet {
            let setAnyoneOff = {
                self.anyoneButton.setOn(false, animated: false)
            }
            if let bool = self.currentUserFilter["allowFemale"] as? Bool {
                if bool {
                    self.womenRadioButton.setOn(true, animated: true)
                } else {
                    setAnyoneOff()
                    self.womenRadioButton.setOn(false, animated: true)
                }
            }
            if let bool = self.currentUserFilter["allowMale"] as? Bool {
                if bool {
                    self.menRadioButton.setOn(true, animated: true)
                } else {
                    setAnyoneOff()
                    self.menRadioButton.setOn(false, animated: true)
                }
            }
//            if let bool = self.currentUserFilter["allowGay"] as? Bool {
//                if bool {
//                    self.gaySexualityRadioButton.setOn(true, animated: true)
//                } else {
//                    setAnyoneOff()
//                    self.gaySexualityRadioButton.setOn(false, animated: true)
//                }
//            }
//            if let bool = self.currentUserFilter["allowStraight"] as? Bool {
//                if bool {
//                    self.straightSexualityRadioButton.setOn(true, animated: true)
//                } else {
//                    setAnyoneOff()
//                    self.straightSexualityRadioButton.setOn(false, animated: true)
//                }
//            }
//            if let bool = self.currentUserFilter["allowBi"] as? Bool {
//                if bool {
//                    self.bisexualSexualityRadioButton.setOn(true, animated: true)
//                } else {
//                    setAnyoneOff()
//                    self.bisexualSexualityRadioButton.setOn(false, animated: true)
//                }
//            }
//            if let bool = self.currentUserFilter["allowSingles"] as? Bool {
//                if bool {
//                    self.singleStatusButton.setOn(true, animated: true)
//                } else {
//                    setAnyoneOff()
//                    self.singleStatusButton.setOn(false, animated: true)
//                }
//            }
//
//            if let bool = self.currentUserFilter["allowTaken"] as? Bool {
//                if bool {
//                    self.relationshipStatusButton.setOn(true, animated: true)
//                } else {
//                    setAnyoneOff()
//                    self.relationshipStatusButton.setOn(false, animated: true)
//                }
//            }
            if let lastLocationRadius = currentUserFilter["lastLocationRadius"] as? Double {
                if Float(lastLocationRadius) < geographicRadiusSlider.selectedMaximum {
                    setAnyoneOff()
                }
                geographicRadiusSlider.selectedMaximum = Float(lastLocationRadius)
            }
            if let birthdateLowerBound = currentUserFilter["birthdateLowerBound"] as? Double, let birthdateUpperBound = currentUserFilter["birthdateUpperBound"] as? Double {
                if Float(birthdateUpperBound) < ageRangeSlider.selectedMaximum || Float(birthdateLowerBound) > ageRangeSlider.selectedMinimum {
                    setAnyoneOff()
                }
                ageRangeSlider.selectedMinimum = Float(birthdateLowerBound)
                ageRangeSlider.selectedMaximum = Float(birthdateUpperBound)
            }
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }

    @IBOutlet weak var anyoneButton: BEMCheckBox! {
        didSet {
            anyoneButton.tintColor = UIColor.vocaleFilterTextColor()
            anyoneButton.onTintColor = UIColor.vocaleTextGreyColor()
            anyoneButton.onCheckColor = UIColor.vocaleTextGreyColor()
            anyoneButton.onFillColor = UIColor.vocaleTextGreyColor()
            anyoneButton.onAnimationType = .Bounce
            anyoneButton.offAnimationType = .Bounce
            anyoneButton.setOn(true, animated: false)
            anyoneButton.delegate = self
        }
    }

    @IBOutlet weak var menRadioButton: BEMCheckBox! {
        didSet {
            menRadioButton.tintColor = UIColor.vocaleFilterTextColor()
            menRadioButton.onTintColor = UIColor.vocaleTextGreyColor()
            menRadioButton.onCheckColor = UIColor.vocaleTextGreyColor()
            menRadioButton.onFillColor = UIColor.vocaleTextGreyColor()
            menRadioButton.onAnimationType = .Bounce
            menRadioButton.offAnimationType = .Bounce
            menRadioButton.setOn(true, animated: false)
            menRadioButton.delegate = self
        }
    }
    @IBOutlet weak var womenRadioButton: BEMCheckBox! {
        didSet {
            womenRadioButton.tintColor = UIColor.vocaleFilterTextColor()
            womenRadioButton.onTintColor = UIColor.vocaleTextGreyColor()
            womenRadioButton.onFillColor = UIColor.vocaleTextGreyColor()
            womenRadioButton.onCheckColor = UIColor.vocaleTextGreyColor()
            womenRadioButton.onAnimationType = .Bounce
            womenRadioButton.offAnimationType = .Bounce
            womenRadioButton.setOn(true, animated: false)
            womenRadioButton.delegate = self
        }
    }


    @IBOutlet weak var geographicRadiusSlider: TTRangeSlider! {
        didSet {
            geographicRadiusSlider.disableRange = true
            let numberFormatter = NSNumberFormatter()
            numberFormatter.positiveSuffix = "km"
            geographicRadiusSlider.numberFormatterOverride = numberFormatter
            geographicRadiusSlider.tintColor = UIColor.vocaleTextGreyColor()

            geographicRadiusSlider.selectedMaximum = Float(200)
            geographicRadiusSlider.delegate = self
        }
    }
    @IBOutlet weak var ageRangeSlider: TTRangeSlider! {
        didSet {
            let numberFormatter = NSNumberFormatter()
            numberFormatter.positiveSuffix = "years"
            ageRangeSlider.numberFormatterOverride = numberFormatter
            ageRangeSlider.selectedMaximum = Float(100)
            ageRangeSlider.selectedMinimum = Float(18)
            ageRangeSlider.tintColor = UIColor.vocaleTextGreyColor()
            ageRangeSlider.delegate = self
        }
    }

    @IBOutlet weak var gaySexualityRadioButton: BEMCheckBox! {
        didSet {
            gaySexualityRadioButton.tintColor = UIColor.vocaleFilterTextColor()
            gaySexualityRadioButton.onTintColor = UIColor.vocaleTextGreyColor()
            gaySexualityRadioButton.onFillColor = UIColor.vocaleTextGreyColor()
            gaySexualityRadioButton.onCheckColor = UIColor.vocaleTextGreyColor()
            gaySexualityRadioButton.onAnimationType = .Bounce
            gaySexualityRadioButton.offAnimationType = .Bounce
            gaySexualityRadioButton.setOn(true, animated: false)
            gaySexualityRadioButton.delegate = self
        }
    }
    @IBOutlet weak var bisexualSexualityRadioButton: BEMCheckBox! {
        didSet {
            bisexualSexualityRadioButton.tintColor = UIColor.vocaleFilterTextColor()
            bisexualSexualityRadioButton.onTintColor = UIColor.vocaleTextGreyColor()
            bisexualSexualityRadioButton.onFillColor = UIColor.vocaleTextGreyColor()
            bisexualSexualityRadioButton.onCheckColor = UIColor.vocaleTextGreyColor()
            bisexualSexualityRadioButton.onAnimationType = .Bounce
            bisexualSexualityRadioButton.offAnimationType = .Bounce
            bisexualSexualityRadioButton.setOn(true, animated: false)
            bisexualSexualityRadioButton.delegate = self
        }
    }
    @IBOutlet weak var straightSexualityRadioButton: BEMCheckBox! {
        didSet {
            straightSexualityRadioButton.tintColor = UIColor.vocaleFilterTextColor()
            straightSexualityRadioButton.onTintColor = UIColor.vocaleTextGreyColor()
            straightSexualityRadioButton.onFillColor = UIColor.vocaleTextGreyColor()
            straightSexualityRadioButton.onCheckColor = UIColor.vocaleTextGreyColor()
            straightSexualityRadioButton.onAnimationType = .Bounce
            straightSexualityRadioButton.offAnimationType = .Bounce
            straightSexualityRadioButton.setOn(true, animated: false)
            straightSexualityRadioButton.delegate = self
        }
    }
    @IBOutlet weak var relationshipStatusButton: BEMCheckBox! {
        didSet {
            relationshipStatusButton.tintColor = UIColor.vocaleFilterTextColor()
            relationshipStatusButton.onTintColor = UIColor.vocaleTextGreyColor()
            relationshipStatusButton.onFillColor = UIColor.vocaleTextGreyColor()
            relationshipStatusButton.onCheckColor = UIColor.vocaleTextGreyColor()
            relationshipStatusButton.onAnimationType = .Bounce
            relationshipStatusButton.offAnimationType = .Bounce
            relationshipStatusButton.setOn(true, animated: false)

            relationshipStatusButton.delegate = self
        }
    }
    @IBOutlet weak var complicatedStatusButton: BEMCheckBox! {
        didSet {
            complicatedStatusButton.tintColor = UIColor.vocaleFilterTextColor()
            complicatedStatusButton.onTintColor = UIColor.vocaleTextGreyColor()
            complicatedStatusButton.onFillColor = UIColor.vocaleTextGreyColor()
            complicatedStatusButton.onCheckColor = UIColor.vocaleTextGreyColor()
            complicatedStatusButton.onAnimationType = .Bounce
            complicatedStatusButton.offAnimationType = .Bounce
            complicatedStatusButton.setOn(true, animated: false)
            complicatedStatusButton.delegate = self
        }
    }
    @IBOutlet weak var singleStatusButton: BEMCheckBox! {
        didSet {
            singleStatusButton.tintColor = UIColor.vocaleFilterTextColor()
            singleStatusButton.onTintColor = UIColor.vocaleTextGreyColor()
            singleStatusButton.onFillColor = UIColor.vocaleTextGreyColor()
            singleStatusButton.onCheckColor = UIColor.vocaleTextGreyColor()
            singleStatusButton.onAnimationType = .Bounce
            singleStatusButton.offAnimationType = .Bounce
            singleStatusButton.setOn(true, animated: false)
            singleStatusButton.delegate = self
        }
    }
    @IBOutlet weak var anyoneLabel: UILabel!

    // MARK: View Controller LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        if PFUser.currentUser()?["userFilter"] != nil {
            PFUser.currentUser()?["userFilter"].fetchIfNeededInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
                if let object = object where error == nil {
                    if self.createFilter == true {
                        self.currentUserFilter = object
                    }
                }
            })
        }
    }

    override func viewWillAppear(animated: Bool) {
        if self.view.frame.size.width > 320 {
            self.tableView.scrollEnabled = false
        }
        self.navigationController?.setToolbarHidden(false, animated: true)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
    }

    @IBAction func saveTapped(sender: AnyObject) {
        prepareForSave()
        navigationController?.popViewControllerAnimated(true)
    }

    override func viewWillDisappear(animated: Bool) {
        //prepareForSave()
        self.delegate?.filterDismissed()
    }

    // MARK: Actions

    func didTapCheckBox(checkBox: BEMCheckBox) {
        let specificCheckBoxes = [menRadioButton, womenRadioButton, gaySexualityRadioButton, bisexualSexualityRadioButton, straightSexualityRadioButton, relationshipStatusButton, singleStatusButton]
        switch checkBox {
        case anyoneButton:
            if anyoneButton.on {
                for button in specificCheckBoxes {
                    button.setOn(true, animated: true)
                }
                geographicRadiusSlider.selectedMaximum = Float(200)
                ageRangeSlider.selectedMaximum = Float(100)
                ageRangeSlider.selectedMinimum = Float(18)
            }
        default:
            anyoneButton.setOn(false, animated: true)
        }
    }

    // MARK: Auxiliary Methods

    func prepareForSave() {
        resultingQueryWithConstraints = {
            query in
            self.currentUserFilter["allowFemale"] = false
            self.currentUserFilter["allowMale"] = false
//            self.currentUserFilter["allowGay"] = false
//            self.currentUserFilter["allowStraight"] = false
//            self.currentUserFilter["allowBi"] = false
//            self.currentUserFilter["allowSingles"] = false
//            self.currentUserFilter["allowTaken"] = false

            if let userQuery = PFUser.query() {

                var allowedGenders = [String]()
                var allowedSexuality = [String]()
                var allowedRelationshipStatus = [String]()

                if self.womenRadioButton.on {
                    self.currentUserFilter["allowFemale"] = true
                    allowedGenders.append("female")
                }
                if self.menRadioButton.on {
                    self.currentUserFilter["allowMale"] = true
                    allowedGenders.append("male")
                }
//                if self.gaySexualityRadioButton.on {
//                    self.currentUserFilter["allowGay"] = true
//                    allowedSexuality.append("gay")
//                }
//                if self.straightSexualityRadioButton.on {
//                    self.currentUserFilter["allowStraight"] = true
//                    allowedSexuality.append("straight")
//                }
//                if self.bisexualSexualityRadioButton.on {
//                    self.currentUserFilter["allowBi"] = true
//                    allowedSexuality.append("bisexual")
//                }
//                if self.singleStatusButton.on {
//                    self.currentUserFilter["allowSingles"] = true
//                    allowedRelationshipStatus.append("single")
//                }
//                if self.relationshipStatusButton.on {
//                    self.currentUserFilter["allowTaken"] = true
//                    allowedRelationshipStatus.append("taken")
//                }
                
                if self.anyoneButton.on {
                    allowedGenders.removeAll()
                    allowedGenders.append("male")
                    allowedGenders.append("female")
                    
//                    allowedSexuality.removeAll()
//                    allowedSexuality.append("gay")
//                    allowedSexuality.append("straight")
//                    allowedSexuality.append("bisexual")
//                    
//                    allowedRelationshipStatus.removeAll()
//                    allowedRelationshipStatus.append("single")
//                    allowedRelationshipStatus.append("taken")
                } else {
                    if let lastLocation = PFUser.currentUser()?["lastLocation"] as? PFGeoPoint {
                        //print(Double(self.geographicRadiusSlider.selectedMaximum))
                        //userQuery.whereKey("lastLocation", nearGeoPoint: lastLocation, withinKilometers: Double(self.geographicRadiusSlider.selectedMaximum))
                        self.currentUserFilter["lastLocationRadius"] = Double(self.geographicRadiusSlider.selectedMaximum)
                        query?.whereKey("location", nearGeoPoint: lastLocation, withinMiles: Double(self.geographicRadiusSlider.selectedMaximum))
                    }
//                    userQuery.whereKey("birthdate", lessThan: NSDate().dateByAddingYears(-Int(self.ageRangeSlider.selectedMinimum)))
//                    userQuery.whereKey("birthdate", greaterThan: NSDate().dateByAddingYears(-Int(self.ageRangeSlider.selectedMaximum)))
                }

                userQuery.whereKey("gender", containedIn: allowedGenders)
                //userQuery.whereKey("sexuality", containedIn: allowedSexuality)
                //userQuery.whereKey("relationshipStatus", containedIn: allowedRelationshipStatus)

                self.currentUserFilter["birthdateLowerBound"] = Double(self.ageRangeSlider.selectedMinimum)
                self.currentUserFilter["birthdateUpperBound"] = Double(self.ageRangeSlider.selectedMaximum)
                self.currentUserFilter.saveEventually()
                PFUser.currentUser()?["userFilter"] = self.currentUserFilter
                self.currentUserFilter.saveInBackground()
                PFUser.currentUser()?.saveInBackground()
                if self.anyoneButton.on {
                    query?.whereKey("owner", matchesQuery:userQuery)
                } else {
                    if let birthdateQuery = PFUser.query() {
                        birthdateQuery.whereKeyDoesNotExist("birthdate")
                        if let rangeBirthdayQuery = PFUser.query() {
                            rangeBirthdayQuery.whereKey("birthdate", lessThan: NSDate().dateByAddingYears(-Int(self.ageRangeSlider.selectedMinimum)))
                            rangeBirthdayQuery.whereKey("birthdate", greaterThan: NSDate().dateByAddingYears(-Int(self.ageRangeSlider.selectedMaximum)))
                            
                            query?.whereKey("owner", matchesQuery:PFQuery.orQueryWithSubqueries([birthdateQuery, rangeBirthdayQuery]))
                            query?.whereKey("owner", matchesQuery:userQuery)
                        }
                    }
                }
                //query?.whereKey("owner", matchesQuery:userQuery)
            }
        }
        
        resultingFilterRequest["allowFemale"] = false
        resultingFilterRequest["allowMale"] = false
//        resultingFilterRequest["allowGay"] = false
//        resultingFilterRequest["allowStraight"] = false
//        resultingFilterRequest["allowBi"] = false
//        resultingFilterRequest["allowSingles"] = false
//        resultingFilterRequest["allowTaken"] = false

        if self.womenRadioButton.on {
            resultingFilterRequest["allowFemale"] = true
        }
        if self.menRadioButton.on {
            resultingFilterRequest["allowMale"] = true
        }
//        if self.gaySexualityRadioButton.on {
//            resultingFilterRequest["allowGay"] = true
//        }
//        if self.straightSexualityRadioButton.on {
//            resultingFilterRequest["allowStraight"] = true
//        }
//        if self.bisexualSexualityRadioButton.on {
//            resultingFilterRequest["allowBi"] = true
//        }
//        if self.gaySexualityRadioButton.on {
//            resultingFilterRequest["allowGay"] = true
//        }
//        if self.straightSexualityRadioButton.on {
//            resultingFilterRequest["allowStraight"] = true
//        }
//        if self.bisexualSexualityRadioButton.on {
//            resultingFilterRequest["allowBi"] = true
//        }
//        if self.relationshipStatusButton.on {
//            resultingFilterRequest["allowTaken"] = true
//        }
//        if self.singleStatusButton.on {
//            resultingFilterRequest["allowSingles"] = true
//        }
        if self.anyoneButton.on {
            resultingFilterRequest["anyone"] = true
        }


        if let lastLocation = PFUser.currentUser()?["lastLocation"] as? PFGeoPoint {

            resultingFilterRequest["lastLocation"] = lastLocation
            resultingFilterRequest["lastLocationRadius"] = Double(self.geographicRadiusSlider.selectedMaximum)
        }

        resultingFilterRequest["birthdateLowerBound"] = Double(self.ageRangeSlider.selectedMinimum)
        resultingFilterRequest["birthdateUpperBound"] = Double(self.ageRangeSlider.selectedMaximum)

        resultingFilterRequest.saveInBackground()
        if createFilter == true {
            self.resultingQueryWithConstraints(query: nil)
        }
        didFilterWithCompletion(resultingQueryWithConstraints: self.resultingQueryWithConstraints)
        didSelectFilterWithCompletion(resultingFilter: self.resultingFilterRequest)

    }

    // Mark: TTRangeSliderDelegate

    func rangeSlider(_: TTRangeSlider!, didChangeSelectedMinimumValue: Float, andMaximumValue: Float) -> Void {
        self.anyoneButton.setOn(false, animated: true)
    }

}
