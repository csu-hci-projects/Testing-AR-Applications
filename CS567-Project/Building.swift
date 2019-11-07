//
//  File.swift
//  CS567-Project
//
//  Created by Lafranchi, Richard A on 11/6/19.
//  Copyright © 2019 Richard LaFranchi. All rights reserved.
//

import Foundation
import SceneKit

class Building {
    var corners: [simd_float2];
    init() {
        corners = [];
    }
    
    func addCorner(corner: simd_float2) {
        corners.append(corner);
    }
}
