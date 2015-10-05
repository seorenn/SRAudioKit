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
        throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriterGetFormat")
    }
    return result
}

func SRAudioFileWriterSetFileFormat(fileRef: ExtAudioFileRef, audioStreamDescription: AudioStreamBasicDescription) throws {
    let size = UInt32(sizeof(AudioStreamBasicDescription))
    var inFormat = audioStreamDescription
    let res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &inFormat)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriterSetFileFormat")
    }
}

func SRAudioFileWriterOpen(path: String, fileFormat: SRAudioFileFormat, audioStreamDescription: AudioStreamBasicDescription) throws -> ExtAudioFileRef {
    let url = NSURL(fileURLWithPath: path) as CFURL
    let fileTypeID = SRAudioFileTypeFromFormat(fileFormat)
    var fileRef: ExtAudioFileRef = nil

    var outputDesc = audioStreamDescription

    print("Current Format Description: \(outputDesc)")

    var size = UInt32(sizeof(AudioStreamBasicDescription))
    var res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &outputDesc)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res, description: "AudioFormatGetProperty")
    }
    
    print("Updated Format Description: \(outputDesc)")
    
    res = ExtAudioFileCreateWithURL(url, fileTypeID, &outputDesc, nil, AudioFileFlags.EraseFile.rawValue, &fileRef)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res, description: "ExtAudioFileCreateWithURL")
    }
//    fileRef = SRAudioFileCreate(path, fileTypeID, &outputDesc, true)
//    if fileRef == nil {
//        throw SRAudioError.OSStatusError(status: 0, description: "OOPS!")
//    }
    
    var sf = audioStreamDescription
    size = UInt32(sizeof(AudioStreamBasicDescription))
    
    print("SRAudioFileWriterOpen: Try to update stream format: \(audioStreamDescription)")
    res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &sf)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res, description: "ExtAudioFileSetProperty")
    }
    
    return fileRef
}

public class SRAudioFileWriter {
    var fileRef: ExtAudioFileRef?
    
    public init?(audioStreamDescription: AudioStreamBasicDescription, fileFormat: SRAudioFileFormat, filePath: String) {
        do {
            print("SRAudioFileWriter INIT [\(filePath)] [\(fileFormat)] [\(audioStreamDescription)]")
            self.fileRef = try SRAudioFileWriterOpen(filePath, fileFormat: fileFormat, audioStreamDescription: audioStreamDescription)
            try SRAudioFileWriterSetFileFormat(self.fileRef!, audioStreamDescription: audioStreamDescription)
        }
        catch SRAudioError.OSStatusError(let status, let description) {
            print("[\(description)] Failed to open file: \(OSStatusString(status))")
            switch (status) {
            case kExtAudioFileError_InvalidProperty:
                print("E: Invalid Property")
            case kExtAudioFileError_InvalidPropertySize:
                print("E: Invalid Property Size")
            case kExtAudioFileError_NonPCMClientFormat:
                print("E: Non PCM Client Format")
            case kExtAudioFileError_InvalidChannelMap:
                print("E: Invalid Channel Map")
            case kExtAudioFileError_InvalidOperationOrder:
                print("E: Invalid Operation Order")
            case kExtAudioFileError_InvalidDataFormat:
                print("E: Invalid Data Format")
            case kExtAudioFileError_MaxPacketSizeUnknown:
                print("E: Max Packet Size Unknown")
            case kExtAudioFileError_InvalidSeek:
                print("E: Invalid Seek")
            case kExtAudioFileError_AsyncWriteTooLarge:
                print("E: Async Write Too Large")
            case kExtAudioFileError_AsyncWriteBufferOverflow:
                print("E: Async Write Buffer Overflow")
            case kAudioFormatUnsupportedDataFormatError:
                print("E: AudioFormat: Unsupported Data Format Error")
            default:
                print("E: kExtAudioFileError Status \(status)")
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
            SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriter.close()")
        }
    }
 
    public func append(bufferList: UnsafePointer<AudioBufferList>, bufferSize: UInt32) throws {
        guard let fileRef = self.fileRef else { return }
        
        let res = ExtAudioFileWriteAsync(fileRef, bufferSize, bufferList)
        if res != noErr {
            SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriter.append()")
        }
    }
}
