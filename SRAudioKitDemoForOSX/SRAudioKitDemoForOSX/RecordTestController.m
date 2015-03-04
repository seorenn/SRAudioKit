//
//  RecordTestController.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 2..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "RecordTestController.h"
#import "SRAudioKit.h"

@interface RecordTestController () <SRAudioInputDelegate>
@property (strong) SRAudioInput *input;
@end

@implementation RecordTestController

- (id)init {
    self = [super init];
    if (self) {
        self.input = [[SRAudioInput alloc] initWithStereoDevice:nil leftChannel:0 rightChannel:1 sampleRate:SRAudioSampleRate44100 bufferSize:SRAudioBufferSize1024Samples];
        if (self.input == nil) {
            NSLog(@"Failed to initialize SRAudioInput");
        } else {
            self.input.delegate = self;
        }
    }
    return self;
}

- (IBAction)pressedButton:(id)sender {
    if (self.input == nil) return;
    
    if (self.input.isCapturing) {
        [self.input stopCapture];
    }
    else {
        [self.input startCapture];
    }
}

@end
