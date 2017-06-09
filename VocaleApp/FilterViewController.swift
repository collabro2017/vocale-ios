//
//  FilterViewController.swift
//  VocaleApp
//
//  Created by Vladimir Kadurin on 9/2/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

enum FilterOptions {
    case who
    case age
    case distance
}

protocol FilterDelegate: class {
    func filterDismissed()
}

class FilterViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    weak var delegate: FilterDelegate?
    var createFilter = true
    var browseFilterTapped = false
    var resultingQueryWithConstraints: (query: PFQuery?) -> Void = {_ in }
    var didFilterWithCompletion: (resultingQueryWithConstraints: (query: PFQuery?) -> Void) -> Void = {queryWithConstraints in}
    var didSelectFilterWithCompletion: (resultingFilter: PFObject?) -> Void = {_ in }
    var resultingFilterRequest: PFObject = PFObject(className: "FilterRequest")
    var eventInCreation: PFObject?
    var currentUserFilter = PFObject(className: "Filter") {
        didSet {
//            var whoCell = WhoTableViewCell()
//            var ageCell = AgeTableViewCell()
//            var distanceCell = DistanceTableViewCell()
//
//            if let whoCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? WhoTableViewCell {
//                whoCell = whoCellTemp
//            }
//            if let ageCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? AgeTableViewCell {
//                ageCell = ageCellTemp
//            }
//            if let distanceCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as? DistanceTableViewCell {
//                distanceCell = distanceCellTemp
//            }
//            
//            whoCell.bothSignButton.selected  = false
//            whoCell.femaleSignButton.selected = false
//            whoCell.maleSignButton.selected = false
//            
//            if let bool = self.currentUserFilter["allowFemale"] as? Bool {
//                whoCell.femaleSignButton.selected = bool
//            }
//            if let bool = self.currentUserFilter["allowMale"] as? Bool {
//                whoCell.maleSignButton.selected = bool
//            }
//            
//            if whoCell.femaleSignButton.selected == true || whoCell.maleSignButton.selected == true {
//                whoCell.bothSignButton.selected  = true
//                whoCell.femaleSignButton.selected = false
//                whoCell.maleSignButton.selected = false
//            }

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.navigationController?.setToolbarHidden(false, animated: false)
        
        title = "Filters"
        
        if self.browseFilterTapped == false {
            if PFUser.currentUser()?["userFilter"] != nil {
                PFUser.currentUser()?["userFilter"].fetchIfNeededInBackgroundWithBlock({ (object: PFObject?, error: NSError?) -> Void in
                    if let object = object where error == nil {
                        if self.createFilter == true {
                            self.currentUserFilter = object
                            dispatch_async(dispatch_get_main_queue(), {
                                self.tableView.reloadData()
                            })
                            
                        }
                    }
                })
            }
        } else {
//            if let filter = NSUserDefaults.standardUserDefaults().objectForKey("AppliedFilter") as? PFObject {
//                self.currentUserFilter = filter
//                dispatch_async(dispatch_get_main_queue(), {
//                    self.tableView.reloadData()
//                })
//            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if self.view.frame.size.width > 320 {
            self.tableView.scrollEnabled = false
        }
        
        self.navigationController?.setToolbarHidden(false, animated: false)
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor(netHex: 0x211E23), NSFontAttributeName: UIFont(name: "Raleway-Bold", size: 18)!], forState: .Normal)
        self.navigationController?.toolbar.barTintColor = UIColor.vocaleTextGreyColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

