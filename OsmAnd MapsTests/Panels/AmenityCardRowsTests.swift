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
        let rows = buildRows(["test:reference": "abc_def", "test:status": "air_conditioning_yes"])
        XCTAssertEqual(rows["test:reference"]?.text, "abc_def")
        XCTAssertEqual(rows["test:status"]?.text, "air_conditioning_yes")
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

    func testOpeningHoursKeepsRawScheduleAndIndependentCheckDate() throws {
        let schedule = "Mo-Su sunrise-sunset; week 01-26 Sa 10:00-12:00"
        let rows = buildRows(["amenity_opening_hours": schedule,
                              "osm_tag_check_date_opening_hours": "2025-03-28",
                              "osm_tag_check_date": "2025-11-18"])
        let row = try XCTUnwrap(rows[OPENING_HOURS_TAG])
        let view = try XCTUnwrap(row.collapsableView as? OACollapsableLabelView)
        let text = try XCTUnwrap(view.label.attributedText)
        let openingDate = try XCTUnwrap(CheckDateFormatter.format("2025-03-28"))
        let generalDate = try XCTUnwrap(CheckDateFormatter.format("2025-11-18"))
        XCTAssertTrue(text.string.hasPrefix(schedule + "\n"))
        XCTAssertTrue(text.string.hasSuffix(openingDate))
        XCTAssertFalse(text.string.contains(generalDate))
        XCTAssertTrue(row.collapsed)
        XCTAssertNil(rows[CHECK_DATE_OPENING_HOURS_TAG])
        XCTAssertEqual(rows[CHECK_DATE_TAG]?.text, generalDate)
        XCTAssertEqual(rows[CHECK_DATE_TAG]?.textPrefix, "Check date")
        XCTAssertEqual(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, .preferredFont(forTextStyle: .subheadline))
        XCTAssertEqual(text.attribute(.font, at: text.length - 1, effectiveRange: nil) as? UIFont, .preferredFont(forTextStyle: .footnote))
        XCTAssertEqual(text.attribute(.foregroundColor, at: text.length - 1, effectiveRange: nil) as? UIColor, .textColorSecondary)
        for width in [CGFloat(240), 390, 700] {
            view.adjustHeight(forWidth: width)
            let bounds = text.boundingRect(with: CGSize(width: view.label.bounds.width, height: 10000),
                                           options: .usesLineFragmentOrigin, context: nil)
            XCTAssertGreaterThanOrEqual(view.label.bounds.height, ceil(bounds.height))
        }
    }

    func testGeneralCheckDateDoesNotBecomeOpeningHoursCaption() throws {
        let schedule = "Mo-Fr 09:00-18:00; Sa 10:00-12:00"
        let rows = buildRows(["amenity_opening_hours": schedule, "osm_tag_check_date": "2025-11-18"])
        let view = try XCTUnwrap(rows[OPENING_HOURS_TAG]?.collapsableView as? OACollapsableLabelView)
        XCTAssertEqual(view.label.text, schedule)
        XCTAssertEqual(rows[CHECK_DATE_TAG]?.text, CheckDateFormatter.format("2025-11-18"))
        XCTAssertNil(rows[CHECK_DATE_OPENING_HOURS_TAG])
    }

    func testOpeningHoursWithoutDatesPreservesExistingScheduleFormatting() throws {
        let schedule = "Mo,We 09:00-18:00; Sa 10:00-12:00"
        let rows = buildRows(["amenity_opening_hours": schedule])
        let view = try XCTUnwrap(rows[OPENING_HOURS_TAG]?.collapsableView as? OACollapsableLabelView)
        XCTAssertEqual(view.label.text, "Mo, We 09:00-18:00; Sa 10:00-12:00")
        XCTAssertNil(rows[CHECK_DATE_TAG])
    }

    func testOpeningHoursDateReadsNormalizedSavedKeys() throws {
        let helper = AmenityUIHelper(infoBundle: AdditionalInfoBundle(poiTypes: OAPOIHelper.sharedInstance().kPoiTypes,
                                                                      additionalInfo: ["amenity_opening_hours": "24/7",
                                                                                       "osm_tag_check_date_opening_hours": "2025-03"]))
        let row = try XCTUnwrap(helper.buildInternal().first { $0.key == OPENING_HOURS_TAG })
        let view = try XCTUnwrap(row.collapsableView as? OACollapsableLabelView)
        let text = try XCTUnwrap(view.label.text)
        XCTAssertTrue(text.hasPrefix("24/7\n"))
        XCTAssertTrue(text.hasSuffix("2025-03"))
    }

    func testGeneralCheckDatePreservesPartialAndInvalidValues() {
        for date in ["2025-03", "2025-02-30", "checked recently"] {
            let rows = buildRows(["osm_tag_check_date": date])
            XCTAssertEqual(rows[CHECK_DATE_TAG]?.text, date)
        }
    }

    func testWaypointAmenityWritesTagsWithoutReplacingExistingExtensions() {
        let poi = OAPOI()
        poi.setAdditionalInfo([OPENING_HOURS_TAG: "24/7", CHECK_DATE_OPENING_HOURS_TAG: "2025-03-28", CHECK_DATE_TAG: "2025-11-18"])
        let point = WptPt()
        point.lat = 50.4359905
        point.lon = 30.5082094
        point.ele = 123.5
        point.speed = 4.5
        point.time = 1730000000000
        point.name = "Recorded waypoint"
        point.getExtensionsToWrite()["test:country"] = "Ukraine"
        point.setAmenity(poi)
        point.setAmenity(nil)
        let extensions = point.getExtensionsToRead()
        XCTAssertEqual(extensions["amenity_opening_hours"], "24/7")
        XCTAssertEqual(extensions["osm_tag_check_date_opening_hours"], "2025-03-28")
        XCTAssertEqual(extensions["osm_tag_check_date"], "2025-11-18")
        XCTAssertEqual(extensions["test:country"], "Ukraine")
        XCTAssertNil(point.extensionsWriters)
        XCTAssertEqual(point.lat, 50.4359905)
        XCTAssertEqual(point.lon, 30.5082094)
        XCTAssertEqual(point.ele, 123.5)
        XCTAssertEqual(point.speed, 4.5)
        XCTAssertEqual(point.time, 1730000000000)
        XCTAssertEqual(point.name, "Recorded waypoint")
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
        let helper = AmenityUIHelper(infoBundle: AdditionalInfoBundle(poiTypes: OAPOIHelper.sharedInstance().kPoiTypes,
                                                                      additionalInfo: poi.getAmenityExtensions(false)))
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
