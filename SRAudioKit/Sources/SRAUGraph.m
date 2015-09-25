//
//  SRAUGraph.m
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 18..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import "SRAUGraph.h"
#import "SRAudioKitUtils.h"
#import "SRAUNode.h"
#import "SRAudioUnit.h"

#import "TargetConditionals.h"

@import CoreAudio;
@import AudioToolbox;

// Callback Definitions
static OSStatus SRAUGraphNodeInputCallback(void                          *inRefCon,
                                           AudioUnitRenderActionFlags    *ioActionFlags,
                                           const AudioTimeStamp          *inTimeStamp,
                                           UInt32                        inBusNumber,
                                           UInt32                        inNumberFrames,
                                           AudioBufferList               *ioData);

@interface SRAUGraph () {
    AUGraph _graph;
}

@end

@implementation SRAUGraph

#pragma mark - Life Cycle

- (nonnull instancetype)init {
    self = [super init];
    if (self) {
        CheckOSStatus(NewAUGraph(&_graph), @"NewAUGraph");
    }
    return self;
}

- (void)dealloc {
    [self dispose];
}

#pragma mark - Properties Getters 



#pragma mark - AUGraph Wrappers

- (BOOL)initialize {
    return CheckOSStatus(AUGraphInitialize(_graph), @"AUGraphInitialize");
}

- (BOOL)uninitialize {
    return CheckOSStatus(AUGraphUninitialize(_graph), @"AUGraphUninitialize");
}


- (nullable SRAUNode *)addNodeWithAudioComponentDescription:(AudioComponentDescription)audioComponentDescription {
    AUNode node;
    if (CheckOSStatus(AUGraphAddNode(_graph, &audioComponentDescription, &node), @"AUGraphAddNode") == NO) {
        return nil;
    };
    
    /*
    SRAudioUnit *audioUnit = [self nodeInfo:node];
    if (audioUnit == nil) {
        return nil;
    }
     */

    SRAUNode *nodeObject = [[SRAUNode alloc] initWithNode:node audioComponentDescription:audioComponentDescription];
    
    return nodeObject;
}

- (nullable SRAudioUnit *)nodeInfo:(nonnull SRAUNode *)node withAudioComponentDescription:(AudioComponentDescription)audioComponentDescription {
    AudioComponentDescription description;
    AudioUnit audioUnit;
    
    if (CheckOSStatus(AUGraphNodeInfo(_graph, node.node, &description, &audioUnit), @"AUGraphNodeInfo") == NO) {
        return nil;
    }
    
    SRAudioUnit *au = [[SRAudioUnit alloc] initWithAudioUnit:audioUnit];
    return au;
}

- (BOOL)setNodeDelegate:(nonnull id<SRAUNodeDelegate>)delegate destInputNumber:(UInt32)destInputNumber forNode:(nonnull SRAUNode *)node {
    AURenderCallbackStruct callbackStruct;
    callbackStruct.inputProc = SRAUGraphNodeInputCallback;
    callbackStruct.inputProcRefCon = (__bridge void *)node;

    BOOL res = CheckOSStatus(AUGraphSetNodeInputCallback(_graph, node.node, destInputNumber, &callbackStruct), @"AUGraphSetNodeInputCallback");
    if (res) {
        node.delegate = delegate;
    }
    return res;
}

- (BOOL)connectSourceNodeInput:(nonnull SRAUNode *)sourceNode sourceOutputNumber:(UInt32)sourceOutputNumber destNode:(nonnull SRAUNode *)destNode destOutputNumber:(UInt32)destInputNumber {
    return CheckOSStatus(AUGraphConnectNodeInput(_graph, sourceNode.node, sourceOutputNumber, destNode.node, destInputNumber), @"AUGraphConnectNodeInput");
}

- (BOOL)disconnectNodeInput:(nonnull SRAUNode *)destNode destInputNumber:(UInt32)destInputNumber {
    return CheckOSStatus(AUGraphDisconnectNodeInput(_graph, destNode.node, destInputNumber), @"AUGraphDisconnectNodeInput");
}

- (BOOL)removeNode:(nonnull SRAUNode *)node {
    return CheckOSStatus(AUGraphRemoveNode(_graph, node.node), @"AUGraphRemoveNode");
}

- (BOOL)update:(BOOL)synchronize {
    // TODO: This method returns incorrect values by some cases...
    if (synchronize) {
        return CheckOSStatus(AUGraphUpdate(_graph, NULL), @"AUGraphUpdate");
    }
    else {
        Boolean value = false;
        if (CheckOSStatus(AUGraphUpdate(_graph, &value), @"AUGraphUpdate") == NO) {
            return NO;
        }
        
        return value;
    }
    return NO;
}

- (BOOL)open {
    return CheckOSStatus(AUGraphOpen(_graph), @"AUGraphOpen");
}

- (BOOL)start {
    return CheckOSStatus(AUGraphStart(_graph), @"AUGraphStart");
}

- (BOOL)stop {
    return CheckOSStatus(AUGraphStop(_graph), @"AUGraphStop");
}

- (BOOL)close {
    return CheckOSStatus(AUGraphClose(_graph), @"AUGraphClose");
}

- (BOOL)dispose {
    return CheckOSStatus(DisposeAUGraph(_graph), @"DispostAUGraph");
}

@end

static OSStatus SRAUGraphNodeInputCallback(void                          *inRefCon,
                                           AudioUnitRenderActionFlags    *ioActionFlags,
                                           const AudioTimeStamp          *inTimeStamp,
                                           UInt32                        inBusNumber,
                                           UInt32                        inNumberFrames,
                                           AudioBufferList               *ioData) {
    SRAUNode *node = (__bridge SRAUNode *)inRefCon;
    OSStatus error = noErr;
    
    error = AudioUnitRender(node.audioUnit.audioUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, node.audioUnit.audioBufferList);
    
    if (CheckOSStatus(error, @"AudioUnitRender") == NO) {
        return error;
    }
    
    if (node.delegate == nil) return error;
    
    [node.delegate auNode:node
        didTakeBufferList:node.audioUnit.audioBufferList
               bufferSize:inNumberFrames
         numberOfChannels:node.audioUnit.audioStreamBasicDescription.mChannelsPerFrame];
    
    return error;
}

