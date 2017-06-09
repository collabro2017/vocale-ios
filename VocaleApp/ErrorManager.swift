//
//  ErrorManager.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/10.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import Foundation
import UIKit

class ErrorManager {
    private static var pastErrors = [String]()
    private static var hiddenErrors = ["The operation couldn’t be completed. (kCLErrorDomain error 0.)"]

    static func handleError(error: NSError?) {
        if let error = error {
            if !ErrorManager.hiddenErrors.contains(error.localizedDescription) {
                if !ErrorManager.pastErrors.contains(error.localizedDescription) {
                    SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                    ErrorManager.pastErrors.append(error.localizedDescription)
                } else {
                    //KGStatusBar.showErrorWithStatus(error.localizedDescription)
                }
            }
        }
    }

    static func discreetlyHandleError(error: NSError?) {
        if let error = error {
            print(error, terminator: "")
        }
    }
}
