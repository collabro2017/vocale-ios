//
//  HamzaImageCollectionViewCell.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/03/19.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class HamzaImageCollectionViewCell: UICollectionViewCell {
    var imageURL: NSURL?
    var image: UIImage?

    var cellSelected = false {
        didSet {
            if selected {
                self.imageView.layer.borderWidth = 3
                self.imageView.layer.borderColor = UIColor.whiteColor().CGColor
            } else {
                self.imageView.layer.borderWidth = 0
            }
        }
    }

    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.contentMode = .ScaleAspectFill
        }
    }

    func loadImage() {
        self.imageView.sd_setImageWithURL(imageURL, placeholderImage: UIImage()) { (image: UIImage!, error: NSError!, cacheType: SDImageCacheType, url: NSURL!) -> Void in
            self.image = image
        }
    }

}
