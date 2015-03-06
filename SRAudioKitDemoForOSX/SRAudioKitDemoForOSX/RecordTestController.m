//
//  RecordTestController.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 2..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "RecordTestController.h"
#import "SRAudioKit.h"

@interface RecordTestController () <SRAudioUnitInputDelegate>
@property (strong) SRAudioUnitInput *input;
@property (strong) SRAudioFileWriter *fileOutput;
@end

@implementation RecordTestController

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (IBAction)pressedButton:(id)sender {
    if (self.input.isCapturing) {
        [self.fileOutput close];
        [self.input stopCapture];
        
        self.input = nil;
        self.fileOutput = nil;
    }
    else {
        /*
        self.input = [[SRAudioInput alloc] initWithStereoDevice:nil leftChannel:0 rightChannel:1 sampleRate:SRAudioSampleRate44100 bufferSize:SRAudioBufferFrameSize1024Samples];
        if (self.input == nil) {
            NSLog(@"Failed to initialize SRAudioInput");
        } else {
            self.input.delegate = self;
        }
         */
        self.input = [[SRAudioUnitInput alloc] init];
        self.input.audioDevice = [SRAudioDeviceManager sharedManager].defaultDevice;
        self.input.sampleRate = SRAudioSampleRate44100;
        self.input.bufferFrameSize = SRAudioBufferFrameSize1024;
        self.input.stereo = YES;
        
        [self.input instantiate];
        
        NSLog(@"SRAudioInput Initialized with Buffer Size: %d", self.input.bufferByteSize);
        
        

        NSArray *desktopPaths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
        NSLog(@"Desktop Paths: %@", desktopPaths);
        
        NSString *desktopPath = desktopPaths.firstObject;
        NSLog(@"Desktop Path: %@", desktopPath);
        
        NSString *outputPathString = [desktopPath stringByAppendingPathComponent:@"record.wav"];
        NSLog(@"Output File Path: %@", outputPathString);
        
        NSURL *fileURL = [NSURL fileURLWithPath:outputPathString];
        NSLog(@"Output File URL: %@", fileURL);
        
        self.fileOutput = [[SRAudioFileWriter alloc] initWithFileURL:fileURL outputFileFormat:SRAudioFileWriterFormatWAVE inputStreamDescription:self.input.streamFormat];
        if (self.fileOutput == nil) {
            NSLog(@"Failed to initialize file output");
            return;
        }
        
        [self.input startCapture];
    }
}

- (void)audioUnitInput:(SRAudioUnitInput *)audioUnitInput didTakeBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize numberOfChannels:(UInt32)numberOfChannels {
    NSLog(@"Writing Buffer List with Size: %ld", (long)bufferSize);
    [self.fileOutput appendDataFromBufferList:bufferList withBufferSize:bufferSize];
}

@end
