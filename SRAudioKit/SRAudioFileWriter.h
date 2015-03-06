//
//  SRAudioFileWriter.h
//  SRAudioKit
//
//  Created by Seorenn on 2015. 3. 5..
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(UInt32, SRAudioFileWriterFormat) {
    SRAudioFileWriterFormatAIFF,
    SRAudioFileWriterFormatWAVE
};

@interface SRAudioFileWriter : NSObject

- (id) initWithFileURL:(NSURL *)url
      outputFileFormat:(SRAudioFileWriterFormat)writerFormat
inputStreamDescription:(AudioStreamBasicDescription)inputStreamDescription;

- (BOOL)appendDataFromBufferList:(AudioBufferList *)bufferList withBufferSize:(UInt32)bufferSize;

- (BOOL)close;

@end
