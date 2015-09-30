//
//  SRAudioKitUtils.h
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 21..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#if TARGET_OS_IPHONE
#import <CoreAudio/CoreAudioTypes.h>
#else
#import <CoreAudio/CoreAudio.h>
#endif

typedef NS_ENUM(UInt32, SRAudioFrameType) {
    SRAudioFrameTypeUnknown = 0,
    SRAudioFrameTypeFloat32Bit,
    SRAudioFrameTypeSignedInteger16Bit
};

BOOL CheckOSStatus(OSStatus status, NSString * _Nonnull description);
UInt32 SRAudioUnsetBitUInt32(UInt32 field, UInt32 value);

AudioObjectPropertyAddress SRAudioGetAOPADefault(AudioObjectPropertySelector inSelector);
AudioStreamBasicDescription SRAudioGetAudioStreamBasicDescription(BOOL stereo, Float64 sampleRate, SRAudioFrameType frameType, BOOL interleaved, BOOL canonical);
BOOL SRAudioIsNonInterleaved(AudioStreamBasicDescription stream);
AudioStreamBasicDescription SRAudioGetCanonicalNoninterleavedStreamFormat(BOOL stereo, Float64 sampleRate);

#if TARGET_OS_IPHONE
#pragma mark - Utilities for iOS

#else   // #if TARGET_OS_IPHONE

#pragma mark - OS X APIs for Audio Device

NSString * _Nullable SRAudioGetDeviceName(AudioDeviceID deviceID);
NSString * _Nullable SRAudioGetDeviceUID(AudioDeviceID deviceID);
UInt32 SRAudioGetNumberOfDeviceInputChannels(AudioDeviceID deviceID);
UInt32 SRAudioGetNumberOfDeviceOutputChannels(AudioDeviceID deviceID);
NSArray<NSNumber *> * _Nullable SRAudioGetDevices();

#endif  // #if TARGET_OS_IPHONE #else

void SRAudioCAShow(AUGraph _Nonnull graph);

@interface SRAudioKitUtils : NSObject

@end
