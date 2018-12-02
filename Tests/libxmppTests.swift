//
//  libxmppTests.swift
//  libxmppTests
//
//  Created by Michael Johnson on 12/1/18.
//  Copyright © 2018 Michael Johnson. All rights reserved.
//

import XCTest
@testable import libxmpp
import dnssd

class BaseTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testSRVResolver() {
        let resolver = Resolver(srvName: "_xmpp-client._tcp.johnson.computer")
        let error = resolver.resolve()
        XCTAssertNil(error)
        XCTAssertGreaterThan(resolver.results.count, 0)
        print("Results: " + String(describing: resolver.results))
    }

    func testSRVResolver2() {
        let resolver = Resolver(srvName: "_xmpp-server._tcp.johnson.computer")
        let error = resolver.resolve()
        XCTAssertNotNil(error)
        guard let serviceError = error as? DNSServiceError else {
            XCTFail("error is not a DNSServiceError")
            return
        }
        XCTAssertEqual(Int(serviceError.errorNumber), kDNSServiceErr_NoSuchRecord)
        XCTAssertEqual(resolver.results.count, 0)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
