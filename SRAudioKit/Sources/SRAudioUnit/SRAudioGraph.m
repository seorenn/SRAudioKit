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
@synthesize graph = _graph;

@synthesize isRunning = _running;

- (id)init {
    self = [super init];
    if (self) {
        _graph = NULL;
        _running = NO;
        
        [self initializeGraph];
    }
    return self;
}

- (void)initializeGraph {
    OSStatus error = noErr;
    
    error = NewAUGraph(&_graph);
    NSAssert(error == noErr && _graph != NULL, @"Failed to create AUGraph");

    // TODO
}

- (void)dealloc {
    if (_graph) {
        DisposeAUGraph(_graph);
    }
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
