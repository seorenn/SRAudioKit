//
//  SRAudioBuffer.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 10. 7..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import CoreAudio
import AudioToolbox
import SRAudioKitPrivates

public class SRAudioBuffer {
    public private(set) var audioBufferList: UnsafeMutableAudioBufferListPointer

    public init(ASBD: AudioStreamBasicDescription, frameCapacity: UInt32) {
        self.audioBufferList = UnsafeMutableAudioBufferListPointer(SRAudioAllocateBufferList(ASBD, frameCapacity))
        
        print("[SRAudioBuffer] Buffer Count: \(self.audioBufferList.count)")
        for b in self.audioBufferList {
            print("[SRAudioBuffer] Each Buffer -> \(b.mNumberChannels) channels \(b.mDataByteSize) bytes")
        }
    }

    deinit {
        SRAudioFreeBufferList(self.audioBufferList.unsafeMutablePointer)
    }
    
    // Sideway Wrapper of AudioUnitRender ;-)
    public func render(
        audioUnit audioUnit: SRAudioUnit,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inOutputBusNumber: UInt32,
        inNumberFrames: UInt32) throws {
                            
        let res = AudioUnitRender(audioUnit.audioUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, self.audioBufferList.unsafeMutablePointer)
        
        if res != noErr {
            throw SRAudioError.OSStatusError(status: res, description: "[SRAudioBuffer.render]")
        }
    }
    
    public func copy(source: UnsafeMutableAudioBufferListPointer) {
        SRAudioCopyBufferList(source.unsafeMutablePointer, self.audioBufferList.unsafeMutablePointer)
    }

    public func copy(source: UnsafeMutablePointer<AudioBufferList>) {
        SRAudioCopyBufferList(source, self.audioBufferList.unsafeMutablePointer)
    }
}
