//
//  SRAudioContants.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 6..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#ifndef __SRAudioContants_h__
#define __SRAudioContants_h__

#import <Foundation/Foundation.h>

#define SRAudioSampleRate44100  44100.0
#define SRAudioSampleRate48000  48000.0
#define SRAudioSampleRate96000  96000.0

typedef NS_ENUM(UInt32, SRAudioBufferFrameSize) {
#if TARGET_OS_IPHONE
    SRAudioBufferFrameSize256 =     256,
    SRAudioBufferFrameSize1024 =    1024,
    SRAudioBufferFrameSize4096 =    4096
#else
    SRAudioBufferFrameSize64 =      64,
    SRAudioBufferFrameSize128 =     128,
    SRAudioBufferFrameSize256 =     256,
    SRAudioBufferFrameSize512 =     512,
    SRAudioBufferFrameSize1024 =    1024,
    SRAudioBufferFrameSize2048 =    2048
#endif
};

#if TARGET_OS_IPHONE
#define SRAudioBufferFrameSizeList @[   @SRAudioBufferFrameSize256,     \
                                        @SRAudioBufferFrameSize1024,    \
                                        @SRAudioBufferFrameSize4096 ]
#else
#define SRAudioBufferFrameSizeList @[   @SRAudioBufferFrameSize64,      \
                                        @SRAudioBufferFrameSize128,     \
                                        @SRAudioBufferFrameSize256,     \
                                        @SRAudioBufferFrameSize512,     \
                                        @SRAudioBufferFrameSize1024,    \
                                        @SRAudioBufferFrameSize2048 ]
#endif

typedef NS_ENUM(UInt32, SRAudioFrameType) {
    SRAudioFrameTypeFloat32Bit = 0,
    SRAudioFrameTypeSignedInteger16Bit
};

#endif  //__SRAudioContants_h__
