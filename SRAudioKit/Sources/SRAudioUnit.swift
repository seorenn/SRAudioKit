//
//  SRAudioUnit.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudioKit
import AudioToolbox

public enum SRAudioUnitBus: AudioUnitElement {
    case Input = 1
    case Output = 0
}

func SRAudioUnitErrorDesc(name: String, scope: AudioUnitScope?, bus: SRAudioUnitBus?) -> String {
    let scopeString: String
    if let s = scope {
        if s == kAudioUnitScope_Global {
            scopeString = " SCOPE[GLOBAL]"
        } else if s == kAudioUnitScope_Input {
            scopeString = " SCOPE[INPUT]"
        } else if s == kAudioUnitScope_Output {
            scopeString = " SCOPE[OUTPUT]"
        } else {
            scopeString = " SCOPE[OTHER]"
        }
    } else {
        scopeString = ""
    }
    
    let busString: String
    if let b = bus {
        if b == .Input {
            busString = " BUS[INPUT]"
        } else if b == .Output {
            busString = " BUS[OUTPUT]"
        } else {
            busString = " BUS[UNKNOWN]"
        }
    } else {
        busString = ""
    }
    
    return "[\(name)\(scopeString)\(busString)]"
}

public class SRAudioUnit {
    let audioUnit: AudioUnit
    
    public init(audioUnit: AudioUnit) {
        self.audioUnit = audioUnit
    }
    
    // MARK: - Devices
    
    public func setDevice(device: SRAudioDevice, bus: SRAudioUnitBus) throws {
        #if os(OSX)
            var deviceID = device.deviceID
            let size = UInt32(sizeof(AudioDeviceID))
            let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, bus.rawValue, &deviceID, size)
            
            if res != noErr {
                throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setDevice]")
            }
        #else
            // TODO: for iOS
        #endif
    }
    
    public func getDevice(bus: SRAudioUnitBus) -> SRAudioDevice? {
        #if os(OSX)
            var deviceID = AudioDeviceID()
            var size = UInt32(sizeof(AudioDeviceID))
            let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, bus.rawValue, &deviceID, &size)
            
            if res == noErr {
                return SRAudioDevice(deviceID: deviceID)
            }
            
            return nil
        #else
            return nil
        #endif
    }
    
    public func setChannelMap(channelMap: [Bool]) -> OSStatus {
        let dataPtr = UnsafeMutablePointer<Int32>.alloc(channelMap.count)
        var curPtr = dataPtr
        for value in channelMap {
            curPtr.memory = value ? Int32(1) : Int32(0)
            curPtr = curPtr.successor()
        }
        
        let size = UInt32(channelMap.count * sizeof(Int32))
        
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Output, SRAudioUnitBus.Input.rawValue, dataPtr, size)
        dataPtr.dealloc(channelMap.count)
        
        return res
    }
    
    public func getChannelMap(numberInputChannels: Int) -> [Bool]? {
        let dataPtr = UnsafeMutablePointer<Int32>.alloc(numberInputChannels)
        var size = UInt32(numberInputChannels * sizeof(Int32))
        var result: [Bool]? = nil
        
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Output, SRAudioUnitBus.Input.rawValue, dataPtr, &size)
        if res == noErr {
            result = [Bool]()
            var curPtr = dataPtr
            for _ in 0..<numberInputChannels {
                result!.append(curPtr.memory == 1 ? true : false)
                curPtr = curPtr.successor()
            }
        }
        
        dataPtr.dealloc(numberInputChannels)
        return result
    }
    
    // MARK: - Buffer Frame Size
    
    public func setBufferFrameSize(frameSize: UInt32, bus: SRAudioUnitBus) -> OSStatus {
        var value = frameSize
        let size = UInt32(sizeof(UInt32))
        
        #if os(OSX)
            let pid = kAudioDevicePropertyBufferFrameSize
        #else
            let pid = kAudioUnitProperty_MaximumFramesPerSlice
        #endif
        
        let res = AudioUnitSetProperty(self.audioUnit, pid, kAudioUnitScope_Global, bus.rawValue, &value, size)
        return res
    }
    
    public func getBufferFrameSize(bus: SRAudioUnitBus) -> UInt32 {
        var value = UInt32()
        var size = UInt32(sizeof(UInt32))
        
        #if os(OSX)
            let pid = kAudioDevicePropertyBufferFrameSize
        #else
            let pid = kAudioUnitProperty_MaximumFramesPerSlice
        #endif

        let res = AudioUnitGetProperty(self.audioUnit, pid, kAudioUnitScope_Global, bus.rawValue, &value, &size)
        if res == noErr {
            return value
        }
        
        return 0
    }
    
    // MARK: - Format
    
    public func setStreamFormat(format: AudioStreamBasicDescription, scope: AudioUnitScope, bus: SRAudioUnitBus) throws {
        var desc = format
        let size = UInt32(sizeof(AudioStreamBasicDescription))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, scope, bus.rawValue, &desc, size)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setStreamFormat]")
        }
    }
    
    public func getStreamFormat(scope: AudioUnitScope, bus: SRAudioUnitBus) throws -> AudioStreamBasicDescription {
        var desc = AudioStreamBasicDescription()
        var size = UInt32(sizeof(AudioStreamBasicDescription))
        let res = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, scope, bus.rawValue, &desc, &size)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.getStreamFormat]")
        }
        
        return desc
    }
    
    // MARK: - IO Enabling
    
    public func enableIO(enable: Bool, scope: AudioUnitScope, bus: SRAudioUnitBus) throws {
        var flag = enable ? UInt32(1) : UInt32(0)
        let size = UInt32(sizeof(UInt32))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, scope, bus.rawValue, &flag, size)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res, description: SRAudioUnitErrorDesc("SRAudioUnit.enableIO \(enable)", scope: scope, bus: bus))
        }
    }
    
    public func getEnableIO(scope: AudioUnitScope, bus: SRAudioUnitBus) -> Bool? {
        var flag = UInt32()
        var size = UInt32(sizeof(UInt32))
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, scope, bus.rawValue, &flag, &size)
        if res == noErr {
            return (flag == 1 ? true : false)
        }
        
        return nil
    }
    
    // MARK: - Callbacks
    
    public func addRenderNotify(userData userData: AnyObject, callback: AURenderCallback) -> OSStatus {
        var userDataVar = userData
        let res = AudioUnitAddRenderNotify(self.audioUnit, callback, &userDataVar)
        
        return res
    }
    
    public func setRenderCallback(scope: AudioUnitScope, bus: SRAudioUnitBus, callbackStruct: AURenderCallbackStruct) throws {
        var mutableCallbackStruct = callbackStruct
        let size = UInt32(sizeof(AURenderCallbackStruct))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SetRenderCallback, scope, bus.rawValue, &mutableCallbackStruct, size)
        
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res, description: "SRAudioUnit.setRenderCallback")
        }
    }
}
