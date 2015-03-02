//
//  SRAudioDeviceManager.h
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SRAudioDevice;

@interface SRAudioDeviceManager : NSObject

@property (nonatomic, readonly) NSArray *devices;
@property (nonatomic, readonly) SRAudioDevice *defaultDevice;

+ (SRAudioDeviceManager *)sharedManager;

- (void)refreshDevices;

@end
