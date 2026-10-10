import XCTest
import OsmAndShared
@testable import OsmAnd_Maps

@MainActor
final class AmenityCardRowsTests: XCTestCase {

    private static let knownColonKey = "authentication:phone_call:number"
    private static let customKey = "test:country"

    func testKnownColonKeyUsesExistingPoiResolution() {
        let rows = buildRows([Self.knownColonKey: "+380441234567"])
        let row = rows[Self.knownColonKey]
        XCTAssertNotNil(row)
        XCTAssertEqual(row?.typeName, "authentication_phone_call_number")
        XCTAssertEqual(row?.isText, true)
    }

    func testUnknownStoredKeyUsesGenericFallback() {
        let extensions = [Self.customKey: "United States", "test:state": "Virginia",
                          "test:telephone": "+1 804 828 0100", "test:postcode": "23284", "test:start_date": "1838"]
        let rows = buildRows(extensions)
        for (key, value) in extensions {
            XCTAssertEqual(rows[key]?.text, value, key)
        }
        XCTAssertEqual(rows[Self.customKey]?.textPrefix, "Country")
    }

    func testGarminWaypointAddressGetsRowsWithValues() {
        let extensions = ["gpxx:street_address": "Schoodic Loop Rd", "gpxx:city": "Winter Harbor Twn",
                          "gpxx:state": "Maine", "gpxx:country": "United States", "gpxx:postal_code": "04693",
                          "phone": "207-288-1300"]
        let rows = buildRows(extensions)
        for (key, value) in extensions {
            XCTAssertEqual(rows[key]?.text, value, key)
        }
        XCTAssertEqual(rows["gpxx:street_address"]?.textPrefix, "Street address")
        XCTAssertEqual(rows["gpxx:postal_code"]?.textPrefix, "Postal code")
        XCTAssertEqual(rows["phone"]?.isPhoneNumber, true)
    }

    func testCustomKeyCollidingWithPoiRuleGetsGenericRow() {
        let rows = buildRows(["phone:custom": "value"])
        XCTAssertEqual(rows["phone:custom"]?.text, "value")
    }

    func testUnknownKeyWithoutGenericRowIsNotShown() {
        let rows = buildRows(["unknown:amenity:field": "internal value"], genericRowKeysFrom: [:])
        XCTAssertNil(rows["unknown:amenity:field"])
    }

    func testInternalPointFieldsAreNotShown() {
        let extensions = ["hidden": "true", "visited_date": "2024-01-01T00:00:00Z", "offset": "1",
                          Self.customKey: "United States"]
        let rows = buildRows(extensions)
        XCTAssertNil(rows["hidden"])
        XCTAssertNil(rows["visited_date"])
        XCTAssertNil(rows["offset"])
        XCTAssertNotNil(rows[Self.customKey])
    }

    func testNoInternalPointFieldIsTreatedAsCustom() {
        let serviceFields = ["hidden": "true", "address": "address", "pickup_date": "2024-01-01T00:00:00Z",
                        "visited_date": "2024-01-01T00:00:00Z", "creation_date": "2024-01-01T00:00:00Z",
                        "calendar_event": "true", "icon": "special_star", "background": "circle",
                        "color": "#ffff0000", "amenity_origin": "origin", "osm_url": "url", "pinned": "true"]
        XCTAssertEqual(genericRowKeys(serviceFields), [])
    }

    func testUnknownUnprefixedFieldUsesGenericFallback() {
        let rows = buildRows(["unknown_point_field": "value"])
        XCTAssertEqual(rows["unknown_point_field"]?.text, "value")
    }

    func testGenericFallbackShowsStoredValueAsIs() {
        let rows = buildRows(["test:reference": "abc_def"])
        XCTAssertEqual(rows["test:reference"]?.text, "abc_def")
    }

    func testCustomFieldMatchingAmenityFilterIsStillNotShown() {
        let rows = buildRows(["test:route_id": "1234"])
        XCTAssertNil(rows["test:route_id"])
    }

    func testKnownFilterOnlyPoiFieldIsNotShown() {
        let rows = buildRows(["osmand_socket_type2": "yes"])
        XCTAssertNil(rows["osmand_socket_type2"])
    }

