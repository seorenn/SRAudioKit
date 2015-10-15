//
//  SRAudioUtilities.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudioKit
import AudioToolbox

// BASIC THEORY

/* 
# Interleaved: 
Audio data that contains all channel informations in single stream.
Stereo channels comes with left then right then left right L R L R ...

eg., A audio buffer contains all channel datas. If interleaved stereo, data will be L R L R L R ...

# Noninterleaved:
Each individual buffer consists of one channel of data
*/

// MARK: - AudioStreamBasicDescription Generators

public extension AudioStreamBasicDescription {
    public static func genericUncompressedDescription(sampleRate: Float64, numberOfChannels: UInt32, frameType: SRAudioFrameType, interleaved: Bool) -> AudioStreamBasicDescription {
        //let commonFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked
        let commonFlags = kAudioFormatFlagIsPacked
        let formatFlags: UInt32
        let sampleSize: UInt32
        
        if frameType == .SignedInteger16Bit {
            // SInt16
            formatFlags = commonFlags | kAudioFormatFlagIsSignedInteger
            sampleSize = UInt32(sizeof(Int16))
        } else if frameType == .SignedInteger32Bit {
            // SInt32
            formatFlags = commonFlags | kAudioFormatFlagIsSignedInteger
            sampleSize = UInt32(sizeof(Int32))
        } else {
            // Float32
            formatFlags = commonFlags | kAudioFormatFlagIsFloat
            sampleSize = UInt32(sizeof(Float32))
        }

        let bytesPerFrame: UInt32

        if interleaved {
            bytesPerFrame = numberOfChannels * sampleSize
        } else {
            bytesPerFrame = sampleSize
        }
        
        return AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: formatFlags,
            mBytesPerPacket: bytesPerFrame, // needs confirm
            mFramesPerPacket: 1, // Feature of Uncompressed
            mBytesPerFrame: bytesPerFrame,
            mChannelsPerFrame: numberOfChannels,
            mBitsPerChannel: 8 * sampleSize,    // Canonical (But canonical was deprecated)
            mReserved: 0)
    }

    public static func genericCompressedDescription(formatID: OSType, numberOfChannels: UInt32) throws -> AudioStreamBasicDescription {
        var asbd = AudioStreamBasicDescription()
        asbd.mFormatID = formatID
        asbd.mChannelsPerFrame = numberOfChannels
        
        var size = UInt32(sizeof(AudioStreamBasicDescription))
        
        let res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &asbd)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "AudioStreamBasicDescription.genericCompressedDescription formatID \(formatID) numberOfChannels \(numberOfChannels)") }
        
        return asbd
    }

    public static func fileTypeDescription(type: SRAudioFileType) -> AudioStreamBasicDescription {
        switch (type) {
        case .AIFF:
            return AudioStreamBasicDescription(
                mSampleRate: 44100,
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger,
                mBytesPerPacket: 8,
                mFramesPerPacket: 1,
                mBytesPerFrame: 8,
                mChannelsPerFrame: 2,
                mBitsPerChannel: 32,
                mReserved: 0)
        case .WAVE:
            return AudioStreamBasicDescription(
                mSampleRate: 44100,
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat,
                mBytesPerPacket: 8,
                mFramesPerPacket: 1,
                mBytesPerFrame: 8,
                mChannelsPerFrame: 2,
                mBitsPerChannel: 32,
                mReserved: 0)
        default:
            return try! AudioStreamBasicDescription.genericCompressedDescription(type.audioFormatID, numberOfChannels: 2)
        }
    }
}

// MARK: - AudioComponentDescription Generators

public extension AudioComponentDescription {
    public static func HAL() -> AudioComponentDescription {
        #if os(OSX)
            return AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_HALOutput,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0)
        #else
            return AudioComponentDescription(
                componentType: kAudioUnitType_Output,
                componentSubType: kAudioUnitSubType_RemoteIO,
                componentManufacturer: kAudioUnitManufacturer_Apple,
                componentFlags: 0,
                componentFlagsMask: 0)
        #endif
    }
    
    public static func multichannelMixer() -> AudioComponentDescription {
        return AudioComponentDescription(
            componentType: kAudioUnitType_Mixer,
            componentSubType: kAudioUnitSubType_MultiChannelMixer,
            componentManufacturer: kAudioUnitManufacturer_Apple,
            componentFlags: 0,
            componentFlagsMask: 0)
    }
}

// MARK: - MISC

// TODO: NOT USED IN CURRENTLY. REMOVE OR USE THIS! :-)
public extension UInt32 {
    public func flagged(flag: UInt32) -> UInt32 {
        return self | flag
    }
    
    public func unflagged(flag: UInt32) -> UInt32 {
        return self & ~flag
    }
    
    public func isFlagged(flag: UInt32) -> Bool {
        return (self & flag) == flag
    }
}

public func SRAudioGetDuration(sampleRate: Float64, framesPerPacket: UInt32) -> Float64 {
    let unit = Float64( 1.0 / Float64(sampleRate) )
    return unit * Float64(framesPerPacket)
}
