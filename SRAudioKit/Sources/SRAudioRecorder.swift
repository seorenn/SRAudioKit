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
    
    public init?(inputDevice: SRAudioDevice?, inputStreamDescription: AudioStreamBasicDescription, outputPath: String, outputStreamDescription: AudioStreamBasicDescription, outputFileFormat: SRAudioFileFormat) {
        self.graph = SRAUGraph()
        do {
            let ioNodeDesc = AudioComponentDescription.mainIO()
            self.ioNode = try self.graph!.addNode(ioNodeDesc)
            
            let mixerDesc = AudioComponentDescription.multichannelMixer()
            self.mixerNode = try self.graph!.addNode(mixerDesc)
            
            self.ioAudioUnit = try self.graph!.nodeInfo(self.ioNode!)
            
            self.ioAudioUnit!.enableIO(true, scope: kAudioUnitScope_Input, bus: .Input)
            self.ioAudioUnit!.setStreamFormat(inputStreamDescription, scope: kAudioUnitScope_Input, bus: .Input)
            
            #if os(OSX)
                let inputScopeFormat = self.ioAudioUnit!.getStreamFormat(kAudioUnitScope_Output, bus: .Input)
                print("IO-AU Input Scope Format: \(inputScopeFormat)")
                let outputScopeFormat = self.ioAudioUnit!.getStreamFormat(kAudioUnitScope_Input, bus: .Output)
                print("IO-AU Output Scope Format: \(outputScopeFormat)")
            #endif
            
            // When open below comment, input callback will not calling.
            //self.ioAudioUnit.enableIO(false, scope: kAudioUnitScope_Output, bus: .Output)
            
            self.mixerAudioUnit = try! self.graph!.nodeInfo(self.mixerNode!)
            
            // Configure Audio Units
            
            let dev: SRAudioDevice = inputDevice ?? SRAudioDeviceManager.sharedManager.defaultInputDevice!
            self.ioAudioUnit!.setDevice(dev, bus: .Output)
            
            // Connect
            
            // mixerNode -> ioNOde
            try self.graph!.connect(sourceNode: self.mixerNode!, sourceOutputNumber: 0, destNode: self.ioNode!, destInputNumber: 0)
            // ioNode -> mixerNode
            try self.graph!.connect(sourceNode: self.ioNode!, sourceOutputNumber: 1, destNode: self.mixerNode!, destInputNumber: 1)

            try self.graph!.open()
            
            // Prepare File Writer
            
            self.writer = SRAudioFileWriter(audioStreamDescription: outputStreamDescription, fileFormat: outputFileFormat, filePath: outputPath)
            if self.writer == nil {
                print("Failed to initialize SRAudioFileWriter. Cancel operations")
                return nil
            }

            // Configure Callbacks
            
            let selfPointer = UnsafeMutablePointer<Void>(Unmanaged.passUnretained(self).toOpaque())
            let callback = AURenderCallbackStruct(
                inputProc: { (inRefCon, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> OSStatus in
                    let recorderObject = Unmanaged<SRAudioRecorder>.fromOpaque(COpaquePointer(inRefCon)).takeUnretainedValue()
                    // TODO
                    return noErr
                },
                inputProcRefCon: selfPointer)
            try! self.graph!.setNodeInputCallback(self.mixerNode!, destInputNumber: 0, callback: callback)
            
            /*
            try! self.graph?.setNodeInputCallback(
                self.mixerNode!,
                destInputNumber: 0,
                userData: self,
                callback: {
                    (userData, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData) -> OSStatus in
                    print("IN Callback")
                    let obj = userData as! SRAudioRecorder
                    
                    AudioUnitRender(obj.mixerAudioUnit!.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData)
                    obj.append(ioData, bufferSize: inNumberFrames)
                    
                    return noErr
            })
            */
            
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
            try self.graph!.stop()
            self.graph!.CAShow()
        }
        catch {
            print("Failed to stop graph")
        }
    }
}
