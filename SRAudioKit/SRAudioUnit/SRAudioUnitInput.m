//
//  SRAudioUnitInput.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUnitInput.h"

#import "SRAudioDevice.h"
#import "SRAudioDeviceManager.h"

static const AudioUnitScope SRAudioUnitInputBusInput = 1;
static const AudioUnitScope SRAudioUnitInputBusOutput = 0;

static OSStatus inputCallback(void                          *inRefCon,
                              AudioUnitRenderActionFlags    *ioActionFlags,
                              const AudioTimeStamp          *inTimeStamp,
                              UInt32                        inBusNumber,
                              UInt32                        inNumberFrames,
                              AudioBufferList               *ioData);

@implementation SRAudioUnitInput {
    BOOL _isBufferFrameSizeUpdated;
}

@synthesize audioUnit = _audioUnit;
@synthesize streamFormat = _streamFormat;

@synthesize audioDevice = _audioDevice;
@synthesize inputChannelMap = _inputChannelMap;
@synthesize stereo = _stereo;
@synthesize bufferFrameSize = _bufferFrameSize;
@synthesize isCapturing = _capturing;

- (id)init {
#if TARGET_OS_IPHONE
    self = [super initWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO];
#else
    self = [super initWithType:kAudioUnitType_Output subType:kAudioUnitSubType_HALOutput];
#endif
    if (self) {
        self.stereo = YES;
//        _bufferFrameSize = SRAudioBufferFrameSize1024;
    }
    return self;
}

- (void)dealloc {
    if (_capturing) {
        [self stopCapture];
    }
    
    [super dealloc];
    
    if (_audioBufferList) {
        [self freeAudioBufferList];
    }
}

- (void)instantiateAudioUnitWithAudioDevice:(SRAudioDevice *)audioDevice {
    [super instantiateAudioUnit];
    
    if (_isBufferFrameSizeUpdated == NO) {
        // Default Sample Rate
        self.bufferFrameSize = SRAudioBufferFrameSize1024;
    }

    if (audioDevice) {
        self.audioDevice = audioDevice;
    }
}


- (void)setAudioDevice:(SRAudioDevice *)audioDevice {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiateAudioUnit method.");
    
    AudioDeviceID deviceID = 0;
    if (audioDevice == nil) {
        deviceID = [SRAudioDeviceManager sharedManager].defaultDevice.deviceID;
    } else {
        deviceID = audioDevice.deviceID;
    }
    
    if ([self setProperty:kAudioOutputUnitProperty_CurrentDevice
                    scope:kAudioUnitScope_Global
                  element:SRAudioUnitInputBusOutput
                     data:&deviceID
                 dataSize:sizeof(deviceID)] == NO) {
        NSLog(@"Failed to set audio device");
        return;
    }
    
    _audioDevice = audioDevice;
}

- (void)setInputChannelMap:(NSArray *)inputChannelMap {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiateAudioUnit method.");
    NSAssert(_audioDevice != nil, @"You must set audioDevice before.");
    
    if (inputChannelMap.count > _audioDevice.numberInputChannels) {
        NSLog(@"WARNING: inputChannelMap count is bigger than audioDeivce.numberInputChannels");
    }
    
    UInt32 mapSize = _audioDevice.numberInputChannels * sizeof(SInt32);
    SInt32 *channelMap = malloc(mapSize);
    NSAssert(channelMap != NULL, @"Insufficient Memory");
    
    int index = 0;
    for (NSNumber *number in inputChannelMap) {
        channelMap[index] = (SInt32)number.intValue;
    }
    
    if ([self setProperty:kAudioOutputUnitProperty_ChannelMap
                    scope:kAudioUnitScope_Output
                  element:1
                     data:channelMap
                 dataSize:mapSize]) {
        _inputChannelMap = inputChannelMap;
    } else {
        NSLog(@"Failed to set channel map");
        _inputChannelMap = nil;
    }
    
}

- (void)setStereo:(BOOL)stereo {
    _stereo = stereo;
    
    self.channelsPerFrame = stereo ? 2 : 1;
}

- (void)setBufferFrameSize:(SRAudioBufferFrameSize)bufferFrameSize {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiateAudioUnit method.");
    
    UInt32 value = bufferFrameSize;
    UInt32 size = sizeof(UInt32);

#if TARGET_OS_IPHONE
    AudioUnitPropertyID propertyID = kAudioUnitProperty_MaximumFramesPerSlice;
#else
    AudioUnitPropertyID propertyID = kAudioDevicePropertyBufferFrameSize;
#endif

    if ([self setProperty:propertyID
                    scope:kAudioUnitScope_Global
                  element:SRAudioUnitInputBusOutput
                     data:&value
                 dataSize:size] == NO) {
        NSLog(@"Failed to set Buffer Frame Size");
    }
    
    // Pull buffer frame size from Audio Unit
    value = 0
    
    if ([self getProperty:propertyID
                    scope:kAudioUnitScope_Global
                  element:SRAudioUnitInputBusOutput
                  outData:&value
               ioDataSize:&size] == NO) {
        NSLog(@"Failed to update Buffer Frame Size");
        return;
    }
    
    _bufferFrameSize = value;
    _isBufferFrameSizeUpdated = YES;
}

