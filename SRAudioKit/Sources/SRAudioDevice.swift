//
//  SRAudioDevice.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#if os(OSX)

import Foundation
import AudioToolbox
import CoreAudio
import SRAudioKitPrivates
    
private enum SRAudioDeviceIOChannelsType {
    case Input, Output
}

public class SRAudioDeviceIOChannels: CustomDebugStringConvertible {
    private let deviceID: AudioDeviceID
    private var channelEnables: [Bool]
    private let type: SRAudioDeviceIOChannelsType
    
    public let count: Int
    
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
    
    public func enableChannel(channelIndex: Int, value: Bool) {
        guard channelIndex >= 0 && channelIndex < self.count else { return }
    }
    
    public subscript(index: Int) -> Bool {
        set {
            self.channelEnables[index] = newValue
        }
        get {
            return self.channelEnables[index]
        }
    }
    
    public var debugDescription: String {
        let typeString = self.type == .Input ? "IN" : "OUT"
        var enables = ""
        for i in 0..<self.count {
            enables = enables + (self[i] ? "o" : ".")
        }
        
        return "<SRAudioDeviceIOChannels \(typeString) \(self.count) Ports [\(enables)]>"
    }
}
    
public class SRAudioDevice: CustomDebugStringConvertible {
    public let deviceID: AudioDeviceID

    public var name: String {
        return SRAudioGetDeviceName(self.deviceID) ?? "Unknown Device Name"
    }
    
    public var deviceUID: String {
        return SRAudioGetDeviceUID(self.deviceID) ?? "Unknown Device UID"
    }
    
    public let inputChannels: SRAudioDeviceIOChannels
    public let outputChannels: SRAudioDeviceIOChannels
    
    public init(deviceID: AudioDeviceID) {
        self.deviceID = deviceID
        self.inputChannels = SRAudioDeviceIOChannels(deviceID: self.deviceID, type: .Input)
        self.outputChannels = SRAudioDeviceIOChannels(deviceID: self.deviceID, type: .Output)
    }
    
    public var debugDescription: String {
        return "<SRAudioDevice \"\(self.name)(\(self.deviceID))\" IN(\(self.inputChannels.count)) OUT(\(self.outputChannels.count))>"
    }
}

#endif
