//
//  GeoFenceManager.swift
//  VocaleApp
//
//  Created by Nikolay Yanev on 9/22/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import Foundation
import CoreLocation

class GeoFenceManager {
    static let sharedInstance = GeoFenceManager()
    
    var milesRange = 200
    var userLocation: CLLocation?
    var parseGeoPoint: PFGeoPoint? {
        get {
            if let userLocation = self.userLocation  {
                return PFGeoPoint(location: userLocation)
            }
            
            return nil
        }
    }
    
    init() {
        
    }
    
    func geoLocationCheck(completion: (inRange: Bool) -> Void) {
        let regionsQuery = PFQuery(className: "Region")
        regionsQuery.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
            if let objects = objects {
                if objects.count == 0 {
                    completion(inRange: true)
                    return
                } else {
                    if let parseGeoPoint = self.parseGeoPoint {
                        let query = PFQuery(className: "Region")
                        query.whereKey("location", nearGeoPoint: parseGeoPoint, withinMiles: 200)
                        query.findObjectsInBackgroundWithBlock({ (objects: [PFObject]?, error: NSError?) -> Void in
                            if let objects = objects {
                                if objects.count == 0 {
                                    completion(inRange: false)
                                } else {
                                    completion(inRange: true)
                                }
                            } else {
                                completion(inRange: false)
                            }
                        })
                    } else {
                        completion(inRange: false)
                    }
                }
            } else {
                completion(inRange: true)
                return
            }
            
            
        })
    }
}
