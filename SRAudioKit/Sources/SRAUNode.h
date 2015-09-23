//
//  SRAUNode.h
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 18..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "TargetConditionals.h"
#if TARGET_OS_IPHONE
#import <CoreAudio/CoreAudioTypes.h>
#else
#import <CoreAudio/CoreAudio.h>
#endif

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>

@class SRAUNode;
@class SRAudioUnit;

@protocol SRAUNodeDelegate <NSObject>

- (void)auNode:(nonnull SRAUNode *)node didTakeBufferList:(nonnull AudioBufferList *)bufferList bufferSize:(UInt32)bufferSize numberOfChannels:(UInt32)numberOfChannels;

@end

@interface SRAUNode : NSObject

@property (nonatomic, readonly) AudioComponentDescription audioComponentDescription;
@property (nonatomic, readonly) AUNode node;
@property (nonnull, nonatomic, readonly) SRAudioUnit *audioUnit;

@property (nullable, nonatomic, weak) id<SRAUNodeDelegate> delegate;

- (nonnull instancetype)initWithNode:(AUNode)node audioComponentDescription:(AudioComponentDescription)audioComponentDescription audioUnit:(nonnull SRAudioUnit *)audioUnit;

@end
