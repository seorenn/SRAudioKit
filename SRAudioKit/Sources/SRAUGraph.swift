//
//  SRAUGraph.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox

public class SRAUGraph {
    let graph: AUGraph
    
    public init() {
        var graph = AUGraph()
        NewAUGraph(&graph)
        self.graph = graph
    }
    
    public func addNode(componentDescription: AudioComponentDescription) throws -> SRAUNode {
        var node = AUNode()
        var desc = componentDescription
        let res = AUGraphAddNode(self.graph, &desc, &node)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
        
        return SRAUNode(node: node)
    }
    
    public func open() throws {
        let res = AUGraphOpen(self.graph)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
    }
    
    public func nodeInfo(node: SRAUNode) throws -> SRAudioUnit {
        var audioUnit = AudioUnit()
        let res = AUGraphNodeInfo(self.graph, node.node, nil, &audioUnit)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
        
        return SRAudioUnit(audioUnit: audioUnit)
    }
    
    public func connect(sourceNode: SRAUNode, sourceOutputNumber: UInt32, destNode: SRAUNode, destInputNumber: UInt32) throws {
        let res = AUGraphConnectNodeInput(self.graph, sourceNode.node, sourceOutputNumber, destNode.node, destInputNumber)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
    }
    
    public func setNodeInputCallback(destNode: SRAUNode, destInputNumber: UInt32, procRefCon: AnyObject, callback: AURenderCallback) throws {
        var ref = procRefCon
        var callbackStruct = AURenderCallbackStruct(inputProc: callback, inputProcRefCon: &ref)
        let res = AUGraphSetNodeInputCallback(self.graph, destNode.node, destInputNumber, &callbackStruct)
        
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
    }
    
    public func initialize() throws {
        let res = AUGraphInitialize(self.graph)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
    }
    
    public func start() throws {
        let res = AUGraphStart(self.graph)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
    }
    
    public func stop() throws {
        let res = AUGraphStop(self.graph)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
    }
    
    public func dispose() throws {
        let res = DisposeAUGraph(self.graph)
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res)
        }
    }
}
