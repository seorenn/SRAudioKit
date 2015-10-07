//
//  SRAudioUtils.swift
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

public extension AudioStreamBasicDescription {
    public init(sampleRate: Float64, numberOfChannels:UInt32, format: SRAudioFormat, frameType: SRAudioFrameType, interleaved: Bool = false) {
        self.init()
        
        self.mChannelsPerFrame = numberOfChannels
        self.mSampleRate = sampleRate
        
        self.mFormatID = SRAudioGetFormatID(format)
        
        let sampleSize: UInt32
        if frameType == .SignedInteger16Bit {
            sampleSize = UInt32(sizeof(Int16))
            self.mFormatFlags |= SRAudioSIntFormatFlags
        }
        else {
            // Float32Bit
            sampleSize = UInt32(sizeof(Float32))
            self.mFormatFlags |= SRAudioFloatFormatFlags
        }
        
        if interleaved == false {
            self.mFormatFlags |= kAudioFormatFlagIsNonInterleaved
        }
        
        self.mFramesPerPacket = 1
        self.mBitsPerChannel = 8 * sampleSize
        self.mBytesPerPacket = sampleSize * numberOfChannels
        self.mBytesPerFrame = sampleSize * numberOfChannels
    }
    
    public static func genericUncompressedDescription(sampleRate: Float64, numberOfChannels: UInt32, frameType: SRAudioFrameType, interleaved: Bool) -> AudioStreamBasicDescription {
        //let commonFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked
        let commonFlags = kAudioFormatFlagIsPacked
        let formatFlags: UInt32
        let sampleSize: UInt32
        
        if frameType == .SignedInteger16Bit {
            // SInt16
            formatFlags = commonFlags | kAudioFormatFlagIsSignedInteger
            sampleSize = UInt32(sizeof(Int16))
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
    
    public static func genericInterleavedDescription(sampleRate: Float64, numberOfChannels: UInt32, frameType: SRAudioFrameType) -> AudioStreamBasicDescription {
        let formatFlags: UInt32
        let sampleSize: UInt32
        
        if frameType == .SignedInteger16Bit {
            // SInt16
            formatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
            sampleSize = UInt32(sizeof(Int16))
        } else {
            // Float32
            formatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked
            sampleSize = UInt32(sizeof(Float32))
        }

        return AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: formatFlags,
            mBytesPerPacket: sampleSize * numberOfChannels,
            mFramesPerPacket: 1,
            mBytesPerFrame: sampleSize,
            mChannelsPerFrame: numberOfChannels,
            mBitsPerChannel: sampleSize * 8,
            mReserved: 0)
    }
    
    public static func genericNoninterleavedDescription(sampleRate: Float64, numberOfChannels: UInt32, frameType: SRAudioFrameType) -> AudioStreamBasicDescription {
        let formatFlags: UInt32
        let sampleSize: UInt32
        
        if frameType == .SignedInteger16Bit {
            // SInt16
            formatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
            sampleSize = UInt32(sizeof(Int16))
        } else {
            // Float32
            formatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked
            sampleSize = UInt32(sizeof(Float32))
        }
        
        return AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: formatFlags,
            mBytesPerPacket: sampleSize * numberOfChannels,
            mFramesPerPacket: 1,
            mBytesPerFrame: sampleSize * numberOfChannels,
            mChannelsPerFrame: numberOfChannels,
            mBitsPerChannel: sampleSize * 8,
            mReserved: 0)
    }
    
    public static func fileFormatDescription(format: SRAudioFileFormat) -> AudioStreamBasicDescription {
        switch (format) {
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
        case .MP3:
            // TODO: Not Confirmed
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
        }
    }

    public static func genericAiffFileDescription(sampleRate: Float64, numberOfChannels: UInt32, frameType: SRAudioFrameType) -> AudioStreamBasicDescription {
        let formatFlags: UInt32
        let sampleSize: UInt32
        
        if frameType == .SignedInteger16Bit {
            // SInt16
            formatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
            sampleSize = UInt32(sizeof(Int16))
        } else {
            // Float32
            formatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked
            sampleSize = UInt32(sizeof(Float32))
        }
        
        return AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: formatFlags,
            mBytesPerPacket: sampleSize * numberOfChannels,
            mFramesPerPacket: 1,
            mBytesPerFrame: sampleSize * numberOfChannels,
            mChannelsPerFrame: numberOfChannels,
            mBitsPerChannel: sampleSize * 8,
            mReserved: 0)
    }
}

public extension AudioComponentDescription {
    public static func mainIO() -> AudioComponentDescription {
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

func SRAudioGenErrorDescription(status: OSStatus, description: String?) -> String {
    if let description = description {
        return "Status(\(status)) Description: \(description)"
    } else {
        return "\(status)"
    }
}

public func SRAudioAssert(status: OSStatus, description: String? = nil) throws {
    if (status != noErr) {
        throw SRAudioError.GenericError(description: SRAudioGenErrorDescription(status, description: description))
    }
}

enum SRAUGraphError: String, ErrorType {
    case Unknown = "Unknown Error"
    case NodeNotFound = "Node Not Found"
    case InvalidConnection = "Invalid Connection"
    case OutputNodeError = "Output Node Error"
    case CannotDoInCurrentContext = "Cannot Do In Current Context"
    case InvalidAudioUnit = "Invalid Audio Unit"
}

public func SRAUGraphAssert(status: OSStatus) throws {
    switch (status) {
    case noErr:
        return
    case kAUGraphErr_NodeNotFound:
        throw SRAUGraphError.NodeNotFound
    case kAUGraphErr_InvalidConnection:
        throw SRAUGraphError.InvalidConnection
    case kAUGraphErr_OutputNodeErr:
        throw SRAUGraphError.OutputNodeError
    case kAUGraphErr_CannotDoInCurrentContext:
        throw SRAUGraphError.CannotDoInCurrentContext
    case kAUGraphErr_InvalidAudioUnit:
        throw SRAUGraphError.InvalidAudioUnit
    default:
        throw SRAUGraphError.Unknown
    }
}

// MARK: - MISC

public func SRAudioGetDuration(sampleRate: Float64, framesPerPacket: UInt32) -> Float64 {
    let unit = Float64( 1.0 / Float64(sampleRate) )
    return unit * Float64(framesPerPacket)
}
