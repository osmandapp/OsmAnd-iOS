import XCTest

final class CheckDateFormatterTests: XCTestCase {
    func testCompleteDates() {
        XCTAssertEqual(CheckDateFormatter.format("2025-07-29", locale: Locale(identifier: "en_GB")), "29/07/2025")
        XCTAssertEqual(CheckDateFormatter.format("2024-02-29", locale: Locale(identifier: "en_GB")), "29/02/2024")
        XCTAssertEqual(CheckDateFormatter.format(" 2025-07-29", locale: Locale(identifier: "en_GB")), "29/07/2025")
        XCTAssertEqual(CheckDateFormatter.format("2099-12-31", locale: Locale(identifier: "en_GB")), "31/12/2099")
    }

    func testLocaleSpecificDates() {
        XCTAssertEqual(CheckDateFormatter.format("2025-07-29", locale: Locale(identifier: "en_US")), "7/29/25")
        XCTAssertEqual(CheckDateFormatter.format("2025-07-29", locale: Locale(identifier: "de_DE")), "29.07.25")
        XCTAssertEqual(CheckDateFormatter.format("2025-07-29", locale: Locale(identifier: "en_GB")), "29/07/2025")
    }

    func testMissingDates() {
        XCTAssertNil(CheckDateFormatter.format(nil))
        XCTAssertNil(CheckDateFormatter.format("", locale: Locale(identifier: "en_GB")))
        XCTAssertEqual(CheckDateFormatter.format(" \n\t", locale: Locale(identifier: "en_GB")), " \n\t")
    }

    func testUnsupportedValuesArePreserved() {
        let values = [
            "2025-02-29", "2025-02-30", "2025-13-01", "2025-00-01",
            "2025-07-00", "0000-01-01", "2025", "2025-07", "checked recently",
            "2025/07/29", "2025.07.29", "2025-07-29T10:00", "2025-07-29 extra", "2025-07-29 ", "2025-07-29\n"
        ]
        for value in values {
            XCTAssertEqual(CheckDateFormatter.format(value), value)
        }
        XCTAssertEqual(CheckDateFormatter.format("  checked recently  ", locale: Locale(identifier: "en_GB")), "  checked recently  ")
    }

    func testAndroidCompatibleCompleteDateShapes() {
        XCTAssertEqual(CheckDateFormatter.format("2025-7-9", locale: Locale(identifier: "en_GB")), "09/07/2025")
        XCTAssertEqual(CheckDateFormatter.format("２０２５-０７-２９", locale: Locale(identifier: "en_GB")), "29/07/2025")
        XCTAssertEqual(CheckDateFormatter.format("2025-007-029", locale: Locale(identifier: "en_GB")), "29/07/2025")
    }

    func testRepeatedCallsDoNotChangeFormat() {
        XCTAssertEqual(CheckDateFormatter.format("2025-07-29", locale: Locale(identifier: "en_GB")), "29/07/2025")
        XCTAssertEqual(CheckDateFormatter.format("2025-02-30", locale: Locale(identifier: "en_GB")), "2025-02-30")
        XCTAssertEqual(CheckDateFormatter.format("2024-02-29", locale: Locale(identifier: "en_GB")), "29/02/2024")
    }
}
