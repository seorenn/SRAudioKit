//
//  RecordTestController.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 2..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "RecordTestController.h"
#import "SRAudioKit.h"

@interface RecordTestController ()
@property (strong) SRAudioInput *input;
@end

@implementation RecordTestController

- (id)init {
    self = [super init];
    if (self) {
        SRAudioDevice *device = [[SRAudioDeviceManager sharedManager].devices objectAtIndex:1];
        self.input = [[SRAudioInput alloc] initWithDevice:device sampleRate:SRAudioSampleRate44100 bufferSize:SRAudioBufferSize1024Samples];
    }
    return self;
}

- (IBAction)pressedButton:(id)sender {
}

@end
