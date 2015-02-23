//
//  SRAudioQueue.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioQueue.h"

#define SRAudioQueueNumberOfBuffers 3

/*
static void SRAudioQueueInputBufferHandler(void *aqData,
                                           AudioQueueRef inAQ,
                                           AudioQueueBufferRef inBuffer,
                                           const AudioTimeStamp *inStartTime,
                                           UInt32 inNumPackets,
                                           const AudioStreamPacketDescription *inPacketDesc);
*/

@interface SRAudioQueue () {
    AudioStreamBasicDescription _dataFormat;
    AudioQueueRef               _queue;
    AudioQueueBufferRef         _buffers[SRAudioQueueNumberOfBuffers];
    AudioFileID                 _audioFile;
    UInt32                      _bufferByteSize;
    SInt64                      _currentPacket;
    BOOL                        _isRunning;
    BOOL                        _isPrepared;
}
@property (assign) AudioStreamBasicDescription dataFormat;
@property (assign) AudioQueueRef queue;
@end

@implementation SRAudioQueue

@synthesize dataFormat = _dataFormat;
@synthesize queue = _queue;

- (id)init {
    self = [super init];
    if (self) {
        _queue = NULL;
        
        self.sampleRate = 44100.0;
        self.channelsPerFrame = 2;
        self.bitsPerChannel = 16;
        self.framesPerPacket = 1;
        self.bufferSize = SRAudioQueueBufferSize1024Samples;
        
        _isRunning = NO;
        _isPrepared = NO;
    }
    return self;
}

- (void)dealloc {
    if (_queue) {
        [self stop];
        [self dispose];
    }
}

- (BOOL)dispose {
    if (_queue == NULL) return YES;
    
    OSStatus error = AudioQueueDispose(_queue, true);
    if (error != noErr) {
        NSLog(@"AudioQueueDispose Failed");
        return NO;
    }
    
    _queue = NULL;
    return YES;
}

- (AudioQueueRef)queueWithFormat:(AudioStreamBasicDescription *)format {
    NSAssert(NO, @"You must not use SRAudioQueue class directly. Use SRAudioQueueInput instead.");
    return NULL;
}

- (BOOL)prepare {
    [self stop];
    [self dispose];
    
    OSStatus error = noErr;
    
    _dataFormat.mFormatID = kAudioFormatLinearPCM;
    _dataFormat.mSampleRate = self.sampleRate;
    _dataFormat.mChannelsPerFrame = self.channelsPerFrame;
    _dataFormat.mBitsPerChannel = self.bitsPerChannel;
    
    int bytesPerPacket = self.bitsPerChannel / 8;
    _dataFormat.mBytesPerPacket = bytesPerPacket * self.channelsPerFrame;
    _dataFormat.mBytesPerFrame = bytesPerPacket * self.channelsPerFrame;
    
    _dataFormat.mFramesPerPacket = self.framesPerPacket;
    
    _dataFormat.mFormatFlags =
        kLinearPCMFormatFlagIsBigEndian |
        kLinearPCMFormatFlagIsSignedInteger |
        kLinearPCMFormatFlagIsPacked;
    
    _queue = [self queueWithFormat:&_dataFormat];
    if (_queue == NULL) {
        NSLog(@"queueWithFormat Failed");
        return NO;
    }
    
    /*
    error = AudioQueueNewInput(&_dataFormat,
                               SRAudioQueueInputBufferHandler,
                               (__bridge void *)self,
                               NULL,
                               kCFRunLoopCommonModes,
                               0,
                               &_inputQueue);
    if (error != noErr) {
        NSLog(@"AudioQueueNewInput Failed");
        return NO;
    }
     */
    
    // Determine Current Device
    if (self.device) {
        CFStringRef uid = (__bridge CFStringRef)self.device.deviceUID;
        error = AudioQueueSetProperty(_queue, kAudioQueueProperty_CurrentDevice, (void *)uid, sizeof(uid));
        if (error != noErr) {
            NSLog(@"Failed to setup device [%@(%@)]", self.device.deviceUID, self.device.name);
            return NO;
        }
    }
    
    UInt32 dataFormatSize = sizeof(_dataFormat);
    error = AudioQueueGetProperty(_queue,
                                  kAudioConverterCurrentOutputStreamDescription,
                                  &_dataFormat,
                                  &dataFormatSize);
    if (error != noErr) {
        NSLog(@"AudioQueueGetProperty Failed");
        return NO;
    }
    
    _bufferByteSize = self.bufferSize * _dataFormat.mBytesPerPacket;
    for (int i=0; i < SRAudioQueueNumberOfBuffers; ++i) {
        error = AudioQueueAllocateBuffer(_queue, _bufferByteSize, &_buffers[i]);
        if (error != noErr) {
            NSLog(@"AudioQueueAllocateBuffer Failed");
            return NO;
        }
        
        error = AudioQueueEnqueueBuffer(_queue, _buffers[i], 0, NULL);
        if (error != noErr) {
            NSLog(@"AudioQueueEnqueueBuffer Failed");
            return NO;
        }
    }

    _isPrepared = YES;
    return YES;
}

- (BOOL)start {
    OSStatus error = noErr;
    
    _currentPacket = 0;
    error = AudioQueueStart(_queue, NULL);
    if (error != noErr) {
        NSLog(@"AudioQueueStart Failed");
        return NO;
    }
    _isRunning = YES;
    
    return YES;
}

- (BOOL)stop {
    if (_queue == NULL || _isRunning == NO) return YES;
    
    OSStatus error = noErr;
    
    error = AudioQueueStop(_queue, true);
    if (error != noErr) {
        NSLog(@"AudioQueueStop Failed");
        return NO;
    }
    
    _isRunning = NO;
    
    return YES;
}

@end

/*
static void SRAudioQueueInputBufferHandler(void *aqData,
                                           AudioQueueRef inAQ,
                                           AudioQueueBufferRef inBuffer,
                                           const AudioTimeStamp *inStartTime,
                                           UInt32 inNumPackets,
                                           const AudioStreamPacketDescription *inPacketDesc) {
    SRAudioQueue *audioQueue = (__bridge SRAudioQueue *)aqData;
    
    if (inNumPackets == 0 && audioQueue.dataFormat.mBytesPerPacket != 0) {
        inNumPackets = inBuffer->mAudioDataByteSize / audioQueue.dataFormat.mBytesPerPacket;
    }
    
    // TODO
}
*/