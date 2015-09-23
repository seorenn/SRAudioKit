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

public class SRAudioManager {
    public static let sharedManager = SRAudioManager()
    
    private let graph = SRAUGraph()
    
    public var streamConfiguration: AudioStreamBasicDescription = SRAudioGetAudioStreamBasicDescription(true, 44100, .SignedInteger16Bit, false, true)
    
    public init() {
        
    }
    
    public func connect(input: SRAudioInput, output: SRAudioOutput) {
        
    }
    
    public func start() {
        
    }
    
    public func stop() {
        
    }
}
