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

struct SRAudioRecorderInternal {
    let graph: SRAUGraph
    
    let ioNode: SRAUNode
    let ioAudioUnit: SRAudioUnit
    
    let mixerNode: SRAUNode
    let mixerAudioUnit: SRAudioUnit
    
    init?(device: SRAudioDevice?, sampleRate: Float64, frameType: SRAudioFrameType) {
        self.graph = SRAUGraph()
        do {
            #if os(OSX)
                let ioNodeDesc = AudioComponentDescription(componentType: kAudioUnitType_Output,
                    componentSubType: kAudioUnitSubType_HALOutput,
                    componentManufacturer: kAudioUnitManufacturer_Apple,
                    componentFlags: 0,
                    componentFlagsMask: 0)
            #else
                let ioNodeDesc = AudioComponentDescription(componentType: kAudioUnitType_Output,
                    componentSubType: kAudioUnitSubType_RemoteIO,
                    componentManufacturer: kAudioUnitManufacturer_Apple,
                    componentFlags: 0,
                    componentFlagsMask: 0)
            #endif
            
            self.ioNode = try self.graph.addNode(ioNodeDesc)
            
            let mixerDesc = AudioComponentDescription(componentType: kAudioUnitType_Mixer, componentSubType: kAudioUnitSubType_MultiChannelMixer, componentManufacturer: kAudioUnitManufacturer_Apple, componentFlags: 0, componentFlagsMask: 0)
            self.mixerNode = try self.graph.addNode(mixerDesc)
            
            try self.graph.open()
            
            self.ioAudioUnit = try self.graph.nodeInfo(self.ioNode)
            
            self.ioAudioUnit.enableIO(true, scope: kAudioUnitScope_Input, bus: .Input)
            
            // When open below comment, input callback will not calling.
            //self.ioAudioUnit.enableIO(false, scope: kAudioUnitScope_Output, bus: .Output)
            
            self.mixerAudioUnit = try! self.graph.nodeInfo(self.mixerNode)
            
            // Configure Audio Units
            
            let dev: SRAudioDevice = device ?? SRAudioDeviceManager.sharedManager.defaultInputDevice!
            self.ioAudioUnit.setDevice(dev, bus: .Output)
            
            // Connect
            
            // mixerNode -> ioNOde
            try self.graph.connect(sourceNode: self.mixerNode, sourceOutputNumber: 0, destNode: self.ioNode, destInputNumber: 0)
            // ioNode -> mixerNode
            try self.graph.connect(sourceNode: self.ioNode, sourceOutputNumber: 1, destNode: self.mixerNode, destInputNumber: 1)
            
            // Configure Callbacks
            
            try! self.graph.setNodeInputCallback(self.mixerNode, destInputNumber: 0, procRefCon: self.mixerNode, callback: {
                (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> OSStatus in
                debugPrint("[Callback] Frames: \(inNumberFrames)")
                return noErr
            })
            
            try self.graph.initialize()
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
}

public class SRAudioRecorder {
    let intls: SRAudioRecorderInternal!
    
    public private(set) var recording: Bool = false
    
    public init?(device: SRAudioDevice?, sampleRate: Float64, frameType: SRAudioFrameType) {
        self.intls = SRAudioRecorderInternal(device: device, sampleRate: sampleRate, frameType: frameType)
        if self.intls == nil { return nil }
        
        self.intls.graph.CAShow()
    }
    
    public func startRecord(outputPath: String) {
        self.recording = true
        do {
            if self.intls.graph.running {
                debugPrint("Graph already running...")
                return
            }
            try self.intls.graph.start()
            self.intls.graph.CAShow()
        }
        catch {
            debugPrint("Failed to start graph")
        }
    }
    
    public func stopRecord() {
        self.recording = false
        do {
            if self.intls.graph.running == false {
                debugPrint("Graph not running")
                return
            }
            try self.intls.graph.stop()
            self.intls.graph.CAShow()
        }
        catch {
            debugPrint("Failed to stop graph")
        }
    }
}
