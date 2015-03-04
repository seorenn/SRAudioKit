//
//  SRAudioInput.m
//  SRAudioKitDemoForOSX
//
//  Created by Heeseung Seo on 2015. 3. 2..
//  Copyright (c) 2015년 Seorenn. All rights reserved.
//

#import "SRAudioInput.h"
#import "SRAudioDevice.h"
#import "SRAudioDeviceManager.h"
#import "SRAudioUtilities.h"

#import <AudioToolbox/AudioToolbox.h>
@import AudioToolbox;

#import <AudioUnit/AudioUnit.h>
@import AudioUnit;

static const AudioUnitScope SRAudioBusInput = 1;
static const AudioUnitScope SRAudioBusOutput = 0;

@interface SRAudioInput () {
    AudioUnit _auHAL;
    AudioUnit _audioUnit;
    AudioStreamBasicDescription _inputScopeFormat;
    AudioStreamBasicDescription _outputScopeFormat;
}
@end

@implementation SRAudioInput

@synthesize device = _device;
@synthesize sampleRate = _sampleRate;
@synthesize bufferSize = _bufferSize;

- (id)initWithDevice:(SRAudioDevice *)device sampleRate:(Float64)sampleRate bufferSize:(SRAudioBufferSize)bufferSize {
    self = [super init];
    if (self) {
        if (device == nil) {
            _device = [SRAudioDeviceManager sharedManager].defaultDevice;
        } else {
            _device = device;
        }
        _sampleRate = sampleRate;
        _bufferSize = bufferSize;
        
        _audioUnit = [self createAudioUnitWithDevice:device];

#if TARGET_OS_MAC
        _inputScopeFormat = [self inputScopeFormatWithAudioUnit:_audioUnit];
        _outputScopeFormat = [self outputScopeFormatWithAudioUnit:_audioUnit];
#endif
    }
    return self;
}

- (void)startCapture {
    
}

- (void)stopCapture {
    
}

#pragma mark - Internal APIs

- (AudioUnit)createAudioUnitWithDevice:(SRAudioDevice *)device {
    AudioComponentDescription description = [self audioComponentDescription];
    AudioComponent component = [self audioComponentWithDescription:description];
    
    AudioUnit audioUnitInstance = [self audioUnitInstanceWithAudioComponent:component];
    
    [self enableInputScopeWithAudioUnit:audioUnitInstance];
    [self disableOutputScopeWithAudioUnit:audioUnitInstance];
    
    [self audioUnit:audioUnitInstance useDevice:device];
    
    return audioUnitInstance;
}

- (AudioStreamBasicDescription)inputScopeFormatWithAudioUnit:(AudioUnit)audioUnit {
    AudioStreamBasicDescription desc;
    UInt32 size = sizeof(desc);
    OSStatus error = AudioUnitGetProperty(audioUnit,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Output,
                                          SRAudioBusInput,
                                          &desc,
                                          &size);
    CheckOSStatusFailure(error, @"AudioUnitGetProperty StreamFormat Output Failed");
    return desc;
}

- (AudioStreamBasicDescription)outputScopeFormatWithAudioUnit:(AudioUnit)audioUnit {
    AudioStreamBasicDescription desc;
    UInt32 size = sizeof(desc);
    OSStatus error = AudioUnitGetProperty(audioUnit,
                                          kAudioUnitProperty_StreamFormat,
                                          kAudioUnitScope_Input,
                                          SRAudioBusInput,
                                          &desc,
                                          &size);
    CheckOSStatusFailure(error, @"AudioUnitGetProperty StreamFormat Input Failed");
    return desc;
}

- (AudioUnit)audioUnitInstanceWithAudioComponent:(AudioComponent)component {
    AudioUnit instance;
    OSStatus error = noErr;
    
    error = AudioComponentInstanceNew(component, &instance);
    CheckOSStatusFailure(error, @"AudioComponentInstanceNew Failed");
    
    return instance;
}

- (void)enableInputScopeWithAudioUnit:(AudioUnit)audioUnit {
    OSStatus error = noErr;
    UInt32 flag = 1;

    error = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, SRAudioBusInput, &flag, sizeof(flag));
    CheckOSStatusFailure(error, @"AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO Input Failed");
}

- (void)disableOutputScopeWithAudioUnit:(AudioUnit)audioUnit {
    OSStatus error = noErr;
#if TARGET_OS_IPHONE
    UInt32 flag = 1;
#else
    UInt32 flag = 0;
#endif
    
    error = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, SRAudioBusOutput, &flag, sizeof(flag));
    CheckOSStatusFailure(error, @"AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO Output Failed");
}

- (AudioComponentDescription)audioComponentDescription {
    AudioComponentDescription description;
    description.componentType = kAudioUnitType_Output;
    description.componentManufacturer = kAudioUnitManufacturer_Apple;
    description.componentFlags = 0;
    description.componentFlagsMask = 0;

#if TARGET_OS_IPHONE
    description.componentSubType = kAudioUnitSubType_RemoteIO;
#elif TARGET_OS_MAC
    description.componentSubType = kAudioUnitSubType_HALOutput;
#endif
    
    return description;
}

- (AudioComponent)audioComponentWithDescription:(AudioComponentDescription)description {
    AudioComponent component = AudioComponentFindNext(NULL, &description);
    NSAssert(component, @"Failed to get AudioComponent");
    return component;
}

- (void)audioUnit:(AudioUnit)audioUnit useDevice:(SRAudioDevice *)device {
    OSStatus error = noErr;
    AudioDeviceID deviceID = device.deviceID;
    
    error = AudioUnitSetProperty(audioUnit, kAudioOutputUnitProperty_CurrentDevice, kAudioUnitScope_Global, SRAudioBusOutput, &deviceID, sizeof(deviceID));
    CheckOSStatusFailure(error, @"Failed to set device")
}

@end
