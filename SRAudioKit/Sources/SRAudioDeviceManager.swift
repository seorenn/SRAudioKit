//
//  SRAudioDeviceManager.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import SRAudioKitPrivates

#if os(OSX)

public class SRAudioDeviceManager {
    public static let sharedManager: SRAudioDeviceManager = SRAudioDeviceManager()

    public var devices: [SRAudioDevice] {
        guard let deviceArray = SRAudioGetDevices() else {
            return [SRAudioDevice]()
        }
        
        return deviceArray.map {
            let deviceID = AudioDeviceID($0.unsignedLongValue)
            return SRAudioDevice(deviceID: deviceID)
        }
    }

    public init() {
        
    }

    
}

#endif
