//
//  SRAudioUtils.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudioKit
import AudioToolbox

public enum SRAudioError: ErrorType {
    case UnknownError
    case GenericError(description: String)
    case OSStatusError(status: OSStatus)
}

func SRAudioGenErrorDescription(status: OSStatus, description: String?) -> String {
    if let description = description {
        return "Status(\(status)) Description: \(description)"
    } else {
        return "\(status)"
    }
}

public func SRAudioAssert(status: OSStatus, description: String? = nil) throws {
    if (status != noErr) {
        throw SRAudioError.GenericError(description: SRAudioGenErrorDescription(status, description: description))
    }
}

enum SRAUGraphError: String, ErrorType {
    case Unknown = "Unknown Error"
    case NodeNotFound = "Node Not Found"
    case InvalidConnection = "Invalid Connection"
    case OutputNodeError = "Output Node Error"
    case CannotDoInCurrentContext = "Cannot Do In Current Context"
    case InvalidAudioUnit = "Invalid Audio Unit"
}

public func SRAUGraphAssert(status: OSStatus) throws {
    switch (status) {
    case noErr:
        return
    case kAUGraphErr_NodeNotFound:
        throw SRAUGraphError.NodeNotFound
    case kAUGraphErr_InvalidConnection:
        throw SRAUGraphError.InvalidConnection
    case kAUGraphErr_OutputNodeErr:
        throw SRAUGraphError.OutputNodeError
    case kAUGraphErr_CannotDoInCurrentContext:
        throw SRAUGraphError.CannotDoInCurrentContext
    case kAUGraphErr_InvalidAudioUnit:
        throw SRAUGraphError.InvalidAudioUnit
    default:
        throw SRAUGraphError.Unknown
    }
}

class SRAudioUtils: NSObject {

}
