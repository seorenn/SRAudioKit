//
//  SRAudioDeviceManager.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import SRAudioKitPrivates
import AudioToolbox
import CoreAudio

public class SRAudioDeviceManager {
    public static let sharedManager: SRAudioDeviceManager = SRAudioDeviceManager()

    public var devices: [SRAudioDevice] {
        #if os(OSX)
            var dataSize: UInt32 = 0;
            var results = [SRAudioDevice]()
            
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster)
            
            var err = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize);
            
            guard err == noErr else { return results }
            
            let count = Int(dataSize / UInt32(sizeof(AudioObjectID)))
            guard count > 0 else { return results }

            let devicesPtr = UnsafeMutablePointer<AudioObjectID>.alloc(Int(dataSize))
            defer { devicesPtr.dealloc(Int(dataSize)) }
            
            err = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, devicesPtr);

            guard err == noErr else { return results }
            
            var curPtr = devicesPtr
            for _ in 0..<count {
                let deviceID = curPtr.memory
                let d = SRAudioDevice(deviceID: deviceID)
                results.append(d)
                
                curPtr = curPtr.successor()
            }
            
            return results
        #else
            return [SRAudioDevice]()
        #endif
    }
    
    public var defaultInputDevice: SRAudioDevice? {
        #if os(OSX)
            var size = UInt32(sizeof(AudioDeviceID))
            var deviceID = AudioDeviceID()
            var address = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDefaultInputDevice,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMaster)
            
            let error = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
            guard error == noErr else { return nil }
            
            return SRAudioDevice(deviceID: deviceID)
        #else
            return nil
        #endif
    }
    
    public init() {
        
    }

    
}
