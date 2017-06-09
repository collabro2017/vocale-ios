//
//  ChatViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/12/14.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import LayerKit

class ChatViewController: JSQMessagesViewController, LYRQueryControllerDelegate, JSQMessagesKeyboardControllerDelegate, JSQMessagesInputToolbarDelegate {

    var otherEndUser: PFUser?
    var layerClient: LYRClient?
    var queryController: LYRQueryController?
    var conversation: LYRConversation?

    var jsq_isObserving = false
    var toolbarBottomLayoutGuide: NSLayoutConstraint?
    var toolbarHeightConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tabBarController?.tabBar.hidden = true

        self.senderId = PFUser.currentUser()?.objectId!
        self.senderDisplayName = "Name"

        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self

        self.senderId = PFUser.currentUser()?.objectId!
        self.senderDisplayName = "Name"
        print(self.senderDisplayName, terminator: "")
        setupQuery()

        self.view.layoutIfNeeded()
        self.collectionView?.collectionViewLayout.invalidateLayout()
        if self.automaticallyScrollsToMostRecentMessage {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.scrollToBottomAnimated(false)
                self.collectionView?.collectionViewLayout.invalidateLayoutWithContext(JSQMessagesCollectionViewFlowLayoutInvalidationContext())

            })
        }

    }

    override func scrollToBottomAnimated(animated: Bool) {
        if self.collectionView?.numberOfSections() == 0 {
            return
        }
        let items = self.collectionView?.numberOfItemsInSection(0)
        if items == 0 {
            return
        }

        let collectionViewContentHeight = self.collectionView?.collectionViewLayout.collectionViewContentSize().height
        let isContentTooSmall = (collectionViewContentHeight < CGRectGetHeight(self.collectionView!.bounds))

        if (isContentTooSmall) {
            self.collectionView?.scrollRectToVisible(CGRectMake(0.0, collectionViewContentHeight! - 1.0, 1.0, 1.0), animated: animated)
            return
        }
        let finalRow = max(0, (self.collectionView?.numberOfItemsInSection(0))! - 1)
        let finalIndexPath = NSIndexPath(forItem: finalRow, inSection: 0)
        let finalCellSize = self.collectionView?.collectionViewLayout.sizeForItemAtIndexPath(finalIndexPath)

        let maxHeightForVisibleMessage = CGRectGetHeight(self.collectionView!.bounds) - self.collectionView!.contentInset.top - CGRectGetHeight(self.inputToolbar!.bounds)

        let scrollPosition = (finalCellSize!.height > maxHeightForVisibleMessage) ? UICollectionViewScrollPosition.Bottom : UICollectionViewScrollPosition.Top

        self.collectionView?.scrollToItemAtIndexPath(finalIndexPath, atScrollPosition: scrollPosition, animated: animated)

    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.senderId = PFUser.currentUser()?.objectId!
        self.senderDisplayName = "Name"
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.senderId = PFUser.currentUser()?.objectId!
        self.senderDisplayName = "Name"

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func setupQuery() {
        self.senderId = PFUser.currentUser()?.objectId!
        self.senderDisplayName = "Name"

        let query = LYRQuery(queryableClass: LYRMessage.classForCoder())
        query.predicate = LYRPredicate(property: "conversation", predicateOperator: .IsEqualTo, value: self.conversation!)
        queryController = layerClient!.queryControllerWithQuery(query)

        queryController?.delegate = self
        let success = queryController?.executeWithCompletion({ (completed: Bool, error: NSError) -> Void in
          self.collectionView?.reloadData()
        })
        print(success)
    }

    func configureMessageController() {
        self.view.backgroundColor = UIColor.whiteColor()

        self.jsq_isObserving = false
        if let toolbarHeight = self.inputToolbar?.preferredDefaultHeight {

            self.toolbarHeightConstraint?.constant = toolbarHeight
        }

        self.collectionView?.dataSource = self
        self.collectionView?.delegate = self

        self.inputToolbar?.delegate = self
        self.inputToolbar?.contentView?.textView?.placeHolder = "New message"
        self.inputToolbar?.contentView?.textView?.delegate = self

        self.automaticallyScrollsToMostRecentMessage = true

        self.outgoingCellIdentifier = JSQMessagesCollectionViewCellOutgoing.cellReuseIdentifier()
        self.outgoingMediaCellIdentifier = JSQMessagesCollectionViewCellOutgoing.mediaCellReuseIdentifier()

        self.incomingCellIdentifier = JSQMessagesCollectionViewCellIncoming.cellReuseIdentifier()
        self.incomingMediaCellIdentifier = JSQMessagesCollectionViewCellIncoming.mediaCellReuseIdentifier()

        self.showTypingIndicator = false

        self.showLoadEarlierMessagesHeader = false

        self.topContentAdditionalInset = 0.0

        self.jsq_updateCollectionViewInsets()



        if self.inputToolbar?.contentView?.textView != nil {
            self.keyboardController = JSQMessagesKeyboardController(textView: self.inputToolbar?.contentView?.textView, contextView: self.view, panGestureRecognizer: self.collectionView?.panGestureRecognizer, delegate: self)
        }

    }

    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        if let otherUserID = otherEndUser?.objectId, otherUserDisplayName = otherEndUser?["name"] as? String {
            if let message = queryController?.objectAtIndexPath(indexPath) as? LYRMessage, data = (message.parts.first?.data), string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                let message = JSQMessage(senderId: message.sender.userID, senderDisplayName: "Name", date: message.sentAt, text:  String(string))
                return message
            }
        }
        return JSQMessage(senderId: ". ", senderDisplayName: " .", date: NSDate(), text: ". ")
    }


    override func collectionView(collectionView: JSQMessagesCollectionView!, didDeleteMessageAtIndexPath indexPath: NSIndexPath!) {

    }

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let numberOfSections = queryController?.numberOfSections() {
        return Int(numberOfSections)
        }
        return 0
    }

    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        return JSQMessagesBubbleImageFactory().incomingMessagesBubbleImageWithColor(UIColor.vocaleRedColor())

    }

    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {

        return nil
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let queryController = self.queryController {
            print(queryController.numberOfObjectsInSection(UInt(section)))
            return Int(queryController.numberOfObjectsInSection(UInt(section)))
        } else {
            return 0
        }
    }

    func keyboardController(keyboardController: JSQMessagesKeyboardController!, keyboardDidChangeFrame keyboardFrame: CGRect) {
        if !(self.inputToolbar!.contentView!.textView!.isFirstResponder()) && self.toolbarBottomLayoutGuide!.constant == 0.0 {
            return
        }

        var heightFromBottom = CGRectGetMaxY(self.collectionView!.frame) - CGRectGetMinY(keyboardFrame)

        heightFromBottom = max(0.0, heightFromBottom)
    }

    func messagesInputToolbar(toolbar: JSQMessagesInputToolbar!, didPressLeftBarButton sender: UIButton!) {
    }

    func messagesInputToolbar(toolbar: JSQMessagesInputToolbar!, didPressRightBarButton sender: UIButton!) {
    }

    func jsq_updateCollectionViewInsets() {
        self.jsq_setCollectionViewInsetsTopValue(self.topLayoutGuide.length + self.topContentAdditionalInset, bottomValue: CGRectGetMaxY(self.collectionView!.frame) - CGRectGetMinY(self.inputToolbar!.frame))
    }

    func jsq_setCollectionViewInsetsTopValue(top: CGFloat, bottomValue: CGFloat) {
        let insets = UIEdgeInsetsMake(top, 0, bottomValue, 0)
        self.collectionView!.contentInset = insets
        self.collectionView!.scrollIndicatorInsets = insets
    }


}
