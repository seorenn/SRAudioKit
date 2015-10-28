//
//  SRAudioUnitHAL.swift
//  Special Cases of Audio Unit
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 10. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import AudioToolbox
import CoreAudio

public class SRAudioUnitHAL: SRAudioUnit {
    public var outputStreamFormat: AudioStreamBasicDescription? {
        // Getter only
        // AUHAL, Output Scope, Element 0
        
        do {
            return try self.getStreamFormat(kAudioUnitScope_Output, bus: 0)
        }
        catch let error as SRAudioError {
            print("[ERROR] SRAudioUnitHAL.outputStreamFormat: \(error)")
            return nil
        }
        catch {
            print("[ERROR] SRAudioUnitHAL.outputStreamFormat: Unknown Exception")
            return nil
        }
    }
    
    public var inputStreamFormat: AudioStreamBasicDescription? {
        // AUHAL, Input Scope, Element 1
        set {
            do {
                try self.setStreamFormat(newValue!, scope: kAudioUnitScope_Input, bus: 1)
            }
            catch let error as SRAudioError {
                print("[ERROR] SRAudioUnitHAL.inputStreamFormat(set): \(error)")
            }
            catch {
                print("[ERROR] SRAudioUnitHAL.inputStreamFormat(set): Unknown Exception")
            }
        }
        get {
            do {
                return try self.getStreamFormat(kAudioUnitScope_Input, bus: 1)
            }
            catch let error as SRAudioError {
                print("[ERROR] SRAudioUnitHAL.inputStreamFormat(get): \(error)")
                return nil
            }
            catch {
                print("[ERROR] SRAudioUnitHAL.inputStreamFormat(get): Unknown Exception")
                return nil
            }
        }
    }
    
    internal var inputDeviceObject: SRAudioDevice? = nil
    public var inputDevice: SRAudioDevice? {
        set {
            do {
                guard let device = newValue else { return }
                try self.setDevice(device, bus: 0)
                self.inputDeviceObject = device
            }
            catch let error as SRAudioError {
                print("[ERROR] SRAudioUnitHAL.inputDevice(set): \(error)")
            }
            catch {
                print("[ERROR] SRAudioUnitHAL.inputDevice(set): Unknown Exception")
            }
        }
        get {
            do {
                return try self.getDevice(0)
            }
            catch let error as SRAudioError {
                print("[ERROR] SRAudioUnitHAL.inputDevice(get): \(error)")
                return nil
            }
            catch {
                print("[ERROR] SRAudioUnitHAL.inputDevice(get): Unknown Exception")
                return nil
            }
        }
    }
    
    // TODO: Implement Output Device Properties
    
    public var inputDeviceChannelMap: [Int32]? {
        set {
            do {
                guard let map = newValue else { return }
                try self.setChannelMap(map, scope: kAudioUnitScope_Output, bus: 1)
            }
            catch let error as SRAudioError {
                print("[ERROR] SRAudioUnitHAL.inputDeviceChannelMap(set): \(error)")
            }
            catch {
                print("[ERROR] SRAudioUnitHAL.inputDeviceChannelMap(set): Unknown Exception")
            }
        }
        get {
            do {
                guard let device = self.inputDevice else {
                    print("[ERROR] SRAudioUnitHAL.inputDeviceChannelMap(get): No Device Information.")
                    return nil
                }
                
                return try self.getChannelMap(device.numberInputChannels, scope: kAudioUnitScope_Output, bus: 1)
            }
            catch let error as SRAudioError {
                print("[ERROR] SRAudioUnitHAL.inputDeviceChannelMap(get): \(error)")
                return nil
            }
            catch {
                print("[ERROR] SRAudioUnitHAL.inputDeviceChannelMap(get): Unknown Exception")
                return nil
            }
        }
    }
}
