//
//  SRAudioDeviceManager.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioDeviceManager.h"
#import "SRAudioDevice.h"

#pragma mark - C Implementations

static OSStatus getAudioDevices(Ptr *devices, UInt16 *devicesAvailable) {
    OSStatus err = noErr;
    UInt32 dataSize = 0;
    
    AudioObjectPropertyAddress address = {
        kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &address, 0, NULL, &dataSize);
    if (err != noErr) return err;
    
    *devicesAvailable = dataSize / (UInt32)sizeof(AudioObjectID);
    if (*devicesAvailable < 1) {
        // No Devices
        return err;
    }
    
    if (*devices != NULL) free(*devices);
    *devices = (Ptr)malloc(dataSize);
    memset(*devices, 0, dataSize);
    
    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &dataSize, (void *)*devices);
    if (err != noErr) {
        free(*devices);
    }
    
    return err;
}

#pragma mark - Objective-C Class Implementations

@implementation SRAudioDeviceManager

+ (NSArray *)devices {
    AudioObjectID *devices = NULL;
    UInt16 devicesAvailable = 0;
    
    NSMutableArray *deviceArray = [[NSMutableArray alloc] init];
    
    if (getAudioDevices((Ptr *)&devices, &devicesAvailable) != noErr) {
        return nil;
    }
    
    for (int i=0; i < devicesAvailable; i++) {
        UInt16 deviceID = devices[i];
        
        SRAudioDevice *device = [[SRAudioDevice alloc] initWithDeviceID:deviceID];
        [deviceArray addObject:device];
    }
    
    free(devices);
    
    return [deviceArray copy];
}

+ (SRAudioDeviceManager *)sharedManager {
    static dispatch_once_t onceToken;
    static SRAudioDeviceManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[SRAudioDeviceManager alloc] init];
    });
    return instance;
}

@end
