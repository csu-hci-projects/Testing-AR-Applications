//
//  PlaneIntersection.swift
//  CS567-Project
//
//  Created by Richard LaFranchi on 10/23/19.
//  Copyright © 2019 Richard LaFranchi. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit

// calculates intersection of two planes
class PlaneIntersection {
    var plane1: simd_float3x3
    var plane2: simd_float3x3
    init(plane1: simd_float3x3, plane2: simd_float3x3) {
        self.plane1 = plane1
        self.plane2 = plane2
    }
    
    // Returns A,B,C,D for plane equation, ex Ax + By + Cz = D
    fileprivate func equation(plane: simd_float3x3) -> simd_float4 {
        let a = plane.columns.0
        let b = plane.columns.1
        let c = plane.columns.2
        let ab = b - a
        let ac = c - a
        let cross = simd_cross(ab, ac)
        let d = -(cross.x*a.x + cross.y*a.y + cross.z*a.z)
        return simd_float4(cross.x, cross.y, cross.z, d)
    }
    
    var eq1: simd_float4 {
        get {
            return equation(plane: plane1)
        }
    }
    
    var eq2: simd_float4 {
        get {
            return equation(plane: plane2)
        }
    }
    
    func pointAt(y: Float) -> simd_float2 {
        let c1 = eq1.y * y
        let c2 = eq2.y * y
        let cMinusd = simd_float2(-eq1.w-c1, -eq2.w-c2)
        let aCVector = simd_float2x2(simd_float2(eq1.x, eq2.x), simd_float2(eq1.z, eq2.z)).inverse
        return aCVector * cMinusd
    }
}
