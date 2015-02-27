//
//  SRAudioQueue.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SRAudioDevice.h"

typedef NS_ENUM(UInt32, SRAudioQueueBufferSize) {
    SRAudioQueueBufferSize64Samples = 64,
    SRAudioQueueBufferSize128Samples = 128,
    SRAudioQueueBufferSize256Samples = 256,
    SRAudioQueueBufferSize512Samples = 512,
    SRAudioQueueBufferSize1024Samples = 1024,
    SRAudioQueueBufferSize2048Samples = 2048
};

@interface SRAudioQueue : NSObject

@property (assign) Float64 sampleRate;
@property (assign) int channelsPerFrame;
@property (assign) int bitsPerChannel;
@property (assign) int framesPerPacket;
@property (assign) SRAudioQueueBufferSize bufferSize;
@property (strong) SRAudioDevice *device;

@end
