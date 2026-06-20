//
//  VPNStatusFetcherTests.swift
//  DynamicNotchTests
//
//  Created by Antigravity on 6/19/26.
//

import XCTest
@testable import DynamicNotch

final class VPNStatusFetcherTests: XCTestCase {
    func testParseLastStatusChangeTime() {
        let scutilOutput = """
Connected
Extended Status <dictionary> {
  LastStatusChangeTime : 06/19/2026 23:30:14
  Status : 2
}
"""
        let date = VPNStatusFetcher.parseLastStatusChangeTime(from: scutilOutput)
        XCTAssertNotNil(date)
        
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = 19
        components.hour = 23
        components.minute = 30
        components.second = 14
        
        // We use POSIX / GMT/Local time for comparisons depending on target timezone, 
        // let's verify formatter parses it non-nil and components match POSIX.
        let parsedComponents = calendar.dateComponents(in: TimeZone(identifier: "en_US_POSIX") ?? .current, from: date!)
        XCTAssertEqual(parsedComponents.year, 2026)
        XCTAssertEqual(parsedComponents.month, 6)
        XCTAssertEqual(parsedComponents.day, 19)
        XCTAssertEqual(parsedComponents.hour, 23)
        XCTAssertEqual(parsedComponents.minute, 30)
        XCTAssertEqual(parsedComponents.second, 14)
    }
    
    func testParseLastStatusChangeTimeInvalid() {
        let invalidOutput = "LastStatusChangeTime : invalid-date-string"
        XCTAssertNil(VPNStatusFetcher.parseLastStatusChangeTime(from: invalidOutput))
        
        let missingOutput = "Some other output without key"
        XCTAssertNil(VPNStatusFetcher.parseLastStatusChangeTime(from: missingOutput))
    }
    
    func testParseVPNList() {
        let sampleList = """
Available network connection services in the current set (*=enabled):
* (Connected)      6E1290F7-08DA-4CBB-9C2B-B76A589F563D VPN (com.urban-vpn.mac) "Urban VPN Desktop"              [VPN:com.urban-vpn.mac]
  (Disconnected)   A4F3294E-1C88-4F11-BD5A-336FF2E9109B IPSec ""
"""
        let list = VPNStatusFetcher.parseVPNList(from: sampleList)
        XCTAssertEqual(list.count, 2)
        
        let active = list[0]
        XCTAssertEqual(active.id, "6E1290F7-08DA-4CBB-9C2B-B76A589F563D")
        XCTAssertEqual(active.name, "Urban VPN Desktop")
        XCTAssertTrue(active.isConnected)
        XCTAssertEqual(active.bundleID, "com.urban-vpn.mac")
        
        let inactive = list[1]
        XCTAssertEqual(inactive.id, "A4F3294E-1C88-4F11-BD5A-336FF2E9109B")
        XCTAssertEqual(inactive.name, "A4F3294E-1C88-4F11-BD5A-336FF2E9109B")
        XCTAssertFalse(inactive.isConnected)
        XCTAssertNil(inactive.bundleID)
    }
}
