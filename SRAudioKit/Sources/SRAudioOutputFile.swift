//
//  SRAudioOutput.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import SRAudioKitPrivates

public class SRAudioOutputFile: SRAudioIOObject {
    let path: String
    
    public init(path: String) {
        self.path = path
    }
    
    override public var componentDescription: AudioComponentDescription {
        #if os(OSX)
            return AudioComponentDescription(componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_GenericOutput,
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