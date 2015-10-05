//
//  SRAudioConstants.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import AudioToolbox

// MARK: - Error Types

public enum SRAudioError: ErrorType {
    case UnknownError
    case GenericError(description: String)
    case OSStatusError(status: OSStatus, description: String)
}

// MARK: - Another Types

public enum SRAudioFrameType: Int {
    case Unknown = 0
    case Float32Bit = 1
    case SignedInteger16Bit = 2
}


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

let SRAudioSIntFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger

let SRAudioFloatFormatFlags = kAudioFormatFlagsNativeFloatPacked

let SRAudioFrameFormatFlags = SRAudioSIntFormatFlags | SRAudioFloatFormatFlags

class SRAudioConstants: NSObject {

}
