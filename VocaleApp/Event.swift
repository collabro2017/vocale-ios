//
//  EventCard.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/27.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import Foundation

class Event: PFObject, PFSubclassing {

    @NSManaged var name: String
    @NSManaged var eventDescription: String
    @NSManaged var location: PFGeoPoint
    @NSManaged var eventDate: NSDate
    @NSManaged var tags: [String]
    @NSManaged var owner: PFUser
    @NSManaged var backgroundImage: PFFile
    @NSManaged var responses: [EventResponse]
    @NSManaged var isGroupEvent: Bool
    @NSManaged var isPast: Bool
    @NSManaged var lastResponseUpdate: NSDate
    @NSManaged var unreadResponseCount: Int
    @NSManaged var timeframe: Int

    var placeholderImage: UIImage?
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
        return "Event"
    }

    func set(name: String, eventDescription: String, location: PFGeoPoint, timeStamp: NSDate, owner: PFUser, backgroundImage: PFFile?, responses: [EventResponse]) {
        self.name = name
        self.eventDescription = eventDescription
        self.location = location
        self.eventDate = timeStamp
        self.tags = Event.detectHashtags(eventDescription)
        //print(self.tags)
        self.owner = owner
        if let image = backgroundImage {
            self.backgroundImage = image
        }
        self.isGroupEvent = false
        self.responses = responses
    }

    func attributedEventDescription() -> NSAttributedString {
        do {
            let regex = try NSRegularExpression(pattern: "#(\\w+)", options: NSRegularExpressionOptions.CaseInsensitive)
            let nsString = self.eventDescription as NSString
            let results = regex.matchesInString(self.eventDescription, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
            let attributedString = NSMutableAttributedString(string: self.eventDescription, attributes: [NSFontAttributeName: UIFont(name: "GillSans", size: 19)!, NSForegroundColorAttributeName: UIColor.whiteColor()])

            for match in results {
                attributedString.setAttributes([NSFontAttributeName: UIFont(name: "GillSans", size: 19)!, NSForegroundColorAttributeName: UIColor.whiteColor()], range: match.range)
            }
            return attributedString
        } catch {
            return NSAttributedString(string: "")
        }
    }

    static func detectHashtags(string: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: "#(\\w+)", options: NSRegularExpressionOptions.CaseInsensitive)
            let nsString = string as NSString
            let results = regex.matchesInString(string, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
            var array = [String]()
            let resultArray = results.map() { nsString.substringWithRange($0.range)}
            for var result in resultArray {
                result = String(result.characters.dropFirst())
                result.replaceRange(result.startIndex...result.startIndex, with: String(result[result.startIndex]).capitalizedString)
                array.append(result)
            }
            return array
        } catch {
            return []
        }
    }

    static func detectGroupTag(string: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: "#Group(\\w+)", options: NSRegularExpressionOptions.CaseInsensitive)
            let nsString = string as NSString
            let results = regex.matchesInString(string, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, nsString.length))
            let arr = results.map() { nsString.substringWithRange($0.range)}
            if (arr.count > 0) {
                return true
            }
            return false
        } catch {
            return false
        }
    }

    func countUnreadResponses(completion: (count: Int) -> Void) {
        /*var count = 0
        do {
            if let responses = self.responses as? [EventResponse] {
                for response in responses {

                    if !response.isRead {
                        count += 1
                    }

                }
            }
        } catch {

        }
        completion(count: count)
        */
        if let query = EventResponse.query() {
            query.whereKey("isRead", equalTo: false)
            query.whereKey("parentEvent", equalTo: self)
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

    func checkContainmentInLocalDatastoreWithCompletion(completion: (isContained: Bool) -> Void) {
        if let id = self.objectId {
            let query = Event.query()
            query?.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
            query?.fromLocalDatastore()

            query?.getObjectInBackgroundWithId(id, block: { (object: PFObject?, error: NSError?) -> Void in
                if object != nil {
                    completion(isContained: true)
                } else {
                    completion(isContained: false)
                }
            })
        } else {
            completion(isContained: false)
        }
    }

    func isContainedInLocalDatastore() -> Bool {
        if let id = self.objectId {
            let query = Event.query()
            query?.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
            query?.fromLocalDatastore()
            do {
                let object = try query?.getObjectWithId(id)
                if object != nil {
                    return true
                } else {
                    return false
                }
            } catch {
                return false
            }
        } else {
            return false
        }
    }

    static func countObjectsInLocalDatastore() -> Int {
        if let query = Event.query() {
            query.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
            query.fromLocalDatastore()
            return query.countObjects(nil)
        } else {
            return 0
        }
    }

    static func countObjectsInLocalDatastoreWithCompletion(completion: (count: Int) -> Void) {
        if let query = Event.query() {
            query.whereKey("eventDate", greaterThanOrEqualTo: NSDate())
            query.fromLocalDatastore()
            query.countObjectsInBackgroundWithBlock({ (count: Int32, error: NSError?) -> Void in
                completion(count: Int(count))
            })
        } else {
            completion(count: 0)
        }
    }

    static func countBookmarkedObjectsInLocalDatastoreWithCompletion(completion: (count: Int) -> Void) {
        if let events = PFUser.currentUser()?["savedEvents"] as? [Event] {
            completion(count: events.count)
        } else {
            completion(count: 0)
        }
    }

    static func countBookmarkedObjectsWithCompletion(completion: (count: Int) -> Void) {
        if let events = PFUser.currentUser()?["savedEvents"] as? [Event] {
            completion(count: events.count)
        } else {
            completion(count: 0)
        }
    }

}
