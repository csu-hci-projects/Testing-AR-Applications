//
//  CS567_ProjectTests.swift
//  CS567-ProjectTests
//
//  Created by Richard LaFranchi on 10/2/19.
//  Copyright © 2019 Richard LaFranchi. All rights reserved.
//

import XCTest
import ARKit
@testable import CS567_Project

class CS567_ProjectTests: XCTestCase {
    var plane2:simd_float3x3!
    var plane1:simd_float3x3!

    override func setUp() {
        super.setUp()
        
        let point1 = simd_float3(1,2,-2)
        let point2 = simd_float3(3,-2,1)
        let point3 = simd_float3(5,1,-4)
        let point4 = simd_float3(5,1,0)
        plane1 = simd_float3x3(point1, point2, point3)
        plane2 = simd_float3x3(point1, point2, point4)
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEquation1() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let planeInt = PlaneIntersection(plane1: plane1, plane2: plane2)
        let eq1 = planeInt.eq1
        XCTAssert(eq1.x == 11)
        XCTAssert(eq1.y == 16)
        XCTAssert(eq1.z == 14)
        XCTAssert(eq1.w == -15)
    }
    
    func testEquation2() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let planeInt = PlaneIntersection(plane1: plane1, plane2: plane2)
        let eq1 = planeInt.eq2
        XCTAssert(eq1.x == -5)
        XCTAssert(eq1.y == 8)
        XCTAssert(eq1.z == 14)
        XCTAssert(eq1.w == 17)
    }
    
    func testIntersectPoint1() {
        let planeInt = PlaneIntersection(plane1: plane1, plane2: plane2)
        let intersect = planeInt.pointAt(y: 2)
        XCTAssert(intersect.x == 1)
        XCTAssert(intersect.y == -2)
    }
    
    func testIntersectPoint2() {
        let planeInt = PlaneIntersection(plane1: plane1, plane2: plane2)
        let intersect = planeInt.pointAt(y: -2)
        XCTAssert(intersect.x == 3)
        XCTAssert(intersect.y == 1)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
