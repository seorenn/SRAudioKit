//
//  SRAudioDeviceManager.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 2. 9..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioDeviceManager.h"
#import "SRAudioDevice.h"
#import "SRAudioUtilities.h"

#import <CoreAudio/CoreAudio.h>

#pragma mark - C Implementations

static OSStatus getAudioDevices(Ptr *devices, UInt16 *devicesAvailable) {
    OSStatus err = noErr;
    UInt32 dataSize = 0;
    
    AudioObjectPropertyAddress address = AOPADefault(kAudioHardwarePropertyDevices);
    
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

OSStatus propertyListenerProc(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[], void *inClientData) {
    SRAudioDeviceManager *managerInstance = (__bridge SRAudioDeviceManager *)inClientData;
    
    for (UInt32 i=0; i < inNumberAddresses; i++) {
        switch (inAddresses[i].mSelector) {
            case kAudioHardwarePropertyDefaultInputDevice:
                NSLog(@"Default Input Device");
                // TODO
                break;
                
            case kAudioHardwarePropertyDefaultOutputDevice:
                NSLog(@"Default Output Device");
                // TODO
                break;
                
            case kAudioHardwarePropertyDefaultSystemOutputDevice:
                NSLog(@"Default System Output Device");
                // TODO
                break;
                
            case kAudioHardwarePropertyDevices:
                NSLog(@"Devices");
                [managerInstance refreshDevices];
                break;
                
            default:
                NSLog(@"Unknown Message");
                // TODO
                break;
        }
    }
    
    return noErr;
}

#pragma mark - Objective-C Class Implementations

@implementation SRAudioDeviceManager

@synthesize devices = _devices;

+ (SRAudioDeviceManager *)sharedManager {
    static dispatch_once_t onceToken;
    static SRAudioDeviceManager *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[SRAudioDeviceManager alloc] init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if (self) {
        [self refreshDevices];
        
        // Add Property Listener
        
        AudioObjectPropertyAddress address = AOPADefault(kAudioHardwarePropertyDevices);
        AudioObjectAddPropertyListener(kAudioObjectSystemObject, &address, propertyListenerProc, (__bridge void *)self);
    }
    return self;
}

- (void)dealloc {
    AudioObjectPropertyAddress address = AOPADefault(kAudioHardwarePropertyDevices);
    AudioObjectRemovePropertyListener(kAudioObjectSystemObject, &address, propertyListenerProc, (__bridge void *)self);
}

- (void)refreshDevices {
    _devices = [self generateDevices];
}

- (NSArray *)generateDevices {
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

@end
