//
//  SRAudioUnit.h
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 21..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

@class SRAudioUnit;
@class SRAUNode;

@protocol SRAudioUnitDelegate <NSObject>

// TODO
- (void)audioUnit:(nonnull SRAudioUnit *)audioUnit blahBlah:(BOOL)blah;

@end

@interface SRAudioUnit : NSObject

@property (nonnull, nonatomic, readonly) AudioUnit audioUnit;
@property (nonatomic, assign) AudioStreamBasicDescription audioStreamBasicDescription;
@property (nonatomic, assign) UInt32 bufferFrameSize;
@property (nonatomic, readonly) UInt32 bufferByteSize;
@property (nullable, nonatomic, weak) id<SRAudioUnitDelegate> delegate;
@property (nullable, nonatomic, readonly) AudioBufferList *audioBufferList;

- (nonnull instancetype)initWithAudioUnit:(nonnull AudioUnit)audioUnit;

@end
