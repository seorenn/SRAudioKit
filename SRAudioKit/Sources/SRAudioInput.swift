//
//  SRAudioInput.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import SRAudioKitPrivates
import AudioToolbox

public class SRAudioInput {
    /**
    NOTE: You must override this method
    */
    public func componentDescription() -> AudioComponentDescription {
        return AudioComponentDescription()
    }
}

public class SRAudioInputDevice: SRAudioInput {
    let device: SRAudioDevice
    
    public init(device: SRAudioDevice) {
        self.device = device
    }
    
    override public func componentDescription() -> AudioComponentDescription {
        #if os(OSX)
            return AudioComponentDescription(componentType: kAudioUnitType_Output,
                                          componentSubType: kAudioUnitSubType_HALOutput,
                                     componentManufacturer: kAudioUnitManufacturer_Apple,
                                            componentFlags: 0,
                                        componentFlagsMask: 0)
        #else
            return AudioComponentDescription(componentType: kAudioUnitType_Output,
                                          componentSubType: kAudioUnitSubType_RemoteIO,
                                     componentManufacturer: kAudioUnitManufacturer_Apple,
                                            componentFlags: 0,
                                        componentFlagsMask: 0)
        #endif
    }
}