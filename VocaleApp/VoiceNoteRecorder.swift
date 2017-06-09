//
//  voiceNoteRecorder.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/12.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit

class VoiceNoteRecorder: UIView {
    var isRecording: Bool = false
    var audioFileURL: NSURL?
    var event: Event?
    private var recordingManager: RecordingManager?
    private var waveFormView = SiriWaveformView()
    var originalCancelButtonSize = CGSize(width: 0, height: 0)
    var cancelButton = UIButton(type: .Custom)
    private var confirmButton = UIButton(type: .Custom)
    var audioMeterLink: (level: CGFloat) -> Void = {level in}

    var rectangularProgressView = RectangularProgressView() {
        didSet {

            rectangularProgressView.frame = CGRectMake(frame.width - 50, 10, 40, 40)
            self.addSubview(rectangularProgressView)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        drawItems()
        audioMeterLink = {
            level in
            self.waveFormView.updateWithLevel(level)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        drawItems()
        audioMeterLink = {
            level in
            self.waveFormView.updateWithLevel(level)
        }
    }

    private func drawItems() {
        print("DrawItems", terminator: "")
        backgroundColor = UIColor.clearColor()

        waveFormView = SiriWaveformView(frame: frame)
        waveFormView.frame.origin = CGPoint.zero
        waveFormView.waveColor = UIColor.vocaleRedColor()
        waveFormView.backgroundColor = UIColor.clearColor()

        cancelButton.frame.size = CGSize(width: 60, height: 60)
        originalCancelButtonSize = cancelButton.frame.size
        cancelButton.center = CGPointMake(frame.width/2, frame.height/2)
        cancelButton.setImage(UIImage(named: "circledCross"), forState: .Normal)
        cancelButton.tag = 1020

        confirmButton.frame.size = CGSize(width: 50, height: 50)
        confirmButton.center = CGPointMake(frame.width/2, frame.height/2)
        confirmButton.setImage(UIImage(named: "circledCheck"), forState: .Normal)

        addSubview(waveFormView)
        addSubview(cancelButton)
    }

    func startRecording() {
        self.isRecording = true
        rectangularProgressView = RectangularProgressView()
        rectangularProgressView.startAnimatingWithDuration(60, completion: {

        })
        recordingManager = RecordingManager()
        if let recordingManager = recordingManager {
            if !recordingManager.isRecording {
                recordingManager.audioMeterLink = audioMeterLink
                recordingManager.event = event
                recordingManager.startRecording()
            }
        }
    }


    var uploadImageView = UIImageView()

    func stopRecording(withCompletion: (success: Bool?, error: NSError?, audioFileUrl: NSURL?) -> Void) {
        if let recordingManager = recordingManager {
            if recordingManager.isRecording {
                recordingManager.stopRecordingAudio({ (success, error, audioFileUrl) -> Void in
                    self.showUploadAnimation()
                    self.isRecording = false
                    withCompletion(success: success, error: error, audioFileUrl: audioFileUrl)
                })
            }
        }

    }

    func stopRecordingOBJC() {
        print("STOPOBJC", terminator: "")
        if let recordingManager = recordingManager {
            print("STOPOBJC2", terminator: "")
            if recordingManager.isRecording {
                print("STOPOBJC3", terminator: "")
                recordingManager.stopRecordingAudio({ (success, error, audioFileUrl) -> Void in
                    print("STOPOBJ4", terminator: "")
                    self.isRecording = false
                    self.showUploadAnimation()
                    self.audioFileURL = audioFileUrl
                })
            }
        }
    }

    func cancelRecordingOBJC() {
        if let recordingManager = recordingManager {
            if recordingManager.isRecording {
                recordingManager.cancelRecordingAudio()
                isRecording = false
            }
        }
        recordingManager = nil
    }

    func cancelTapped(withCompletion: (success: Bool?, error: NSError?) -> Void) {
        if let recordingManager = recordingManager {
            if recordingManager.isRecording {
                recordingManager.cancelRecordingAudio()
                isRecording = false
                withCompletion(success: true, error: nil)
            }
        }
        recordingManager = nil
    }


    func showUploadAnimation() {
        print("VoiceNoteRecorder")
        recordingManager = nil
        let uploadIcon = UIImage(assetIdentifier: .voiceNoteUploadArrow)
        uploadImageView = UIImageView(frame:
            CGRectMake(frame.width/2 - 35, frame.height, 70, 70))
        uploadImageView.image = uploadIcon
        uploadImageView.contentMode = .ScaleAspectFit
        addSubview(uploadImageView)
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.waveFormView.alpha = 0
            self.rectangularProgressView.alpha = 0
            self.cancelButton.alpha = 0
            self.uploadImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 20)
            }) { (completed: Bool) -> Void in

        }
    }

    func completeUploadWithAnimation() {

        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.uploadImageView.frame.origin.y = 0 - self.uploadImageView.frame.height
            self.uploadImageView.alpha = 0

            }) { (completed: Bool) -> Void in

        }

        let checkIcon = UIImage(assetIdentifier: .voiceNoteUploadCheck)
        let checkImageView = UIImageView(frame:
            CGRectMake(self.frame.width/2 - 35, self.frame.height, 70, 70))
        checkImageView.image = checkIcon
        checkImageView.contentMode = .ScaleAspectFit

        self.addSubview(checkImageView)
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            checkImageView.center = CGPointMake(self.frame.width/2, self.frame.height/2 - 20)
            }) { (completed: Bool) -> Void in

        }

        UIView.animateWithDuration(0.4, delay: 0.8, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            checkImageView.frame.origin.y = 0 - checkImageView.frame.height
            checkImageView.alpha = 0
            }) { (completed: Bool) -> Void in
        }
    }
}
