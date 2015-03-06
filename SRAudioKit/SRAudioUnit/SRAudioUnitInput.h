//
//  SRAudioUnitInput.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUnit.h"

@class SRAudioDevice;
@class SRAudioUnitInput;

@protocol SRAudioUnitInputDelegate <NSObject>
@optional
- (void)audioUnitInput:(SRAudioUnitInput *)audioUnitInput didTakeBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize numberOfChannels:(UInt32)numberOfChannels;
@end

@interface SRAudioUnitInput : SRAudioUnit

@property (strong)      SRAudioDevice           *audioDevice;
@property (strong)      NSArray                 *inputChannelMap;
@property (assign)      BOOL                    stereo;
@property (assign)      SRAudioBufferFrameSize  bufferFrameSize;
@property (readonly)    UInt32                  bufferByteSize;
@property (readonly)    AudioBufferList         *audioBufferList;

@property (strong)      id<SRAudioUnitInputDelegate>    delegate;

@property (readonly)    BOOL                    isCapturing;

- (void)instantiateAudioUnitWithAudioDevice:(SRAudioDevice *)audioDevice;

- (void)startCapture;
- (void)stopCapture;

@end
