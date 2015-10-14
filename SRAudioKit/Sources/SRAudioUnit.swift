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

func SRAudioUnitErrorDesc(name: String, scope: AudioUnitScope?, bus: AudioUnitElement?) -> String {
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
        busString = " BUS[\(b)]"
    } else {
        busString = ""
    }
    
    return "[\(name)\(scopeString)\(busString)]"
}

public class SRAudioUnit: CustomDebugStringConvertible {
    let audioUnit: AudioUnit
    let underGraph: Bool

    // MARK: - Initializers
    
    // MARK: With AUGraph
    public init(audioUnit: AudioUnit) {
        assert(audioUnit != nil)
        self.audioUnit = audioUnit
        self.underGraph = true
    }
    
    // MARK: Without AUGraph
    public init?(description: AudioComponentDescription) {
        var mutableDesc = description
        let component = AudioComponentFindNext(nil, &mutableDesc)
        if component == nil {
            self.audioUnit = nil
            self.underGraph = false
            return nil
        }
        
        var au: AudioUnit = nil
        let res = AudioComponentInstanceNew(component, &au)
        if res != noErr {
            self.audioUnit = nil
            self.underGraph = false
            return nil
        }

        self.audioUnit = au
        self.underGraph = false
    }
    
    // MARK: Deinitializer
    deinit {
        if self.underGraph { return }
        AudioComponentInstanceDispose(self.audioUnit)
    }
    
    // MARK: - Devices
    
