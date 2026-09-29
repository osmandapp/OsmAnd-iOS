import XCTest

final class OpeningHoursCheckDateFormatterTests: XCTestCase {
    func testCompleteDates() {
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format("2025-07-29"), "29.07.2025")
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format("2024-02-29"), "29.02.2024")
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format(" 2025-07-29\n"), "29.07.2025")
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format("2099-12-31"), "31.12.2099")
    }

    func testMissingDates() {
        XCTAssertNil(OpeningHoursCheckDateFormatter.format(nil))
        XCTAssertNil(OpeningHoursCheckDateFormatter.format(""))
        XCTAssertNil(OpeningHoursCheckDateFormatter.format(" \n\t"))
    }

    func testUnsupportedValuesArePreserved() {
        let values = [
            "2025-02-29", "2025-02-30", "2025-13-01", "2025-00-01",
            "2025-07-00", "2025-7-9", "2025", "2025-07", "checked recently",
            "2025-07-29T10:00", "2025-07-29 extra", "２０２５-０７-２９"
        ]
        for value in values {
            XCTAssertEqual(OpeningHoursCheckDateFormatter.format(value), value)
        }
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format("  checked recently  "), "checked recently")
    }

    func testRepeatedCallsDoNotChangeFormat() {
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format("2025-07-29"), "29.07.2025")
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format("2025-02-30"), "2025-02-30")
        XCTAssertEqual(OpeningHoursCheckDateFormatter.format("2024-02-29"), "29.02.2024")
    }
}
