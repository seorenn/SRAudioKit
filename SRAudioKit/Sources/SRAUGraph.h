//
//  SRAUGraph.h
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 18..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#if TARGET_OS_IPHONE
#import <CoreAudio/CoreAudioTypes.h>
#else
#import <CoreAudio/CoreAudio.h>
#endif

@class SRAUNode;
@class SRAudioUnit;

@protocol SRAUNodeDelegate;

@interface SRAUGraph : NSObject

// Wrapper of AUGraphGetNodeCount
@property (nonatomic, readonly) UInt32 nodeCount;

// Wrapper of AUGraphIsInitialized
@property (nonatomic, readonly) BOOL isInitialized;

// Wrapper of AUGraphIsOpen
@property (nonatomic, readonly) BOOL isOpen;

// Wrapper of AUGraphIsRunning
@property (nonatomic, readonly) BOOL isRunning;

#pragma mark - Life Cycle

// Wrapper of NewAUGraph
- (nonnull instancetype)init;

#pragma mark - AUGraph Wrappers

// Wrapper of AUGraphInitialize
- (BOOL)initialize;

// Wrapper of AUGraphUninitialize
- (BOOL)uninitialize;

// Wrapper of AUGraphAddNode
- (nullable SRAUNode *)addNodeWithAudioComponentDescription:(AudioComponentDescription)audioComponentDescription;

// Wrapper of AUGraphNodeInfo
- (nullable SRAudioUnit *)nodeInfo:(nonnull SRAUNode *)node withAudioComponentDescription:(AudioComponentDescription)audioComponentDescription;

// Wrapper of AUGraphSetNodeInputCallback
- (BOOL)setNodeDelegate:(nonnull id<SRAUNodeDelegate>)delegate destInputNumber:(UInt32)destInputNumber forNode:(nonnull SRAUNode *)node;

// Wrapper of AUGraphConnectNodeInput
- (BOOL)connectSourceNodeInput:(nonnull SRAUNode *)sourceNode sourceOutputNumber:(UInt32)sourceOutputNumber destNode:(nonnull SRAUNode *)destNode destOutputNumber:(UInt32)destInputNumber;

// Wrapper of AUGraphDisconnectNodeInput
- (BOOL)disconnectNodeInput:(nonnull SRAUNode *)destNode destInputNumber:(UInt32)destInputNumber;

// Wrapper of AUGraphRemoveNode
- (BOOL)removeNode:(nonnull SRAUNode *)node;

// Wrapper of AUGraphUpdate
- (BOOL)update:(BOOL)synchronize;

// Wrapper of AUGraphOpen
- (BOOL)open;

// Wrapper of AUGraphStart
- (BOOL)start;

// Wrapper of AUGraphStop
- (BOOL)stop;

// Wrapper of AUGraphClose
- (BOOL)close;

// Wrapper of DisposeAUGraph
- (BOOL)dispose;

@end