    #if os(OSX)
    public func setDevice(device: SRAudioDevice, bus: AudioUnitElement) throws {
        var deviceID = device.deviceID
        let size = UInt32(sizeof(AudioDeviceID))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, bus, &deviceID, size)
        
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setDevice BUS \(bus) \(device)]") }
    }
    
    public func getDevice(bus: AudioUnitElement) throws -> SRAudioDevice {
        var deviceID = AudioDeviceID()
        var size = UInt32(sizeof(AudioDeviceID))
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, bus, &deviceID, &size)
        
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRaudioUnit.getDevice BUS \(bus)") }
        
        return SRAudioDevice(deviceID: deviceID)
    }
    
    public func setChannelMap(channels: SRAudioDeviceIOChannels, scope: AudioUnitScope = kAudioUnitScope_Output, bus: AudioUnitElement = 1) throws {
        var channelMap = [Bool]()
        for i in 0..<channels.count {
            channelMap.append(channels[i])
        }
        
        try self.setChannelMap(channelMap, scope: scope, bus: bus)
    }
    
    public func setChannelMap(channelMap: [Bool], scope: AudioUnitScope = kAudioUnitScope_Output, bus: AudioUnitElement = 1) throws {
        let dataPtr = UnsafeMutablePointer<Int32>.alloc(channelMap.count)
        defer { dataPtr.dealloc(channelMap.count) }

        var curPtr = dataPtr
        for value in channelMap {
            curPtr.memory = value ? Int32(1) : Int32(0)
            curPtr = curPtr.successor()
        }
        
        let size = UInt32(channelMap.count * sizeof(Int32))
        
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, scope, bus, dataPtr, size)
        
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setChannelMap [\(channelMap)] Scope \(scope) BUS \(bus)]") }
    }
    
    public func getChannelMap(numberInputChannels: Int, scope: AudioUnitScope = kAudioUnitScope_Output, bus: AudioUnitElement = 1) throws -> [Bool]? {
        let dataPtr = UnsafeMutablePointer<Int32>.alloc(numberInputChannels)
        defer { dataPtr.dealloc(numberInputChannels) }
        
        var size = UInt32(numberInputChannels * sizeof(Int32))
        var result: [Bool]? = nil
        
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, scope, bus, dataPtr, &size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.getChannelMap numberInputChannels \(numberInputChannels) scope \(scope) bus \(bus)]") }
        
        result = [Bool]()
        var curPtr = dataPtr
        for _ in 0..<numberInputChannels {
            result!.append(curPtr.memory == 1 ? true : false)
            curPtr = curPtr.successor()
        }
        
        return result
    }
    #endif
    
    // MARK: - Buffer Frame Size
    
    public func setBufferFrameSize(frameSize: UInt32, bus: AudioUnitElement) throws {
        var value = frameSize
        let size = UInt32(sizeof(UInt32))
        
        #if os(OSX)
            let pid = kAudioDevicePropertyBufferFrameSize
        #else
            let pid = kAudioUnitProperty_MaximumFramesPerSlice
        #endif
        
        let res = AudioUnitSetProperty(self.audioUnit, pid, kAudioUnitScope_Global, bus, &value, size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setBufferFrameSize \(frameSize) BUS \(bus)]") }
    }
    
    public func getBufferFrameSize(bus: AudioUnitElement) throws -> UInt32 {
        var value = UInt32()
        var size = UInt32(sizeof(UInt32))
        
        #if os(OSX)
            let pid = kAudioDevicePropertyBufferFrameSize
        #else
            let pid = kAudioUnitProperty_MaximumFramesPerSlice
        #endif

        let res = AudioUnitGetProperty(self.audioUnit, pid, kAudioUnitScope_Global, bus, &value, &size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.getBufferFrameSize BUS \(bus)]") }
        
        return value
    }
    
    // MARK: - Format
    
    public func setStreamFormat(format: AudioStreamBasicDescription, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var desc = format
        let size = UInt32(sizeof(AudioStreamBasicDescription))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, scope, bus, &desc, size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setStreamFormat]") }
    }
    
    public func getStreamFormat(scope: AudioUnitScope, bus: AudioUnitElement) throws -> AudioStreamBasicDescription {
        var desc = AudioStreamBasicDescription()
        var size = UInt32(sizeof(AudioStreamBasicDescription))
        let res = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, scope, bus, &desc, &size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.getStreamFormat]") }
        
        return desc
    }
    
    // MARK: - IO Enabling
    
    public func enableIO(enable: Bool, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var flag = enable ? UInt32(1) : UInt32(0)
        let size = UInt32(sizeof(UInt32))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, scope, bus, &flag, size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: SRAudioUnitErrorDesc("SRAudioUnit.enableIO \(enable)", scope: scope, bus: bus)) }
    }
    
    public func getEnableIO(scope: AudioUnitScope, bus: AudioUnitElement) throws -> Bool {
        var flag = UInt32()
        var size = UInt32(sizeof(UInt32))
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, scope, bus, &flag, &size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.getEnableIO]") }

        return (flag == 1 ? true : false)
    }
    
    public func hasIO(scope: AudioUnitScope, bus: AudioUnitElement) throws -> Bool {
        var value = UInt32(0)
        var size = UInt32(sizeof(UInt32))
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_HasIO, scope, bus, &value, &size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.hasIO Scope \(scope) BUS \(bus)]") }
        
        return value == 0 ? false : true
    }
    
    // MARK: - Callbacks
    
    public func addRenderNotify(userData userData: AnyObject, callback: AURenderCallback) throws {
        var userDataVar = userData
        let res = AudioUnitAddRenderNotify(self.audioUnit, callback, &userDataVar)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.addRenderNotify]") }
    }
    
    public func setRenderCallback(scope: AudioUnitScope, bus: AudioUnitElement, callbackStruct: AURenderCallbackStruct) throws {
        var mutableCallbackStruct = callbackStruct
        let size = UInt32(sizeof(AURenderCallbackStruct))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SetRenderCallback, scope, bus, &mutableCallbackStruct, size)
        
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioUnit.setRenderCallback") }
    }

    public func setInputCallback(callbackStruct: AURenderCallbackStruct, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var mutableCallbackStruct = callbackStruct
        let size = UInt32(sizeof(AURenderCallbackStruct))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_SetInputCallback, scope, bus, &mutableCallbackStruct, size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioUnit.setInputCallback") }
    }
    
    public func setEnableCallbackBufferAllocation(enable: Bool, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var flag = enable ? 1 : 0
        let size = UInt32(sizeof(UInt32))
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, scope, bus, &flag, size)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setEnableCallbackBufferAllocation \(enable) Scope \(scope) BUS \(bus)]") }
    }

    // MARK: - Methods for Non-AUGraph Instances
    
    public func initialize() throws {
        let res = AudioUnitInitialize(self.audioUnit)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioUnit.initialize()") }
    }
    
    public func uninitialize() throws {
        let res = AudioUnitUninitialize(self.audioUnit)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioUnit.uninitialize()") }
    }
    
    public func start() throws {
        let res = AudioOutputUnitStart(self.audioUnit)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioUnit.start()") }
    }
    
    public func stop() throws {
        let res = AudioOutputUnitStop(self.audioUnit)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioUnit.stop()") }
    }
    
    // MARK: - Custom Debug String Convertible
    
    public var debugDescription: String {
        let ug = self.underGraph ? " (Generated via AUGraph)" : ""
        return "<SRAudioUnit \(self.audioUnit)\(ug)>"
    }
}
