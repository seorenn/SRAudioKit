//
//  SRAudioOutputDefaultDevice.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Cocoa
import SRAudioKitPrivates

public class SRAudioOutputDefaultDevice: SRAudioIOObject {
    override public var componentDescription: AudioComponentDescription {
        #if os(OSX)
            return AudioComponentDescription(componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_DefaultOutput,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0)
        #else
            return AudioComponentDescription(componentType: kAudioUnitType_Output,
                // TODO: Check this type is valid
                componentSubType: kAudioUnitSubType_RemoteIO,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0)
        #endif
    }

}
