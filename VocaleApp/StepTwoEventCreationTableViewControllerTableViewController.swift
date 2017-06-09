//
//  StepTwoEventCreationTableViewControllerTableViewController.swift
//  Vocale
//
//  Created by Rayno Willem Mostert on 2015/11/27.
//  Copyright © 2015 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class StepTwoEventCreationTableViewControllerTableViewController: UITableViewController, UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var shouldDisplayPicker = true
    @IBOutlet weak var nextButton: UIBarButtonItem!
    @IBOutlet weak var pictureCell: UITableViewCell!
    @IBOutlet weak var selectedImageView: UIImageView!
    var eventInCreation = Event()

    var imagePicker = UIImagePickerController() {
        didSet {
            imagePicker.delegate = self
            imagePicker.allowsEditing = false
            imagePicker.sourceType = .PhotoLibrary
        }
    }

    var remoteImagePicker: DZNPhotoPickerController?

    @IBOutlet weak var categoryTextView: UITextView! {
        didSet {
            categoryTextView.delegate = self
        }
    }

    // MARK: - Init

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        DZNPhotoPickerController.registerService(.Service500px, consumerKey: "3tztLiJfkUCE6J85MjU8eKaMs3BVlHndmJ3NI7C9", consumerSecret: "Stn39OJJQprtOC3MyOo62cZkG4hLAXpNWyxoS3iT", subscription: .Free)
    }

    // MARK: - View Controller Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBarController?.tabBar.hidden = true



        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Done, target: self, action: "nextTapped")
        nextButton.enabled = false
        self.navigationItem.rightBarButtonItem?.enabled = false
    }

    override func viewWillAppear(animated: Bool) {
        setupAndPresentRemoteImagePicker()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: Actions

    @IBAction func openDeviceAlbumTapped(sender: AnyObject) {
        imagePicker = UIImagePickerController()
        imagePicker.view.backgroundColor = UIColor.vocaleBackgroundGreyColor()
        imagePicker.navigationBar.barTintColor = UIColor.vocaleBackgroundGreyColor()
        presentViewController(imagePicker, animated: true) { () -> Void in
        }
    }

    @IBAction func openRemoteAlbumTapped(sender: AnyObject) {
        setupAndPresentRemoteImagePicker()
    }

    @IBAction func nextTapped() {
        performSegueWithIdentifier("toStepThree", sender: self)
    }

    func requestPhotos() {
    }

    // MARK: UITextViewDelegate

    func textViewDidEndEditing(textView: UITextView) {

    }

    // Mark: - UIImagePickerControllerDelegate

    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.selectedImageView.image = image
            if let data = image.compressedImageData(), let file = PFFile(name: "backgroundImage.jpg", data: data) {
                self.eventInCreation.backgroundImage =  file
                self.eventInCreation.placeholderImage = image
            }
            self.navigationItem.rightBarButtonItem?.enabled = true
            nextButton.enabled = true

            dismissViewControllerAnimated(true) { () -> Void in
            }
        }

    }

    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true) { () -> Void in
        }
    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.selectedImageView.image = image
        if let data = image.compressedImageData(), let file = PFFile(name: "backgroundImage.jpg", data: data) {
            self.eventInCreation.backgroundImage =  file
            self.eventInCreation.placeholderImage = image
        }
        navigationItem.rightBarButtonItem?.enabled = true

        nextButton.enabled = true
        dismissViewControllerAnimated(true) { () -> Void in
        }

    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == 2 {
            var navHeight = CGFloat()
            navHeight = 0
            if let navigationController = navigationController {
                navHeight = navigationController.navigationBar.frame.height
            }
            return view.frame.height - navHeight - 2*tableView.rowHeight - UIApplication.sharedApplication().statusBarFrame.height
        } else {
            return tableView.rowHeight
        }
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let nextVC = segue.destinationViewController as? TimeFramePickerTableViewController {
            nextVC.eventInCreation = eventInCreation
        }
    }

    // MARK: - Auxiliary Functions

    private func setupAndPresentRemoteImagePicker() {
        self.remoteImagePicker = DZNPhotoPickerController()
        self.remoteImagePicker?.allowsEditing = false
        self.remoteImagePicker?.supportedServices = [DZNPhotoPickerControllerServices.Service500px]
        self.remoteImagePicker?.view.backgroundColor = UIColor.blackColor()
        self.remoteImagePicker?.navigationItem.title = "Pick a Background"

        if (eventInCreation.tags.count > 0) {
            let tag = eventInCreation.tags[0]
            self.remoteImagePicker?.initialSearchTerm = tag
        }
        remoteImagePicker?.cancellationBlock = {(picker: DZNPhotoPickerController!) -> Void in
            self.shouldDisplayPicker = false
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.navigationController?.popViewControllerAnimated(true)
                self.shouldDisplayPicker = true
            })
        }
        remoteImagePicker?.finalizationBlock = {(picker: DZNPhotoPickerController!, info: [NSObject: AnyObject]!) -> Void in
            self.shouldDisplayPicker = false
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.shouldDisplayPicker = true
            })

            if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                self.selectedImageView.image = image
                if let data = image.compressedImageData(), let file = PFFile(name: "backgroundImage.jpg", data: data) {
                    self.eventInCreation.backgroundImage =  file
                    self.eventInCreation.placeholderImage = image
                    self.navigationItem.rightBarButtonItem?.enabled = true
                    self.nextButton.enabled = true
                    self.performSegueWithIdentifier("toStepThree", sender: self)
                }

            }
        }
        remoteImagePicker?.failureBlock = {(picker: DZNPhotoPickerController!, error: NSError!) -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }


        if let remoteImagePicker = remoteImagePicker where self.shouldDisplayPicker {
            self.presentViewController(remoteImagePicker, animated: true) { () -> Void in

            }
        }
    }


}
