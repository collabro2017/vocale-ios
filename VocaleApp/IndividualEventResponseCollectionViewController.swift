//
//  IndividualEventResponseCollectionViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/26.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

private let reuseIdentifier = "individualEventResponseCollectionViewCell"

class IndividualEventResponseCollectionViewController: UICollectionViewController {

    var event = Event()
    var selectedResponse = EventResponse()
    var shouldAnimate = true
    var selectedCell: UICollectionViewCell?
    var placeholderView: UIView?

     // MARK: View Controller LifeCycle

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView?.contentInset = UIEdgeInsetsMake(10, 10, 10, 10)
        navigationItem.title = "Responses"
        self.navigationController?.setToolbarHidden(true, animated: true)

            if !(self.event.eventDate.isEarlierThan(NSDate())) {
                self.navigationController?.setToolbarHidden(true, animated: true)
            }
            func backwards(s1: String, _ s2: String) -> Bool {
                return s1 > s2
            }
            self.event.responses.sortInPlace { (response1: EventResponse, response2: EventResponse) -> Bool in
                if let date1 = response1.createdAt, let date2 = response2.createdAt {
                    return date1.isLaterThan(date2)
                } else {
                    return true
                }
            }

    }

    override func viewWillAppear(animated: Bool) {
        self.collectionView?.reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if (event.responses.count == 0) {
            placeholderView = UIView(frame: CGRectMake(0, 60, self.view.frame.size.width, self.view.frame.size.height))
            placeholderView?.backgroundColor = UIColor.clearColor()
            self.navigationController?.view.addSubview(placeholderView!)
            
            let imageView = UIImageView(frame: CGRectMake(self.view.frame.size.width/2 - 25, self.view.frame.size.height/2 - 25 - 60, 50, 50))
            imageView.image = UIImage(named: "noResponses")
            imageView.contentMode = .ScaleAspectFit
            placeholderView?.addSubview(imageView)
            
            let titleLabel = UILabel()
            titleLabel.text = "NO RESPONSES"
            titleLabel.textColor = UIColor.vocaleTextGreyColor()
            titleLabel.font = UIFont(name: "Raleway-SemiBold", size: 23.0)
            titleLabel.sizeToFit()
            titleLabel.frame = CGRectMake(self.view.frame.size.width/2 - titleLabel.frame.size.width/2, self.view.frame.size.height/2 - 25 - 60 + 50 + 20, titleLabel.frame.size.width, titleLabel.frame.size.height)
            placeholderView?.addSubview(titleLabel)
            
            let infoLabel = UILabel()
            infoLabel.text = "No responses for this post currently. Check back later."
            infoLabel.textColor = UIColor.vocaleSecondLevelTextColor()
            infoLabel.font = UIFont(name: "Raleway-Regular", size: 15.0)
            infoLabel.numberOfLines = 2
            infoLabel.textAlignment = .Center
            infoLabel.frame = CGRectMake(44, self.view.frame.size.height/2 - 25 - 60 + 50 + 20 + 23 + 5, self.view.frame.size.width - 88, 40)
            placeholderView?.addSubview(infoLabel)
            
            imageView.alpha = 0
            titleLabel.alpha = 0
            infoLabel.alpha = 0
            UIView.animateWithDuration(0.4, delay: 0, options: .CurveEaseInOut, animations: { 
                imageView.alpha = 1
                titleLabel.alpha = 1
                infoLabel.alpha = 1
                }, completion: { (finished) in
                    
            })
        }
    }

    override func viewWillDisappear(animated: Bool) {
        shouldAnimate = true
        placeholderView?.removeFromSuperview()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return event.responses.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! IndividualEventResponseCollectionViewCell
        cell.response = event.responses[indexPath.row]

        return cell
    }

    override func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? IndividualEventResponseCollectionViewCell {

                cell.response?.fetchIfNeededInBackground()

        }
        if shouldAnimate {

            cell.alpha = 0
            UIView.animateWithDuration(0.3, delay: 0.1*Double(indexPath.item), usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                cell.alpha = 1
                }, completion: { (completed: Bool) -> Void in
                    self.shouldAnimate = false
            })
        }
    }

    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            return CGSizeMake(self.view.frame.width/CGFloat(2.3), self.view.frame.width/CGFloat(1.8))
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedCell = collectionView.cellForItemAtIndexPath(indexPath)
        selectedResponse = event.responses[indexPath.row]
        animateAwayCells { () -> Void in
            self.performSegueWithIdentifier("toResponse", sender: self)
        }

    }


    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        if let cell = cell as? IndividualEventRespondentCardTableViewCell {
            cell.deactivateProximitySensor()
        }
    }

    // MARK: Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let nextVC = segue.destinationViewController as? IndividualEventRespondentsTableViewController {
            nextVC.response = selectedResponse
        }
    }

    // MARK: Actions

    func endPostTapped() {
        let endMenu = UIAlertController(title: "End Post", message: "Are you sure you want to end this post?", preferredStyle: .ActionSheet)

        let endAction = UIAlertAction(title: "End Post", style: UIAlertActionStyle.Default) { (action: UIAlertAction) -> Void in
            self.event.eventDate = NSDate()
            self.event.saveInBackgroundWithBlock({ (completed: Bool, error: NSError?) -> Void in
                if let error = error {
                    ErrorManager.handleError(error)
                } else if completed {
                    SVProgressHUD.showSuccessWithStatus("Post Ended")
                }
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)

        endMenu.addAction(endAction)
        endMenu.addAction(cancelAction)


        self.presentViewController(endMenu, animated: true, completion: nil)
    }

    func animateAwayCells(completion: () -> Void) {
        if let visibleCells = collectionView?.visibleCells() {
            var count = 1
            var i = 0.0
            if visibleCells.count > 0 {
                for cell in visibleCells {
                    UIView.animateWithDuration(0.3, delay: Double(i*0.1), usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
                        if !(cell == self.selectedCell) {
                            cell.alpha = 0
                        }
                        }, completion: { (completed: Bool) -> Void in
                            if count == visibleCells.count {
                                completion()
                            }
                            count += 1
                    })
                    i += 1

                }
            } else {
                completion()
            }
        }
    }

    // MARK: Auxiliary Methods

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}
