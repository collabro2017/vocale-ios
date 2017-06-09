//
//  IndividualEventResponseCollectionViewCell.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/26.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class IndividualEventResponseCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var backgroundProfileImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var isNewLabel: UILabel!

    var response: EventResponse? {
        didSet {
            if let response = response {
                self.isNewLabel.alpha = 0
                response.fetchIfNeededInBackgroundWithBlock({ (response: PFObject?, error: NSError?) -> Void in
                    if error == nil {
                        if let response = response as? EventResponse {
                            if response.isRead {
                                self.isNewLabel.alpha = 0
                            } else {
                                self.isNewLabel.alpha = 1
                            }
                            response.repsondent.fetchIfNeededInBackgroundWithBlock({ (respondent: PFObject?, error: NSError?) -> Void in
                                if let usr = respondent as? PFUser {
                                    usr.pinInBackground()
                                    if let name = usr["name"] as? String {
                                        self.userNameLabel.text = name
                                    } else {
                                        self.userNameLabel.text = usr.username
                                    }
                                    if response.isRead {
                                        self.isNewLabel.alpha = 0
                                    } else {
                                        self.isNewLabel.alpha = 1
                                    }
                                    
                                    if let file = usr["UserImageMain"] as? PFFile  {
                                        file.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) -> Void in
                                            if let _ = error {
                                            } else if let data = data, let image = UIImage(data: data) {
                                                self.backgroundProfileImageView.image = image
                                            }
                                            }, progressBlock: { (progress: Int32) -> Void in
                                        })
                                    } else if let string = usr["FBPictureURL"] as? String, url = NSURL(string: string) {
                                        self.backgroundProfileImageView.sd_setImageWithURL(url, placeholderImage: UIImage(assetIdentifier: .redSquare), options: SDWebImageOptions.ContinueInBackground, progress: { (progress: Int, progress2: Int) -> Void in

                                            }, completed: { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, URL: NSURL!) -> Void in
                                        })
                                    }
                                }
                            })

                            response.repsondent.fetchIfNeededInBackgroundWithBlock { (user: PFObject?, error: NSError?) -> Void in
                                if let error = error {
                                    SVProgressHUD.showErrorWithStatus(error.localizedDescription)
                                }
                                self.userNameLabel.alpha = 1
                            }
                        }
                    }
                })
            }
        }
    }


}
