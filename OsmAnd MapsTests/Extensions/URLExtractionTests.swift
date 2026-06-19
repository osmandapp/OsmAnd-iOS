//
//  URLExtractionTests.swift
//  OsmAnd MapsTests
//
//  Created by Oleksandr Panchenko on 05.06.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import XCTest

final class URLExtractionTests: XCTestCase {

    func testExtractsMultipleURLsSeparatedBySemicolon() {
        let input = "https://google.com;https://apple.com"

        XCTAssertEqual((input as NSString).extractValidURLs(), [
            "https://google.com",
            "https://apple.com"
        ])
    }

    func testExtractsMultipleURLsSeparatedByCommaAndWhitespace() {
        let input = "google.com, apple.com https://osmand.net"

        XCTAssertEqual((input as NSString).extractValidURLs(), [
            "https://google.com",
            "https://apple.com",
            "https://osmand.net"
        ])
    }

    func testPreservesSemicolonInsideSingleURL() {
        let input = "https://osmand.net/a;b"

        XCTAssertEqual((input as NSString).extractValidURLs(), [
            "https://osmand.net/a;b"
        ])
    }

    func testPreservesCommaInsideSingleURL() {
        let input = "https://google.com/search?q=apple,osmand"

        XCTAssertEqual((input as NSString).extractValidURLs(), [
            "https://google.com/search?q=apple,osmand"
        ])
    }

    func testPreservesNonHTTPURLScheme() {
        let input = "ftp://apple.com;https://osmand.net"

        XCTAssertEqual((input as NSString).extractValidURLs(), [
            "ftp://apple.com",
            "https://osmand.net"
        ])
    }
}
