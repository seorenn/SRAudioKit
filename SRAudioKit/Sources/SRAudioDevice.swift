//
//  SRAudioDevice.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import AudioToolbox
import CoreAudio
import SRAudioKitPrivates
    
open class SRAudioDevice: CustomDebugStringConvertible {
    #if os(OSX)
        public let deviceID: AudioDeviceID
    #endif

    open var name: String {
        #if os(OSX)
            return SRAudioGetDeviceName(self.deviceID) ?? "Unknown Device Name"
        #else
            return ""
        #endif
    }
    
    open var deviceUID: String {
        #if os(OSX)
            return SRAudioGetDeviceUID(self.deviceID) ?? "Unknown Device UID"
        #else
            return ""
        #endif
    }

    #if os(OSX)
    public var numberInputChannels: Int {
        return Int(SRAudioGetNumberOfDeviceInputChannels(self.deviceID))
    }
    #endif
    
    #if os(OSX)
    public var numberOutputChannels: Int {
        return Int(SRAudioGetNumberOfDeviceOutputChannels(self.deviceID))
    }
    #endif
    
    #if os(OSX)
    public init(deviceID: AudioDeviceID) {
        self.deviceID = deviceID
    }
    #endif
    
    open var debugDescription: String {
        #if os(OSX)
            return "<SRAudioDevice \"\(self.name)(\(self.deviceID))\" IN(\(self.numberInputChannels)) OUT(\(self.numberOutputChannels))>"
        #else
            return "<SRAudioDevice>"
        #endif
    }
}
