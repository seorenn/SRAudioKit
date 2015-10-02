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

public class SRAudioRecorder {
    var graph: SRAUGraph?
    
    var ioNode: SRAUNode?
    var ioAudioUnit: SRAudioUnit?
    
    var mixerNode: SRAUNode?
    var mixerAudioUnit: SRAudioUnit?
    
    var writer: SRAudioFileWriter?
    
    public private(set) var recording: Bool = false
    
    //public init?(outputPath: String, device: SRAudioDevice?, audioStreamDescription: SRAudioStreamDescription) {
    public init?(inputDevice: SRAudioDevice?, inputAudioStreamDescription: SRAudioStreamDescription, outputPath: String, outputAudioStreamDescription: SRAudioStreamDescription, outputFileFormat: SRAudioFileFormat) {
        self.graph = SRAUGraph()
        do {
            #if os(OSX)
                let ioNodeDesc = AudioComponentDescription(
                    componentType: kAudioUnitType_Output,
                    componentSubType: kAudioUnitSubType_HALOutput,
                    componentManufacturer: kAudioUnitManufacturer_Apple,
                    componentFlags: 0,
                    componentFlagsMask: 0)
            #else
                let ioNodeDesc = AudioComponentDescription(
                    componentType: kAudioUnitType_Output,
                    componentSubType: kAudioUnitSubType_RemoteIO,
                    componentManufacturer: kAudioUnitManufacturer_Apple,
                    componentFlags: 0,
                    componentFlagsMask: 0)
            #endif
            
            self.ioNode = try self.graph?.addNode(ioNodeDesc)
            
            let mixerDesc = AudioComponentDescription(componentType: kAudioUnitType_Mixer, componentSubType: kAudioUnitSubType_MultiChannelMixer, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
            self.mixerNode = try self.graph?.addNode(mixerDesc)
            
            try self.graph?.open()
            
            self.ioAudioUnit = try self.graph?.nodeInfo(self.ioNode!)
            
            self.ioAudioUnit?.enableIO(true, scope: kAudioUnitScope_Input, bus: .Input)
            self.ioAudioUnit?.setStreamFormat(inputAudioStreamDescription.audioStreamBasicDescription, scope: kAudioUnitScope_Input, bus: .Input)
            
            #if os(OSX)
                let inputScopeFormat = self.ioAudioUnit!.getStreamFormat(kAudioUnitScope_Output, bus: .Input)
                debugPrint("IO-AU Input Scope Format:")
                debugPrint(SRAudioStreamDescription(description: inputScopeFormat!))
                let outputScopeFormat = self.ioAudioUnit!.getStreamFormat(kAudioUnitScope_Input, bus: .Output)
                debugPrint("IO-AU Output Scope Format:")
                debugPrint(SRAudioStreamDescription(description: outputScopeFormat!))
            #endif
            
            // When open below comment, input callback will not calling.
            //self.ioAudioUnit.enableIO(false, scope: kAudioUnitScope_Output, bus: .Output)
            
            self.mixerAudioUnit = try! self.graph?.nodeInfo(self.mixerNode!)
            
            // Configure Audio Units
            
            let dev: SRAudioDevice = inputDevice ?? SRAudioDeviceManager.sharedManager.defaultInputDevice!
            self.ioAudioUnit?.setDevice(dev, bus: .Output)
            
            // Connect
            
            // mixerNode -> ioNOde
            try self.graph?.connect(sourceNode: self.mixerNode!, sourceOutputNumber: 0, destNode: self.ioNode!, destInputNumber: 0)
            // ioNode -> mixerNode
            try self.graph?.connect(sourceNode: self.ioNode!, sourceOutputNumber: 1, destNode: self.mixerNode!, destInputNumber: 1)

            // Prepare File Writer
            
            //let streamFormat = self.ioAudioUnit?.getStreamFormat(kAudioUnitScope_Output, bus: .Output)
            //let streamFormat = self.ioAudioUnit?.getStreamFormat(kAudioUnitScope_Output, bus: .Output)
//            let streamFormat = SRAudioGenerateFileFormatDescription(44100, frameType: .SignedInteger16Bit, stereo: true, format: .AIFF)
            self.writer = SRAudioFileWriter(audioStreamDescription: outputAudioStreamDescription, fileFormat: outputFileFormat, filePath: outputPath)
//            self.writer = SRAudioFileWriter(audioStreamDescription: outputAudioStreamDescription, outputPath: outputPath)
            if self.writer == nil { return nil }

            // Configure Callbacks

            try! self.graph?.setNodeInputCallback(self.mixerNode!, destInputNumber: 0, userData: self, callback: { (userData, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> OSStatus in
                let obj = userData as! SRAudioRecorder
                
                AudioUnitRender(obj.mixerAudioUnit!.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData)
                obj.append(ioData, bufferSize: inNumberFrames)
                
                return noErr
            })
            
//            try! self.graph?.setNodeInputCallback(self.mixerNode!, destInputNumber: 0, procRefCon: unsafeAddressOf(self), callback: {
//                (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> OSStatus in
//                //let audioUnit = inRefCon.memory as AudioUnit
//                let userDataPointer = unsafeBitCast(inRefCon, UnsafeMutablePointer<SRAudioRecorder>.self)
//                let userData = userDataPointer.memory
//                /*
//                let au = userData.mixerAudioUnit!.audioUnit
//                let res = AudioUnitRender(au, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData)
//                
//                if res == noErr {
//                    try! userData.writer.append(ioData, bufferSize: inNumberFrames)
//                }
//                return res
//                */
//                
//                userData.append(ioData, bufferSize: inNumberFrames)
//                return noErr
//            })
            
            try self.graph?.initialize()
        }
        catch SRAudioError.OSStatusError(let status) {
            debugPrint("Failed to initialize with OSStats \(status)")
            return nil
        }
        catch {
            debugPrint("Unknown Exception")
            return nil
        }
    }
    
    func append(bufferList: UnsafeMutablePointer<AudioBufferList>, bufferSize: UInt32) {
        guard let writer = self.writer else { return }
        try! writer.append(bufferList, bufferSize: bufferSize)
    }
    
    public func startRecord() {
        self.recording = true
        do {
            if self.graph!.running {
                debugPrint("Graph already running...")
                return
            }
            try self.graph?.start()
            self.graph?.CAShow()
        }
        catch {
            debugPrint("Failed to start graph")
        }
    }
    
    public func stopRecord() {
        self.recording = false
        do {
            if self.graph!.running == false {
                debugPrint("Graph not running")
                return
            }
            try self.graph?.stop()
            self.graph?.CAShow()
        }
        catch {
            debugPrint("Failed to stop graph")
        }
    }
}
