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

open class SRAudioBuffer {
    open fileprivate(set) var audioBufferList: UnsafeMutableAudioBufferListPointer

    public init(ASBD: AudioStreamBasicDescription, frameCapacity: UInt32) {
        self.audioBufferList = UnsafeMutableAudioBufferListPointer(SRAudioAllocateBufferList(ASBD, frameCapacity))!
        
        print("[SRAudioBuffer] Buffer Count: \(self.audioBufferList.count)")
        for b in self.audioBufferList {
            print("[SRAudioBuffer] Each Buffer -> \(b.mNumberChannels) channels \(b.mDataByteSize) bytes")
        }
    }

    deinit {
        SRAudioFreeBufferList(self.audioBufferList.unsafeMutablePointer)
    }
    
    // Sideway Wrapper of AudioUnitRender ;-)
    open func render(
        audioUnit: SRAudioUnit,
        ioActionFlags: UnsafeMutablePointer<AudioUnitRenderActionFlags>,
        inTimeStamp: UnsafePointer<AudioTimeStamp>,
        inOutputBusNumber: UInt32,
        inNumberFrames: UInt32) throws {
                            
        let res = AudioUnitRender(audioUnit.audioUnit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, self.audioBufferList.unsafeMutablePointer)
        
        if res != noErr {
            throw SRAudioError.osStatusError(status: res, description: "[SRAudioBuffer.render]")
        }
    }
    
    open func copy(_ source: UnsafeMutableAudioBufferListPointer) {
        SRAudioCopyBufferList(source.unsafeMutablePointer, self.audioBufferList.unsafeMutablePointer)
    }

    open func copy(_ source: UnsafeMutablePointer<AudioBufferList>) {
        SRAudioCopyBufferList(source, self.audioBufferList.unsafeMutablePointer)
    }
}
