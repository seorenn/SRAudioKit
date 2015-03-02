//
//  SRAudioUtilities.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreAudio/CoreAudio.h>

#define CheckOSStatusFailure(status, description) {    \
    if ((status)) { \
        NSLog(@"%@ (%d)", (description), (status)); \
        exit(1);    \
    }   \
}

AudioObjectPropertyAddress AOPADefault(AudioObjectPropertySelector inSelector);

@interface SRAudioUtilities : NSObject

@end
