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
import SRAudioKitPrivates

public class SRAUGraph {
  let graph: AUGraph
  
  public init() {
    var graphInstance: AUGraph = nil  //= AUGraph()
    NewAUGraph(&graphInstance)
    self.graph = graphInstance
  }
  
  deinit {
    DisposeAUGraph(self.graph)
  }
  
  public var running: Bool {
    var value = DarwinBoolean(false)
    let res = AUGraphIsRunning(self.graph, &value)
    guard res == noErr else { return false }
    
    return value.boolValue
  }
  
  public func clearConnections() throws {
    let res = AUGraphClearConnections(self.graph)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.clearConnections()")
    }
  }
  
  public func addNode(componentDescription: AudioComponentDescription) throws -> SRAUNode {
    var node = AUNode()
    var desc = componentDescription
    let res = AUGraphAddNode(self.graph, &desc, &node)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.addNode()")
    }
    
    return SRAUNode(node: node)
  }
  
  public func open() throws {
    let res = AUGraphOpen(self.graph)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.open()")
    }
  }
  
  public func close() throws {
    let res = AUGraphClose(self.graph)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.close()")
    }
  }
  
  public func nodeInfo(node: SRAUNode) throws -> SRAudioUnit {
    var audioUnit: AudioUnit = nil
    let res = AUGraphNodeInfo(self.graph, node.node, nil, &audioUnit)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.nodeInfo()")
    }
    
    return SRAudioUnit(audioUnit: audioUnit)
  }
  
  public func connect(sourceNode sourceNode: SRAUNode, sourceOutputNumber: UInt32, destNode: SRAUNode, destInputNumber: UInt32) throws {
    let res = AUGraphConnectNodeInput(self.graph, sourceNode.node, sourceOutputNumber, destNode.node, destInputNumber)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.connect()")
    }
  }
  
  public func setNodeInputCallback(destNode: SRAUNode, destInputNumber: UInt32, callback: AURenderCallbackStruct) throws {
    var callbackRef = callback
    let res = AUGraphSetNodeInputCallback(self.graph, destNode.node, destInputNumber, &callbackRef)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.setNodeInputCallback()")
    }
  }
  
  public func addRenderNotify(userData procRefCon: UnsafeMutablePointer<Void>, callback: AURenderCallback) throws {
    let res = AUGraphAddRenderNotify(self.graph, callback, procRefCon)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.addRenderNotify()")
    }
  }
  
  public func initialize() throws {
    let res = AUGraphInitialize(self.graph)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.initialize()")
    }
  }
  
  public func uninitialize() throws {
    let res = AUGraphUninitialize(self.graph)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.uninitialize()")
    }
  }
  
  public func update(sync: Bool = true) throws {
    let res: OSStatus
    
    if sync {
      res = AUGraphUpdate(self.graph, nil)
    } else {
      var updateValue = DarwinBoolean(false)
      res = AUGraphUpdate(self.graph, &updateValue)
    }
    
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.update()")
    }
  }
  
  public func start() throws {
    let res = AUGraphStart(self.graph)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.start()")
    }
  }
  
  public func stop() throws {
    let res = AUGraphStop(self.graph)
    guard res == noErr else {
      throw SRAudioError.OSStatusError(status: res, description: "SRAUGraph.stop()")
    }
  }
  
  public func CAShow() {
    SRAudioCAShow(self.graph)
  }
}
