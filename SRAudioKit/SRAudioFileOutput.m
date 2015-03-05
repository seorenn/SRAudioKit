//
//  SRAudioFileOutput.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 5..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioFileOutput.h"
#import "SRAudioUtilities.h"

@import AudioToolbox;

@interface SRAudioFileOutput () {
    ExtAudioFileRef _fileRef;
    AudioFileTypeID _fileTypeID;
    CFURLRef _fileURLRef;
    AudioStreamBasicDescription _inputStreamDescription;
    AudioStreamBasicDescription _outputStreamDescription;
}

@end

@implementation SRAudioFileOutput

- (id) initWithFileURL:(NSURL *)url
      outputFileFormat:(SRAudioFileOutputFormat)outputFormat
inputStreamDescription:(AudioStreamBasicDescription)inputStreamDescription {
    self = [super init];
    if (self) {
        _fileRef = NULL;
        _fileURLRef = (__bridge CFURLRef)url;
        _fileTypeID = [self typeIDWithFormat:outputFormat];
        _inputStreamDescription = inputStreamDescription;
        _outputStreamDescription = [self descriptionWithFormat:outputFormat];
        
        if ([self commonInitialization] == NO) return nil;
    }
    return self;
}

- (BOOL)appendDataFromBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize {
    if (_fileRef == NULL) return NO;
    
    OSStatus error = ExtAudioFileWriteAsync(_fileRef, bufferSize, bufferList);
    if (error) {
        NSLog(@"Failed to write Audio Buffer List to File (%ld)", (long)error);
        return NO;
    }
    
    return YES;
}

- (BOOL)close {
    if (_fileRef == NULL) return NO;
    
    OSStatus error = ExtAudioFileDispose(_fileRef);
    if (error) {
        NSLog(@"Failed to Dispost File (%ld)", (long)error);
        return NO;
    }
    
    _fileRef = NULL;
    return YES;
}

- (BOOL)commonInitialization {
    UInt32 size = sizeof(_outputStreamDescription);
    OSStatus error = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &_outputStreamDescription);
    if (error) {
        NSLog(@"Failed to get Audio Format Property Format Info (%ld)", (long)error);
        return NO;
    }
    
    error = ExtAudioFileCreateWithURL(_fileURLRef, _fileTypeID, &_outputStreamDescription, NULL, kAudioFileFlags_EraseFile, &_fileRef);
    if (error) {
        NSLog(@"Failed to get create Audio File (%ld)", (long)error);
        return NO;
    }
    
    error = ExtAudioFileSetProperty(_fileRef, kExtAudioFileProperty_ClientDataFormat, sizeof(_inputStreamDescription), &_inputStreamDescription);
    if (error) {
        NSLog(@"Failed to set Audio File Client Data Format Property (%ld)", (long)error);
        return NO;
    }
    
    return YES;
}

- (void)dealloc {
    if (_fileRef) {
        [self close];
    }
}

- (AudioStreamBasicDescription)descriptionWithFormat:(SRAudioFileOutputFormat)format {
    AudioStreamBasicDescription result;
    
    if (format == SRAudioFileOutputFormatAIFF) {
        result.mFormatID = kAudioFormatLinearPCM;
        result.mFormatFlags = kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
        result.mSampleRate = _inputStreamDescription.mSampleRate;
        result.mChannelsPerFrame = _inputStreamDescription.mChannelsPerFrame;
        result.mBitsPerChannel = 32;
        result.mBytesPerPacket = (result.mBitsPerChannel / 8) * result.mChannelsPerFrame;
        result.mFramesPerPacket = 1;
        result.mBytesPerFrame = result.mBytesPerPacket;
    }
    else {
        // WAVE
        result.mFormatID = kAudioFormatLinearPCM;
        result.mFormatFlags = kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat;
        result.mSampleRate = _inputStreamDescription.mSampleRate;
        result.mChannelsPerFrame = _inputStreamDescription.mChannelsPerFrame;
        result.mBitsPerChannel = 8 * sizeof(float);
        result.mBytesPerPacket = sizeof(float) * result.mChannelsPerFrame;
        result.mFramesPerPacket = 1;
        result.mBytesPerFrame = result.mBytesPerPacket;
    }

    return result;
}

- (AudioFileTypeID)typeIDWithFormat:(SRAudioFileOutputFormat)format {
    if (format == SRAudioFileOutputFormatAIFF) {
        return kAudioFileAIFFType;
    }
    else {
        return kAudioFileWAVEType;
    }
}

@end
