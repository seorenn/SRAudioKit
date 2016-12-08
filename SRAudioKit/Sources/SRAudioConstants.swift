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

public func OSStatusErrorDescription(_ status: OSStatus) -> String {
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
        
    // Audio Unit
    case kAudioUnitErr_InvalidProperty:
        return "Invalid Property"
    case kAudioUnitErr_InvalidParameter:
        return "Invalid Parameter"
    case kAudioUnitErr_InvalidElement:
        return "Invalid Element"
    case kAudioUnitErr_NoConnection:
        return "No Connection"
    case kAudioUnitErr_FailedInitialization:
        return "Failed Initialization"
    case kAudioUnitErr_TooManyFramesToProcess:
        return "Too Many Frames To Process"
    case kAudioUnitErr_IllegalInstrument:
        return "Illegal Instrument"
    case kAudioUnitErr_InstrumentTypeNotFound:
        return "Instrument Type Not Found"
    case kAudioUnitErr_InvalidFile:
        return "Invalid File"
    case kAudioUnitErr_UnknownFileType:
        return "Unknown File Type"
    case kAudioUnitErr_FileNotSpecified:
        return "File Not Specified"
    case kAudioUnitErr_FormatNotSupported:
        return "Format Not Supported"
    case kAudioUnitErr_Uninitialized:
        return "Uninitialized"
    case kAudioUnitErr_InvalidScope:
        return "Invalid Scope"
    case kAudioUnitErr_PropertyNotWritable:
        return "Property Not Writable"
    case kAudioUnitErr_CannotDoInCurrentContext:
        return "Cannot Do In Current Context"
    case kAudioUnitErr_InvalidPropertyValue:
        return "Invalid Property Value"
    case kAudioUnitErr_PropertyNotInUse:
        return "PropertyNotInUse"
    case kAudioUnitErr_Initialized:
        return "Initialized"
    case kAudioUnitErr_InvalidOfflineRender:
        return "Invalid Offline Render"
    case kAudioUnitErr_Unauthorized:
        return "Unauthorized"
        
    // Audio
    case kAudio_ParamError:
        return "kAudio_ParamError"
        
    default:
        return "(Unknown Error Description)"
    }
}

public enum SRAudioError: Error, CustomStringConvertible {
    case unknownError
    case genericError(description: String)
    case osStatusError(status: OSStatus, description: String)
    case incompatibleAudioBuffer
    
    public var description: String {
        switch (self) {
        case .unknownError:
            return "Unknown Error"
        case .genericError(let description):
            return "Generic Error: \(description)"
        case .osStatusError(let status, let description):
            return "OSStatus Error: \(description) \(status)(\(OSStatusString(status))) -> \(OSStatusErrorDescription(status))"
        case .incompatibleAudioBuffer:
            return "Incompatible Audio Buffer"
        }
    }
}

// MARK: - Another Types

public enum SRAudioFrameType: Int {
    case unknown = 0
    case float32Bit = 1
    case signedInteger16Bit = 2
    case signedInteger32Bit = 3
}

public enum SRAudioFileType {
    case aiff, wave, mp3, aac //, AC3, MPEG4, MP3
    
    public var compressedType: Bool {
        switch (self) {
        case .aiff:
            return false
        case .wave:
            return false
        default:
            return true
        }
    }
    
    public var audioFormatID: OSType {
        switch (self) {
        case .aiff:
            return kAudioFormatLinearPCM
        case .wave:
            return kAudioFormatLinearPCM
        case .mp3:
            return kAudioFormatMPEGLayer3
        case .aac:
            return kAudioFormatMPEG4AAC
        }
    }
    
    public var audioFileTypeID: AudioFileTypeID {
        switch (self) {
        case .aiff:
            return kAudioFileAIFFType
        case .wave:
            return kAudioFileWAVEType
        case .mp3:
            return kAudioFileMP3Type
        case .aac:
            return kAudioFileAAC_ADTSType
        }
    }
}

let SRAudioAllFileFormatFlags = kAudioFileAIFFType | kAudioFileWAVEType

let SRAudioSIntFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger

let SRAudioFloatFormatFlags = kAudioFormatFlagsNativeFloatPacked

let SRAudioFrameFormatFlags = SRAudioSIntFormatFlags | SRAudioFloatFormatFlags

class SRAudioConstants: NSObject {

}
