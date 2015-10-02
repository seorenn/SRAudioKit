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
        let device = SRAudioDeviceManager.sharedManager.defaultInputDevice!
        debugPrint("Start Record with Output Path: \(outputPath)")
        debugPrint("Using Input Device: \(device)")
        
        let inputConfig = SRAudioStreamDescription(sampleRate: 44100, stereo: true, format: .PCM, frameType: .Float32Bit, interleaved: false)
        debugPrint("Input Config: \(inputConfig)")
        let outputConfig = SRAudioStreamDescription(sampleRate: 44100, stereo: true, format: .PCM, frameType: .Float32Bit, interleaved: false)
        debugPrint("Output Config: \(outputConfig)")
        if let recorder = SRAudioRecorder(inputDevice: device, inputAudioStreamDescription: inputConfig, outputPath: outputPath, outputAudioStreamDescription: outputConfig, outputFileFormat: .AIFF) {
            self.recorder = recorder
            recorder.startRecord()
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

