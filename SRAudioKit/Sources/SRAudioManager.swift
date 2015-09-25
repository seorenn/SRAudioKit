//
//  SRAudioManager.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import SRAudioKitPrivates
import AudioToolbox
import CoreAudio

struct SRAudioNodeConnection {
    let sourceNode: AUNode
    let sourceAudioUnit: AudioUnit
    
    let destNode: AUNode
    let destAudioUnit: AudioUnit
}

public class SRAudioManager: CustomDebugStringConvertible {
    public static let sharedManager = SRAudioManager()
    
    private let graph: AUGraph
    private var connections = [SRAudioNodeConnection]()
    
    public var streamConfiguration: AudioStreamBasicDescription = SRAudioGetAudioStreamBasicDescription(true, 44100, .SignedInteger16Bit, false, true)
    
    public init() {
        var graph = AUGraph()
        NewAUGraph(&graph)
        self.graph = graph
    }
    
    public func connect(input: SRAudioIOObject, output: SRAudioIOObject) {
        do {
            var inputNode = AUNode()
            var inputDescription = input.componentDescription
            
            var outputNode = AUNode()
            var outputDescription = output.componentDescription
            
            try SRAUGraphAssert(AUGraphAddNode(self.graph, &inputDescription, &inputNode))
            try SRAUGraphAssert(AUGraphAddNode(self.graph, &outputDescription, &outputNode))
            
            // Instantiate all audio units indirectly
            try SRAUGraphAssert(AUGraphOpen(self.graph))
            
            var inputAudioUnit = AudioUnit()
            var outputAudioUnit = AudioUnit()
            
            try SRAUGraphAssert(AUGraphNodeInfo(self.graph, inputNode, nil, &inputAudioUnit))
            try SRAUGraphAssert(AUGraphNodeInfo(self.graph, outputNode, nil, &outputAudioUnit))
            
            // Configure Audio Unit Properties
            input.configure(inputNode, audioUnit: inputAudioUnit)
            output.configure(outputNode, audioUnit: outputAudioUnit)
            
            let inputToOutputElement = AudioUnitElement(0)
            let outputFromInputElement = AudioUnitElement(0)
            try SRAUGraphAssert(AUGraphConnectNodeInput(self.graph, inputNode, inputToOutputElement, outputNode, outputFromInputElement))
            
            // TODO: Register Render Callback
            
            // Finish
            
            let con = SRAudioNodeConnection(sourceNode: inputNode, sourceAudioUnit: inputAudioUnit, destNode: outputNode, destAudioUnit: outputAudioUnit)
            self.connections.append(con)
        }
        catch {
            debugPrint("SRAudioManager.connect() ERROR: Something goes wrong")
        }
    }
    
    public func start() {
        
    }
    
    public func stop() {
        
    }
    
    // MARK: - Privates
    
    private func checkOSStatus(status: OSStatus) throws {
        
    }
    
    // MARK: - CustomDebugStringConvertible
    
    public var debugDescription: String {
        var g = self.graph
        CAShow(&g)
        
        return "<SRAudioManager>"
    }
}
