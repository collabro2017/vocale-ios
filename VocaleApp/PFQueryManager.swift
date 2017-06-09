//
//  PFQueryManager.swift
//
//
//  Created by Rayno Willem Mostert on 2016/02/21.
//
//

import Foundation

class PFQueryManager {
    static func standardEventFetch(fromLocalDatastore: Bool) {
        if let user = PFUser.currentUser(), let location = user["lastLocation"] as? PFGeoPoint {
            let query = Event.query()
            if fromLocalDatastore {
                query?.fromLocalDatastore()
            }
            query?.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
            query?.limit = 100
            query?.whereKey("location", nearGeoPoint: location, withinMiles: 1000000)
            query?.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
                if error == nil {
                    PFObject.pinAllInBackground(objects)
                } else {
                }
            })
        }
    }
}
