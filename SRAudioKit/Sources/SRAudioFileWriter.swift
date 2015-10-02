//
//  SRAudioFileWriter.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import AudioToolbox
import SRAudioKitPrivates

public enum SRAudioFileFormat {
    case AIFF, WAVE, MP3//, AAC, AC3, MPEG4, MP3
}

func SRAudioFileTypeFromFormat(format: SRAudioFileFormat) -> AudioFileTypeID {
    switch (format) {
    case .AIFF: return kAudioFileAIFFType
    case .WAVE: return kAudioFileWAVEType
        //    case .AAC: return kAudioFileAAC_ADTSType
        //    case .AC3: return kAudioFileAC3Type
        //    case .MPEG4: return kAudioFileMPEG4Type
    case .MP3: return kAudioFileMP3Type
    }
}

func SRAudioFileWriterGetFormat() throws -> AudioStreamBasicDescription {
    var size = UInt32(sizeof(AudioStreamBasicDescription))
    var result = AudioStreamBasicDescription()
    let res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &result)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
    return result
}

func SRAudioFileWriterSetFileFormat(fileRef: ExtAudioFileRef, audioStreamDescription: SRAudioStreamDescription) throws {
    let size = UInt32(sizeof(AudioStreamBasicDescription))
    var inFormat = audioStreamDescription.audioStreamBasicDescription
    let res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &inFormat)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
}

func SRAudioFileWriterOpen(path: String, fileFormat: SRAudioFileFormat, audioStreamDescription: SRAudioStreamDescription) throws -> ExtAudioFileRef {
    let url = NSURL(fileURLWithPath: path) as CFURL
    let fileTypeID = SRAudioFileTypeFromFormat(fileFormat)
    var fileRef = ExtAudioFileRef()

    var outputDesc = audioStreamDescription.audioStreamBasicDescription
    var size = UInt32(sizeof(AudioStreamBasicDescription))
    var res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &outputDesc)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
    
    let debugFormat = SRAudioStreamDescription(description: outputDesc)
    debugPrint("SRAudioFileWriterOpen: Updated Stream Format: \(debugFormat)")
    
    res = ExtAudioFileCreateWithURL(url, fileTypeID, &outputDesc, nil, AudioFileFlags.EraseFile.rawValue, &fileRef)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
    
    var sf = audioStreamDescription.audioStreamBasicDescription
    size = UInt32(sizeof(AudioStreamBasicDescription))
    
    debugPrint("SRAudioFileWriterOpen: Try to update stream format: \(audioStreamDescription)")
    res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &sf)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
    
    return fileRef
}

public class SRAudioFileWriter {
    var fileRef: ExtAudioFileRef?
    
    public init?(audioStreamDescription: SRAudioStreamDescription, fileFormat: SRAudioFileFormat, filePath: String) {
        do {
            debugPrint("SRAudioFileWriter INIT [\(filePath)] [\(fileFormat)] [\(audioStreamDescription)]")
            self.fileRef = try SRAudioFileWriterOpen(filePath, fileFormat: fileFormat, audioStreamDescription: audioStreamDescription)
            try SRAudioFileWriterSetFileFormat(self.fileRef!, audioStreamDescription: audioStreamDescription)
        }
        catch SRAudioError.OSStatusError(let status) {
            print("Failed to open file: \(OSStatusString(status))")
            switch (status) {
            case kExtAudioFileError_InvalidProperty:
                debugPrint("E: Invalid Property")
            case kExtAudioFileError_InvalidPropertySize:
                debugPrint("E: Invalid Property Size")
            case kExtAudioFileError_NonPCMClientFormat:
                debugPrint("E: Non PCM Client Format")
            case kExtAudioFileError_InvalidChannelMap:
                debugPrint("E: Invalid Channel Map")
            case kExtAudioFileError_InvalidOperationOrder:
                debugPrint("E: Invalid Operation Order")
            case kExtAudioFileError_InvalidDataFormat:
                debugPrint("E: Invalid Data Format")
            case kExtAudioFileError_MaxPacketSizeUnknown:
                debugPrint("E: Max Packet Size Unknown")
            case kExtAudioFileError_InvalidSeek:
                debugPrint("E: Invalid Seek")
            case kExtAudioFileError_AsyncWriteTooLarge:
                debugPrint("E: Async Write Too Large")
            case kExtAudioFileError_AsyncWriteBufferOverflow:
                debugPrint("E: Async Write Buffer Overflow")
            case kAudioFormatUnsupportedDataFormatError:
                debugPrint("E: AudioFormat: Unsupported Data Format Error")
            default:
                debugPrint("E: kExtAudioFileError Status \(status)")
            }
            return nil
        }
        catch {
            return nil
        }
    }
    
    public func close() throws {
        let res = ExtAudioFileDispose(self.fileRef!)
        if res != noErr {
            SRAudioError.OSStatusError(status: res)
        }
    }
 
    public func append(bufferList: UnsafePointer<AudioBufferList>, bufferSize: UInt32) throws {
        guard let fileRef = self.fileRef else { return }
        
        let res = ExtAudioFileWriteAsync(fileRef, bufferSize, bufferList)
        if res != noErr {
            SRAudioError.OSStatusError(status: res)
        }
    }
}
