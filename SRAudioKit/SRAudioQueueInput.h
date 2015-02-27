//
//  SRAudioQueueInput.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 23..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioQueue.h"

@class SRAudioQueueInput;

@protocol SRAudioQueueInputDelegate <NSObject>

- (void)audioQueueInput:(SRAudioQueueInput *)queue encounterBuffer:(AudioQueueBufferRef)bufferRef startTime:(const AudioTimeStamp *)startTime numPackets:(UInt32)numPackets packetDesc:(const AudioStreamPacketDescription *)packetDesc;

@end



@interface SRAudioQueueInput : SRAudioQueue

@property (nonatomic, weak) id<SRAudioQueueInputDelegate> delegate;

- (BOOL)prepare;

- (BOOL)start;
- (BOOL)stop;

- (BOOL)dispose;

@end
