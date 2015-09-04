//
//  SRAudioUnitInput.m
//  SRAudioKit
//
//  NOTE: SRAudioUnitInput Implement Audio Unit Typed General Output. (WTF???)
//
//  Created by Seorenn on 2015. 3. 6..
//  Copyright (c) 2015 Seorenn. All rights reserved.
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
}

@synthesize audioDevice = _audioDevice;
@synthesize inputChannelMap = _inputChannelMap;
@synthesize stereo = _stereo;
@synthesize bufferFrameSize = _bufferFrameSize;
@synthesize isCapturing = _capturing;
@synthesize inputScopeFormat = _inputScopeFormat;
@synthesize outputScopeFormat = _outputScopeFormat;

- (id)init {
#if TARGET_OS_IPHONE
    self = [super initWithType:kAudioUnitType_Output subType:kAudioUnitSubType_RemoteIO];
#else
    self = [super initWithType:kAudioUnitType_Output subType:kAudioUnitSubType_HALOutput];
#endif
    if (self) {
        self.stereo = YES;
        self.bufferFrameSize = SRAudioBufferFrameSize1024;
        _audioDevice = nil;
        _inputChannelMap = nil;
    }
    return self;
}

- (void)dealloc {
    if (_capturing) {
        [self stopCapture];
    }
    
    if (self.audioUnit) {
        AudioComponentInstanceDispose(self.audioUnit);
    }
    
    if (_audioBufferList) {
        [self freeAudioBufferList];
    }
}

// override
- (void)instantiate {
    [super instantiate];
    
    [self enableInputScope];
    [self disableOutputScope];

    if (_audioDevice) {
        self.audioDevice = _audioDevice;
    }
    
#if TARGET_OS_MAC
    _inputScopeFormat = [self createInputScopeFormat];
    _outputScopeFormat = [self createOutputScopeFormat];
#endif
    
    if (_inputChannelMap) {
        self.inputChannelMap = _inputChannelMap;
    }

    self.bufferFrameSize = _bufferFrameSize;
    
    if (self.delegate) {
        [self allocateAudioBufferList];
        if ([self configureCallback] == NO) return;
        if ([self disableCallbackBufferAllocation] == NO) return;
    }
    
    OSStatus error = AudioUnitInitialize(self.audioUnit);
    if (error) {
        NSLog(@"Failed to initialize Audio Unit: %ld", (long)error);
    }
}

- (void)startCapture {
    NSAssert(self.audioUnit != NULL, @"You must create Audio Unit Instance using the instantiate method.");
    if (_capturing) return;
    
    OSStatus error = AudioOutputUnitStart(self.audioUnit);
    if (error) {
        NSLog(@"Failed to start Audio Output Unit: %ld", (long)error);
        return;
    }
    
    _capturing = YES;
}

- (void)stopCapture {
    if (_capturing == NO) return;
    
    OSStatus error = AudioOutputUnitStop(self.audioUnit);
    if (error) {
        NSLog(@"Failed to stop Audio Output Unit: %ld", (long)error);
        return;
    }
    
    _capturing = NO;
}

#pragma mark - Properties

- (void)setAudioDevice:(SRAudioDevice *)audioDevice {
    _audioDevice = audioDevice;

    if (self.audioUnit == NULL) return;
    
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
    _inputChannelMap = inputChannelMap;

    if (self.audioUnit == NULL || _audioDevice == nil) return;
    
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
    _bufferFrameSize = bufferFrameSize;

    if (self.audioUnit == NULL) return;
    
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
    value = 0;
    
    if ([self getProperty:propertyID
                    scope:kAudioUnitScope_Global
                  element:SRAudioUnitInputBusOutput
                  outData:&value
               ioDataSize:&size] == NO) {
        NSLog(@"Failed to update Buffer Frame Size");
        return;
    }
    
    _bufferFrameSize = value;
}

- (UInt32)bufferByteSize {
    return self.streamFormat.mBytesPerFrame * _bufferFrameSize;
}

#pragma mark - Internal APIs

- (AudioStreamBasicDescription)createInputScopeFormat {
    NSAssert(self.audioUnit != NULL, @"You must create Audio Unit Instance using the instantiate method.");
    
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

- (AudioStreamBasicDescription)createOutputScopeFormat {
    NSAssert(self.audioUnit != NULL, @"You must create Audio Unit Instance using the instantiate method.");
    
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
    UInt32 size = self.bufferByteSize; //self.bytesPerFrame * self.bufferFrameSize;
    UInt32 memorySize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * self.channelsPerFrame);
    
    AudioBufferList *buffer = (AudioBufferList *)malloc(memorySize);
    buffer->mNumberBuffers = self.channelsPerFrame;
    
    for (UInt32 i=0; i < buffer->mNumberBuffers; ++i) {
        if (self.interleaved) {
            buffer->mBuffers[i].mNumberChannels = self.channelsPerFrame;
        } else {
            buffer->mBuffers[i].mNumberChannels = 1;    // Non-interleaved
        }
        buffer->mBuffers[i].mDataByteSize = size;
        buffer->mBuffers[i].mData = malloc(size);
    }
    
    _audioBufferList = buffer;
}

- (BOOL)disableCallbackBufferAllocation {
    UInt32 flag = 0;
    if ([self setProperty:kAudioUnitProperty_ShouldAllocateBuffer
                    scope:kAudioUnitScope_Output
                  element:SRAudioUnitInputBusInput
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
    SRAudioUnitInput *input = (__bridge SRAudioUnitInput *)inRefCon;
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