- (UInt32)bufferByteSize {
    return _streamFormat.mBytesPerFrame * _bufferFrameSize;
}

#pragma mark - Internal APIs

- (AudioStreamBasicDescription)inputScopeFormat {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiateAudioUnit method.");
    
    AudioStreamBasicDescription desc;
    UInt32 size = sizeof(desc);
    
    if ([self getProperty:kAudioUnitProperty_StreamFormat
                    scope:kAudioUnitScope_Output
                  element:SRAudioUnitInputBusInput
                  outData:&desc
               ioDataSize:&size] == NO) {
        NSLog(@"Failed to get Input Scope Format");
    }
    
    return desc;
}

- (AudioStreamBasicDescription)outputScopeFormat {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiateAudioUnit method.");
    
    AudioStreamBasicDescription desc;
    UInt32 size = sizeof(desc);

    if ([self getProperty:kAudioUnitProperty_StreamFormat
                    scope:kAudioUnitScope_Input
                  element:SRAudioUnitInputBusInput
                  outData:&desc
               ioDataSize:&size] == NO) {
        NSLog(@"Failed to get Output Scope Format");
    }
    
    return desc;
}

- (BOOL)enableInputScope {
    UInt32 flag = 1;

    if ([self setProperty:kAudioOutputUnitProperty_EnableIO
                    scope:kAudioUnitScope_Input
                  element:SRAudioUnitInputBusInput
                     data:&flag
                 dataSize:sizeof(flag)] == NO) {
        NSLog(@"Failed to enable Input Scope");
        return NO;
    }
    
    return YES;
}

- (BOOL)disableOutputScope {
#if TARGET_OS_IPHONE
    UInt32 flag = 1;
#else
    UInt32 flag = 0;
#endif

    if ([self setProperty:kAudioOutputUnitProperty_EnableIO
                    scope:kAudioUnitScope_Output
                  element:SRAudioUnitInputBusOutput
                     data:&flag
                 dataSize:sizeof(flag)] == NO) {
        NSLog(@"Failed to disable Output Scope");
        return NO;
    }
    
    return YES;
}

- (BOOL)configureCallback {
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = inputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
#if TARGET_OS_IPHONE
    AudioUnitElement element = SRAudioUnitInputBusInput;
#else
    AudioUnitElement element = SRAudioUnitInputBusOutput;
#endif
    
    if ([self setProperty:kAudioOutputUnitProperty_SetInputCallback
                    scope:kAudioUnitScope_Global
                  element:element data:&callbackStruct
                 dataSize:sizeof(callbackStruct)] == NO) {
        NSLog(@"Failed to set callback");
        return NO;
    }
    
    return YES;
}

- (void)allocateAudioBufferList {
    UInt32 size = self.bytesPerFrame * self.bufferFrameSize;
    UInt32 memorySize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * self.channelsPerFrame);
    
    AudioBufferList *buffer = (AudioBufferList *)malloc(memorySize);
    buffer->mNumberBuffers = self.channelsPerFrame;
    
    for (UInt32 i=0; i < buffer->mNumberBuffers; ++i) {
        buffer->mBuffers[i].mNumberChannels = 1;    // Non-interleaved
        buffer->mBuffers[i].mDataByteSize = size;
        buffer->mBuffers[i].mData = malloc(size);
    }
    
    _audioBufferList = buffer;
}

- (BOOL)disableCallbackBufferAllocation {
    UInt32 flag = 0;
    if ([self setProperty:kAudioUnitProperty_ShouldAllocateBuffer
                    scope:kAudioUnitScope_Output
                  element:SRAudioInputBusInput
                     data:&flag
                 dataSize:sizeof(flag)] == NO) {
        NSLog(@"Failed to disable callback allocation");
        return NO;
    }
    
    return YES;
}

- (void)freeAudioBufferList {
    if (_audioBufferList == NULL) return;
    
    for (int i=0; i < _audioBufferList->mNumberBuffers; ++i) {
        if (_audioBufferList->mBuffers[i].mData) {
            free(_audioBufferList->mBuffers[i].mData);
        }
    }
    
    free(_audioBufferList);
    _audioBufferList = NULL;
}

#pragma mark - AudioUnit Callback

static OSStatus inputCallback(void                          *inRefCon,
                              AudioUnitRenderActionFlags    *ioActionFlags,
                              const AudioTimeStamp          *inTimeStamp,
                              UInt32                        inBusNumber,
                              UInt32                        inNumberFrames,
                              AudioBufferList               *ioData ) {
    SRAudioUnitInput *input = (__bridge SRAudioInput *)inRefCon;
    OSStatus error = noErr;
    
    error = AudioUnitRender(input.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, input.audioBufferList);
    
    if (error) {
        NSLog(@"Failed to render (%ld)", (long)error);
        return error;
    }
    
    if (input.delegate == nil) return error;
    
    if ([input.delegate respondsToSelector:@selector(audioUnitInput:didTakeBufferList:withBufferSize:numberOfChannels:)]) {
        [input.delegate audioUnitInput:input
                     didTakeBufferList:input.audioBufferList
                        withBufferSize:inNumberFrames
                      numberOfChannels:input.channelsPerFrame];
    }
    
    // TODO
    
    return error;
}

@end
