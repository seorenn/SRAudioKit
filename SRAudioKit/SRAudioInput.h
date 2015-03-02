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

@class SRAudioDevice;

@interface SRAudioInput : NSObject

@property (readonly) SRAudioDevice *device;
@property (readonly) Float64 sampleRate;
@property (readonly) SRAudioBufferSize bufferSize;

- (id)initWithDevice:(SRAudioDevice *)device sampleRate:(Float64)sampleRate bufferSize:(SRAudioBufferSize)bufferSize;

@end
