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
NSString * _Nonnull OSStatusString(OSStatus status);
UInt32 SRAudioUnsetBitUInt32(UInt32 field, UInt32 value);

AudioStreamBasicDescription SRAudioGetAudioStreamBasicDescription(BOOL stereo, Float64 sampleRate, SRAudioFrameType frameType, BOOL interleaved, BOOL canonical);
BOOL SRAudioIsNonInterleaved(AudioStreamBasicDescription stream);
AudioStreamBasicDescription SRAudioGetCanonicalNoninterleavedStreamFormat(BOOL stereo, Float64 sampleRate);

OSStatus SRAudioFileCreate(NSString * _Nonnull path, AudioFileTypeID inFileType, const AudioStreamBasicDescription * _Nonnull inStreamDesc, const AudioChannelLayout * _Nullable inChannelLayout, BOOL eraseFile, ExtAudioFileRef _Nullable * _Nonnull outExtAudioFile);

#if TARGET_OS_IPHONE
#pragma mark - Utilities for iOS
OSStatus SRAudioFileSetAppleCodecManufacturer(ExtAudioFileRef _Nonnull audioFileRef, BOOL useHardwareCodec);

#else   // #if TARGET_OS_IPHONE

AudioObjectPropertyAddress SRAudioGetAOPADefault(AudioObjectPropertySelector inSelector);

NSString * _Nullable SRAudioGetDeviceName(AudioDeviceID deviceID);
NSString * _Nullable SRAudioGetDeviceUID(AudioDeviceID deviceID);
UInt32 SRAudioGetNumberOfDeviceInputChannels(AudioDeviceID deviceID);
UInt32 SRAudioGetNumberOfDeviceOutputChannels(AudioDeviceID deviceID);
NSArray<NSNumber *> * _Nullable SRAudioGetDevices();

#endif  // #if TARGET_OS_IPHONE #else

void SRAudioCAShow(AUGraph _Nonnull graph);

#pragma mark - Misc

CFURLRef _Nullable CFURLFromPathString(NSString * _Nonnull pathString);

@interface SRAudioKitUtils : NSObject

@end

typedef OSStatus (^SRAudioUnitRenderCallback)(id _Nullable userData, AudioUnitRenderActionFlags * _Nonnull ioActionFlags, const AudioTimeStamp * _Nonnull inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList * _Nonnull ioData);

@interface SRAudioCallbackHelper: NSObject
@property (nullable, nonatomic, weak) id userData;
@property (nullable, nonatomic, strong) SRAudioUnitRenderCallback callback;

- (OSStatus)AUGraphSetNodeInputCallback:(nonnull AUGraph)inGraph node:(AUNode)inDestNode inputNumber:(UInt32)inDestInputNumber;

@end