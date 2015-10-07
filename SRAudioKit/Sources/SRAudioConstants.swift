//
//  SRAudioConstants.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import AudioToolbox
import SRAudioKitPrivates

// MARK: - Error Types

public func OSStatusErrorDescription(status: OSStatus) -> String {
    switch (status) {
    // ExtAudioFile
    case kExtAudioFileError_InvalidProperty:
        return "Invalid Property"
    case kExtAudioFileError_InvalidPropertySize:
        return "Invalid Property Size"
    case kExtAudioFileError_NonPCMClientFormat:
        return "Non PCM Client Format"
    case kExtAudioFileError_InvalidChannelMap:
        return "Invalid Channel Map"
    case kExtAudioFileError_InvalidOperationOrder:
        return "Invalid Operation Order"
    case kExtAudioFileError_InvalidDataFormat:
        return "Invalid Data Format"
    case kExtAudioFileError_MaxPacketSizeUnknown:
        return "Max Packet Size Unknown"
    case kExtAudioFileError_InvalidSeek:
        return "Invalid Seek"
    case kExtAudioFileError_AsyncWriteTooLarge:
        return "Async Write Too Large"
    case kExtAudioFileError_AsyncWriteBufferOverflow:
        return "Async Write Buffer Overflow"
        
    // Audio Format
    case kAudioFormatUnsupportedDataFormatError:
        return "Unsupported Data Format Error"
        
    // AUGraph
    case kAUGraphErr_NodeNotFound:
        return "Node Not Found"
    case kAUGraphErr_InvalidConnection:
        return "Invalid Connection"
    case kAUGraphErr_OutputNodeErr:
        return "Output Node Error"
    case kAUGraphErr_CannotDoInCurrentContext:
        return "Cannot Do In Current Context"
    case kAUGraphErr_InvalidAudioUnit:
        return "Invalid Audio Unit"
        
    default:
        return "(Unknown Error Description)"
    }
}

public enum SRAudioError: ErrorType, CustomStringConvertible {
    case UnknownError
    case GenericError(description: String)
    case OSStatusError(status: OSStatus, description: String)
    
    public var description: String {
        switch (self) {
        case .UnknownError:
            return "Unknown Error"
        case .GenericError(let description):
            return "Generic Error: \(description)"
        case .OSStatusError(let status, let description):
            return "OSStatus Error: \(description) \(status)(\(OSStatusString(status))) -> \(OSStatusErrorDescription(status))"
        }
    }
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
