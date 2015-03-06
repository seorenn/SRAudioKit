//
//  SRAudioGraph.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioGraph.h"

#import "SRAudioUtilities.h"

@import CoreAudio;
@import AudioToolbox;

@interface SRAudioGraph ()

@end

@implementation SRAudioGraph

@synthesize isRunning = _running;

- (id)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)start {
    if (_running) return;
    
    // TODO
    
    _running = YES;
}

- (void)stop {
    if (_running == NO) return;
    
    // TODO
    
    _running = NO;
}

@end
