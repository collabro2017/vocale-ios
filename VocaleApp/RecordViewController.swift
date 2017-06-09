//
//  RecordViewController.swift
//  Talkboy
//
//  Created by Jonathan on 3/21/15.
//  Copyright (c) 2015 Jonathan Underwood. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVAudioRecorderDelegate
{
    var audioRecorder: AVAudioRecorder!
    var isRecording: Bool = false {
        didSet {
            if isRecording {
                waveformView.waveColor = UIColor(red:0.928, green:0.103, blue:0.176, alpha:1)
            } else {
                waveformView.waveColor = UIColor.blackColor()
            }
        }
    }

    @IBOutlet weak var recordLabel: UILabel!
    @IBOutlet weak var waveformView: SiriWaveformView!

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        do {
            try audioRecorder = AVAudioRecorder(URL: NSURL(fileURLWithPath:"/dev/null"), settings: [String: AnyObject]())
        } catch {
            
        }
        
        //audioRecorder = audioRecorder()
        audioRecorder.record()

        let displayLink = CADisplayLink(target: self, selector: #selector(RecordViewController.updateMeters))
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }

    @IBAction func tapWaveform(sender: UITapGestureRecognizer) {
        if isRecording {
            stopRecordingAudio()
        } else {
            recordAudio()
        }

        isRecording = !isRecording
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showPlayback") {
            let navVC = segue.destinationViewController as! UINavigationController
        }
    }

    func updateMeters() {
        audioRecorder.updateMeters()
        let normalizedValue = pow(10, audioRecorder.averagePowerForChannel(0) / 20)
        waveformView.updateWithLevel(CGFloat(normalizedValue))
    }

    func recordAudio() {
        audioRecorder.stop()
        audioRecorder = audioRecorder(timestampedFilePath())
        audioRecorder.delegate = self
        audioRecorder.record()
    }

    func stopRecordingAudio() {
        audioRecorder.stop()
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch _ {
        }
    }

    func timestampedFilePath() -> NSURL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
        let currentDateTime = NSDate()
        let formatter = NSDateFormatter()
        formatter.dateFormat = "ddMMyyyy-HHmmss"
        let recordingName = formatter.stringFromDate(currentDateTime)+".m4a"
        let pathArray = [dirPath, recordingName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)

        return filePath!
    }

    func audioRecorder(filePath: NSURL) -> AVAudioRecorder {
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
        let audioRecorder = try? AVAudioRecorder(URL: filePath, settings: recorderSettings )
        audioRecorder!.meteringEnabled = true
        audioRecorder!.prepareToRecord()

        return audioRecorder!
    }

    // MARK: - AVAudioRecorder

    func audioRecorderDidFinishRecording(recorder: AVAudioRecorder, successfully flag: Bool) {
        if (flag) {
        NSNotificationCenter.defaultCenter().postNotificationName("recordedAudio.saved", object: nil)
           // performSegueWithIdentifier("showPlayback", sender: recordedAudio)
        } else {
            print("Error")
        }
    }
}
