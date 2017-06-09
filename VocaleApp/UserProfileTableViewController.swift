//
//  UserProfileTableViewController.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/16.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class UserProfileTableViewController: UITableViewController {
    
    @IBOutlet weak var profilePictureImageView: UIImageView!
    @IBOutlet weak var nameAgeLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var aboutLabel: UILabel!
    
    var profile: PFUser?
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Posts", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(UserProfileTableViewController.segueToPosts))
        
        if let profile = profile {
            if let file = profile["UserImageMain"] as? PFFile  {
                file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                    if let _ = error {
                    } else if let data = data, let image = UIImage(data: data) {
                        self.profilePictureImageView.image = image
                    }
                    }, progressBlock: { (progress: Int32) -> Void in
                })
            } else if let imageURLString = profile["FBPictureURL"] as? String, let imageURL = NSURL(string: imageURLString) {
                profilePictureImageView.sd_setImageWithURL(imageURL)
            }
            
            if let birthdate = profile["birthdate"] as? NSDate {
                nameAgeLabel.text = "\(profile.firstName), \(birthdate.age)"
            } else {
                nameAgeLabel.text = profile.firstName
                navigationItem.title = profile.firstName
            }
            if let location = profile["location"] as? String {
                locationLabel.text = location
            }
            if let aboutString = profile["AboutMe"] as? String {
                aboutLabel.text = aboutString
            } 
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return view.frame.width
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    // MARK: Auxiliary Methods
    
    func segueToPosts() {
        if let controller = storyboard?.instantiateViewControllerWithIdentifier("individualUserPosts") as? IndividualUserPostsTableViewController, user = PFUser.currentUser() {
            controller.user  = user
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}
