//
//  NSURLExtension.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/10.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

extension NSURL {
    static func timestampedFilePath() -> NSURL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        let currentDateTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let recordingName = formatter.stringFromDate(currentDateTime)+".m4a"
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)

        return filePath!
    }
}
