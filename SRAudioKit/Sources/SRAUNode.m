//
//  SRAUNode.m
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 18..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import "SRAUNode.h"
#import "SRAudioUnit.h"

@import CoreAudio;
@import AudioToolbox;
@import AudioUnit;

@interface SRAUNode () {
}

@end

@implementation SRAUNode

@synthesize node = _node;
@synthesize audioComponentDescription = _audioComponentDescription;

- (nonnull instancetype)initWithNode:(AUNode)node audioComponentDescription:(AudioComponentDescription)audioComponentDescription audioUnit:(nonnull SRAudioUnit *)audioUnit {
    self = [super init];
    if (self) {
        _node = node;
        _audioComponentDescription = audioComponentDescription;
        _audioUnit = audioUnit;
    }
    return self;
}


@end
