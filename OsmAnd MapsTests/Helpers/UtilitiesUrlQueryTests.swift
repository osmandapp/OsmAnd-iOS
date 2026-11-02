// Copyright © 2026 OsmAnd. All rights reserved.

import XCTest

final class UtilitiesUrlQueryTests: XCTestCase {

    func testFlagParameterDoesNotCrashOrDiscardCoordinates() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?lat=45.6313&lon=34.9955&z=8&flag"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "lat": "45.6313",
            "lon": "34.9955",
            "z": "8"
        ])
    }

    func testEmptyQueryPartsAreIgnored() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?&lat=45&&lon=34&"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "lat": "45",
            "lon": "34"
        ])
    }

    func testMissingOrEmptyQueryReturnsEmptyDictionary() throws {
        for urlString in ["osmandmaps://", "osmandmaps://?"] {
            let url = try XCTUnwrap(URL(string: urlString))
            XCTAssertEqual(OAUtilities.parseUrlQuery(url), [:])
        }
    }

    func testEmptyValueIsPreservedAndMissingValueIsIgnored() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?title=&flag&z=8"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "title": "",
            "z": "8"
        ])
    }

    func testLiteralPlusIsSpaceAndEncodedPlusRemainsPlus() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?title=New+York&literal=A%2BB&space=A%20B"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "title": "New York",
            "literal": "A+B",
            "space": "A B"
        ])
    }

    func testEqualsSignsInsideValueArePreserved() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?title=a=b=c"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "title": "a=b=c"
        ])
    }

    func testEncodedSeparatorsDoNotCreateExtraParameters() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?title=a%26b%3Dc&z=8"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "title": "a&b=c",
            "z": "8"
        ])
    }

    func testUnicodeAndEncodedParameterNamesAreDecoded() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?%74itle=%D0%9A%D0%B8%D1%97%D0%B2"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "title": "Київ"
        ])
    }

    func testPercentEncodingIsDecodedOnlyOnce() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?title=%252B"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "title": "%2B"
        ])
    }

    func testLastDuplicateValueWins() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?title=first&title=last&title"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "title": "last"
        ])
    }

    func testEmptyParameterNameIsIgnored() throws {
        let url = try XCTUnwrap(URL(string: "osmandmaps://?=ignored&lat=45"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "lat": "45"
        ])
    }

    func testTileSourceTemplatePreservesNestedQuery() throws {
        let url = try XCTUnwrap(URL(string: "https://osmand.net/add-tile-source?name=Map&url_template=https%3A%2F%2Fexample.com%2F%7Bz%7D%3Ftoken%3Da%3Db%26style%3Dnight&min_zoom=0&max_zoom=18"))
        XCTAssertEqual(OAUtilities.parseUrlQuery(url), [
            "name": "Map",
            "url_template": "https://example.com/{z}?token=a=b&style=night",
            "min_zoom": "0",
            "max_zoom": "18"
        ])
    }
}
