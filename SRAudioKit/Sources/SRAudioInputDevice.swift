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

private let SRAudioInputDeviceBusInput = AudioUnitScope(1)
private let SRAudioInputDeviceBusOutput = AudioUnitScope(0)

public class SRAudioInputDevice: SRAudioIOObject {
    let device: SRAudioDevice
    
    public init(device: SRAudioDevice) {
        self.device = device
    }
    
    override public var componentDescription: AudioComponentDescription {
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
    
    override public func configure(node: AUNode, audioUnit: AudioUnit) {
        // TODO
        // BUS 1: Input from the audio device
        // BUS 0: Output to the audio device
    }
    
    private func enableInputScope(audioUnit: AudioUnit) {
        var flag = UInt32(1)
        let size = UInt32(sizeof(UInt32))
        do {
            try SRAudioAssert(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, SRAudioInputDeviceBusInput, &flag, size))
        }
        catch SRAudioError.GenericError(let description) {
            debugPrint("SRAudioInputDevice.enableInputScope ERROR: \(description)")
        }
        catch {
            debugPrint("SRAudioInputDevice.enableInputScope ERROR: Unknown")
        }
    }
    
    private func disableOutputScope(audioUnit: AudioUnit) {
        #if os(OSX)
            var flag = UInt32(0)
        #else
            var flag = UInt32(1)
        #endif
        
        let size = UInt32(sizeof(UInt32))
        do {
            try SRAudioAssert(AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, SRAudioInputDeviceBusOutput, &flag, size))
        }
        catch SRAudioError.GenericError(let description) {
            debugPrint("SRAudioInputDevice.disableOutputScope ERROR: \(description)")
        }
        catch {
            debugPrint("SRAudioInputDevice.disableOutputScope ERROR: Unknown")
        }
    }
}