//
//  SRAudioQueueInput.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 23..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioQueueInput.h"

@import AudioToolbox;

#define SRAudioQueueInputNumberOfBuffers    3

static void SRAudioQueueInputBufferHandler(void *aqData,
                                           AudioQueueRef inAQ,
                                           AudioQueueBufferRef inBuffer,
                                           const AudioTimeStamp *inStartTime,
                                           UInt32 inNumPackets,
                                           const AudioStreamPacketDescription *inPacketDesc);

@interface SRAudioQueueInput () {
    AudioStreamBasicDescription _dataFormat;
    AudioQueueRef               _queue;
    AudioQueueBufferRef         _buffers[SRAudioQueueInputNumberOfBuffers];
    AudioFileID                 _audioFile;
    UInt32                      _bufferByteSize;
    SInt64                      _currentPacket;
    BOOL                        _isRunning;
    BOOL                        _isPrepared;
}
@property (assign) AudioStreamBasicDescription dataFormat;
@property (readonly) BOOL isRunning;
@property (readonly) BOOL isPrepared;
@end

@implementation SRAudioQueueInput

@synthesize dataFormat = _dataFormat;
@synthesize isRunning = _isRunning;
@synthesize isPrepared = _isPrepared;

- (id)init {
    self = [super init];
    if (self) {
        _queue = NULL;
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
    
    error = AudioQueueNewInput(&_dataFormat,
                               SRAudioQueueInputBufferHandler,
                               (__bridge void *)self,
                               NULL,
                               kCFRunLoopCommonModes,
                               0,
                               &_queue);
    if (error != noErr) {
        NSLog(@"AudioQueueNewInput Failed");
        return NO;
    }
    
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
    for (int i=0; i < SRAudioQueueInputNumberOfBuffers; ++i) {
        error = AudioQueueAllocateBuffer(_queue, _bufferByteSize, &_buffers[i]);
        if (error != noErr) {
            NSLog(@"AudioQueueAllocateBuffer Failed");
            return NO;
        }
        
//        error = AudioQueueEnqueueBuffer(_queue, _buffers[i], 0, NULL);
//        if (error != noErr) {
//            NSLog(@"AudioQueueEnqueueBuffer Failed");
//            return NO;
//        }
    }
    
    _isPrepared = YES;
    return YES;
}

- (BOOL)start {
    if (_isRunning) return YES;
    
    OSStatus error = noErr;
    
    _currentPacket = 0;
    error = AudioQueueStart(_queue, NULL);
    if (error != noErr) {
        NSLog(@"AudioQueueStart Failed");
        return NO;
    }
    
    _isRunning = YES;
    
    for (int i=0; i < SRAudioQueueInputNumberOfBuffers; ++i) {
        error = AudioQueueEnqueueBuffer(_queue, _buffers[i], 0, NULL);
        if (error != noErr) {
            NSLog(@"AudioQueueEnqueueBuffer Failed");
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)stop {
    if (_queue == NULL || _isRunning == NO) return YES;
    
    _isRunning = NO;
    
    OSStatus error = noErr;
    
    error = AudioQueueStop(_queue, true);
    if (error != noErr) {
        NSLog(@"AudioQueueStop Failed");
        return NO;
    }
    
    return YES;
}

@end

static void SRAudioQueueInputBufferHandler(void *aqData,
                                           AudioQueueRef inAQ,
                                           AudioQueueBufferRef inBuffer,
                                           const AudioTimeStamp *inStartTime,
                                           UInt32 inNumPackets,
                                           const AudioStreamPacketDescription *inPacketDesc) {
    SRAudioQueueInput *audioQueue = (__bridge SRAudioQueueInput *)aqData;
    
//    if (inNumPackets == 0 && audioQueue.dataFormat.mBytesPerPacket != 0) {
//        inNumPackets = inBuffer->mAudioDataByteSize / audioQueue.dataFormat.mBytesPerPacket;
//    }
    
    if (audioQueue.delegate) {
        [audioQueue.delegate audioQueueInput:audioQueue encounterBuffer:inBuffer startTime:inStartTime numPackets:inNumPackets packetDesc:inPacketDesc];
    }
    
    if (audioQueue.isRunning) {
        OSStatus error = AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
        if (error) {
            NSLog(@"AudioQueueEnqueueBuffer Failed(%ld) for reenqueue...", (long)error);
            return;
        }
    }
}