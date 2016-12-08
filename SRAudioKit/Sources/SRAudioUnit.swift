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

func SRAudioUnitErrorDesc(_ name: String, scope: AudioUnitScope?, bus: AudioUnitElement?) -> String {
    let scopeString: String
    
    if let s = scope {
        switch (s) {
        case kAudioUnitScope_Global:
            scopeString = " SCOPE[GLOBAL]"
        case kAudioUnitScope_Input:
            scopeString = " SCOPE[INPUT]"
        case kAudioUnitScope_Output:
            scopeString = " SCOPE[OUTPUT]"
        default:
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

open class SRAudioUnit: CustomDebugStringConvertible {
    let audioUnit: AudioUnit
    let underGraph: Bool

    // MARK: - Initializers
    
    // MARK: With AUGraph
    public init(audioUnit: AudioUnit) {
        //assert(audioUnit != nil)
        self.audioUnit = audioUnit
        self.underGraph = true
    }
    
    // MARK: Without AUGraph
    public init?(description: AudioComponentDescription) {
        var mutableDesc = description
        let component = AudioComponentFindNext(nil, &mutableDesc)
        if component == nil {
            //self.audioUnit = nil
            self.underGraph = false
            return nil
        }
        
        var au: AudioUnit? = nil
        let res = AudioComponentInstanceNew(component!, &au)
        if res != noErr {
            //self.audioUnit = nil
            self.underGraph = false
            return nil
        }

        self.audioUnit = au!
        self.underGraph = false
    }
    
    // MARK: Deinitializer
    deinit {
        if self.underGraph { return }
        AudioComponentInstanceDispose(self.audioUnit)
    }
    
    // MARK: - Devices
    
    open func setDevice(_ device: SRAudioDevice, bus: AudioUnitElement) throws {
        #if os(OSX)
            var deviceID = device.deviceID
            let size = UInt32(MemoryLayout<AudioDeviceID>.size)
            let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, bus, &deviceID, size)
            
            guard res == noErr else {
                throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.setDevice BUS \(bus) \(device)]")
            }
        #endif
    }
    
    open func getDevice(_ bus: AudioUnitElement) throws -> SRAudioDevice? {
        #if os(OSX)
            var deviceID = AudioDeviceID()
            var size = UInt32(MemoryLayout<AudioDeviceID>.size)
            let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, bus, &deviceID, &size)
            
            guard res == noErr else {
                throw SRAudioError.osStatusError(status: res, description: "[SRaudioUnit.getDevice BUS \(bus)")
            }
            
            return SRAudioDevice(deviceID: deviceID)
        #else
            return nil
        #endif
    }
    
    // Maybe not used
    /*
    public func setChannelMap(channels: SRAudioDeviceIOChannels, scope: AudioUnitScope = kAudioUnitScope_Output, bus: AudioUnitElement = 1) throws {
        #if os(OSX)
            var channelMap = [Bool]()
            for i in 0..<channels.count {
                channelMap.append(channels[i])
            }
            
            try self.setChannelMap(channelMap, scope: scope, bus: bus)
        #endif
    }
    */
    
    // Maybe not used
    /*
    public func setChannelMap(channelMap: [Bool], scope: AudioUnitScope = kAudioUnitScope_Output, bus: AudioUnitElement = 1) throws {
        #if os(OSX)
            let dataPtr = UnsafeMutablePointer<Int32>.alloc(channelMap.count)
            defer { dataPtr.dealloc(channelMap.count) }

            var curPtr = dataPtr
            for value in channelMap {
                curPtr.memory = value ? Int32(1) : Int32(0)
                curPtr = curPtr.successor()
            }
            
            let size = UInt32(channelMap.count * sizeof(Int32))
            
            let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, scope, bus, dataPtr, size)
            
            guard res == noErr else {
                throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.setChannelMap [\(channelMap)] Scope \(scope) BUS \(bus)]")
            }
        #endif
    }
    */
    
    open func setChannelMap(_ channelMap: [Int32], scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var mutableMap = channelMap
        let size = UInt32(channelMap.count * MemoryLayout<Int32>.size)
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, scope, bus, &mutableMap, size)
        
        if res != noErr {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.setChannelMap \(channelMap) scope \(scope) bus \(bus)")
        }
    }
    
    // Maybe not used
    /*
    public func getChannelMap(numberInputChannels: Int, scope: AudioUnitScope = kAudioUnitScope_Output, bus: AudioUnitElement = 1) throws -> [Bool]? {
        #if os(OSX)
            let dataPtr = UnsafeMutablePointer<Int32>.alloc(numberInputChannels)
            defer { dataPtr.dealloc(numberInputChannels) }
            
            var size = UInt32(numberInputChannels * sizeof(Int32))
            var result: [Bool]? = nil
            
            let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, scope, bus, dataPtr, &size)
            guard res == noErr else {
                throw SRAudioError.OSStatusError(status: res, description: "[SRAudioUnit.getChannelMap numberInputChannels \(numberInputChannels) scope \(scope) bus \(bus)]")
            }
            
            result = [Bool]()
            var curPtr = dataPtr
            for _ in 0..<numberInputChannels {
                result!.append(curPtr.memory == 1 ? true : false)
                curPtr = curPtr.successor()
            }
            
            return result
        #else
           return nil
        #endif
    }
    */
    
    open func getChannelMap(_ numberInputChannels: Int, scope: AudioUnitScope, bus: AudioUnitElement) throws -> [Int32] {
        #if os(OSX)
            let dataPtr = UnsafeMutablePointer<Int32>.allocate(capacity: numberInputChannels)
            defer { dataPtr.deallocate(capacity: numberInputChannels) }
            
            var size = UInt32(numberInputChannels * MemoryLayout<Int32>.size)
            var result = [Int32]()
            
            let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_ChannelMap, scope, bus, dataPtr, &size)
            guard res == noErr else {
                throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.getChannelMap numberInputChannels \(numberInputChannels) scope \(scope) bus \(bus)]")
            }
            
            var curPtr = dataPtr
            for _ in 0..<numberInputChannels {
                result.append(curPtr.pointee)
                curPtr = curPtr.successor()
            }
            
            return result
        #else
            return [Int32]()
        #endif
    }
    
    // MARK: - Buffer Frame Size
    
    open func setBufferFrameSize(_ frameSize: UInt32, bus: AudioUnitElement) throws {
        var value = frameSize
        let size = UInt32(MemoryLayout<UInt32>.size)
        
        #if os(OSX)
            let pid = kAudioDevicePropertyBufferFrameSize
        #else
            let pid = kAudioUnitProperty_MaximumFramesPerSlice
        #endif
        
        let res = AudioUnitSetProperty(self.audioUnit, pid, kAudioUnitScope_Global, bus, &value, size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.setBufferFrameSize \(frameSize) BUS \(bus)]")
        }
    }
    
    open func getBufferFrameSize(_ bus: AudioUnitElement) throws -> UInt32 {
        var value = UInt32()
        var size = UInt32(MemoryLayout<UInt32>.size)
        
        #if os(OSX)
            let pid = kAudioDevicePropertyBufferFrameSize
        #else
            let pid = kAudioUnitProperty_MaximumFramesPerSlice
        #endif

        let res = AudioUnitGetProperty(self.audioUnit, pid, kAudioUnitScope_Global, bus, &value, &size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.getBufferFrameSize BUS \(bus)]")
        }
        
        return value
    }
    
    // MARK: - Format
    
    open func setStreamFormat(_ format: AudioStreamBasicDescription, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var desc = format
        let size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, scope, bus, &desc, size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.setStreamFormat]")
        }
    }
    
    open func getStreamFormat(_ scope: AudioUnitScope, bus: AudioUnitElement) throws -> AudioStreamBasicDescription {
        var desc = AudioStreamBasicDescription()
        var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
        let res = AudioUnitGetProperty(self.audioUnit, kAudioUnitProperty_StreamFormat, scope, bus, &desc, &size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.getStreamFormat]")
        }
        
        return desc
    }
    
    // MARK: - IO Enabling
    
    open func enableIO(_ enable: Bool, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var flag = enable ? UInt32(1) : UInt32(0)
        let size = UInt32(MemoryLayout<UInt32>.size)
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, scope, bus, &flag, size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: SRAudioUnitErrorDesc("SRAudioUnit.enableIO \(enable)", scope: scope, bus: bus))
        }
    }
    
    open func getEnableIO(_ scope: AudioUnitScope, bus: AudioUnitElement) throws -> Bool {
        var flag = UInt32()
        var size = UInt32(MemoryLayout<UInt32>.size)
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_EnableIO, scope, bus, &flag, &size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.getEnableIO]")
        }

        return (flag == 1 ? true : false)
    }
    
    open func hasIO(_ scope: AudioUnitScope, bus: AudioUnitElement) throws -> Bool {
        var value = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        let res = AudioUnitGetProperty(self.audioUnit, kAudioOutputUnitProperty_HasIO, scope, bus, &value, &size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.hasIO Scope \(scope) BUS \(bus)]")
        }
        
        return value == 0 ? false : true
    }
    
    // MARK: - Callbacks
    
    open func addRenderNotify(userData: AnyObject, callback: @escaping AURenderCallback) throws {
        var userDataVar = userData
        let res = AudioUnitAddRenderNotify(self.audioUnit, callback, &userDataVar)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.addRenderNotify]")
        }
    }
    
    open func setRenderCallback(_ scope: AudioUnitScope, bus: AudioUnitElement, callbackStruct: AURenderCallbackStruct) throws {
        var mutableCallbackStruct = callbackStruct
        let size = UInt32(MemoryLayout<AURenderCallbackStruct>.size)
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_SetRenderCallback, scope, bus, &mutableCallbackStruct, size)
        
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "SRAudioUnit.setRenderCallback")
        }
    }

    open func setInputCallback(_ callbackStruct: AURenderCallbackStruct, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var mutableCallbackStruct = callbackStruct
        let size = UInt32(MemoryLayout<AURenderCallbackStruct>.size)
        let res = AudioUnitSetProperty(self.audioUnit, kAudioOutputUnitProperty_SetInputCallback, scope, bus, &mutableCallbackStruct, size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "SRAudioUnit.setInputCallback")
        }
    }
    
    open func setEnableCallbackBufferAllocation(_ enable: Bool, scope: AudioUnitScope, bus: AudioUnitElement) throws {
        var flag = enable ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        let res = AudioUnitSetProperty(self.audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, scope, bus, &flag, size)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioUnit.setEnableCallbackBufferAllocation \(enable) Scope \(scope) BUS \(bus)]")
        }
    }

    // MARK: - Methods for Non-AUGraph Instances
    
    open func initialize() throws {
        let res = AudioUnitInitialize(self.audioUnit)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "SRAudioUnit.initialize()")
        }
    }
    
    open func uninitialize() throws {
        let res = AudioUnitUninitialize(self.audioUnit)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "SRAudioUnit.uninitialize()")
        }
    }
    
    open func start() throws {
        let res = AudioOutputUnitStart(self.audioUnit)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "SRAudioUnit.start()")
        }
    }
    
    open func stop() throws {
        let res = AudioOutputUnitStop(self.audioUnit)
        guard res == noErr else {
            throw SRAudioError.osStatusError(status: res, description: "SRAudioUnit.stop()")
        }
    }
    
    // MARK: - Custom Debug String Convertible
    
    open var debugDescription: String {
        let ug = self.underGraph ? " (Generated via AUGraph)" : ""
        return "<SRAudioUnit \(self.audioUnit)\(ug)>"
    }
}
