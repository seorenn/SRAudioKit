//
//  SRAudioInput.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 2..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioInput.h"
#import "SRAudioDevice.h"
#import "SRAudioDeviceManager.h"
#import "SRAudioUtilities.h"

@import AudioToolbox;
@import AudioUnit;

static const AudioUnitScope SRAudioBusInput = 1;
static const AudioUnitScope SRAudioBusOutput = 0;

static OSStatus inputCallback(void                          *inRefCon,
                              AudioUnitRenderActionFlags    *ioActionFlags,
                              const AudioTimeStamp          *inTimeStamp,
                              UInt32                        inBusNumber,
                              UInt32                        inNumberFrames,
                              AudioBufferList               *ioData);

@interface SRAudioInput () {
    AudioUnit _audioUnit;
    AudioBufferList *_audioBufferList;
    AudioStreamBasicDescription _streamFormat;
    AudioStreamBasicDescription _inputScopeFormat;
    AudioStreamBasicDescription _outputScopeFormat;
    
    BOOL _channelConfigured;
}
@property (readonly) AudioUnit audioUnit;
@property (readonly) AudioBufferList *audioBufferList;
@end

@implementation SRAudioInput

@synthesize streamFormat = _streamFormat;

@synthesize audioUnit = _audioUnit;
@synthesize audioBufferList = _audioBufferList;

@synthesize device = _device;
@synthesize sampleRate = _sampleRate;
@synthesize bufferSize = _bufferSize;
@synthesize isCapturing = _isCapturing;
@synthesize stereo = _stereo;

//- (id)initWithDevice:(SRAudioDevice *)device sampleRate:(Float64)sampleRate bufferSize:(SRAudioBufferSize)bufferSize {
//    self = [super init];
//    if (self) {
//        if (device == nil) {
//            _device = [SRAudioDeviceManager sharedManager].defaultDevice;
//        } else {
//            _device = device;
//        }
//        _sampleRate = sampleRate;
//        _bufferSize = bufferSize;
//        
//        _audioUnit = [self createAudioUnitWithDevice:device];
//        
//        _channelConfigured = NO;
//
//#if TARGET_OS_MAC
//        _inputScopeFormat = [self inputScopeFormatWithAudioUnit:_audioUnit];
//        _outputScopeFormat = [self outputScopeFormatWithAudioUnit:_audioUnit];
//#endif
//    }
//    return self;
//}

- (id)initWithStereoDevice:(SRAudioDevice *)device
               leftChannel:(UInt32)leftChannel
              rightChannel:(UInt32)rightChannel
                sampleRate:(Float64)sampleRate
                bufferSize:(SRAudioBufferFrameSize)bufferSize {
    self = [super init];
    if (self) {
        BOOL res = [self commonInitializationWithDevice:device
                                                 stereo:YES
                                             sampleRate:sampleRate
                                             bufferSize:bufferSize
                                          inputChannel1:leftChannel
                                          inputChannel2:rightChannel];
        if (res == NO) return nil;
    }
    return self;
}

- (id)initWithMonoDevice:(SRAudioDevice *)device
                 channel:(UInt32)channel
              sampleRate:(Float64)sampleRate
              bufferSize:(SRAudioBufferFrameSize)bufferSize {
    self = [super init];
    if (self) {
        BOOL res = [self commonInitializationWithDevice:device
                                                 stereo:NO
                                             sampleRate:sampleRate
                                             bufferSize:bufferSize
                                          inputChannel1:channel
                                          inputChannel2:-1];
        if (res == NO) return nil;
    }
    return self;
}

- (BOOL)startCapture {
    if ([self readyToStart] == NO) return NO;
    if (_isCapturing) return NO;
    
    OSStatus error = AudioOutputUnitStart(_audioUnit);
    if (error) {
        NSLog(@"Failed to start Audio Unit(%ld)", (long)error);
        return NO;
    }

    _isCapturing = YES;
    
    return YES;
}

- (BOOL)stopCapture {
    if (_isCapturing == NO) return NO;

    OSStatus error = AudioOutputUnitStop(_audioUnit);
    if (error) {
        NSLog(@"Failed to stop Audio Unit(%ld)", (long)error);
        return NO;
    }
    
    _isCapturing = NO;
    
    return YES;
}

#pragma mark - Internal APIs