    func testStoredAmenityMetadataDoesNotUseGenericFallback() {
        let rows = buildRows(["osm_tag_top_index_brand": "Internal brand index"])
        XCTAssertNil(rows["top_index_brand"])
    }

    func testGroupsAndTranslationsOfAPoiPoint() {
        let rows = buildRows(["amenity_type": "sustenance", "amenity_subtype": "fast_food",
                              "collapsable_payment_type": "payment_cash_yes;payment_visa_yes",
                              "collapsable_air_conditioning": "air_conditioning_yes",
                              "osm_tag_brand": "McD", "osm_tag_brand:en": "McD en", "osm_tag_brand:uk": "McD uk",
                              "osm_tag_delivery_yes": "yes"])
        XCTAssertEqual(rows["payment_type"]?.textPrefix, "Payment type")
        XCTAssertEqual(rows["payment_type"]?.text, "Cash • Visa")
        XCTAssertEqual(rows["air_conditioning"]?.text, "Yes")
        XCTAssertNotNil(rows.keys.first { $0.hasPrefix("brand") }, rows.keys.sorted().description)
        XCTAssertNotNil(rows["delivery_yes"], rows.keys.sorted().description)
    }

    func testMapAmenityKeepsCustomTagsOfThePoint() {
        let point = WptPt(lat: 50.451145, lon: 30.52157)
        point.setAmenityOriginName(originName: "Amenity:McDonald's: sustenance:fast_food")
        let pointTags = point.getExtensionsToWrite()
        pointTags["test:country"] = "Ukraine"
        pointTags["test:reference"] = "from the point"
        pointTags["amenity_opening_hours"] = "Mo-Su 05:30-23:00"
        let item = OAGpxWptItem.withGpxWpt(point)
        let keys = genericRowKeys(point.getExtensionsToRead())
        let mapAmenity = OAPOI.fromTagValue(["amenity_type": "sustenance", "amenity_subtype": "fast_food",
                                             "osm_tag_phone": "+380441234567", "test:reference": "from the map"],
                                            privatePrefix: "amenity_", osmPrefix: "osm_tag_")

        let rows = buildRows(OAGPXWptViewController.cardAmenity(forPoint: item, mapAmenity: mapAmenity), keys)

        XCTAssertEqual(rows["test:country"]?.text, "Ukraine")
        XCTAssertEqual(rows["phone"]?.text, "+380441234567")
        XCTAssertEqual(rows["test:reference"]?.text, "from the map", "a tag of the map POI is not replaced")
        XCTAssertNotNil(rows["opening_hours"], "a stored POI tag the map POI does not have is kept")
    }

    func testPointWithoutMapAmenityShowsItsOwnTags() {
        let point = WptPt(lat: 50.451145, lon: 30.52157)
        point.getExtensionsToWrite()["test:country"] = "Ukraine"
        let item = OAGpxWptItem.withGpxWpt(point)
        let keys = genericRowKeys(point.getExtensionsToRead())

        let rows = buildRows(OAGPXWptViewController.cardAmenity(forPoint: item, mapAmenity: nil), keys)

        XCTAssertEqual(rows["test:country"]?.text, "Ukraine")
    }

    private func buildRows(_ extensions: [String: String],
                           genericRowKeysFrom stored: [String: String]? = nil) -> [String: OAAmenityInfoRow] {
        let poi = OAPOI.fromTagValue(extensions, privatePrefix: "amenity_", osmPrefix: "osm_tag_")
        return buildRows(poi, genericRowKeys(stored ?? extensions))
    }

    private func buildRows(_ poi: OAPOI?, _ genericRowKeys: Set<String>) -> [String: OAAmenityInfoRow] {
        guard let poi else {
            XCTFail("no amenity")
            return [:]
        }
        SharedTravel.initPoiTypes()
        let helper = AmenityUIHelper(infoBundle: AdditionalInfoBundle(additionalInfo: poi.getAmenityExtensions(false)))
        helper.genericRowKeys = genericRowKeys
        var result = [String: OAAmenityInfoRow]()
        for row in helper.buildInternal() {
            result[row.key] = row
        }
        return result
    }

    private func genericRowKeys(_ extensions: [String: String]) -> Set<String> {
        AdditionalInfoBundle.companion.getGenericRowKeys(storedExtensions: extensions)
    }
}
