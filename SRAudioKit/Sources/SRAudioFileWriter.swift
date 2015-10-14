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
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriterGetFormat") }
    
    return result
}

func SRAudioFileWriterSetFileFormat(fileRef: ExtAudioFileRef, audioStreamDescription: AudioStreamBasicDescription) throws {
    let size = UInt32(sizeof(AudioStreamBasicDescription))
    var inFormat = audioStreamDescription
    let res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &inFormat)
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriterSetFileFormat") }
}

func SRAudioFileWriterOpen(path: String, fileFormat: SRAudioFileFormat, audioStreamDescription: AudioStreamBasicDescription) throws -> ExtAudioFileRef {
    let url = NSURL(fileURLWithPath: path) as CFURL
    let fileTypeID = SRAudioFileTypeFromFormat(fileFormat)
    var fileRef: ExtAudioFileRef = nil

    var outputDesc = audioStreamDescription

    print("Current Format Description: \(outputDesc)")

    var size = UInt32(sizeof(AudioStreamBasicDescription))
    var res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &outputDesc)
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "AudioFormatGetProperty") }
    
    print("Updated Format Description: \(outputDesc)")
    
    res = ExtAudioFileCreateWithURL(url, fileTypeID, &outputDesc, nil, AudioFileFlags.EraseFile.rawValue, &fileRef)
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "ExtAudioFileCreateWithURL") }
    
    var sf = audioStreamDescription
    size = UInt32(sizeof(AudioStreamBasicDescription))
    
    print("SRAudioFileWriterOpen: Try to update stream format: \(audioStreamDescription)")
    res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &sf)
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "ExtAudioFileSetProperty") }
    
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
        catch let error as SRAudioError {
            print("[SRAudioFileWriter.init] \(error)")
            return nil
        }
        catch {
            return nil
        }
    }
    
    public func close() throws {
        guard let fileRef = self.fileRef
            else { return }
        
        let res = ExtAudioFileDispose(fileRef)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriter.close()") }
    }
 
    public func append(bufferList: UnsafePointer<AudioBufferList>, bufferSize: UInt32) throws {
        guard let fileRef = self.fileRef
            else { return }
        
        let res = ExtAudioFileWriteAsync(fileRef, bufferSize, bufferList)
        guard res == noErr
            else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriter.append()") }
    }
}
