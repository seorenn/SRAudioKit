//
//  SRAudioDevice.m
//  SRAudioKitDemoForOSX
//
//  Created by Seorenn on 2015. 2. 9..
//  Copyright (c) 2015 Seorenn. All rights reserved.
//

#import "SRAudioDevice.h"
#import "SRAudioUtilities.h"

@interface SRAudioDevice () {
    NSNumber *_numInput;
    NSNumber *_numOutput;
}

@end

@implementation SRAudioDevice

@synthesize deviceID = _deviceID;
@synthesize name = _name;
@synthesize deviceUID = _deviceUID;

- (id)initWithDeviceID:(AudioDeviceID)deviceID {
    self = [super init];
    if (self) {
        _deviceID = deviceID;
        //[self commonInitialization];
    }
    
    return self;
}

//- (void)commonInitialization {
//    _numberInputChannels = [self inputChannelsOfDevice:_deviceID];
//    _numberOutputChannels = [self outputChannelsOfDevice:_deviceID];
//}

- (NSString *)name {
    if (_name == nil) {
        AudioObjectPropertyAddress address = AOPADefault(kAudioObjectPropertyName);
        
        UInt32 ioSize = sizeof(CFStringRef);
        CFStringRef stringRef = NULL;
        OSStatus err = AudioObjectGetPropertyData(_deviceID, &address, 0, NULL, &ioSize, &stringRef);
        if (err != noErr || stringRef == NULL) {
            // Failed to get name
            return nil;
        }
        
        _name = (__bridge NSString *)stringRef;
        CFRelease(stringRef);
    }
    
    return _name;
}

//- (UInt32)inputChannelsOfDevice:(AudioDeviceID)deviceID {
//    AudioObjectPropertyAddress address = {
//        kAudioDevicePropertyStreamConfiguration,
//        kAudioObjectPropertyScopeInput,
//        0
//    };
//    
//    UInt32 ioSize = 0;
//    UInt32 result = 0;
//    
//    OSStatus err = AudioObjectGetPropertyDataSize(deviceID, &address, 0, NULL, &ioSize);
//    if (err != noErr || ioSize == 0) {
//        // Error or no result
//        return 0;
//    }
//    
//    AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
//    if (bufferList == NULL) {
//        // Insufficient Memory
//        return 0;
//    }
//    
//    err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, bufferList);
//    if (err != noErr) {
//        // Insufficient Memory
//        free(bufferList);
//        return 0;
//    }
//        
//    for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
//        result += bufferList->mBuffers[i].mNumberChannels;
//    }
//        
//    free(bufferList);
//
//    return result;
//}

//- (UInt32)outputChannelsOfDevice:(AudioDeviceID)deviceID {
//    AudioObjectPropertyAddress address = {
//        kAudioDevicePropertyStreamConfiguration,
//        kAudioObjectPropertyScopeOutput,
//        0
//    };
//    
//    UInt32 ioSize = 0;
//    UInt32 result = 0;
//    
//    OSStatus err = AudioObjectGetPropertyDataSize(deviceID, &address, 0, NULL, &ioSize);
//    if (err != noErr || ioSize == 0) {
//        // Error or no result
//        return 0;
//    }
//    
//    AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
//    if (bufferList == NULL) {
//        // Insufficient Memory
//        return 0;
//    }
//    
//    err = AudioObjectGetPropertyData(deviceID, &address, 0, NULL, &ioSize, bufferList);
//    if (err != noErr) {
//        // Insufficient Memory
//        free(bufferList);
//        return 0;
//    }
//    
//    for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
//        result += bufferList->mBuffers[i].mNumberChannels;
//    }
//    
//    free(bufferList);
//    
//    return result;
//}

- (UInt32)numberInputChannels {
    if (_numInput == nil) {
        AudioObjectPropertyAddress address = {
            kAudioDevicePropertyStreamConfiguration,
            kAudioObjectPropertyScopeInput,
            0
        };
        
        UInt32 ioSize = 0;
        UInt32 result = 0;
        
        OSStatus err = AudioObjectGetPropertyDataSize(_deviceID, &address, 0, NULL, &ioSize);
        if (err != noErr || ioSize == 0) {
            // Error or no result
            return 0;
        }
        
        AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
        if (bufferList == NULL) {
            // Insufficient Memory
            return 0;
        }
        
        err = AudioObjectGetPropertyData(_deviceID, &address, 0, NULL, &ioSize, bufferList);
        if (err != noErr) {
            // Insufficient Memory
            free(bufferList);
            return 0;
        }
        
        for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
            result += bufferList->mBuffers[i].mNumberChannels;
        }
        
        free(bufferList);

        _numInput = [NSNumber numberWithInt:result];
    }
    
    return _numInput.intValue;
}

- (UInt32)numberOutputChannels {
    if (_numOutput == nil) {
        AudioObjectPropertyAddress address = {
            kAudioDevicePropertyStreamConfiguration,
            kAudioObjectPropertyScopeOutput,
            0
        };
        
        UInt32 ioSize = 0;
        UInt32 result = 0;
        
        OSStatus err = AudioObjectGetPropertyDataSize(_deviceID, &address, 0, NULL, &ioSize);
        if (err != noErr || ioSize == 0) {
            // Error or no result
            return 0;
        }
        
        AudioBufferList *bufferList = (AudioBufferList *)malloc(ioSize);
        if (bufferList == NULL) {
            // Insufficient Memory
            return 0;
        }
        
        err = AudioObjectGetPropertyData(_deviceID, &address, 0, NULL, &ioSize, bufferList);
        if (err != noErr) {
            // Insufficient Memory
            free(bufferList);
            return 0;
        }
        
        for (int i = 0; i < bufferList->mNumberBuffers; ++i) {
            result += bufferList->mBuffers[i].mNumberChannels;
        }
        
        free(bufferList);

        _numOutput = [NSNumber numberWithInt:result];
    }
    
    return _numOutput.intValue;
}

- (NSString *)deviceUID {
    if (_deviceUID == nil) {
        AudioObjectPropertyAddress address = AOPADefault(kAudioDevicePropertyDeviceUID);
        
        CFStringRef stringRef = NULL;
        UInt32 size = sizeof(CFStringRef);
        
        OSStatus err = AudioObjectGetPropertyData(_deviceID, &address, 0, NULL, &size, &stringRef);
        if (err != noErr || stringRef == NULL) {
            return nil;
        }
        
        _deviceUID = (__bridge NSString *)stringRef;
        CFRelease(stringRef);
    }
    
    return _deviceUID;
}

@end
