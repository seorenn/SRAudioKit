//
//  SRAudioBufferSize.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 2..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#ifndef SRAudioKitDemoForOSX_SRAudioBufferSize_h
#define SRAudioKitDemoForOSX_SRAudioBufferSize_h

#import <Foundation/Foundation.h>

typedef NS_ENUM(UInt32, SRAudioBufferSize) {
#if TARGET_OS_IPHONE
    SRAudioBufferSize256Samples = 256,
    SRAudioBufferSize1024Samples = 1024,
    SRAudioBufferSize4096Samples = 4096
#else
    SRAudioBufferSize64Samples = 64,
    SRAudioBufferSize128Samples = 128,
    SRAudioBufferSize256Samples = 256,
    SRAudioBufferSize512Samples = 512,
    SRAudioBufferSize1024Samples = 1024,
    SRAudioBufferSize2048Samples = 2048
#endif
};

#define SRAudioDurationFromBufferSize(bufferSize, sampleRate) (Float64)( (Float64)(bufferSize) / (sampleRate) )

#endif
