//
//  SRAudioDevice.m
//  SRAudioKitDemoForOSX
//
//  Created by Seorenn on 2015. 2. 9..
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import "SRAudioDevice.h"

//#pragma mark - C Implementations
//
//static OSStatus getAudioDevices(Ptr *devices, UInt16 *devicesAvailable) {
//    OSStatus err = noErr;
//    UInt32 dataSize = 0;
//    
//    AudioObjectPropertyAddress address = {
//        kAudioHardwarePropertyDevices,
//        kAudioObjectPropertyScopeGlobal,
//        kAudioObjectPropertyElementMaster
//    };
//    
//    err = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &address, 0, NULL, &dataSize);
//    if (err != noErr) return err;
//    
//    *devicesAvailable = dataSize / (UInt32)sizeof(AudioObjectID);
//    if (*devicesAvailable < 1) {
//        // No Devices
//        return err;
//    }
//    
//    if (*devices != NULL) free(*devices);
//    *devices = (Ptr)malloc(dataSize);
//    memset(*devices, 0, dataSize);
//    
//    err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &address, 0, NULL, &dataSize, (void *)*devices);
//    if (err != noErr) {
//        free(*devices);
//    }
//    
//    return err;
//}

@implementation SRAudioDevice

@synthesize deviceID = _deviceID;
@synthesize name = _name;
@synthesize numberInputChannels = _numberInputChannels;
@synthesize numberOutputChannels = _numberOutputChannels;

//+ (NSArray *)devices {
//    AudioObjectID *devices = NULL;
//    UInt16 devicesAvailable = 0;
//    
//    NSMutableArray *deviceArray = [[NSMutableArray alloc] init];
//    
//    if (getAudioDevices((Ptr *)&devices, &devicesAvailable) != noErr) {
//        return nil;
//    }
//    
//    for (int i=0; i < devicesAvailable; i++) {
//        UInt16 deviceID = devices[i];
//        
//        SRAudioDevice *device = [[SRAudioDevice alloc] initWithDeviceID:deviceID];
//        [deviceArray addObject:device];
//    }
//    
//    free(devices);
//    
//    return [deviceArray copy];
//}

- (id)initWithDeviceID:(AudioDeviceID)deviceID {
    self = [super init];
    if (self) {
        _deviceID = deviceID;
        _name = [self nameOfDevice:deviceID];
        _numberInputChannels = [self inputChannelsOfDevice:deviceID];
        _numberOutputChannels = [self outputChannelsOfDevice:deviceID];
    }
    
    return self;
}

- (NSString *)nameOfDevice:(AudioDeviceID)deviceID {
    AudioObjectPropertyAddress address = {
        kAudioObjectPropertyName,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster
    };
    
    UInt32 ioSize = sizeof(CFStringRef);
    CFStringRef stringRef = NULL;
    OSStatus err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, &stringRef);
    if (err != noErr || stringRef == NULL) {
        // Failed to get name
        return nil;
    }
    
    NSString *name = (__bridge NSString *)stringRef;
    CFRelease(stringRef);
    
    return name;
}

- (UInt32)inputChannelsOfDevice:(AudioDeviceID)deviceID {
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyStreamConfiguration,
        kAudioObjectPropertyScopeInput,
        0
    };
    
    UInt32 ioSize = 0;
    UInt32 result = 0;
    
    OSStatus err = AudioObjectGetPropertyDataSize(deviceID, &address, 0, NULL, &ioSize);
    if (err != noErr || ioSize == 0) {
        // Error or no result
        return 0;
    }
    
    AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
    if (bufferList == NULL) {
        // Insufficient Memory
        return 0;
    }
    
    err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, bufferList);
    if (err != noErr) {
        // Insufficient Memory
        free(bufferList);
        return 0;
    }
        
    for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
        result += bufferList->mBuffers[i].mNumberChannels;
    }
        
    free(bufferList);

    return result;
}

- (UInt32)outputChannelsOfDevice:(AudioDeviceID)deviceID {
    AudioObjectPropertyAddress address = {
        kAudioDevicePropertyStreamConfiguration,
        kAudioObjectPropertyScopeOutput,
        0
    };
    
    UInt32 ioSize = 0;
    UInt32 result = 0;
    
    OSStatus err = AudioObjectGetPropertyDataSize(deviceID, &address, 0, NULL, &ioSize);
    if (err != noErr || ioSize == 0) {
        // Error or no result
        return 0;
    }
    
    AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
    if (bufferList == NULL) {
        // Insufficient Memory
        return 0;
    }
    
    err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, bufferList);
    if (err != noErr) {
        // Insufficient Memory
        free(bufferList);
        return 0;
    }
    
    for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
        result += bufferList->mBuffers[i].mNumberChannels;
    }
    
    free(bufferList);
    
    return result;
}

@end
