//
//  AppDelegate.swift
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        let dd = SRAudioDeviceManager.sharedManager().defaultDevice
        println("Default Device: [\(dd.deviceID):\(dd.deviceUID)]")
        let devices = SRAudioDeviceManager.sharedManager().devices as [SRAudioDevice]
        for dev in devices {
            println("Device [\(dev.name):\(dev.deviceID):\(dev.deviceUID)]: I[\(dev.numberInputChannels)] O[\(dev.numberOutputChannels)]")
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

