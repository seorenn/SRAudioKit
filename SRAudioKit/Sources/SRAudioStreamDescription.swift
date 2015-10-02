//
//  SRAudioStreamDescription.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 10. 2..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox

public enum SRAudioFormat {
    case PCM, AAC, MP3, NotSupported
}

func SRAudioGetFormatID(format: SRAudioFormat) -> AudioFormatID {
    switch (format) {
    case .PCM:
        return kAudioFormatLinearPCM
    case .AAC:
        return kAudioFormatMPEG4AAC
    case .MP3:
        return kAudioFormatMPEGLayer3
    case .NotSupported:
        return kAudioFormatLinearPCM
    }
}


let SRAudioAllFileFormatFlags = kAudioFileAIFFType | kAudioFileWAVEType

let SRAudioCommonFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked

let SRAudioSIntFormatFlags = SRAudioCommonFormatFlags | kAudioFormatFlagIsSignedInteger

let SRAudioFloatFormatFlags = SRAudioCommonFormatFlags | kAudioFormatFlagsNativeFloatPacked

let SRAudioFrameFormatFlags = SRAudioSIntFormatFlags | SRAudioFloatFormatFlags

public struct SRAudioStreamDescription: CustomDebugStringConvertible {
    public var audioStreamBasicDescription = AudioStreamBasicDescription()
    
    public init() {
        // Default Values
        self.stereo = true
        self.sampleRate = 44100
        self.interleaved = false
        self.format = .PCM
        self.frameType = .SignedInteger16Bit
    }
    
    public init(sampleRate: Float64, stereo: Bool, format: SRAudioFormat, frameType: SRAudioFrameType, interleaved: Bool = false) {
        self.stereo = stereo
        self.sampleRate = sampleRate
        self.format = format
        self.frameType = frameType
        self.interleaved = interleaved
    }
    
    public init(description: AudioStreamBasicDescription) {
        self.audioStreamBasicDescription = description
    }
    
    // MARK: - Helper Properties
    
    public private(set) var interleaved: Bool {
        set {
            if newValue {
                self.audioStreamBasicDescription.mFormatFlags = self.audioStreamBasicDescription.mFormatFlags.unflagged(kAudioFormatFlagIsNonInterleaved)
            } else {
                self.audioStreamBasicDescription.mFormatFlags = self.audioStreamBasicDescription.mFormatFlags.flagged(kAudioFormatFlagIsNonInterleaved)
            }
        }
        get {
            return !self.audioStreamBasicDescription.mFormatFlags.isFlagged(kAudioFormatFlagIsNonInterleaved)
        }
    }
    
    public private(set) var stereo: Bool {
        set {
            self.audioStreamBasicDescription.mChannelsPerFrame = newValue ? 2 : 1
        }
        get {
            return self.audioStreamBasicDescription.mChannelsPerFrame > 1
        }
    }
    
    public private(set) var sampleRate: Float64 {
        set {
            self.audioStreamBasicDescription.mSampleRate = newValue
        }
        get {
            return self.audioStreamBasicDescription.mSampleRate
        }
    }
    
    public private(set) var format: SRAudioFormat {
        set {
            self.audioStreamBasicDescription.mFormatID = SRAudioGetFormatID(format)
        }
        get {
            switch (self.audioStreamBasicDescription.mFormatID) {
            case kAudioFormatLinearPCM:
                return .PCM
            case kAudioFormatMPEG4AAC:
                return .AAC
            case kAudioFormatMPEGLayer3:
                return .MP3
            default:
                return .PCM
            }
        }
    }
    
    public private(set) var frameType: SRAudioFrameType {
        set {
            self.audioStreamBasicDescription.mFormatFlags = self.audioStreamBasicDescription.mFormatFlags.unflagged(SRAudioFrameFormatFlags)
            
            let sampleSize: UInt32
            if newValue == .SignedInteger16Bit {
                sampleSize = UInt32(sizeof(Int16))
                self.audioStreamBasicDescription.mFormatFlags = self.audioStreamBasicDescription.mFormatFlags.flagged(SRAudioSIntFormatFlags)
            }
            else {
                // Float32Bit
                sampleSize = UInt32(sizeof(Float32))
                self.audioStreamBasicDescription.mFormatFlags = self.audioStreamBasicDescription.mFormatFlags.flagged(SRAudioFloatFormatFlags)
            }
            
            self.audioStreamBasicDescription.mFramesPerPacket = 1
            self.audioStreamBasicDescription.mBitsPerChannel = 8 * sampleSize
            self.audioStreamBasicDescription.mBytesPerFrame = sampleSize * self.audioStreamBasicDescription.mChannelsPerFrame;
            self.audioStreamBasicDescription.mBytesPerPacket = self.audioStreamBasicDescription.mFramesPerPacket * self.audioStreamBasicDescription.mBytesPerFrame
        }
        get {
            if self.audioStreamBasicDescription.mFormatFlags.isFlagged(SRAudioFloatFormatFlags) {
                return .Float32Bit
            }
            else if self.audioStreamBasicDescription.mFormatFlags.isFlagged(SRAudioSIntFormatFlags) {
                return .SignedInteger16Bit
            }
            else {
                // I do not know how to decide exactly...
                return .Unknown
            }
        }
    }
    
    // MARK: - CustomDebugStringConvertible
    
    public var debugDescription: String {
        let stereoString = self.stereo ? "STEREO" : "MONO"
        
        let formatString: String
        switch (self.format) {
        case .PCM:
            formatString = "PCM Format"
        case .AAC:
            formatString = "ACC Format"
        case .MP3:
            formatString = "MP3 Format"
        default:
            formatString = "Unknown Format"
        }
        
        let frameString: String
        switch (self.frameType) {
        case .SignedInteger16Bit:
            frameString = "SInt 16Bit"
        case .Float32Bit:
            frameString = "Float 32Bit"
        default:
            frameString = "Unknown Frame Type"
        }
        
        let interleavedString = self.interleaved ? "Interleaved" : "Non-interleaved"
        
        return "<SRAudioStreamDescription: SampleRate=\(self.sampleRate) \(stereoString) (\(frameString)) [\(formatString), \(interleavedString)]"
    }
}
