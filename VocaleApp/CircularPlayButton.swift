//
//  CircularPlayButton.swift
//  VocaleApp
//
//  Created by Rayno Willem Mostert on 2016/02/07.
//  Copyright © 2016 Rayno Willem Mostert. All rights reserved.
//

import UIKit
import AVFoundation

class CircularPlayButton: UIView, AVAudioPlayerDelegate {

    let playButton = UIButton(type: UIButtonType.Custom)
    var progressView: KDCircularProgress?
    var audioPlayer: AVAudioPlayer?
    
    var clockwise: Bool = true {
        didSet {
            progressView?.clockwise = clockwise
        }
    }
    var startAngle: Int = 0 {
        didSet {
            progressView?.startAngle = startAngle
        }
    }

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    convenience init(frame: CGRect, asset: AVURLAsset) {

        self.init(frame:frame)

        playButton.frame = CGRectMake((frame.width-frame.height/1.35)/2,(frame.height - frame.height/1.35)/2, frame.height/1.35, frame.height/1.35)
        playButton.setImage(UIImage(named: "Message Played Icon"), forState: UIControlState.Normal)
        progressView = KDCircularProgress(frame: CGRectMake(frame.width/2-frame.height/2,0, frame.height, frame.height), colors: UIColor.vocaleRedColor())
        progressView?.trackColor = UIColor.clearColor()
        progressView?.angle = 360
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: asset.URL)
        } catch {
        }

        playButton.addTarget(self, action: #selector(CircularPlayButton.playTapped as (CircularPlayButton) -> () -> ()), forControlEvents: UIControlEvents.TouchUpInside)
        addSubview(playButton)
        addSubview(progressView!)
    }

    func playTapped() {
        playTapped { (done) -> Void in
            self.progressView?.stopAnimation()
        }
    }

    func playTapped(completion: (done: Bool) -> Void) {
        if let audioPlayer = audioPlayer {
            if  (audioPlayer.playing) {
                audioPlayer.stop()
                deactivateProximitySensor()
                progressView?.stopAnimation()
            } else {
                audioPlayer.play()
                activateProximitySensor()
                progressView?.animateFromAngle(360, toAngle: 0, duration: audioPlayer.duration, completion: { (done: Bool) -> Void in
                    completion(done: done)
                })
            }
        }
    }

    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        progressView?.stopAnimation()
        progressView?.angle = 360
        deactivateProximitySensor()
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func activateProximitySensor() {
        let device = UIDevice.currentDevice()
        device.proximityMonitoringEnabled = true
        if device.proximityMonitoringEnabled {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CircularPlayButton.proximityChanged(_:)), name: "UIDeviceProximityStateDidChangeNotification", object: device)
        }
    }

    func deactivateProximitySensor() {
        let device = UIDevice.currentDevice()
        if device.proximityMonitoringEnabled {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: "UIDeviceProximityStateDidChangeNotification", object: device)
            device.proximityMonitoringEnabled = false
        }
    }

    func proximityChanged(notification: NSNotification) {
        if let player = audioPlayer {
            if player.playing {
                if let device = notification.object as? UIDevice {
                    //print("\(device) detected!")
                    if device.proximityState {
                        player.stop()
                        if (player.currentTime > 3) {
                            player.currentTime = player.currentTime - 3

                        } else {
                            player.currentTime = 0
                        }

                        do {
                            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
                            player.play()
                        } catch _ {
                        }
                    } else {
                        if (player.currentTime > 3) {
                            player.currentTime = player.currentTime - 3

                        } else {
                            player.currentTime = 0
                        }
                        do {
                            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                            player.play()
                        } catch _ {
                        }
                    }
                }
            }
        }
    }


}
