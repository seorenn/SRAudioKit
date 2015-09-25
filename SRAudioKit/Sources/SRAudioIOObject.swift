//
//  SRAudioIOObject.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudio
import AudioToolbox

public class SRAudioIOObject {
    public var audioStreamBasicDescription = AudioStreamBasicDescription()
    
    /**
    You must override this getter
    */
    public var componentDescription: AudioComponentDescription {
        return AudioComponentDescription()
    }
    
    /**
    You must override this method
    */
    public func configure(node: AUNode, audioUnit: AudioUnit) { }
}
