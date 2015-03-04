//
//  SRAudioInput.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 2..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRAudioSampleRate.h"
#import "SRAudioBufferSize.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

@class SRAudioDevice;
@class SRAudioInput;

@protocol SRAudioInputDelegate <NSObject>
@optional
- (void)audioInput:(SRAudioInput *)audioInput didTakeFloatAudioBuffer:(float **)buffer withBufferSize:(UInt32)bufferSize numberOfChannels:(UInt32)numberOfChannels;
- (void)audioInput:(SRAudioInput *)audioInput didTakeBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize numberOfChannels:(UInt32)numberOfChannels;
@end

@interface SRAudioInput : NSObject

@property (readonly) SRAudioDevice *device;
@property (readonly) Float64 sampleRate;
@property (readonly) SRAudioBufferSize bufferSize;
@property (readonly) BOOL isCapturing;
@property (readonly) BOOL stereo;

@property (nonatomic, weak) id<SRAudioInputDelegate> delegate;

//- (id)initWithDevice:(SRAudioDevice *)device sampleRate:(Float64)sampleRate bufferSize:(SRAudioBufferSize)bufferSize;
- (id)initWithStereoDevice:(SRAudioDevice *)device
               leftChannel:(UInt32)leftChannel
              rightChannel:(UInt32)rightChannel
                sampleRate:(Float64)sampleRate
                bufferSize:(SRAudioBufferSize)bufferSize;
- (id)initWithMonoDevice:(SRAudioDevice *)device
                 channel:(UInt32)channel
              sampleRate:(Float64)sampleRate
              bufferSize:(SRAudioBufferSize)bufferSize;

- (BOOL)startCapture;
- (BOOL)stopCapture;

@end
