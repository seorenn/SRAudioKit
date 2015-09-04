//
//  SRAudioUtilities.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUtilities.h"
#import <AudioToolbox/AudioToolbox.h>

AudioObjectPropertyAddress AOPADefault(AudioObjectPropertySelector inSelector) {
    AudioObjectPropertyAddress address = {
        inSelector,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    return address;
}

AudioStreamBasicDescription SRAudioGetAudioStreamBasicDescription(BOOL stereo, Float64 sampleRate, SRAudioFrameType frameType, BOOL interleaved, BOOL canonical) {
    AudioStreamBasicDescription desc;
    
    UInt32 sampleSize = 0;
    
    desc.mChannelsPerFrame = (stereo) ? 2 : 1;
    desc.mSampleRate = sampleRate;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFramesPerPacket = 1;
    
    desc.mBitsPerChannel = 8 * sampleSize;
    
    if (stereo) {
        if (interleaved) {
            
        } else {
            
        }
    } else {
        if (interleaved) {
            
        } else {
            
        }
    }
    
    if (frameType == SRAudioFrameTypeFloat32Bit) {
#if TARGET_OS_MAC
        sampleSize = sizeof(Float32);
#elif TARGET_OS_IPHONE
        sampleSize = sizeof(float);
#endif
        desc.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
    } else if (frameType == SRAudioFrameTypeSignedInteger16Bit) {
        sampleSize = sizeof(SInt16);
        desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
    } else {
        NSLog(@"Not Implemented Frame Type");
        exit(1);
    }
    
    if (interleaved) {
        desc.mBytesPerPacket = desc.mBytesPerFrame = desc.mChannelsPerFrame * sampleSize;
    } else {
        desc.mBytesPerPacket = desc.mBytesPerFrame = sampleSize;
        desc.mFormatFlags = desc.mFormatFlags | kAudioFormatFlagIsNonInterleaved;
    }
    
    return desc;
}

AudioStreamBasicDescription SRAudioGetCanonicalNoninterleavedStreamFormat(BOOL stereo, Float64 sampleRate) {
    AudioStreamBasicDescription desc;
    
#if TARGET_OS_MAC
    UInt32 sampleSize = sizeof(Float32);
#elif TARGET_OS_IPHONE
    UInt32 sampleSize = sizeof(float);
#endif
    
    desc.mChannelsPerFrame = (stereo) ? 2 : 1;
    desc.mSampleRate = sampleRate;
    desc.mFormatID = kAudioFormatLinearPCM;
    desc.mFramesPerPacket = 1;
    
    desc.mBitsPerChannel = 8 * sampleSize;
    
    // Non-inerleaved format requires buffer size of single channel.
    desc.mBytesPerFrame = sampleSize;
    desc.mBytesPerPacket = sampleSize;
    
    desc.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
    
    return desc;
}

@implementation SRAudioUtilities

@end
