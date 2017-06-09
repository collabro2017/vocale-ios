//
//  NSDateExtension.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/17.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

extension NSDate {
        /// Returns the rounded down current "age" of the date
    var age: Int {
        return NSCalendar.currentCalendar().components(.Year, fromDate: self, toDate: NSDate(), options: []).year
    }
}
