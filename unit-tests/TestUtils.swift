//
//  TestUtils.swift
//  unit-tests
//
//  Created by De Wildt van Reenen on 11/7/16.
//  Copyright (c) 2016 Broken-D. All rights reserved.
//

import XCTest

class TestUtilFunctions: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testHashGeneration() {
        // Create sample data to hash
        let src1 = "Some data to hash"
        let src2 = "Some other data to hash"

        // Calculate some hashes
        let hash1 = makeHashSHA1(data: src1)
        XCTAssert(hash1.isEmpty == false, "Hash returned empty string")

        let hash2 = makeHashSHA1(data: src2)
        XCTAssert(hash1.isEmpty == false, "Hash returned empty string")

        let hash3 = makeHashSHA1(data: src1)
        XCTAssert(hash1.isEmpty == false, "Hash returned empty string")

        // Check that they are different for diffent sources
        XCTAssert(hash1 != hash2, "Hash matches for different input")

        // Check that same string is same hash
        XCTAssert(hash1 == hash3, "Same input results in different hashes")

    }

}
