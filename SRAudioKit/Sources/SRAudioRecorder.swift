//
//  SRAudioRecorder.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudioKit
import AudioToolbox
import SRAudioKitPrivates

let BusHALInput = AudioUnitElement(1)
let BusHALOutput = AudioUnitElement(0)
let SRAudioRecorderDefaultFrameSize = UInt32(1024)

public class SRAudioRecorder {
    var au: SRAudioUnit?
    var writer: SRAudioFileWriter?
    var buffer: SRAudioBuffer?
    
    lazy var pointer: UnsafeMutablePointer<Void> = {
        return UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
        }()
    
    let callback: AURenderCallback = {
        (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) in
        
        print("AURenderCallback: Called with Bus \(inBusNumber), \(inNumberFrames)frames")
        
        let recorderObject: SRAudioRecorder = Unmanaged<SRAudioRecorder>.fromOpaque(COpaquePointer(inRefCon)).takeUnretainedValue()
        //let res = AudioUnitRender(recorderObject.au!.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData)
        
        do {
            try recorderObject.buffer!.render(audioUnit: recorderObject.au!, ioActionFlags: ioActionFlags, inTimeStamp: inTimeStamp, inOutputBusNumber: inBusNumber, inNumberFrames: inNumberFrames)
            
            recorderObject.append(inNumberFrames)
        } catch let err as SRAudioError {
            print("Render Callback Error: \(err)")
        } catch {
            print("Unknown Error")
        }

        return noErr
    }
    
    lazy var callbackStruct: AURenderCallbackStruct = {
        return AURenderCallbackStruct(inputProc: self.callback, inputProcRefCon: self.pointer)
        }()
    
    public private(set) var recording: Bool = false
    
    public init?(inputDevice: SRAudioDevice?, outputPath: String, streamDescription: AudioStreamBasicDescription, outputFileFormat: SRAudioFileFormat) {
        let desc = AudioComponentDescription.HAL()
        self.au = SRAudioUnit(description: desc)
        if self.au == nil { return nil }
        
        do {
            // Enable Input Scope
            try self.au!.enableIO(true, scope: kAudioUnitScope_Input, bus: BusHALInput)
            // Disable Output Scope
            try self.au!.enableIO(false, scope: kAudioUnitScope_Output, bus: BusHALOutput)
            
            let dev: SRAudioDevice = inputDevice ?? SRAudioDeviceManager.sharedManager.defaultInputDevice!
            try self.au!.setDevice(dev, bus: BusHALOutput)
            
            try self.au!.setStreamFormat(streamDescription, scope: kAudioUnitScope_Input, bus: BusHALOutput)
            try self.au!.setStreamFormat(streamDescription, scope: kAudioUnitScope_Output, bus: BusHALInput)

            #if os(OSX)
                let inputScopeFormat = try self.au!.getStreamFormat(kAudioUnitScope_Output, bus: BusHALInput)
                print("IO-AU Input Scope Format: \(inputScopeFormat)")
                let outputScopeFormat = try self.au!.getStreamFormat(kAudioUnitScope_Input, bus: BusHALOutput)
                print("IO-AU Output Scope Format: \(outputScopeFormat)")
            #endif
            

            try self.au!.setChannelMap(dev.inputChannels, scope: kAudioUnitScope_Output, bus: BusHALInput)
            
            try self.au!.setBufferFrameSize(SRAudioRecorderDefaultFrameSize, bus: BusHALInput)
            try self.au!.setBufferFrameSize(SRAudioRecorderDefaultFrameSize, bus: BusHALOutput)
            
            // Prepare Buffer
            
            let frameSize = try self.au!.getBufferFrameSize(BusHALInput)
            self.buffer = SRAudioBuffer(ASBD: inputScopeFormat, frameCapacity: frameSize)
            
            // Prepare File Writer
            
            self.writer = SRAudioFileWriter(audioStreamDescription: inputScopeFormat, fileFormat: outputFileFormat, filePath: outputPath)
            guard let _ = self.writer else {
                print("Failed to initialize SRAudioFileWriter. Cancel operations")
                return nil
            }
            
            // Configure Callbacks
            try self.au!.setInputCallback(callbackStruct, scope: kAudioUnitScope_Global, bus: BusHALOutput)
            try self.au!.setEnableCallbackBufferAllocation(false, scope: kAudioUnitScope_Output, bus: BusHALInput)
            
            try self.au!.initialize()
        }
        catch let error as SRAudioError {
            print("[SRAudioRecorder.init] \(error)")
        }
        catch {
            print("Unknown Exception")
            return nil
        }
    }
    
    
    
    func append(bufferList: UnsafeMutablePointer<AudioBufferList>, bufferSize: UInt32) {
        guard let writer = self.writer
            else { return }
        
        try! writer.append(bufferList, bufferSize: bufferSize)
    }
    
    func append(bufferSize: UInt32) {
        self.append(self.buffer!.audioBufferList.unsafeMutablePointer, bufferSize: bufferSize)
    }
    
    public func startRecord() {
        guard let au = self.au
            else { return }
        
        try! au.start()
        self.recording = true
    }
    
    public func stopRecord() {
        guard self.recording
            else { return }
        
        defer { self.recording = false }
        
        guard let au = self.au
            else { return }

        try! au.stop()
        
        guard let writer = self.writer
            else { return }
        
        try! writer.close()
    }
}

/* OLD CODES HERE */
/* This is backup code. Because, this code not works but I don't know any ideas */

public class SRAudioRecorderWithGraph {
    var graph: SRAUGraph?
    
    var ioNode: SRAUNode?
    var ioAudioUnit: SRAudioUnit?
    
    var writer: SRAudioFileWriter?
    
    var buffer: SRAudioBuffer?
    
