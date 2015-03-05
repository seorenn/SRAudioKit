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
@property (strong) SRAudioFileOutput *fileOutput;
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
        [self.fileOutput close];
        [self.input stopCapture];
    }
    else {
        NSArray *desktopPaths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
        NSLog(@"Desktop Paths: %@", desktopPaths);
        
        NSString *desktopPath = desktopPaths.firstObject;
        NSLog(@"Desktop Path: %@", desktopPath);
        
        NSString *outputPathString = [desktopPath stringByAppendingPathComponent:@"record.wav"];
        NSLog(@"Output File Path: %@", outputPathString);
        
        NSURL *fileURL = [NSURL fileURLWithPath:outputPathString];
        NSLog(@"Output File URL: %@", fileURL);
        
        self.fileOutput = [[SRAudioFileOutput alloc] initWithFileURL:fileURL outputFileFormat:SRAudioFileOutputFormatWAVE inputStreamDescription:self.input.streamFormat];
        if (self.fileOutput == nil) {
            NSLog(@"Failed to initialize file output");
            return;
        }
        
        [self.input startCapture];
    }
}

- (void)audioInput:(SRAudioInput *)audioInput didTakeBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize numberOfChannels:(UInt32)numberOfChannels {
    NSLog(@"Writing Buffer List with Size: %ld", (long)bufferSize);
    [self.fileOutput appendDataFromBufferList:bufferList withBufferSize:bufferSize];
}

@end
