//
//  SRAudioOutput.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 23..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import SRAudioKitPrivates

public class SRAudioOutput {

}

public class SRAudioOutputFile: SRAudioOutput {
    let path: String
    
    public init(path: String) {
        self.path = path
    }
}