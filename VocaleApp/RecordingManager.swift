//
//  RecordingManager.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/01/10.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import AVFoundation

class RecordingManager: NSObject, AVAudioRecorderDelegate {

    private var audioRecorder: AVAudioRecorder!
    private var shouldCancel = false
    var event: Event?
    var isRecording: Bool = false
    var completion: (success: Bool?, error: NSError?, audioFileURL: NSURL?) -> Void = {
        success, error, url in
        print("completion: \(success), error: \(error)\n")
    }

    var audioMeterLink: (level: CGFloat) -> Void = {level in
    }

    override init() {
        super.init()
        do {
            try audioRecorder = AVAudioRecorder(URL: NSURL(fileURLWithPath:"/dev/null"), settings: [String: AnyObject]())
        } catch {

        }
        audioRecorder.record()
        let displayLink = CADisplayLink(target: self, selector: #selector(RecordingManager.updateMeters))
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

//        let pScope = PermissionScope()
//        pScope.addPermission(MicrophonePermission(),
//            message: "Use your microphone to\n send a voice note.")
//        pScope.show({ (finished, results) -> Void in
//            }, cancelled: { (results) -> Void in
//        })
    }

    func updateMeters() {
        audioRecorder.updateMeters()
        let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0) / 20)*2.5
        audioMeterLink(level: CGFloat(normalizedValue))
    }

    func startRecording() {

        isRecording = true
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        audioRecorder.stop()
        audioRecorder = audioRecorder(NSURL.timestampedFilePath())
        audioRecorder.delegate = self

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) { () -> Void in
            self.audioRecorder.record()
        }

    }

    func stopRecordingAudio(withCompletion: (success: Bool?, error: NSError?, audioFileUrl: NSURL?) -> Void) {
        completion = withCompletion
        audioRecorder.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch _ {
        }
    }

    func cancelRecordingAudio() {
        shouldCancel = true
        audioRecorder.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch _ {
        }
    }

    // MARK: - AVAudioRecorder

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if (!shouldCancel) {
            if (flag) {
                NSNotificationCenter.defaultCenter().postNotificationName("recordedAudio.saved", object: nil)
                completion(success: true, error: nil, audioFileURL: recorder.url)
            } else {
                completion(success: false, error: nil, audioFileURL: nil)
                SVProgressHUD.showErrorWithStatus("An error occurred. Please do try again.")
            }
        } else {
            completion(success: false, error: nil, audioFileURL: nil)
            //KGStatusBar.dismiss()
            shouldCancel = false
        }
    }

    private func audioRecorder(filePath: NSURL) -> AVAudioRecorder {
        let recorderSettings: [String:AnyObject] = [
            AVSampleRateKey: 44100.0,
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.Min.rawValue
        ]
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        } catch _ {
        }
        if let audioRecorder = try? AVAudioRecorder(URL: filePath, settings: recorderSettings ) {
            audioRecorder.meteringEnabled = true
            audioRecorder.prepareToRecord()
            return audioRecorder
        } else {
            SVProgressHUD.showErrorWithStatus("An error occurred.  Please do try again.")
            completion(success: false, error: nil, audioFileURL: nil)
        }
        return AVAudioRecorder()
    }

}
