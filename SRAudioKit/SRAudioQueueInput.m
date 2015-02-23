//
//  SRAudioQueueInput.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 23..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioQueueInput.h"

static void SRAudioQueueInputBufferHandler(void *aqData,
                                           AudioQueueRef inAQ,
                                           AudioQueueBufferRef inBuffer,
                                           const AudioTimeStamp *inStartTime,
                                           UInt32 inNumPackets,
                                           const AudioStreamPacketDescription *inPacketDesc);

@interface SRAudioQueueInput ()
@property (assign) AudioStreamBasicDescription dataFormat;
@end

@implementation SRAudioQueueInput

- (AudioQueueRef)queueWithFormat:(AudioStreamBasicDescription *)format {
    AudioQueueRef queue = NULL;
    
    OSStatus error = AudioQueueNewInput(format,
                                        SRAudioQueueInputBufferHandler,
                                        (__bridge void *)self,
                                        NULL,
                                        kCFRunLoopCommonModes,
                                        0,
                                        &queue);
    if (error != noErr) {
        NSLog(@"queueWithFormat Failed");
        return NULL;
    }
    
    return queue;
}

@end

static void SRAudioQueueInputBufferHandler(void *aqData,
                                           AudioQueueRef inAQ,
                                           AudioQueueBufferRef inBuffer,
                                           const AudioTimeStamp *inStartTime,
                                           UInt32 inNumPackets,
                                           const AudioStreamPacketDescription *inPacketDesc) {
    SRAudioQueueInput *audioQueue = (__bridge SRAudioQueueInput *)aqData;
    
    if (inNumPackets == 0 && audioQueue.dataFormat.mBytesPerPacket != 0) {
        inNumPackets = inBuffer->mAudioDataByteSize / audioQueue.dataFormat.mBytesPerPacket;
    }
    
    if (audioQueue.delegate) {
        [audioQueue.delegate audioQueueInput:audioQueue encounterBuffer:inBuffer startTime:inStartTime numPackets:inNumPackets packetDesc:inPacketDesc];
    }
    
    // TODO
}