//
//  EventResponse.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/27.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import Foundation

class EventResponse: PFObject, PFSubclassing {

    @NSManaged var parentEvent: Event
    @NSManaged var repsondent: PFUser
    @NSManaged var voiceNote: PFFile
    @NSManaged var timeStamp: NSDate
    @NSManaged var isRead: Bool
    var hasLocalCopy = false

    override class func initialize() {
        struct Static {
            static var onceToken: dispatch_once_t = 0
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }

    static func parseClassName() -> String {
        return "EventResponse"
    }

    func isContainedInLocalDatastore() -> Bool {
        if let id = self.objectId {
            let query = EventResponse.query()
            query?.whereKey("objectId", equalTo: id)
            query?.whereKey("savedLocally", equalTo: true)
            query?.fromLocalDatastore()
            if let count = query?.countObjects(nil) where count > 0 {
                return true
            }
        }
        return false
    }

    func checkIsContainedInLocalDatastoreWithCompletion(completion: (contained: Bool) -> Void) {
        if let id = self.objectId {
            let query = EventResponse.query()
            query?.whereKey("objectId", equalTo: id)
            query?.whereKey("savedLocally", equalTo: true)
            query?.fromLocalDatastore()
            query?.countObjectsInBackgroundWithBlock({ (count: Int32, error: NSError?) -> Void in
                if let error = error {} else {
                    if (count > 0) {
                        completion(contained: true)
                    } else {
                        completion(contained: false)
                    }
                }
            })
        }
    }

    static func countObjectsInLocalDatastore() -> Int {
        if let query = Event.query() {
            query.fromLocalDatastore()
            return query.countObjects(nil)
        } else {
            return 0
        }
    }


    static func countUnreadObjectsWithCompletion(completion: (count: Int) -> Void) {
        if let query = EventResponse.query(), let eventQuery = Event.query() {
            if let user = PFUser.currentUser() where !PFAnonymousUtils.isLinkedWithUser(user) {
                eventQuery.whereKey("owner", equalTo: user)
            }
            query.whereKey("isRead", equalTo: false)
            query.whereKey("parentEvent", matchesQuery: eventQuery)
            query.countObjectsInBackgroundWithBlock({ (result: Int32, error: NSError?) -> Void in
                if let error = error {
                } else {
                    completion(count: Int(result))
                }
            })
        } else {
            completion(count: 0)
        }
    }

    static func countObjectsInLocalDatastoreForEvent(event: Event) -> Int {
        let query = EventResponse.query()
        query?.whereKey("parentEvent", equalTo: event)
        query?.whereKey("savedLocally", equalTo: true)
        query?.fromLocalDatastore()
        if let count = query?.countObjects(nil) {
            return count
        }
        return 0
    }

}
