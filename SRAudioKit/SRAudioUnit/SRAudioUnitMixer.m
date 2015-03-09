//
//  SRAudioUnitMixer.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUnitMixer.h"

@import CoreAudio;
@import AudioToolbox;

static OSStatus SRAudioUnitMixerRenderInput(void *inRefCon,
                                            AudioUnitRenderActionFlags *ioActionFlags,
                                            const AudioTimeStamp *inTimeStamp,
                                            UInt32 inBusNumber,
                                            UInt32 inNumberFrames,
                                            AudioBufferList *ioData);

@implementation SRAudioUnitMixer
@synthesize numberOfBuses = _numberOfBuses;

- (id)init {
    self = [super initWithType:kAudioUnitType_Mixer subType:kAudioUnitSubType_MultiChannelMixer];
    if (self) {
        
    }
    return self;
}

// override
- (void)instantiate {
    [super instantiate];
    
    // TODO
    
    OSStatus error = AudioUnitInitialize(self.audioUnit);
    NSAssert(error == noErr, @"Failed to initialize AudioUnitMixer");
}

#pragma mark - APIs

- (BOOL)setInputStreamFormat:(AudioStreamBasicDescription)format forBusIndex:(UInt32)busIndex {
    NSAssert(busIndex >= 0 && busIndex < _numberOfBuses, @"Invalid busIndex");
    
    return [self setProperty:kAudioUnitProperty_StreamFormat
                       scope:kAudioUnitScope_Input
                     element:busIndex
                        data:&format
                    dataSize:sizeof(AudioStreamBasicDescription)];
}

#pragma mark - Properties

- (void)setNumberOfBuses:(UInt32)numberOfBuses {
    _numberOfBuses = numberOfBuses;
    
    if (self.audioUnit == NULL) return;
    
    if ([self setProperty:kAudioUnitProperty_ElementCount scope:kAudioUnitScope_Input element:0 data:&numberOfBuses dataSize:sizeof(UInt32)] == NO) {
        _numberOfBuses = 0;
    }
}

#pragma mark - Private APIs

- (BOOL)updateOutputStreamFormat {
    AudioStreamBasicDescription format = self.streamFormat;
    if ([self setProperty:kAudioUnitProperty_StreamFormat
                    scope:kAudioUnitScope_Output
                  element:0
                     data:&format
                 dataSize:sizeof(AudioStreamBasicDescription)] == NO) {
        return NO;
    }
    
    UInt32 size = sizeof(AudioStreamBasicDescription);
    if ([self getProperty:kAudioUnitProperty_StreamFormat scope:kAudioUnitScope_Output element:0 outData:&format ioDataSize:&size] == NO) {
        return NO;
    }
    
    self.streamFormat = format;
    return YES;
}

- (BOOL)prepareCallback {
    // TODO
    return NO;
}

@end

#pragma mark - Callback

static OSStatus SRAudioUnitMixerRenderInput(void *inRefCon,
                                            AudioUnitRenderActionFlags *ioActionFlags,
                                            const AudioTimeStamp *inTimeStamp,
                                            UInt32 inBusNumber,
                                            UInt32 inNumberFrames,
                                            AudioBufferList *ioData) {
    SRAudioUnitMixer *mixer = (__bridge SRAudioUnitMixer *)inRefCon;
    
    // TODO
    return noErr;
}

