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

func SRAudioFileWriterGetFormat() throws -> AudioStreamBasicDescription {
    var size = UInt32(sizeof(AudioStreamBasicDescription))
    var result = AudioStreamBasicDescription()
    let res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &result)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
    return result
}

func SRAudioFileWriterSetFileFormat(fileRef: ExtAudioFileRef, format: AudioStreamBasicDescription) throws {
    let size = UInt32(sizeof(AudioStreamBasicDescription))
    var inFormat = format
    let res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &inFormat)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
}

func SRAudioFileWriterOpen(path: String, fileFormat: SRAudioFileWriterFormat) throws -> ExtAudioFileRef {
    let url = CFURLFromString(path)!
    let fileTypeID = SRAudioFileWriterTypeFromFormat(fileFormat)
    var fileRef = ExtAudioFileRef()

    var outputDescription: AudioStreamBasicDescription
    do {
        outputDescription = try SRAudioFileWriterGetFormat()
    }
    catch SRAudioError.OSStatusError(let status) {
        throw SRAudioError.OSStatusError(status: status)
    }
    catch {
        throw SRAudioError.UnknownError
    }
    
    let res = ExtAudioFileCreateWithURL(url.takeUnretainedValue(), fileTypeID, &outputDescription, nil, AudioFileFlags.EraseFile.rawValue, &fileRef)
    if res != noErr {
        throw SRAudioError.OSStatusError(status: res)
    }
    
    return fileRef
}

public enum SRAudioFileWriterFormat {
    case AIFF, WAVE
}

func SRAudioFileWriterTypeFromFormat(format: SRAudioFileWriterFormat) -> AudioFileTypeID {
    switch (format) {
    case .AIFF: return kAudioFileAIFFType
    case .WAVE: return kAudioFileWAVEType
    }
}

public class SRAudioFileWriter {
    let fileRef: ExtAudioFileRef
    
    public init(streamFormat: AudioStreamBasicDescription, fileFormat: SRAudioFileWriterFormat, path: String) {
        self.fileRef = try! SRAudioFileWriterOpen(path, fileFormat: fileFormat)
        try! SRAudioFileWriterSetFileFormat(self.fileRef, format: streamFormat)
    }
    
    public func close() throws {
        let res = ExtAudioFileDispose(self.fileRef)
        if res != noErr {
            SRAudioError.OSStatusError(status: res)
        }
    }
 
    public func append(bufferList: UnsafePointer<AudioBufferList>, bufferSize: UInt32) throws {
        let res = ExtAudioFileWriteAsync(self.fileRef, bufferSize, bufferList)
        if res != noErr {
            SRAudioError.OSStatusError(status: res)
        }
    }
}
