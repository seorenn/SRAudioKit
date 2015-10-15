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

//func SRAudioFileTypeFromFormat(format: SRAudioFileType) -> AudioFileTypeID {
//    switch (format) {
//    case .AIFF: return kAudioFileAIFFType
//    case .WAVE: return kAudioFileWAVEType
//        //    case .AAC: return kAudioFileAAC_ADTSType
//        //    case .AC3: return kAudioFileAC3Type
//        //    case .MPEG4: return kAudioFileMPEG4Type
//    case .MP3: return kAudioFileMP3Type
//    }
//}

//func SRAudioFileWriterGetFormat() throws -> AudioStreamBasicDescription {
//    var size = UInt32(sizeof(AudioStreamBasicDescription))
//    var result = AudioStreamBasicDescription()
//    let res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &result)
//    guard res == noErr
//        else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriterGetFormat") }
//    
//    return result
//}

//func SRAudioFileWriterSetFileFormat(fileRef: ExtAudioFileRef, audioStreamDescription: AudioStreamBasicDescription) throws {
//    let size = UInt32(sizeof(AudioStreamBasicDescription))
//    var inFormat = audioStreamDescription
//    let res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &inFormat)
//    guard res == noErr
//        else { throw SRAudioError.OSStatusError(status: res, description: "SRAudioFileWriterSetFileFormat") }
//}

func SRAudioFileWriterOpen(path: String, fileType: SRAudioFileType, clientFormat: AudioStreamBasicDescription, fileFormat: AudioStreamBasicDescription) throws -> ExtAudioFileRef {
    let url = NSURL(fileURLWithPath: path) as CFURL
    let fileTypeID = fileType.audioFileTypeID
    var fileRef: ExtAudioFileRef = nil

    var outputDesc = fileFormat

    var size = UInt32(sizeof(AudioStreamBasicDescription))
    var res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &outputDesc)
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "AudioFormatGetProperty kAudioFormatProperty_FormatInfo") }
    
    res = ExtAudioFileCreateWithURL(url, fileTypeID, &outputDesc, nil, AudioFileFlags.EraseFile.rawValue, &fileRef)
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "ExtAudioFileCreateWithURL") }
    
    var cf = clientFormat
    size = UInt32(sizeof(AudioStreamBasicDescription))
    
    res = ExtAudioFileSetProperty(fileRef, kExtAudioFileProperty_ClientDataFormat, size, &cf)
    guard res == noErr
        else { throw SRAudioError.OSStatusError(status: res, description: "ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat") }
    
    return fileRef
}

public class SRAudioFileWriter {
    var fileRef: ExtAudioFileRef?
    
    public init?(clientFormat: AudioStreamBasicDescription, fileFormat: AudioStreamBasicDescription, fileType: SRAudioFileType, filePath: String) {
        do {
            print("SRAudioFileWriter INIT filePath[\(filePath)] clientFormat[\(clientFormat)] fileFormat[\(fileFormat)] fileType[\(fileType)]")
            self.fileRef = try SRAudioFileWriterOpen(filePath, fileType: fileType, clientFormat: clientFormat, fileFormat: fileFormat)
//            try SRAudioFileWriterSetFileFormat(self.fileRef!, audioStreamDescription: audioStreamDescription)
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
