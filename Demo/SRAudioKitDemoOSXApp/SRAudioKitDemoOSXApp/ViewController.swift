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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        print("Devices:")
        for d in SRAudioDeviceManager.sharedManager.devices {
            debugPrint(d)
        }
    }
    
    func startRecord(device: SRAudioDevice, outputPath: String) {
        let input = SRAudioInputDevice(device: device)
        let output = SRAudioOutputFile(path: outputPath)
        
        SRAudioManager.sharedManager.connect(input, output: output)
        SRAudioManager.sharedManager.start()
    }
    
    func stopRecord() {
        SRAudioManager.sharedManager.stop()
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func pressedReccordButton(sender: AnyObject) {
        if let device = SRAudioDeviceManager.sharedManager.defaultInputDevice {
            debugPrint("Use default input device \(device)")
            self.startRecord(device, outputPath: "")
        }
    }
}

