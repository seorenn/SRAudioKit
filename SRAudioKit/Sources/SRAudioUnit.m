//
//  SRAudioUnit.m
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 21..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUnit.h"
#import "SRAudioKitUtils.h"

static const AudioUnitScope SRAudioUnitBusInput = 1;
static const AudioUnitScope SRAudioUnitBusOutput = 0;

// Callback Definitions
static OSStatus SRAudioUnitCallback(void                          *inRefCon,
                                    AudioUnitRenderActionFlags    *ioActionFlags,
                                    const AudioTimeStamp          *inTimeStamp,
                                    UInt32                        inBusNumber,
                                    UInt32                        inNumberFrames,
                                    AudioBufferList               *ioData);

@implementation SRAudioUnit

@synthesize audioUnit = _audioUnit;
@synthesize delegate = _delegate;

- (nonnull instancetype)initWithAudioUnit:(nonnull AudioUnit)audioUnit {
    self = [super init];
    if (self) {
        _audioUnit = audioUnit;
        
        //self.bufferFrameSize = 1024;
    }
    return self;
}

- (void)setBufferFrameSize:(UInt32)bufferFrameSize {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance before use this...");
    
    UInt32 value = bufferFrameSize;
    UInt32 size = sizeof(UInt32);
    
#if TARGET_OS_IPHONE
    AudioUnitPropertyID propertyID = kAudioUnitProperty_MaximumFramesPerSlice;
#else
    AudioUnitPropertyID propertyID = kAudioDevicePropertyBufferFrameSize;
#endif
    
    if ([self setProperty:propertyID
                    scope:kAudioUnitScope_Global
                  element:SRAudioUnitBusOutput
                     data:&value
                 dataSize:size] == NO) {
        NSLog(@"Failed to set Buffer Frame Size");
    }
}

- (UInt32)bufferFrameSize {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance before use this...");
    
    UInt32 value = 0;
    UInt32 size = sizeof(UInt32);
    
#if TARGET_OS_IPHONE
    AudioUnitPropertyID propertyID = kAudioUnitProperty_MaximumFramesPerSlice;
#else
    AudioUnitPropertyID propertyID = kAudioDevicePropertyBufferFrameSize;
#endif
    
    if ([self getProperty:propertyID
                    scope:kAudioUnitScope_Global
                  element:SRAudioUnitBusOutput
                  outData:&value
               ioDataSize:&size] == NO) {
        NSLog(@"Failed to update Buffer Frame Size");
        return 0;
    }
    
    return value;
}

- (UInt32)bufferByteSize {
    return _audioStreamBasicDescription.mBytesPerFrame * self.bufferFrameSize;
}

- (void)setDelegate:(id<SRAudioUnitDelegate>)delegate {
    if (_delegate) {
        // TODO: Reset already registered callback
    }
    
    _delegate = delegate;
    
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = SRAudioUnitCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)self;
    
#if TARGET_OS_IPHONE
    AudioUnitElement element = SRAudioUnitBusInput;
#else
    AudioUnitElement element = SRAudioUnitBusOutput;
#endif
    
    [self setProperty:kAudioOutputUnitProperty_SetInputCallback scope:kAudioUnitScope_Global element:element data:&callbackStruct dataSize:sizeof(callbackStruct)];
}

- (BOOL)enableInputScope {
    UInt32 flag = 1;
    
    if ([self setProperty:kAudioOutputUnitProperty_EnableIO
                    scope:kAudioUnitScope_Input
                  element:SRAudioUnitBusInput
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
                  element:SRAudioUnitBusOutput
                     data:&flag
                 dataSize:sizeof(flag)] == NO) {
        NSLog(@"Failed to disable Output Scope");
        return NO;
    }
    
    return YES;
}

- (void)allocateAudioBufferList {
    UInt32 size = self.bufferByteSize; //self.bytesPerFrame * self.bufferFrameSize;
    UInt32 memorySize = offsetof(AudioBufferList, mBuffers[0]) + (sizeof(AudioBuffer) * self.audioStreamBasicDescription.mChannelsPerFrame);
    
    AudioBufferList *buffer = (AudioBufferList *)malloc(memorySize);
    buffer->mNumberBuffers = self.audioStreamBasicDescription.mChannelsPerFrame;
    
    for (UInt32 i=0; i < buffer->mNumberBuffers; ++i) {
        if (SRAudioIsNonInterleaved(self.audioStreamBasicDescription) == NO) {
            buffer->mBuffers[i].mNumberChannels = self.audioStreamBasicDescription.mChannelsPerFrame;
        } else {
            buffer->mBuffers[i].mNumberChannels = 1;    // Non-interleaved
        }
        buffer->mBuffers[i].mDataByteSize = size;
        buffer->mBuffers[i].mData = malloc(size);
    }
    
    _audioBufferList = buffer;
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

- (BOOL)disableCallbackBufferAllocation {
    UInt32 flag = 0;
    if ([self setProperty:kAudioUnitProperty_ShouldAllocateBuffer
                    scope:kAudioUnitScope_Output
                  element:SRAudioUnitBusInput
                     data:&flag
                 dataSize:sizeof(flag)] == NO) {
        NSLog(@"Failed to disable callback allocation");
        return NO;
    }
    
    return YES;
}

#pragma mark - Helpful APIs

- (BOOL)setProperty:(AudioUnitPropertyID)propertyID
              scope:(AudioUnitScope)scope
            element:(AudioUnitElement)element
               data:(const void *)data
           dataSize:(UInt32)dataSize {
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiate method.");
    
    OSStatus error = AudioUnitSetProperty(_audioUnit, propertyID, scope, element, data, dataSize);
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
    NSAssert(_audioUnit != NULL, @"You must create Audio Unit Instance using the instantiate method.");
    
    OSStatus error = AudioUnitGetProperty(_audioUnit, propertyID, scope, element, outData, ioDataSize);
    if (error) {
        NSLog(@"Failed to get property: %ld", (long)error);
        return NO;
    }
    
    return YES;
}

@end

#pragma mark - Callback Implementation

static OSStatus SRAudioUnitCallback(void                          *inRefCon,
                                    AudioUnitRenderActionFlags    *ioActionFlags,
                                    const AudioTimeStamp          *inTimeStamp,
                                    UInt32                        inBusNumber,
                                    UInt32                        inNumberFrames,
                                    AudioBufferList               *ioData) {
    SRAudioUnit *audioUnit = (__bridge SRAudioUnit *)inRefCon;
    OSStatus error = noErr;
    
    error = AudioUnitRender(audioUnit.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, audioUnit.audioBufferList);
    
    if (CheckOSStatus(error, @"AudioUnitRender") == NO) {
        return error;
    }
    
    if (audioUnit.delegate == nil) return error;

    // TODO
    
    return error;
}