- (BOOL)commonInitializationWithDevice:(SRAudioDevice *)device
                                stereo:(BOOL)stereo
                            sampleRate:(Float64)sampleRate
                            bufferSize:(SRAudioBufferFrameSize)bufferSize
                         inputChannel1:(UInt32)inputChannel1
                         inputChannel2:(UInt32)inputChannel2 {
    _stereo = stereo;
    
    _device = (device) ? device : [SRAudioDeviceManager sharedManager].defaultDevice;
    if (_device.numberInputChannels == 0) {
        NSLog(@"The device[%@] has no input channel", _device);
        return NO;
    }
    
    _sampleRate = sampleRate;
    _bufferSize = bufferSize;
    _channelConfigured = NO;
    _audioUnit = [self createAudioUnitWithDevice:_device];
    
#if TARGET_OS_MAC
    _inputScopeFormat = [self inputScopeFormatWithAudioUnit:_audioUnit];
    _outputScopeFormat = [self outputScopeFormatWithAudioUnit:_audioUnit];
#endif
    
    if (stereo) {
        if ([self configureStereoChannelMapWithChannelLeft:inputChannel1 channelRight:inputChannel2] == NO) {
            return NO;
        }
    } else {
        if ([self configureMonoChannelMapWithChannel:inputChannel1] == NO) {
            return NO;
        }
    }
    
    [self setBufferFrameSize:_bufferSize];
    _bufferSize = [self bufferFrameSize];
    if (_bufferSize == 0) {
        return NO;
    }
    
    _audioBufferList = [self allocateAudioBufferListWithStreamDescription:_streamFormat sampleBufferSize:_bufferSize];
    
    if ([self configureCallback] == NO) {
        return NO;
    }
    
    if ([self disableCallbackBufferAllocation] == NO) {
        return NO;
    }
    
    OSStatus error = AudioUnitInitialize(_audioUnit);
    if (error) {
        NSLog(@"Failed to initialize Audio Unit (%ld)", (long)error);
        return NO;
    }
    
    return YES;
}

- (void)dealloc {
    if (_isCapturing) {
        [self stopCapture];
    }
    if (_audioUnit) {
        AudioComponentInstanceDispose(_audioUnit);
    }
    if (_audioBufferList) {
        [self freeAudioBufferList:_audioBufferList];
    }
}

//- (AudioStreamBasicDescription)streamFormatWithStereo:(BOOL)stereo sampleRate:(Float64)sampleRate frameType:(SRAudioFrameType)frameType interleaved:(BOOL)interleaved {
//    AudioStreamBasicDescription desc;
//    
//    UInt32 sampleSize = 0;
//    
//    desc.mChannelsPerFrame = (stereo) ? 2 : 1;
//    desc.mSampleRate = sampleRate;
//    desc.mFormatID = kAudioFormatLinearPCM;
//    desc.mFramesPerPacket = 1;
//    
//    desc.mBitsPerChannel = 8 * sampleSize;
//
//    if (frameType == SRAudioFrameTypeFloat32Bit) {
//#if TARGET_OS_MAC
//        sampleSize = sizeof(Float32);
//#elif TARGET_OS_IPHONE
//        sampleSize = sizeof(float);
//#endif
//        desc.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
//    } else if (frameType == SRAudioFrameTypeSignedInteger16Bit) {
//        sampleSize = sizeof(SInt16);
//        desc.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked;
//    } else {
//        NSAssert(NO, @"Not Implemented Frame Type");
//    }
//    
//    if (interleaved) {
//        desc.mBytesPerPacket = desc.mBytesPerFrame = desc.mChannelsPerFrame * sampleSize;
//    } else {
//        desc.mBytesPerPacket = desc.mBytesPerFrame = sampleSize;
//        desc.mFormatFlags = desc.mFormatFlags | kAudioFormatFlagIsNonInterleaved;
//    }
//
//    return desc;
//}

- (BOOL)readyToStart {
    if (_channelConfigured == NO) {
        NSLog(@"Channel Not Configured");
        return NO;
    }
    
    return YES;
}

- (BOOL)configureStereoChannelMapWithChannelLeft:(UInt32)leftChannel channelRight:(UInt32)rightChannel {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i=0; i < _device.numberInputChannels; ++i) {
        if (i == leftChannel || i == rightChannel) {
            [array addObject:[NSNumber numberWithInt:i]];
        } else {
            [array addObject:[NSNumber numberWithInt:-1]];
        }
    }
    
    BOOL res = [self configureChannelMapWithChannelArray:array];
    if (res == NO) {
        return NO;
    }
    
    _streamFormat = SRAudioGetCanonicalNoninterleavedStreamFormat(YES, _sampleRate);
    [self configureStreamFormat:_streamFormat];
    
    _channelConfigured = YES;
    
    return YES;
}

- (BOOL)configureMonoChannelMapWithChannel:(UInt32)channel {
    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (int i=0; i < _device.numberInputChannels; ++i) {
        if (i == channel) {
            [array addObject:[NSNumber numberWithInt:i]];
        } else {
            [array addObject:[NSNumber numberWithInt:-1]];
        }
    }
    
    BOOL res = [self configureChannelMapWithChannelArray:array];
    if (res == NO) {
        return NO;
    }
    
    _streamFormat = SRAudioGetCanonicalNoninterleavedStreamFormat(NO, _sampleRate);
    [self configureStreamFormat:_streamFormat];
    
    _channelConfigured = YES;
    
    return YES;
}

