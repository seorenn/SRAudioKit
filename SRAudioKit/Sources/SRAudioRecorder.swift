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

public class SRAudioRecorder {
    let graph = SRAUGraph()
    let ioNode: SRAUNode
    let ioAudioUnit: SRAudioUnit
    //let mixerNode: SRAUNode
    
    public init(device: SRAudioDevice?, sampleRate: Float64, frameType: SRAudioFrameType) {
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
        
        self.ioNode = try! self.graph.addNode(ioNodeDesc)
        
        try! self.graph.open()
        
        self.ioAudioUnit = try! self.graph.nodeInfo(self.ioNode)
        
        if let device = device {
            self.setupDevice(self.ioAudioUnit, device: device)
        } else {
            self.setupDevice(self.ioAudioUnit, device: SRAudioDeviceManager.sharedManager.defaultInputDevice!)
        }
    }
    
    func setupDevice(audioUnit: SRAudioUnit, device: SRAudioDevice) {
        
    }
    
    public func startRecord(outputPath: String) {
        
    }
    
    public func stopRecord() {
        
    }
}
