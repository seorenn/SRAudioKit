//
//  SRAudioDevice.h
//  SRAudioKitDemoForOSX
//
//  Created by Seorenn on 2015. 2. 9..
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>

@interface SRAudioDevice : NSObject

@property (nonatomic, readonly) AudioDeviceID deviceID;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) UInt32 numberInputChannels;
@property (nonatomic, readonly) UInt32 numberOutputChannels;

+ (NSArray *)devices;

- (id)initWithDeviceID:(AudioDeviceID)deviceID;

@end