- (BOOL)configureStreamFormat:(AudioStreamBasicDescription)description {
    UInt32 size = sizeof(AudioStreamBasicDescription);
    
    OSStatus error = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, SRAudioBusOutput, &description, size);
    if (error) {
        NSLog(@"Failed to set stream formet for Output Bus(%ld)", (long)error);
        return NO;
    }
    
    error = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, SRAudioBusInput, &description, size);
    if (error) {
        NSLog(@"Failed to set stream formet for Input Bus(%ld)", (long)error);
        return NO;
    }
    
    return YES;
}

- (AudioBufferList *)allocateAudioBufferListWithStreamDescription:(AudioStreamBasicDescription)description sampleBufferSize:(SRAudioBufferFrameSize)sampleBufferSize {
    UInt32 size = description.mBytesPerFrame * sampleBufferSize;
    UInt32 memorySize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * description.mChannelsPerFrame);
    
    AudioBufferList *buffer = (AudioBufferList *)malloc(memorySize);
    buffer->mNumberBuffers = description.mChannelsPerFrame;
    
    for (UInt32 i=0; i < buffer->mNumberBuffers; ++i) {
        buffer->mBuffers[i].mNumberChannels = 1;    // Non-interleaved
        buffer->mBuffers[i].mDataByteSize = size;
        buffer->mBuffers[i].mData = malloc(size);
    }
    
    return buffer;
}

- (void)freeAudioBufferList:(AudioBufferList *)audioBufferList {
    if (audioBufferList == NULL) return;
    
    for (int i=0; i < audioBufferList->mNumberBuffers; ++i) {
        if (audioBufferList->mBuffers[i].mData) {
            free(audioBufferList->mBuffers[i].mData);
        }
    }
    
    free(audioBufferList);
}

- (BOOL)configureChannelMapWithChannelArray:(NSArray *)channelArray {
    UInt32 mapSize = _device.numberInputChannels * sizeof(SInt32);
    SInt32 *channelMap = malloc(mapSize);
    
    if (channelMap == NULL) {
        NSLog(@"Insufficient Memory!");
        return NO;
    }
    
    int i = 0;
    for (NSNumber *number in channelArray) {
        channelMap[i] = (SInt32)[number intValue];
    }
    
    OSStatus error = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_ChannelMap, kAudioUnitScope_Output, 1, channelMap, mapSize);
    free(channelMap);
    if (error) {
        NSLog(@"Failed to set channel map(%ld)", (long)error);
        return NO;
    }
    return YES;
}

- (AudioUnit)createAudioUnitWithDevice:(SRAudioDevice *)device {
    AudioComponentDescription description = [self audioComponentDescription];
    AudioComponent component = [self audioComponentWithDescription:description];
    
    AudioUnit audioUnitInstance = [self audioUnitInstanceWithAudioComponent:component];
    
    [self enableInputScopeWithAudioUnit:audioUnitInstance];
    [self disableOutputScopeWithAudioUnit:audioUnitInstance];
    
    [self audioUnit:audioUnitInstance useDevice:device];
    
    return audioUnitInstance;
}

- (AudioStreamBasicDescription)inputScopeFormatWithAudioUnit:(AudioUnit)audioUnit {
    AudioStreamBasicDescription desc;
    UInt32 size = sizeof(desc);
    OSStatus error = AudioUnitGetProperty(audioUnit,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Output,
                                          SRAudioBusInput,
                                          &desc,
                                          &size);
    CheckOSStatusFailure(error, @"AudioUnitGetProperty StreamFormat Output Failed");
    return desc;
}

- (AudioStreamBasicDescription)outputScopeFormatWithAudioUnit:(AudioUnit)audioUnit {
    AudioStreamBasicDescription desc;
    UInt32 size = sizeof(desc);
    OSStatus error = AudioUnitGetProperty(audioUnit,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Input,
                                          SRAudioBusInput,
                                          &desc,
                                          &size);
    CheckOSStatusFailure(error, @"AudioUnitGetProperty StreamFormat Input Failed");
    return desc;
}

- (AudioUnit)audioUnitInstanceWithAudioComponent:(AudioComponent)component {
    AudioUnit instance;
    OSStatus error = noErr;
    
    error = AudioComponentInstanceNew(component, &instance);
    CheckOSStatusFailure(error, @"AudioComponentInstanceNew Failed");
    
    return instance;
}

- (void)enableInputScopeWithAudioUnit:(AudioUnit)audioUnit {
    OSStatus error = noErr;
    UInt32 flag = 1;

    error = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, SRAudioBusInput, &flag, sizeof(flag));
    CheckOSStatusFailure(error, @"AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO Input Failed");
}

