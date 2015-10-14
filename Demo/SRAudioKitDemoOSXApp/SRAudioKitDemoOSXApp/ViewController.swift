//
//  ViewController.swift
//  SRAudioKitDemoOSXApp
//
//  Created by Heeseung Seo on 2015. 9. 21..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import CoreAudio
import AudioToolbox
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
        print("Start Record with Output Path: \(outputPath)")
        print("Using Input Device: \(device)")
        
        let inputConfig = AudioStreamBasicDescription.genericUncompressedDescription(44100, numberOfChannels: 2, frameType: .SignedInteger16Bit, interleaved: true)
        print("Input Config: \(inputConfig)")
        let outputConfig = AudioStreamBasicDescription.fileFormatDescription(.WAVE)
        print("Output Config: \(outputConfig)")
        if let recorder = SRAudioRecorder(inputDevice: device, outputPath: outputPath, streamDescription: outputConfig, outputFileFormat: .WAVE) {
            self.recorder = recorder
            recorder.startRecord()
        } else {
            print("Failed to initialize SRAudioRecorder")
        }
    }
    
    func stopRecord() {
        print("Stop Record")
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
        let outputPath = "/Users/hirenn/Desktop/output.wav"
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

