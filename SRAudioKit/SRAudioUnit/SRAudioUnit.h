//
//  SRAudioUnit.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRAudioContants.h"

#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>

@class SRAudioDevice;

@interface SRAudioUnit : NSObject

#pragma mark - Internal Properties

@property (assign) AudioComponentDescription    audioComponentDescription;
@property (assign) AudioStreamBasicDescription  streamFormat;
@property (readonly) AudioUnit                  audioUnit;

#pragma mark - Public Properties

@property (assign) Float64                  sampleRate;
@property (assign) UInt32                   channelsPerFrame;
@property (assign) UInt32                   bytesPerFrame;
@property (assign) BOOL                     interleaved;

#pragma mark - Initializers

- (id)initWithType:(OSType)type subType:(OSType)subType;

#pragma mark - APIs

- (void)instantiateAudioUnit;

#pragma mark - Helpful APIs

- (BOOL)setProperty:(AudioUnitPropertyID)propertyID
              scope:(AudioUnitScope)scope
            element:(AudioUnitElement)element
               data:(const void *)data
           dataSize:(UInt32)dataSize;

- (BOOL)getProperty:(AudioUnitPropertyID)propertyID
              scope:(AudioUnitScope)scope
            element:(AudioUnitElement)element
            outData:(void *)outData
         ioDataSize:(UInt32 *)ioDataSize;

@end
