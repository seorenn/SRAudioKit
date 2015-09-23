//
//  SRAudioKitUtils.m
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 21..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import "SRAudioKitUtils.h"

#define SRAudioUInt32BitCount   (sizeof(UInt32) * 8)

BOOL CheckOSStatus(OSStatus status, NSString *description) {
    if (status) {
        NSLog(@"Failed: %@", description);
        return NO;
    }
    return YES;
}

UInt32 SRAudioUnsetBitUInt32(UInt32 field, UInt32 value) {
    return field & ~value;
}

AudioObjectPropertyAddress SRAudioGetAOPADefault(AudioObjectPropertySelector inSelector) {
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
#if TARGET_OS_IPHONE
        sampleSize = sizeof(float);
#else
        sampleSize = sizeof(Float32);
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

BOOL SRAudioIsNonInterleaved(AudioStreamBasicDescription stream) {
    return (stream.mFormatFlags & kAudioFormatFlagIsNonInterleaved) == kAudioFormatFlagIsNonInterleaved;
}


AudioStreamBasicDescription SRAudioGetCanonicalNoninterleavedStreamFormat(BOOL stereo, Float64 sampleRate) {
    AudioStreamBasicDescription desc;
    
#if TARGET_OS_IPHONE
    UInt32 sampleSize = sizeof(float);
#else
    UInt32 sampleSize = sizeof(Float32);
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

#if TARGET_OS_IPHONE

#pragma mark - Utilities for iOS

#else   // if TARGET_OS_IPHONE

#pragma mark - OS X APIs for Audio Device

NSString * _Nullable SRAudioGetDeviceName(AudioDeviceID deviceID) {
    AudioObjectPropertyAddress address = SRAudioGetAOPADefault(kAudioObjectPropertyName);
    UInt32 ioSize = sizeof(CFStringRef);
    CFStringRef stringRef = NULL;
    OSStatus err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, &stringRef);
    if (err != noErr || stringRef == NULL) {
        return nil;
    }
    
    NSString *result = (__bridge NSString *)stringRef;
    CFRelease(stringRef);
    
    return result;
}

NSString * _Nullable SRAudioGetDeviceUID(AudioDeviceID deviceID) {
    AudioObjectPropertyAddress address = SRAudioGetAOPADefault(kAudioDevicePropertyDeviceUID);
    
    CFStringRef stringRef = NULL;
    UInt32 size = sizeof(CFStringRef);
    
    OSStatus err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &size, &stringRef);
    if (err != noErr || stringRef == NULL) {
        return nil;
    }
    
    NSString *uid = (__bridge NSString *)stringRef;
    CFRelease(stringRef);
    
    return uid;
}

UInt32 SRAudioGetNumberOfDeviceInputChannels(AudioDeviceID deviceID) {
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyStreamConfiguration,
        kAudioObjectPropertyScopeInput,
        0
    };
    
    UInt32 ioSize = 0;
    UInt32 result = 0;
    
    OSStatus err = AudioObjectGetPropertyDataSize(deviceID, &address, 0, NULL, &ioSize);
    if (err != noErr || ioSize == 0) {
        // Error or no result
        return 0;
    }
    
    AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
    if (bufferList == NULL) {
        // Insufficient Memory
        return 0;
    }
    
    err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, bufferList);
    if (err != noErr) {
        // Insufficient Memory
        free(bufferList);
        return 0;
    }
    
    for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
        result += bufferList->mBuffers[i].mNumberChannels;
    }
    
    free(bufferList);
    
    return result;
}

UInt32 SRAudioGetNumberOfDeviceOutputChannels(AudioDeviceID deviceID) {
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyStreamConfiguration,
        kAudioObjectPropertyScopeOutput,
        0
    };
    
    UInt32 ioSize = 0;
    UInt32 result = 0;
    
    OSStatus err = AudioObjectGetPropertyDataSize(deviceID, &address, 0, NULL, &ioSize);
    if (err != noErr || ioSize == 0) {
        // Error or no result
        return 0;
    }
    
    AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
    if (bufferList == NULL) {
        // Insufficient Memory
        return 0;
    }
    
    err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, bufferList);
    if (err != noErr) {
        // Insufficient Memory
        free(bufferList);
        return 0;
    }
    
    for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
        result += bufferList->mBuffers[i].mNumberChannels;
    }
    
    free(bufferList);
    
    return result;
}

/**
 NOTE: You must free() the devices pointer.
 */
OSStatus SRAudioGetRawDevices(Ptr * _Nonnull devices, UInt16 * _Nonnull devicesAvailable) {
    OSStatus err = noErr;
    UInt32 dataSize = 0;
    
    AudioObjectPropertyAddress address = SRAudioGetAOPADefault(kAudioHardwarePropertyDevices);
    
    err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &address, 0, NULL, &dataSize);
    if (err != noErr) return err;
    
    *devicesAvailable = dataSize / (UInt32)sizeof(AudioObjectID);
    if (*devicesAvailable < 1) {
        // No Devices
        return err;
    }
    
    if (*devices != NULL) free(*devices);
    *devices = (Ptr)malloc(dataSize);
    memset(*devices, 0, dataSize);
    
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &dataSize, (void *)*devices);
    if (err != noErr) {
        free(*devices);
    }
    
    return err;
}

/**
 RETURNS [UInt32]
 */
NSArray<NSNumber *> * _Nullable SRAudioGetDevices() {
    AudioObjectID *devices = NULL;
    UInt16 devicesAvailable = 0;
    
    if (SRAudioGetRawDevices((Ptr *)&devices, &devicesAvailable) != noErr) {
        return nil;
    }
    
    NSMutableArray<NSNumber *> *deviceArray = [[NSMutableArray alloc] init];
    for (int i=0; i < devicesAvailable; i++) {
        AudioDeviceID deviceID = devices[i];
        [deviceArray addObject:[NSNumber numberWithUnsignedInteger:deviceID]];
    }
    
    free(devices);
    
    return [deviceArray copy];
}

#endif

@implementation SRAudioKitUtils

@end
