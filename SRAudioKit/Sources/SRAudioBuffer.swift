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

//    public convenience init(channelsPerFrame: UInt32, frameType: SRAudioFrameType, interleaved: Bool, capacity: UInt32) {
//        let bytesPerFrame: UInt32
//        
//        if frameType == .SignedInteger16Bit {
//            bytesPerFrame = UInt32(sizeof(Int16))
//        } else if frameType == .SignedInteger32Bit {
//            bytesPerFrame = UInt32(sizeof(Int32))
//        } else {
//            // Float32Bit
//            bytesPerFrame = UInt32(sizeof(Float32))
//        }
//
//        self.init(channelsPerFrame: channelsPerFrame, bytesPerFrame: bytesPerFrame, interleaved: interleaved, capacity: capacity)
//    }
    
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
                            
        print("-> SRAudioBuffer.render")
        print(" - Buffer: \(self.audioBufferList)")
        print(" - AudioUnit: \(audioUnit)")
        print(" - ioActionFlags: \(ioActionFlags.memory)")
        print(" - inTimeStamp: \(inTimeStamp.memory)")
        print(" - inOutputBusNumber: \(inOutputBusNumber)")
        print(" - inNumberFrames: \(inNumberFrames)")
            
        
                            
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