    // MARK: - Callback Properties
    
    lazy var pointer: UnsafeMutablePointer<Void> = {
        return UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
    }()
    
    let callback: AURenderCallback = {
        (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) in
        
        print("AURenderCallback: Called with Bus \(inBusNumber), \(inNumberFrames)frames")
        
        if ioActionFlags.memory.contains([.UnitRenderAction_PostRender]) == false {
            return noErr;
        }
        
        let recorderObject: SRAudioRecorder = Unmanaged<SRAudioRecorder>.fromOpaque(COpaquePointer(inRefCon)).takeUnretainedValue()
        let abl = UnsafeMutableAudioBufferListPointer(ioData)
        print("AURenderCallback: ioData = \(abl.count) buffers")
        for b: AudioBuffer in abl {
            print("AURenderCallback: ioData Buffer = \(b.mNumberChannels) channels \(b.mDataByteSize) bytes")
        }
        
        recorderObject.buffer!.copy(UnsafeMutableAudioBufferListPointer(ioData))
        
        return noErr
    }

    lazy var callbackStruct: AURenderCallbackStruct = {
        return AURenderCallbackStruct(inputProc: self.callback, inputProcRefCon: self.pointer)
    }()
    
    public private(set) var recording: Bool = false
    
    // MARK: -
    
    public init?(inputDevice: SRAudioDevice?, outputPath: String, streamDescription: AudioStreamBasicDescription, outputFileFormat: SRAudioFileFormat) {
        self.graph = SRAUGraph()
        
        do {
            let ioNodeDesc = AudioComponentDescription.HAL()
            self.ioNode = try self.graph!.addNode(ioNodeDesc)
            
            try self.graph!.open()
            
            self.ioAudioUnit = try self.graph!.nodeInfo(self.ioNode!)
            
            // Enable Input Scope
            try self.ioAudioUnit!.enableIO(true, scope: kAudioUnitScope_Input, bus: BusHALInput)
            // Disable Output Scope
            try self.ioAudioUnit!.enableIO(false, scope: kAudioUnitScope_Output, bus: BusHALOutput)
            
            let dev: SRAudioDevice = inputDevice ?? SRAudioDeviceManager.sharedManager.defaultInputDevice!
            try self.ioAudioUnit!.setDevice(dev, bus: BusHALOutput)
            
            #if os(OSX)
                let inputScopeFormat = try self.ioAudioUnit!.getStreamFormat(kAudioUnitScope_Output, bus: BusHALInput)
                print("IO-AU Input Scope Format: \(inputScopeFormat)")
                let outputScopeFormat = try self.ioAudioUnit!.getStreamFormat(kAudioUnitScope_Input, bus: BusHALOutput)
                print("IO-AU Output Scope Format: \(outputScopeFormat)")
            #endif
            
            // Prepare Buffer
            
            self.buffer = SRAudioBuffer(ASBD: streamDescription, frameCapacity: 512)
            
            // Prepare File Writer
            
            self.writer = SRAudioFileWriter(audioStreamDescription: streamDescription, fileFormat: outputFileFormat, filePath: outputPath)
            if self.writer == nil {
                print("Failed to initialize SRAudioFileWriter. Cancel operations")
                return nil
            }

            // Configure Callbacks
            
            /*
            let selfPointer = UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
            let callback: AURenderCallback = {
                (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) in
                
                print("AURenderCallback: Called with Bus \(inBusNumber), \(inNumberFrames)frames")
                
                if ioActionFlags.memory.contains([.UnitRenderAction_PostRender]) == false {
                    return noErr;
                }
                
                let recorderObject: SRAudioRecorder = Unmanaged<SRAudioRecorder>.fromOpaque(COpaquePointer(inRefCon)).takeUnretainedValue()
                let abl = UnsafeMutableAudioBufferListPointer(ioData)
                print("AURenderCallback: ioData = \(abl.count) buffers")
                for b: AudioBuffer in abl {
                    print("AURenderCallback: ioData Buffer = \(b.mNumberChannels) channels \(b.mDataByteSize) bytes")
                }
                
                recorderObject.buffer!.copy(UnsafeMutableAudioBufferListPointer(ioData))
                
                return noErr
            }
            
            let callbackStruct = AURenderCallbackStruct(inputProc: callback, inputProcRefCon: selfPointer)
            */
            try! self.graph!.setNodeInputCallback(self.ioNode!, destInputNumber: BusHALOutput, callback: self.callbackStruct)
            
            try self.ioAudioUnit!.setStreamFormat(streamDescription, scope: kAudioUnitScope_Input, bus: BusHALOutput)
            
            try self.graph!.initialize()
        }
        catch let error as SRAudioError {
            print("[SRAudioRecorder.init] \(error)")
        }
        catch {
            print("Unknown Exception")
            return nil
        }
    }
    
    deinit {
        try! self.graph!.uninitialize()
        try! self.graph!.close()
    }
    
    func append(bufferList: UnsafeMutablePointer<AudioBufferList>, bufferSize: UInt32) {
        guard let writer = self.writer else { return }
        try! writer.append(bufferList, bufferSize: bufferSize)
    }
    
    public func startRecord() {
        if self.graph == nil { return }
        
        self.recording = true
        do {
            if self.graph!.running {
                print("Graph already running...")
                return
            }
            try self.graph!.start()
            self.graph!.CAShow()
        }
        catch {
            print("Failed to start graph")
        }
    }
    
    public func stopRecord() {
        if self.graph == nil { return }

        self.recording = false
        do {
            if self.graph!.running == false {
                print("Graph not running")
                return
            }
            try self.writer?.close()
            try self.graph!.stop()
            self.graph!.CAShow()
        }
        catch {
            print("Failed to stop graph")
        }
    }
}
