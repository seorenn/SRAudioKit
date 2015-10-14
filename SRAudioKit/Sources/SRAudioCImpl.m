//
//  SRAudioKitUtils.m
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 21..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import "SRAudioCImpl.h"

#define SRAudioUInt32BitCount   (sizeof(UInt32) * 8)

NSString * _Nonnull OSStatusString(OSStatus status) {
    char str[10] = { 0, };
    
    *(UInt32 *)(str + 1) = CFSwapInt32HostToBig(status);
    if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
        str[0] = str[5] = '\'';
        str[6] = '\0';
    } else {
        // no, format it as an integer
        sprintf(str, "%d", (int)status);
    }
    
    return [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
}

/*
AudioBufferList * _Nonnull SRAudioAllocateBufferList(UInt32 channelsPerFrame,
                                                     UInt32 bytesPerFrame,
                                                     BOOL interleaved,
                                                     UInt32 capacityFrames) {
    AudioBufferList *bufferList = NULL;
    
    UInt32 numBuffers = interleaved ? 1 : channelsPerFrame;
    UInt32 channelsPerBuffer = interleaved ? channelsPerFrame : 1;
    
    bufferList = (AudioBufferList *)(calloc(1, offsetof(AudioBufferList, mBuffers) + (sizeof(AudioBuffer) * numBuffers)));
    
    bufferList->mNumberBuffers = numBuffers;
    
    for(UInt32 bufferIndex = 0; bufferIndex < bufferList->mNumberBuffers; ++bufferIndex) {
        bufferList->mBuffers[bufferIndex].mData = (void *)(calloc(capacityFrames, bytesPerFrame));
        bufferList->mBuffers[bufferIndex].mDataByteSize = capacityFrames * bytesPerFrame;
        bufferList->mBuffers[bufferIndex].mNumberChannels = channelsPerBuffer;
    }
    
    return bufferList;
}
 */

AudioBufferList * _Nullable SRAudioAllocateBufferList(AudioStreamBasicDescription asbd, UInt32 capacityFrames) {
    AudioBufferList *bufferList = NULL;

    BOOL interleaved = asbd.mFormatFlags & kAudioFormatFlagIsNonInterleaved ? NO : YES;
    
    int numBuffers = interleaved ? 1 : asbd.mChannelsPerFrame;
    int channels = interleaved ? asbd.mChannelsPerFrame : 1;
    int bufferSize = asbd.mBytesPerFrame * capacityFrames;

    bufferList = malloc(sizeof(AudioBufferList) + ((numBuffers - 1) * sizeof(AudioBuffer)));
    if (bufferList == NULL) return NULL;
    
    bufferList->mNumberBuffers = numBuffers;
    for (int i=0; i < numBuffers; i++) {
        bufferList->mBuffers[i].mDataByteSize = bufferSize;
        bufferList->mBuffers[i].mNumberChannels = channels;
        
        if (bufferSize > 0) {
            bufferList->mBuffers[i].mData = calloc(bufferSize, 1);
            if (bufferList->mBuffers[i].mData == NULL) {
                SRAudioFreeBufferList(bufferList);
                return NULL;
            }
        } else {
            bufferList->mBuffers[i].mData = NULL;
        }
    }
    
    return bufferList;
}

void SRAudioCopyBufferList(AudioBufferList * _Nonnull src, AudioBufferList * _Nonnull dest) {
    for (int i=0; i < src->mNumberBuffers; ++i) {
        memcpy(src->mBuffers[i].mData, dest->mBuffers[i].mData, src->mBuffers[i].mDataByteSize);
    }
}

void SRAudioFreeBufferList(AudioBufferList * _Nonnull bufferList) {
    if (bufferList == NULL) return;
    
    for (UInt32 i=0; i < bufferList->mNumberBuffers; ++i) {
        free(bufferList->mBuffers[i].mData);
    }
    
    free(bufferList);
}

#if TARGET_OS_IPHONE

#pragma mark - Utilities for iOS

OSStatus SRAudioFileSetCodecManufacturer(ExtAudioFileRef _Nonnull audioFileRef, UInt32 codec) {
    UInt32 size = sizeof(codec);
    OSStatus res = ExtAudioFileSetProperty(audioFileRef,
                                           kExtAudioFileProperty_CodecManufacturer,
                                           size,
                                           &codec);
    return res;
}

OSStatus SRAudioFileSetAppleCodecManufacturer(ExtAudioFileRef _Nonnull audioFileRef, BOOL useHardwareCodec) {
    UInt32 codec = kAppleSoftwareAudioCodecManufacturer;
    if (useHardwareCodec) codec = kAppleHardwareAudioCodecManufacturer;
    return SRAudioFileSetCodecManufacturer(audioFileRef, codec);
}

#else   // if TARGET_OS_IPHONE

AudioObjectPropertyAddress SRAudioGetAOPADefault(AudioObjectPropertySelector inSelector) {
    AudioObjectPropertyAddress address = {
        inSelector,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    return address;
}

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
    /*
     AudioObjectPropertyAddress address = {
     inSelector,
     kAudioObjectPropertyScopeGlobal,
     kAudioObjectPropertyElementMaster
     };

     */
    
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

#pragma mark - Misc

void SRAudioCAShow(AUGraph _Nonnull graph) {
    CAShow(graph);
}
