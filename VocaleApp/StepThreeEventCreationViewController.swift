//
//  StepThreeEventCreationViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/28.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class StepThreeEventCreationViewController: UIViewController, KPTimePickerDelegate {

    var timePicker = KPTimePicker() {
        didSet {
            timePicker.delegate = self
            timePicker.minimumDate = self.timePicker.pickingDate.dateAtStartOfDay()
            timePicker.maximumDate = self.timePicker.pickingDate.dateByAddingMinutes(60*24*365)
            let calendar = NSCalendar.currentCalendar()
            let comps = calendar.components([NSCalendarUnit.Era, NSCalendarUnit.Year, NSCalendarUnit.Month, NSCalendarUnit.Day, NSCalendarUnit.Hour], fromDate: NSDate())
            comps.hour = comps.hour+1
            timePicker.pickingDate = calendar.dateFromComponents(comps)
        }
    }

    var eventInCreation = Event()

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem?.title = " "

        timePicker = KPTimePicker(frame: self.view.frame)
        self.view.addSubview(timePicker)

        self.tabBarController?.tabBar.hidden = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Set", style: .Done, target: self, action: #selector(StepThreeEventCreationViewController.nextTapped))
    }

    // MARK: - Time Picker Delegate

    func timePicker(timePicker: KPTimePicker!, selectedDate date: NSDate!) {
        eventInCreation.eventDate = date
        eventInCreation.isPast = false
        performSegueWithIdentifier("toConfirmationVC", sender: self)
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let destinationVC = segue.destinationViewController as? CreatedEventConfirmationTableViewController {
            destinationVC.eventInCreation = eventInCreation
        }
    }

    // MARK: - Auxiliary Functions

    func nextTapped() {
        eventInCreation.eventDate = timePicker.pickingDate
        performSegueWithIdentifier("toConfirmationVC", sender: self)
    }

}
