//
//  SRAUNode.swift
//  SRAudioKit
//
//  Created by Heeseung Seo on 2015. 9. 24..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

import Foundation
import CoreAudioKit
import AudioToolbox

open class SRAUNode {
    let node: AUNode
    
    public init(node: AUNode) {
        self.node = node
    }
}
