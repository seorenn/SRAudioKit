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
import SRAudioKit

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
        guard let device = SRAudioDeviceManager.sharedManager.defaultInputDevice else {
            print("Failed to get default input device")
            return
        }
        
        let type = SRAudioFileType.AAC
        
        print("Start Record with Output Path: \(outputPath)")
        print("Using Input Device: \(device)")
        
        let inputConfig = AudioStreamBasicDescription.genericUncompressedDescription(44100, numberOfChannels: 2, frameType: .SignedInteger16Bit, interleaved: true)
        print("Input Config: \(inputConfig)")
        
        let outputConfig = AudioStreamBasicDescription.fileTypeDescription(type)
        print("Output Config: \(outputConfig)")
        
        guard let recorder = SRAudioRecorder(inputDevice: device, outputPath: outputPath, streamDescription: inputConfig, outputFileType: type) else {
            print("Failed to initialize SRAudioRecorder")
            return
        }
        
        self.recorder = recorder
        recorder.startRecord()
    }
    
    func stopRecord() {
        print("Stop Record")
        
        guard let recorder = self.recorder
            else { return }
        
        recorder.stopRecord()
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