- (void)disableOutputScopeWithAudioUnit:(AudioUnit)audioUnit {
    OSStatus error = noErr;
#if TARGET_OS_IPHONE
    UInt32 flag = 1;
#else
    UInt32 flag = 0;
#endif
    
    error = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, SRAudioBusOutput, &flag, sizeof(flag));
    CheckOSStatusFailure(error, @"AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO Output Failed");
}

- (AudioComponentDescription)audioComponentDescription {
    AudioComponentDescription description;
    description.componentType = kAudioUnitType_Output;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    description.componentFlags = 0;
    description.componentFlagsMask = 0;

#if TARGET_OS_IPHONE
    description.componentSubType = kAudioUnitSubType_RemoteIO;
#elif TARGET_OS_MAC
    description.componentSubType = kAudioUnitSubType_HALOutput;
#endif
    
    return description;
}

- (AudioComponent)audioComponentWithDescription:(AudioComponentDescription)description {
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    NSAssert(component, @"Failed to get AudioComponent");
    return component;
}

- (void)audioUnit:(AudioUnit)audioUnit useDevice:(SRAudioDevice *)device {
    OSStatus error = noErr;
    AudioDeviceID deviceID = device.deviceID;
    
    error = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, SRAudioBusOutput, &deviceID, sizeof(deviceID));
    CheckOSStatusFailure(error, @"Failed to set device")
}

- (UInt32)bufferFrameSize {
    UInt32 bufferFrameSize = 0;
    UInt32 size = sizeof(bufferFrameSize);
    OSStatus error = AudioUnitGetProperty(_audioUnit,
#if TARGET_OS_IPHONE
                                          kAudioUnitProperty_MaximumFramesPerSlice,
#else
                                          kAudioDevicePropertyBufferFrameSize,
#endif
                                          kAudioUnitScope_Global,
                                          SRAudioBusOutput,
                                          &bufferFrameSize,
                                          &size);
    if (error) {
        NSLog(@"Failed to get Buffer Frame Size (%ld)", (long)error);
        return 0;
    }
    
    return bufferFrameSize;
}

- (void)setBufferFrameSize:(UInt32)bufferFrameSize {
    UInt32 size = sizeof(bufferFrameSize);
    OSStatus error = AudioUnitSetProperty(_audioUnit,
#if TARGET_OS_IPHONE
                                          kAudioUnitProperty_MaximumFramesPerSlice,
#else
                                          kAudioDevicePropertyBufferFrameSize,
#endif
                                          kAudioUnitScope_Global,
                                          SRAudioBusOutput,
                                          &bufferFrameSize,
                                          size);
    if (error) {
        NSLog(@"Failed to set Buffer Frame Size (%ld)", (long)error);
    }
}

- (BOOL)configureCallback {
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = inputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
    OSStatus error = AudioUnitSetProperty(_audioUnit, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global,
#if TARGET_OS_IPHONE
                                          SRAudioBusInput,
#else
                                          SRAudioBusOutput,
#endif
                                          &callbackStruct, sizeof(callbackStruct));
    if (error) {
        NSLog(@"Failed to set callback (%ld)", (long)error);
        return NO;
    }
    
    return YES;
}

- (BOOL)disableCallbackBufferAllocation {
    UInt32 flag = 0;
    OSStatus error = AudioUnitSetProperty(_audioUnit, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, SRAudioBusInput, &flag, sizeof(flag));
    if (error) {
        NSLog(@"Failed to disable callback allocation (%ld)", (long)error);
        return NO;
    }
    
    return YES;
}

#pragma mark - AudioUnit Callback

static OSStatus inputCallback(void                          *inRefCon,
                              AudioUnitRenderActionFlags    *ioActionFlags,
                              const AudioTimeStamp          *inTimeStamp,
                              UInt32                        inBusNumber,
                              UInt32                        inNumberFrames,
                              AudioBufferList               *ioData ) {
    SRAudioInput *audioInput = (__bridge SRAudioInput *)inRefCon;
    OSStatus error = noErr;
    
    error = AudioUnitRender(audioInput.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, audioInput.audioBufferList);
    
    if (error) {
        NSLog(@"Failed to render (%ld)", (long)error);
        return error;
    }
    
    if (audioInput.delegate == nil) return error;
    
    if ([audioInput.delegate respondsToSelector:@selector(audioInput:didTakeBufferList:withBufferSize:numberOfChannels:)]) {
        [audioInput.delegate audioInput:audioInput didTakeBufferList:audioInput.audioBufferList withBufferSize:inNumberFrames numberOfChannels:audioInput.streamFormat.mChannelsPerFrame];
    }
    
    // TODO
    
    return error;
}

@end
