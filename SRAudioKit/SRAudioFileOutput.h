//
//  SRAudioFileOutput.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 5..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(UInt32, SRAudioFileOutputFormat) {
    SRAudioFileOutputFormatAIFF,
    SRAudioFileOutputFormatWAVE
};

@interface SRAudioFileOutput : NSObject

- (id) initWithFileURL:(NSURL *)url
      outputFileFormat:(SRAudioFileOutputFormat)outputFormat
inputStreamDescription:(AudioStreamBasicDescription)inputStreamDescription;

- (BOOL)appendDataFromBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize;

- (BOOL)close;

@end
