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
    
private enum SRAudioDeviceIOChannelsType {
    case Unknown, Input, Output
}

public class SRAudioDeviceIOChannels: CustomDebugStringConvertible {
    #if os(OSX)
        private let deviceID: AudioDeviceID
        private var channelEnables: [Bool]
        private let type: SRAudioDeviceIOChannelsType
    
        public let count: Int
    #endif

    #if os(OSX)
    private init(deviceID: AudioDeviceID, type: SRAudioDeviceIOChannelsType) {
        self.deviceID = deviceID
        self.type = type
        
        if (type == .Input) {
            self.count = Int(SRAudioGetNumberOfDeviceInputChannels(self.deviceID))
        } else {
            self.count = Int(SRAudioGetNumberOfDeviceOutputChannels(self.deviceID))
        }
        
        self.channelEnables = [Bool](count: self.count, repeatedValue: true)
    }
    #endif
    
    public func enableChannel(channelIndex: Int, value: Bool) {
        #if os(OSX)
            guard channelIndex >= 0 && channelIndex < self.count else { return }
            self[channelIndex] = value
        #endif
    }

    public subscript(index: Int) -> Bool {
        set {
            #if os(OSX)
                self.channelEnables[index] = newValue
            #endif
        }
        get {
            #if os(OSX)
                return self.channelEnables[index]
            #else
                return false
            #endif
        }
    }
    
    public var debugDescription: String {
        #if os(OSX)
            let typeString = self.type == .Input ? "IN" : "OUT"
            var enables = ""
            for i in 0..<self.count {
                enables = enables + (self[i] ? "o" : ".")
            }
            
            return "<SRAudioDeviceIOChannels \(typeString) \(self.count) Ports [\(enables)]>"
        #else
            return "<SRAudioDeviceIOChannels>"
        #endif
    }
}
    
public class SRAudioDevice: CustomDebugStringConvertible {
    #if os(OSX)
        public let deviceID: AudioDeviceID
        public let inputChannels: SRAudioDeviceIOChannels
        public let outputChannels: SRAudioDeviceIOChannels
    #endif

    public var name: String {
        #if os(OSX)
            return SRAudioGetDeviceName(self.deviceID) ?? "Unknown Device Name"
        #else
            return ""
        #endif
    }
    
    public var deviceUID: String {
        #if os(OSX)
            return SRAudioGetDeviceUID(self.deviceID) ?? "Unknown Device UID"
        #else
            return ""
        #endif
    }
    
    #if os(OSX)
    public init(deviceID: AudioDeviceID) {
        self.deviceID = deviceID
        self.inputChannels = SRAudioDeviceIOChannels(deviceID: self.deviceID, type: .Input)
        self.outputChannels = SRAudioDeviceIOChannels(deviceID: self.deviceID, type: .Output)
    }
    #endif
    
    public var debugDescription: String {
        #if os(OSX)
            return "<SRAudioDevice \"\(self.name)(\(self.deviceID))\" IN(\(self.inputChannels.count)) OUT(\(self.outputChannels.count))>"
        #else
            return "<SRAudioDevice>"
        #endif
    }
}
