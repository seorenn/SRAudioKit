//
//  ViewController.swift
//  SRAudioKitDemoOSXApp
//
//  Created by Heeseung Seo on 2015. 9. 21..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRAudioKitOSX

class ViewController: NSViewController {
    
    var recorder: SRAudioRecorder?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Devices:")
        for d in SRAudioDeviceManager.sharedManager.devices {
            debugPrint(d)
        }
    }
    
    func startRecord(outputPath: String) {
        let device = SRAudioDeviceManager.sharedManager.devices[2]  // TODO: This is test case
        debugPrint("Start Record with Output Path: \(outputPath)")
        debugPrint("Using Input Device: \(device)")
        if let recorder = SRAudioRecorder(device: device, sampleRate: 44100, frameType: .SignedInteger16Bit) {
            self.recorder = recorder
            recorder.startRecord(outputPath)
        } else {
            debugPrint("Failed to initialize SRAudioRecorder")
        }
    }
    
    func stopRecord() {
        debugPrint("Stop Record")
        if let recorder = self.recorder {
            recorder.stopRecord()
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func pressedReccordButton(sender: AnyObject) {
        let outputPath = "/Users/hirenn/Desktop/output.aac"
        if let recorder = self.recorder {
            if recorder.recording {
                self.stopRecord()
            } else {
                self.startRecord(outputPath)
            }
        } else {
            self.startRecord(outputPath)
        }
    }
}

