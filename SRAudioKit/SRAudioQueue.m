//
//  SRAudioQueue.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioQueue.h"

@implementation SRAudioQueue

- (id)init {
    self = [super init];
    if (self) {
        self.sampleRate = 44100.0;
        self.channelsPerFrame = 2;
        self.bitsPerChannel = 16;
        self.framesPerPacket = 1;
        self.bufferSize = SRAudioQueueBufferSize1024Samples;
    }
    return self;
}

@end
