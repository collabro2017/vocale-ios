//
//  NoPostsTableViewCell.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/18.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class NoPostsTableViewCell: UITableViewCell {

    @IBOutlet weak var noPostsExplanationLabel: UILabel!
    @IBOutlet weak var noPostsLabel: UILabel!
    @IBOutlet weak var noPostsImageView: UIImageView!

    enum BrowseType {
        case All
        case Today
        case Saved
        case noResponses
        case noPosts
        case loadingPosts
        case noResults
    }

    enum ResponseType {
        case All
        case Saved
    }

    var browseControllerType: BrowseType = .All {
        didSet {
            switch browseControllerType {
            case .Today: //TODAY POSTS
                noPostsImageView.image = UIImage(named: "Logo New-1")
                noPostsLabel.text = "NO TODAY POSTS"
                noPostsExplanationLabel.text = "Try again later or change your filter settings for more results"
            case .Saved: //SAVED POSTS
                noPostsLabel.text = "NO SAVED POSTS"
                let bookmarkIcon = FAKFontAwesome.bookmarkIconWithSize(15)
                let string1 = NSMutableAttributedString(string: "Tap the ")
                string1.appendAttributedString(bookmarkIcon.attributedString())
                string1.appendAttributedString(NSMutableAttributedString(string: " icon to save posts and respond to them at a later time"))
                noPostsExplanationLabel.attributedText = string1
                noPostsImageView.image = UIImage(named: "savedImage")
            case .noResponses:
                noPostsLabel.text = "NO MORE RESPONSES"
                noPostsExplanationLabel.text = "Try again later for more results"
            case .noPosts:
                noPostsLabel.text = "NO POSTS"
                noPostsExplanationLabel.text = "Create posts about things you need or want to do and get responses from people around you."
            case .loadingPosts: //LOADING POSTS
                noPostsImageView.image = UIImage(named: "loadingIcon")
                noPostsLabel.text = "LOADING POSTS"
                noPostsExplanationLabel.text = "Please wait while we get the latest posts from around you."
            case .noResults: //NO RESULTS
                noPostsImageView.image = UIImage(named: "searchingIcon")
                noPostsLabel.text = "NO RESULTS"
                noPostsExplanationLabel.text = "For posts that contain"
            default: //NO MORE POSTS
                noPostsImageView.image = UIImage(named: "Logo New-1")
                noPostsLabel.text = "NO MORE POSTS"
                noPostsExplanationLabel.text = "Try again later or change your filter settings for more results. You can also tap the \"All\" tab to reload posts. "
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor(red: 33/255, green: 30/255, blue: 35/255, alpha: 1)
    }

}
