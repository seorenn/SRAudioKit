//
//  SRAudioQueueOutput.m
//  SRAudioKitDemoForOSX
//
//  Created by Seorenn on 2015. 2. 27..
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import "SRAudioQueueOutput.h"

#include <pthread.h>

#define SRAudioQueueOutputNumberOfBuffers   3

static void SRAudioQueueOutputBufferHandler(void *inUserData,
                                            AudioQueueRef inAQ,
                                            AudioQueueBufferRef inBuffer);

typedef struct _buffer_box_t_ {
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    AudioQueueBufferRef buffer;
    BOOL full;
} SRAudioQueueOutputBuffer;

@interface SRAudioQueueOutput () {
    AudioStreamBasicDescription _dataFormat;
    AudioQueueRef               _queue;
    //AudioQueueBufferRef         _buffers[SRAudioQueueOutputNumberOfBuffers];
    SRAudioQueueOutputBuffer    _buffers[SRAudioQueueOutputNumberOfBuffers];
    AudioFileID                 _audioFile;
    UInt32                      _bufferByteSize;
    SInt64                      _currentPacket;
    BOOL                        _isRunning;
    BOOL                        _isPrepared;
}
@property (assign) AudioStreamBasicDescription dataFormat;
@end

@implementation SRAudioQueueOutput

@synthesize dataFormat = _dataFormat;
@synthesize bufferByteSize = _bufferByteSize;

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
    
    if (_isPrepared) {
        for (int i=0; i < SRAudioQueueOutputNumberOfBuffers; ++i) {
            pthread_mutex_destroy(&_buffers[i].mutex);
            pthread_cond_destroy(&_buffers[i].cond);
        }
    }
    
    _isPrepared = NO;
    
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
    
    error = AudioQueueNewOutput(&_dataFormat,
                                SRAudioQueueOutputBufferHandler,
                                (__bridge void *)self,
                                NULL,
                                kCFRunLoopCommonModes,
                                0,
                                &_queue);
    if (error != noErr) {
        NSLog(@"AudioQueueNewOutput Failed");
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
    
    /*
    UInt32 dataFormatSize = sizeof(_dataFormat);
    error = AudioQueueGetProperty(_queue,
                                  kAudioConverterCurrentOutputStreamDescription,
                                  &_dataFormat,
                                  &dataFormatSize);
    if (error != noErr) {
        NSLog(@"AudioQueueGetProperty Failed");
        return NO;
    }
     */
    
    _bufferByteSize = self.bufferSize * _dataFormat.mBytesPerPacket;
    for (int i=0; i < SRAudioQueueOutputNumberOfBuffers; ++i) {
        memset(&_buffers[i], 0, sizeof(SRAudioQueueOutputBuffer));
        
        error = AudioQueueAllocateBuffer(_queue, _bufferByteSize, &_buffers[i].buffer);
        if (error != noErr) {
            NSLog(@"AudioQueueAllocateBuffer Failed");
            return NO;
        }
        
        int res = pthread_mutex_init(&_buffers[i].mutex, NULL);
        if (res) {
            NSLog(@"pthread_mutex_init Failed");
            return NO;
        }
        
        res = pthread_cond_init(&_buffers[i].cond, NULL);
        if (res) {
            NSLog(@"pthread_cond_init Failed");
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

- (SRAudioQueueOutputBuffer *)bufferOnReady {
    // TODO
    return NULL;
}

- (void)makeReadyBuffer:(AudioQueueBufferRef)buffer {
    SRAudioQueueOutputBuffer *targetBuffer = NULL;
    for (int i=0; i < SRAudioQueueOutputNumberOfBuffers; ++i) {
        if (_buffers[i].buffer == buffer) {
            targetBuffer = &_buffers[i];
            break;
        }
    }
    
    if (targetBuffer == NULL) {
        NSLog(@"Failed to get buffer from bufferRef");
        return;
    }
    
    pthread_mutex_lock(&targetBuffer->mutex);
    
    targetBuffer->full = NO;
    
    pthread_mutex_unlock(&targetBuffer->mutex);
    pthread_cond_signal(&targetBuffer->cond);
}

- (BOOL)feedBufferWithData:(NSData *)data {
    // TODO
    return NO;
}

- (BOOL)feedBuffer:(AudioQueueBufferRef)buffer {
    // TODO
    return NO;
}

@end

static void SRAudioQueueOutputBufferHandler(void *inUserData,
                                            AudioQueueRef inAQ,
                                            AudioQueueBufferRef inBuffer) {
    SRAudioQueueOutput *audioQueue = (__bridge SRAudioQueueOutput *)inUserData;
    [audioQueue makeReadyBuffer:inBuffer];
}
