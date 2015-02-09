//
//  SRAudioUtilities.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioUtilities.h"

AudioObjectPropertyAddress AOPADefault(AudioObjectPropertySelector inSelector) {
    AudioObjectPropertyAddress address = {
        inSelector,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    return address;
}

@implementation SRAudioUtilities

@end
