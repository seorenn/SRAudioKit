//
//  SRAudioUnit.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUnit.h"

#import "SRAudioUtilities.h"

@import CoreAudio;
@import AudioToolbox;

@interface SRAudioUnit () {
}

@end

@implementation SRAudioUnit

@synthesize audioComponentDescription = _audioComponentDescription;
@synthesize streamFormat = _streamFormat;
@synthesize audioDevice = _audioDevice;
@synthesize audioUnit = _audioUnit;

- (id)initWithType:(OSType)type subType:(OSType)subType {
    self = [super init];
    if (self) {
        _audioUnit = NULL;
        
        _audioComponentDescription.componentType = type;
        _audioComponentDescription.componentSubType = type;
        _audioComponentDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
        _audioComponentDescription.componentFlags = 0;
        _audioComponentDescription.componentFlagsMask = 0;
        
        // Default Stream Format
        
#if TARGET_OS_MAC
        UInt32 sampleSize = sizeof(Float32);
#elif TARGET_OS_IPHONE
        UInt32 sampleSize = sizeof(float);
#endif
        _streamFormat.mChannelsPerFrame = 2;                // Stereo
        _streamFormat.mSampleRate = SRAudioSampleRate44100
        _streamFormat.mFormatID = kAudioFormatLinearPCM;
        _streamFormat.mFramesPerPacket = 1;
        _streamFormat.mBitsPerChannel = 8 * sampleSize;
        
        // Non-inerleaved format requires buffer size of single channel.
        desc.mBytesPerFrame = sampleSize;
        desc.mBytesPerPacket = sampleSize;
        
        desc.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    }
}

- (void)dealloc {
    if (_audioUnit) {
        AudioComponentInstanceDispose(_audioUnit);
    }
}

#pragma mark - Public Properties

- (void)setSampleRate:(Float64)sampleRate {
    _streamFormat.mSampleRate = sampleRate;
}
- (Float64)sampleRate {
    return _streamFormat.mSampleRate;
}

- (void)setChannelsPerFrame:(UInt32)channelsPerFrame {
    _streamFormat.mChannelsPerFrame = channelsPerFrame;
}
- (UInt32)channelsPerFrame {
    return _streamFormat.mChannelsPerFrame;
}

- (void)setBytesPerFrame:(UInt32)bytesPerFrame {
    _streamFormat.mBytesPerFrame = bytesPerFrame;
    _streamFormat.mBytesPerPacket = bytesPerFrame;
    _streamFormat.mBitsPerChannel = 8 * bytesPerFrame;
}
- (UInt32)bytesPerFrame {
    return _streamFormat.mBytesPerFrame;
}

- (void)setInterleaved:(BOOL)interleaved {
    if (interleaved) {
        SRAudioUnsetFlag(_streamFormat.mFormatFlags, kAudioFormatFlagIsNonInterleaved);
    } else {
        SRAudioSetFlag(_streamFormat.mFormatFlags, kAudioFormatFlagIsNonInterleaved);
    }
}

#pragma mark - APIs

- (void)instantiateAudioUnit {
    AudioComponent component = AudioComponentFindNext(NULL, &_audioComponentDescription);
    NSAssert(component, @"Failed to find component");
    
    OSStatus error = AudioComponentInstanceNew(component, &_audioUnit);
    if (error) {
        NSLog(@"Failed to intantiate Audio Component: %ld", (long)error);
    }
}

#pragma mark - Helpful APIs

- (BOOL)setAudioUnitProperty:(AudioUnitPropertyID)propertyID
                       scope:(AudioUnitScope)scope
                     element:(AudioUnitElement)element
                        data:(const void *)data
                    dataSize:(UInt32)dataSize {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiateAudioUnit method.");
    
    OSStatus error = AudioUnitSetProperty(_audioUnit, propertyID, scope, element, data, size);
    if (error) {
        NSLog(@"Failed to set property: %ld", (long)error);
        return NO;
    }
    
    return YES;
}

- (BOOL)getProperty:(AudioUnitPropertyID)propertyID
              scope:(AudioUnitScope)scope
            element:(AudioUnitElement)element
            outData:(void *)outData
         ioDataSize:(UInt32 *)ioDataSize {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiateAudioUnit method.");

    OSStatus error = AudioUnitGetProperty(_audioUnit, propertyID, scope, element, outData, ioDataSize);
    if (error) {
        NSLog(@"Failed to get property: %ld", (long)error);
        return NO;
    }
    
    return YES;
}

@end