//        if let whoCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? WhoTableViewCell {
//            whoCellTemp.bothSignButton.selected  = true
//        }
    }
    
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        prepareForSave()
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        //prepareForSave()
        self.delegate?.filterDismissed()
    }
    
    func prepareForSave() {
        resultingQueryWithConstraints = {
            query in
            self.currentUserFilter["allowFemale"] = false
            self.currentUserFilter["allowMale"] = false
            
            if let userQuery = PFUser.query() {
                
                var allowedGenders = [String]()
                var allowedSexuality = [String]()
                var allowedRelationshipStatus = [String]()
                
                var whoCell = WhoTableViewCell()
                var ageCell = AgeTableViewCell()
                var distanceCell = DistanceTableViewCell()
                
                if let whoCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? WhoTableViewCell {
                    whoCell = whoCellTemp
                }
                if let ageCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? AgeTableViewCell {
                    ageCell = ageCellTemp
                }
                if let distanceCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as? DistanceTableViewCell {
                    distanceCell = distanceCellTemp
                }
                
                if whoCell.femaleSignButton.selected == true {
                    self.currentUserFilter["allowFemale"] = true
                    allowedGenders.append("female")
                }
                if whoCell.maleSignButton.selected == true {
                    self.currentUserFilter["allowMale"] = true
                    allowedGenders.append("male")
                }
                
                if whoCell.bothSignButton.selected == true {
                    allowedGenders.removeAll()
                    self.currentUserFilter["allowFemale"] = true
                    self.currentUserFilter["allowMale"] = true
                    allowedGenders.append("male")
                    allowedGenders.append("female")
                }
                
                if let lastLocation = PFUser.currentUser()?["lastLocation"] as? PFGeoPoint {
                    self.currentUserFilter["lastLocationRadius"] = Double(distanceCell.distanceSlider.selectedMaximum)
                    query?.whereKey("location", nearGeoPoint: lastLocation, withinMiles: Double(distanceCell.distanceSlider.selectedMaximum))
                }
                
                userQuery.whereKey("gender", containedIn: allowedGenders)
                
                self.currentUserFilter["birthdateLowerBound"] = Double(ageCell.ageSlider.selectedMinimum)
                self.currentUserFilter["birthdateUpperBound"] = Double(ageCell.ageSlider.selectedMaximum)
                self.currentUserFilter.saveEventually()
                if self.browseFilterTapped == false {
                    PFUser.currentUser()?["userFilter"] = self.currentUserFilter
                    self.currentUserFilter.saveInBackground()
                    PFUser.currentUser()?.saveInBackground()
                }
                if let birthdateQuery = PFUser.query() {
                    birthdateQuery.whereKeyDoesNotExist("birthdate")
                    if let rangeBirthdayQuery = PFUser.query() {
                        rangeBirthdayQuery.whereKey("birthdate", lessThan: NSDate().dateByAddingYears(-Int(ageCell.ageSlider.selectedMinimum)))
                        rangeBirthdayQuery.whereKey("birthdate", greaterThan: NSDate().dateByAddingYears(-Int(ageCell.ageSlider.selectedMaximum)))
                        
                        query?.whereKey("owner", matchesQuery:PFQuery.orQueryWithSubqueries([birthdateQuery, rangeBirthdayQuery]))
                        query?.whereKey("owner", matchesQuery:userQuery)
                    }
                }
                //query?.whereKey("owner", matchesQuery:userQuery)
            }
        }
        
        resultingFilterRequest["allowFemale"] = false
        resultingFilterRequest["allowMale"] = false
        
        var whoCell = WhoTableViewCell()
        var ageCell = AgeTableViewCell()
        var distanceCell = DistanceTableViewCell()
        
        if let whoCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? WhoTableViewCell {
            whoCell = whoCellTemp
        }
        if let ageCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1)) as? AgeTableViewCell {
            ageCell = ageCellTemp
        }
        if let distanceCellTemp = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2)) as? DistanceTableViewCell {
            distanceCell = distanceCellTemp
        }
        
        if whoCell.femaleSignButton.selected == true {
            resultingFilterRequest["allowFemale"] = true
        }
        if whoCell.maleSignButton.selected == true {
            resultingFilterRequest["allowMale"] = true
        }
        if whoCell.bothSignButton.selected == true {
            resultingFilterRequest["anyone"] = true
        }
        
        
        if let lastLocation = PFUser.currentUser()?["lastLocation"] as? PFGeoPoint {
            
            resultingFilterRequest["lastLocation"] = lastLocation
            resultingFilterRequest["lastLocationRadius"] = Double(distanceCell.distanceSlider.selectedMaximum)
        }
        
        resultingFilterRequest["birthdateLowerBound"] = Double(ageCell.ageSlider.selectedMinimum)
        resultingFilterRequest["birthdateUpperBound"] = Double(ageCell.ageSlider.selectedMaximum)
        
        resultingFilterRequest.saveInBackground()
        if self.browseFilterTapped == true {
//            if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//                delegate.appliedFilter = resultingFilterRequest
//            }
        }

        if createFilter == true {
            self.resultingQueryWithConstraints(query: nil)
        }
        didFilterWithCompletion(resultingQueryWithConstraints: self.resultingQueryWithConstraints)
        didSelectFilterWithCompletion(resultingFilter: resultingFilterRequest)
        
    }
    
    //MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("WhoCell", forIndexPath: indexPath) as! WhoTableViewCell
            cell.selectionStyle = .None
            
            cell.maleSignButton.selected = false
            cell.femaleSignButton.selected = false
            cell.bothSignButton.selected = false
            
            if self.browseFilterTapped == false {
                if let allowFemale = self.currentUserFilter["allowFemale"] as? Int, let allowMale = self.currentUserFilter["allowMale"] as? Int {
                    if allowMale == 1 && allowFemale == 1 {
                        cell.bothSignButton.selected = true
                    } else if allowMale == 1 {
                        cell.maleSignButton.selected = true
                    }
                    else if allowFemale == 1 {
                        cell.femaleSignButton.selected = true
                    } else {
                        cell.bothSignButton.selected = true
                    }
                } else {
                    cell.bothSignButton.selected = true
                }
            } else {
//                if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//                    if let filter = delegate.appliedFilter {
//                        if let allowFemale = filter["allowFemale"] as? Int, let allowMale = filter["allowMale"] as? Int {
//                            
//                            if allowMale == 1 {
//                                cell.maleSignButton.selected = true
//                            } else if allowFemale == 1 {
//                                cell.femaleSignButton.selected = true
//                            } else {
//                                cell.bothSignButton.selected = true
//                            }
//                        } else {
//                            cell.bothSignButton.selected = true
//                        }
//                    } else {
//                        cell.bothSignButton.selected = true
//                    }
//                }
            }

            return cell
        } else if indexPath.section == 1 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("AgeCell", forIndexPath: indexPath) as! AgeTableViewCell
            cell.selectionStyle = .None
            
            if self.browseFilterTapped == false {
                if let birthdateLowerBound = currentUserFilter["birthdateLowerBound"] as? Double, let birthdateUpperBound = currentUserFilter["birthdateUpperBound"] as? Double {
                    cell.ageSlider.selectedMinimum = Float(birthdateLowerBound)
                    cell.ageSlider.selectedMaximum = Float(birthdateUpperBound)
                }
            } else {
//                if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//                    if let filter = delegate.appliedFilter {
//                        if let birthdateLowerBound = filter["birthdateLowerBound"] as? Double, let birthdateUpperBound = filter["birthdateUpperBound"] as? Double {
//                            cell.ageSlider.selectedMinimum = Float(birthdateLowerBound)
//                            cell.ageSlider.selectedMaximum = Float(birthdateUpperBound)
//                        }
//                    }
//                }
            }

            return cell
        } else {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("DistanceCell", forIndexPath: indexPath) as! DistanceTableViewCell
            cell.selectionStyle = .None
            
            if self.browseFilterTapped == false {
                if let lastLocationRadius = currentUserFilter["lastLocationRadius"] as? Double {
                    cell.distanceSlider.selectedMaximum = Float(lastLocationRadius)
                }
            } else {
//                if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
//                    if let filter = delegate.appliedFilter {                    if let lastLocationRadius = filter["lastLocationRadius"] as? Double {
//                        cell.distanceSlider.selectedMaximum = Float(lastLocationRadius)
//                        }
//                    }
//                }
            }

            return cell
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = self.tableView.dequeueReusableCellWithIdentifier("FilterHeaderCell")
        if let header = header as? FilterHeaderTableViewCell {
            if section == 0 {
                header.filterHeaderLabel.text = "WHO"
                header.headerLine.backgroundColor = UIColor(netHex: 0xFB4B4E)
            } else if section == 1 {
                header.filterHeaderLabel.text = "AGE"
                header.headerLine.backgroundColor = UIColor(netHex: 0x86B155)
            } else {
                header.filterHeaderLabel.text = "WITHIN"
                header.headerLine.backgroundColor = UIColor(netHex: 0x1098F7)
            }
        }
        return header
    }
    
    //MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 105
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 75
    }
}
