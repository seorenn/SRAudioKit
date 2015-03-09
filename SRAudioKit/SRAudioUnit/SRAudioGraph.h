//
//  SRAudioGraph.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRAudioContants.h"

#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>

@interface SRAudioGraph : NSObject

@property (readonly) AUGraph graph;

@property (readonly) BOOL isRunning;

- (void)start;
- (void)stop;

@end
