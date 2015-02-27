//
//  SRAudioQueueOutput.h
//  SRAudioKitDemoForOSX
//
//  Created by Seorenn on 2015. 2. 27..
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import "SRAudioQueue.h"

@interface SRAudioQueueOutput : SRAudioQueue

@property (readonly) UInt32 bufferByteSize;

- (BOOL)prepare;

- (BOOL)start;

- (BOOL)feedBufferWithData:(NSData *)data;
- (BOOL)feedBuffer:(AudioQueueBufferRef)buffer;

- (BOOL)stop;

- (BOOL)dispose;

@end
