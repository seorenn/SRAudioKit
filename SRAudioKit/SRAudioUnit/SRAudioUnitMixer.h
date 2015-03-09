//
//  SRAudioUnitMixer.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUnit.h"

#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SRAudioUnitMixer : SRAudioUnit

@property (nonatomic, assign) UInt32 numberOfBuses;

- (BOOL)setInputStreamFormat:(AudioStreamBasicDescription)format forBusIndex:(UInt32)busIndex;

@end
