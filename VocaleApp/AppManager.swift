//
//  AppManager.swift
//  VocaleApp
//
//  Created by Nikolay Yanev on 10/3/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import Foundation

class AppManager {
    static let sharedInstance = AppManager()
    
    func openSettings() {
        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}
