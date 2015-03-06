//
//  SRAudioUnitInput.h
//  SRAudioKit
//
//  NOTE: SRAudioUnitInput Implement Audio Unit Typed General Output. (WTF???)
//
//
//  Created by Seorenn on 2015. 3. 6..
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import "SRAudioUnit.h"

@class SRAudioDevice;
@class SRAudioUnitInput;

@protocol SRAudioUnitInputDelegate <NSObject>
@optional
- (void)audioUnitInput:(SRAudioUnitInput *)audioUnitInput
     didTakeBufferList:(AudioBufferList *)bufferList
        withBufferSize:(UInt32)bufferSize
      numberOfChannels:(UInt32)numberOfChannels;
@end

@interface SRAudioUnitInput : SRAudioUnit

@property (nonatomic, strong)   SRAudioDevice           *audioDevice;
@property (nonatomic, strong)   NSArray                 *inputChannelMap;
@property (nonatomic, assign)   BOOL                    stereo;
@property (nonatomic, assign)   SRAudioBufferFrameSize  bufferFrameSize;
@property (readonly)    UInt32                          bufferByteSize;
@property (readonly)    AudioBufferList                 *audioBufferList;
@property (assign)      AudioStreamBasicDescription     inputScopeFormat;
@property (assign)      AudioStreamBasicDescription     outputScopeFormat;

@property (strong)      id<SRAudioUnitInputDelegate>    delegate;

@property (readonly)    BOOL                            isCapturing;

- (void)startCapture;
- (void)stopCapture;

@end
