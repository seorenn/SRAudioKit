//
//  SRAudioConstants.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation

// MARK: - Error Types

public enum SRAudioError: ErrorType {
    case UnknownError
    case GenericError(description: String)
    case OSStatusError(status: OSStatus)
}

// MARK: - Another Types

public enum SRAudioFrameType: Int {
    case Unknown = 0
    case Float32Bit = 1
    case SignedInteger16Bit = 2
}


class SRAudioConstants: NSObject {

}
