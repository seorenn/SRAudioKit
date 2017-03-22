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

func SRAudioFileWriterOpen(_ path: String, fileType: SRAudioFileType, clientFormat: AudioStreamBasicDescription, fileFormat: AudioStreamBasicDescription) throws -> ExtAudioFileRef {
  let url = URL(fileURLWithPath: path) as CFURL
  let fileTypeID = fileType.audioFileTypeID
  var fileRef: ExtAudioFileRef? = nil
  
  var outputDesc = fileFormat
  
  var size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
  var res = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, nil, &size, &outputDesc)
  guard res == noErr else {
    throw SRAudioError.osStatusError(status: res, description: "AudioFormatGetProperty kAudioFormatProperty_FormatInfo")
  }
  print("SRAudioFileWriterOpen:")
  print("- File Format: \(fileFormat)")
  print("- Generated Output Description: \(outputDesc)")
  
  res = ExtAudioFileCreateWithURL(url, fileTypeID, &outputDesc, nil, AudioFileFlags.eraseFile.rawValue, &fileRef)
  guard res == noErr else {
    throw SRAudioError.osStatusError(status: res, description: "ExtAudioFileCreateWithURL")
  }
  
  var cf = clientFormat
  size = UInt32(MemoryLayout<AudioStreamBasicDescription>.size)
  
  res = ExtAudioFileSetProperty(fileRef!, kExtAudioFileProperty_ClientDataFormat, size, &cf)
  guard res == noErr else {
    throw SRAudioError.osStatusError(status: res, description: "ExtAudioFileSetProperty kExtAudioFileProperty_ClientDataFormat")
  }
  
  return fileRef!
}

open class SRAudioFileWriter {
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
  
  open func close() throws {
    guard let fileRef = self.fileRef else { return }
    
    let res = ExtAudioFileDispose(fileRef)
    guard res == noErr else {
      throw SRAudioError.osStatusError(status: res, description: "SRAudioFileWriter.close()")
    }
  }
  
  open func append(_ bufferList: UnsafePointer<AudioBufferList>, bufferSize: UInt32) throws {
    guard let fileRef = self.fileRef else { return }
    
    let res = ExtAudioFileWriteAsync(fileRef, bufferSize, bufferList)
    guard res == noErr else {
      throw SRAudioError.osStatusError(status: res, description: "SRAudioFileWriter.append()")
    }
  }
}
