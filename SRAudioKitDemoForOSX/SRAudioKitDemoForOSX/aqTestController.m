//
//  aqTestController.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 27..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "aqTestController.h"
#import "SRAudioKit.h"

@interface aqTestController () <SRAudioQueueInputDelegate>
@property (strong) SRAudioQueueInput *inputQueue;
@property (strong) SRAudioQueueOutput *outputQueue;
@property (assign) BOOL testingDirectRouting;
@end

@implementation aqTestController

- (id)init {
    self = [super init];
    if (self) {
        self.inputQueue = [[SRAudioQueueInput alloc] init];
        self.inputQueue.delegate = self;
        [self.inputQueue prepare];
        
        self.outputQueue = [[SRAudioQueueOutput alloc] init];
        [self.outputQueue prepare];
    }
    return self;
}

- (void)dealloc {
    [self.inputQueue stop];
    [self.inputQueue dispose];
    
    [self.outputQueue stop];
    [self.outputQueue dispose];
}

- (IBAction)pressedDirectRoutingTest:(id)sender {
    if (self.testingDirectRouting) {
        NSLog(@"Stop!");
        [self.inputQueue stop];
        [self.outputQueue stop];
        self.testingDirectRouting = NO;
    }
    else {
        NSLog(@"Start!");
        [self.inputQueue start];
        [self.outputQueue start];
        self.testingDirectRouting = YES;
    }
}

#pragma mark - SRAudioQueueInputDelegate

- (void)audioQueueInput:(SRAudioQueueInput *)queue encounterBuffer:(AudioQueueBufferRef)bufferRef startTime:(const AudioTimeStamp *)startTime numPackets:(UInt32)numPackets packetDesc:(const AudioStreamPacketDescription *)packetDesc
{
    NSLog(@"AudioQueue Input Buffer: %d byte(s)", bufferRef->mAudioDataByteSize);
}

@end
