//
//  SRAudioUtilities.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SRAudioFrameType.h"

#import <CoreAudio/CoreAudio.h>

#define CheckOSStatusFailure(status, description) {    \
    if ((status)) { \
        NSLog(@"%@ (%d)", (description), (status)); \
        exit(1);    \
    }   \
}

AudioObjectPropertyAddress AOPADefault(AudioObjectPropertySelector inSelector);

/**
 @param interleaved     
 When stereo format, interleaved format buffer is sequence of LEFT_FRAME, RIGHT_FRAME, LEFT_FRAME, RIGHT_FRAME, ... 
 But non-interleaved format buffer has left channel only or right channel only per each buffer.
 */
AudioStreamBasicDescription SRAudioGetAudioStreamBasicDescription(BOOL stereo, Float64 sampleRate, SRAudioFrameType frameType, BOOL interleaved, BOOL canonical);
AudioStreamBasicDescription SRAudioGetCanonicalNoninterleavedStreamFormat(BOOL stereo, Float64 sampleRate);

@interface SRAudioUtilities : NSObject

@end
