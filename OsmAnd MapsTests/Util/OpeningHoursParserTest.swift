//
//  OsmAnd MapsTests
//  OpeningHoursParserTest.swift
//  Port from OpeningHoursParserTest.java
//

import XCTest

final class OpeningHoursParserTest: XCTestCase {

    override func setUp() {
        super.setUp()
        configure(localeIdentifier: "en_GB", twelveHour: false)
    }

    func testNSDateToTmWeekday() {
        let date = Date(timeIntervalSince1970: 1_788_110_400)
        let expectedWeekday = Calendar.current.component(.weekday, from: date) - 1
        XCTAssertEqual(OpeningHoursParserTestSupport.weekday(for: date), expectedWeekday)
    }

    func testOpeningHours() {
        var hours = makeHours("Mo-Fr 11:00-22:00; Sa,Su,PH 12:00-22:00; 2022 jul 31-2022 Aug 31 off \"Betriebsferien\"")
        assertOpened("25.08.2022 11:30", hours: hours, expected: false)
        assertOpened("31.08.2022 21:59", hours: hours, expected: false)
        assertOpened("01.09.2022 11:00", hours: hours, expected: true)
        assertInfo("25.08.2022 11:30", hours: hours, equals: "Will open on 11:00 Thu.")

        hours = makeHours("Mo-Fr 10:00-18:30; We 10:00-14:00; Sa 10:00-13:00; Dec-Feb Mo-Fr 11:00-17:00; Dec-Feb We off; Dec-Feb Sa 11:00-13:00; Dec 24-Dec 31 off \"Inventurarbeiten\"; PH off")
        assertOpened("05.11.2022 10:30", hours: hours, expected: true)
        assertOpened("05.12.2022 10:30", hours: hours, expected: false)
        assertOpened("05.12.2022 11:30", hours: hours, expected: true)
        assertOpened("30.12.2022 11:00", hours: hours, expected: false)
        assertInfo("29.12.2022 14:00", hours: hours, equals: "Will open on 11:00 Mon.")
        assertInfo("30.12.2022 14:00", hours: hours, equals: "Will open on 11:00 Mon.")

        hours = makeHours("2024 Jan 1-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("01.01.2025 00:00", hours: hours, expected: false)

        hours = makeHours("2024 Jan 01-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("01.01.2025 00:00", hours: hours, expected: false)

        hours = makeHours("2024 Jan 01-2024 Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("01.01.2025 00:00", hours: hours, expected: false)

        hours = makeHours("2024 Jan 01-2025 Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("01.01.2025 00:00", hours: hours, expected: true)
        assertOpened("31.12.2025 23:59", hours: hours, expected: true)
        assertOpened("01.01.2026 00:00", hours: hours, expected: false)

        hours = makeHours("2022 Oct 24 - 2023 Oct 30")
        assertOpened("20.10.2022 10:00", hours: hours, expected: false)
        assertOpened("20.06.2023 10:00", hours: hours, expected: true)
        assertOpened("01.11.2023 10:00", hours: hours, expected: false)
        assertOpened("31.12.2023 10:00", hours: hours, expected: false)

        hours = makeHours("2022 Oct 30 - 2023 Oct 24")
        assertOpened("25.10.2023 10:00", hours: hours, expected: false)

        hours = makeHours("2022 Oct 24 - 2023 Aug 30")
        assertOpened("25.10.2022 10:00", hours: hours, expected: true)
        assertOpened("25.09.2023 10:00", hours: hours, expected: false)
        assertOpened("25.09.2022 10:00", hours: hours, expected: false)
        assertOpened("25.08.2022 10:00", hours: hours, expected: false)
        assertOpened("25.08.2023 10:00", hours: hours, expected: true)

        hours = makeHours("11:00-14:00,17:00-22:00; We off; Fr,Sa 11:00-14:00,17:00-00:00")
        assertOpened("28.06.2023 12:00", hours: hours, expected: false)

        hours = makeHours("Mo 09:00-12:00; We,Sa 13:30-17:00, Apr 01-Oct 31 We,Sa 17:00-18:30; PH off")
        assertInfo("03.10.2020 14:00", hours: hours, equals: "Open until 18:30")

        hours = makeHours("PH,Mo-Su 09:00-22:00")
        assertOpened("13.10.2021 11:54", hours: hours, expected: true)

        hours = makeHours("Mo-We 07:00-21:00, Th-Fr 07:00-21:30, PH,Sa-Su 08:00-21:00")
        assertOpened("29.08.2021 10:09", hours: hours, expected: true)

        hours = makeHours("Mo-Fr 08:00-12:30, Mo-We 12:30-16:30 \"Sur rendez-vous\", Fr 12:30-15:30 \"Sur rendez-vous\"")
        assertInfo("13.10.2019 18:00", hours: hours, equals: "Will open tomorrow at 08:00")

        hours = makeHours("2019 Oct 1 - 2024 dec 31 ")
        assertOpened("30.09.2019 10:30", hours: hours, expected: false)
        assertOpened("01.10.2019 10:30", hours: hours, expected: true)
        assertOpened("05.02.2023 10:30", hours: hours, expected: true)
        assertOpened("31.08.2024 10:30", hours: hours, expected: true)
        assertOpened("31.12.2024 10:30", hours: hours, expected: true)
        assertOpened("01.01.2025 10:30", hours: hours, expected: false)

        hours = makeHours("2019 Oct - 2024 dec")
        assertOpened("30.09.2019 10:30", hours: hours, expected: false)
        assertOpened("01.10.2019 10:30", hours: hours, expected: true)
        assertOpened("05.02.2023 10:30", hours: hours, expected: true)
        assertOpened("31.12.2024 10:30", hours: hours, expected: true)
        assertOpened("01.01.2025 10:30", hours: hours, expected: false)

        hours = makeHours("2019 Apr 1 - 2020 Apr 1")
        assertOpened("01.04.2018 15:00", hours: hours, expected: false)
        assertOpened("01.04.2019 15:00", hours: hours, expected: true)
        assertOpened("01.04.2020 15:00", hours: hours, expected: true)
        assertOpened("01.08.2019 15:00", hours: hours, expected: true)

        hours = makeHours("2019 Apr 15 -  2020 Mar 1")
        assertOpened("01.04.2018 15:00", hours: hours, expected: false)
        assertOpened("01.04.2019 15:00", hours: hours, expected: false)
        assertOpened("15.04.2019 15:00", hours: hours, expected: true)
        assertOpened("15.09.2019 15:00", hours: hours, expected: true)
        assertOpened("15.02.2020 15:00", hours: hours, expected: true)
        assertOpened("15.03.2020 15:00", hours: hours, expected: false)
        assertOpened("15.04.2020 15:00", hours: hours, expected: false)

        hours = makeHours("2019 Jul 23 05:00-24:00; 2019 Jul 24-2019 Jul 26 00:00-24:00; 2019 Jul 27 00:00-18:00")
        assertOpened("23.07.2018 15:00", hours: hours, expected: false)
        assertOpened("23.07.2019 15:00", hours: hours, expected: true)
        assertOpened("23.07.2019 04:00", hours: hours, expected: false)
        assertOpened("23.07.2020 15:00", hours: hours, expected: false)
        assertOpened("25.07.2018 15:00", hours: hours, expected: false)
        assertOpened("24.07.2019 15:00", hours: hours, expected: true)
        assertOpened("25.07.2019 04:00", hours: hours, expected: true)
        assertOpened("26.07.2019 15:00", hours: hours, expected: true)
        assertOpened("25.07.2020 15:00", hours: hours, expected: false)
        assertOpened("27.07.2018 15:00", hours: hours, expected: false)
        assertOpened("27.07.2019 15:00", hours: hours, expected: true)
        assertOpened("27.07.2019 19:00", hours: hours, expected: false)
        assertOpened("27.07.2020 15:00", hours: hours, expected: false)

        hours = makeHours("2019 Sep 1 - 2022 Apr 1")
        assertOpened("01.02.2018 15:00", hours: hours, expected: false)
        assertOpened("29.05.2019 15:00", hours: hours, expected: false)
        assertOpened("05.09.2019 11:00", hours: hours, expected: true)
        assertOpened("05.02.2020 11:00", hours: hours, expected: true)
        assertOpened("03.06.2020 11:00", hours: hours, expected: true)
        assertOpened("05.02.2021 11:00", hours: hours, expected: true)
        assertOpened("05.02.2022 11:00", hours: hours, expected: true)
        assertOpened("05.02.2023 11:00", hours: hours, expected: false)

        hours = makeHours("2019 Apr 15 - 2019 Sep 1: Mo-Fr 00:00-24:00")
        assertOpened("06.04.2019 15:00", hours: hours, expected: false)
        assertOpened("29.05.2019 15:00", hours: hours, expected: true)
        assertOpened("25.07.2019 11:00", hours: hours, expected: true)
        assertOpened("12.07.2018 11:00", hours: hours, expected: false)
        assertOpened("18.07.2020 11:00", hours: hours, expected: false)
        assertOpened("28.07.2021 11:00", hours: hours, expected: false)

        hours = makeHours("2019 Sep 1 - 2020 Apr 1")
        assertOpened("01.04.2019 15:00", hours: hours, expected: false)
        assertOpened("29.05.2019 15:00", hours: hours, expected: false)
        assertOpened("05.09.2019 11:00", hours: hours, expected: true)
        assertOpened("05.02.2020 11:00", hours: hours, expected: true)
        assertOpened("05.06.2020 11:00", hours: hours, expected: false)
        assertOpened("05.02.2021 11:00", hours: hours, expected: false)

        hours = makeHours("2019 Apr 15 - 2019 Sep 1")
        assertOpened("01.04.2019 15:00", hours: hours, expected: false)
        assertOpened("29.05.2019 15:00", hours: hours, expected: true)
        assertOpened("27.07.2019 15:00", hours: hours, expected: true)
        assertOpened("05.09.2019 11:00", hours: hours, expected: false)
        assertOpened("05.06.2018 11:00", hours: hours, expected: false)
        assertOpened("05.06.2020 11:00", hours: hours, expected: false)

        hours = makeHours("Apr 15 - Sep 1")
        assertOpened("01.04.2019 15:00", hours: hours, expected: false)
        assertOpened("29.05.2019 15:00", hours: hours, expected: true)
        assertOpened("27.07.2019 15:00", hours: hours, expected: true)
        assertOpened("05.09.2019 11:00", hours: hours, expected: false)

        hours = makeHours("Apr 15 - Sep 1: Mo-Fr 00:00-24:00")
        assertOpened("01.04.2019 15:00", hours: hours, expected: false)
        assertOpened("29.05.2019 15:00", hours: hours, expected: true)
        assertOpened("24.07.2019 15:00", hours: hours, expected: true)
        assertOpened("27.07.2019 15:00", hours: hours, expected: false)
        assertOpened("05.09.2019 11:00", hours: hours, expected: false)

        hours = makeHours("Apr 05-Oct 24: Fr 08:00-16:00")
        assertOpened("26.08.2018 15:00", hours: hours, expected: false)
        assertOpened("29.03.2019 15:00", hours: hours, expected: false)
        assertOpened("05.04.2019 11:00", hours: hours, expected: true)

        hours = makeHours("Oct 24-Apr 05: Fr 08:00-16:00")
        assertOpened("26.08.2018 15:00", hours: hours, expected: false)
        assertOpened("29.03.2019 15:00", hours: hours, expected: true)
        assertOpened("26.04.2019 11:00", hours: hours, expected: false)

        hours = makeHours("Oct 24-Apr 05, Jun 10-Jun 20, Jul 6-12: Fr 08:00-16:00")
        assertOpened("26.08.2018 15:00", hours: hours, expected: false)
        assertOpened("02.01.2019 15:00", hours: hours, expected: false)
        assertOpened("29.03.2019 15:00", hours: hours, expected: true)
        assertOpened("26.04.2019 11:00", hours: hours, expected: false)

        hours = makeHours("Apr 05-24: Fr 08:00-16:00")
        assertOpened("12.10.2018 11:00", hours: hours, expected: false)
        assertOpened("12.04.2019 15:00", hours: hours, expected: true)
        assertOpened("27.04.2019 15:00", hours: hours, expected: false)

        hours = makeHours("Apr 5: Fr 08:00-16:00")
        assertOpened("05.04.2019 15:00", hours: hours, expected: true)
        assertOpened("06.04.2019 15:00", hours: hours, expected: false)

        hours = makeHours("Apr 24-05: Fr 08:00-16:00")
        assertOpened("12.10.2018 11:00", hours: hours, expected: false)
        assertOpened("12.04.2018 15:00", hours: hours, expected: false)

        hours = makeHours("Apr: Fr 08:00-16:00")
        assertOpened("12.10.2018 11:00", hours: hours, expected: false)
        assertOpened("12.04.2019 15:00", hours: hours, expected: true)

        hours = makeHours("Apr-Oct: Fr 08:00-16:00")
        assertOpened("09.11.2018 11:00", hours: hours, expected: false)
        assertOpened("12.10.2018 11:00", hours: hours, expected: true)
        assertOpened("24.08.2018 15:00", hours: hours, expected: true)
        assertOpened("09.03.2018 15:00", hours: hours, expected: false)

        hours = makeHours("Apr, Oct: Fr 08:00-16:00")
        assertOpened("09.11.2018 11:00", hours: hours, expected: false)
        assertOpened("12.10.2018 11:00", hours: hours, expected: true)
        assertOpened("24.08.2018 15:00", hours: hours, expected: false)
        assertOpened("12.04.2019 15:00", hours: hours, expected: true)

        hours = makeHours("Mo-Fr 08:30-14:40")
        assertOpened("09.08.2012 11:00", hours: hours, expected: true)
        assertOpened("09.08.2012 16:00", hours: hours, expected: false)

        hours = makeHours("Mo-Fr 11:30-15:00, 17:30-23:00; Sa, Su, PH 11:30-23:00")
        assertAssembled(hours, equals: "Mo-Fr 11:30-15:00, 17:30-23:00; Sa, Su, PH 11:30-23:00")
        assertOpened("7.09.2015 14:54", hours: hours, expected: true)
        assertOpened("7.09.2015 15:05", hours: hours, expected: false)
        assertOpened("6.09.2015 16:05", hours: hours, expected: true)

        hours = makeHours("Mo-We, Fr 08:30-14:40,15:00-19:00")
        assertOpened("08.08.2012 14:00", hours: hours, expected: true)
        assertOpened("08.08.2012 14:50", hours: hours, expected: false)
        assertOpened("10.08.2012 15:00", hours: hours, expected: true)

        hours = makeHours("Mo-Sa 08:30-14:40; Tu 08:00 - 14:00")
        assertOpened("07.08.2012 14:20", hours: hours, expected: false)
        assertOpened("07.08.2012 08:15", hours: hours, expected: true)

        hours = makeHours("Mo-Sa 09:00-18:25; Th off")
        assertOpened("08.08.2012 12:00", hours: hours, expected: true)
        assertOpened("09.08.2012 12:00", hours: hours, expected: false)

        hours = makeHours("24/7")
        assertOpened("08.08.2012 23:59", hours: hours, expected: true)
        assertOpened("08.08.2012 12:23", hours: hours, expected: true)
        assertOpened("08.08.2012 06:23", hours: hours, expected: true)

        hours = makeHours("24/7 closed \"Temporarily, for major repairs\"")
        assertOpened("13.10.2019 18:00", hours: hours, expected: false)
        assertInfo("13.10.2019 18:00", hours: hours, equals: "24/7 off - Temporarily, for major repairs")

        _ = makeHours("Sa-Su 24/7")
        _ = makeHours("Mo-Fr 9-19")
        _ = makeHours("09:00-17:00")
        _ = makeHours("sunrise-sunset")
        _ = makeHours("10:00+")

        hours = makeHours("Su-Th sunset-24:00, 04:00-sunrise; Fr-Sa sunset-sunrise")
        assertOpened("12.08.2012 04:00", hours: hours, expected: true)
        assertOpened("12.08.2012 23:00", hours: hours, expected: true)
        assertOpened("08.08.2012 12:00", hours: hours, expected: false)
        assertOpened("08.08.2012 05:00", hours: hours, expected: true)

        hours = makeHours("Mo 20:00-02:00")
        assertOpened("05.05.2013 10:30", hours: hours, expected: false)
        assertOpened("05.05.2013 23:59", hours: hours, expected: false)
        assertOpened("06.05.2013 10:30", hours: hours, expected: false)
        assertOpened("06.05.2013 20:30", hours: hours, expected: true)
        assertOpened("06.05.2013 23:59", hours: hours, expected: true)
        assertOpened("07.05.2013 00:00", hours: hours, expected: true)
        assertOpened("07.05.2013 00:30", hours: hours, expected: true)
        assertOpened("07.05.2013 01:59", hours: hours, expected: true)
        assertOpened("07.05.2013 20:30", hours: hours, expected: false)

        hours = makeHours("Su 10:00-10:00")
        assertOpened("05.05.2013 09:59", hours: hours, expected: false)
        assertOpened("05.05.2013 10:00", hours: hours, expected: true)
        assertOpened("05.05.2013 23:59", hours: hours, expected: true)
        assertOpened("06.05.2013 00:00", hours: hours, expected: true)
        assertOpened("06.05.2013 09:59", hours: hours, expected: true)
        assertOpened("06.05.2013 10:00", hours: hours, expected: false)

        hours = makeHours("Tu-Th 07:00-2:00; Fr 17:00-4:00; Sa 18:00-05:00; Su,Mo off")
        assertOpened("05.05.2013 04:59", hours: hours, expected: true)
        assertOpened("05.05.2013 05:00", hours: hours, expected: false)
        assertOpened("05.05.2013 12:30", hours: hours, expected: false)
        assertOpened("06.05.2013 10:30", hours: hours, expected: false)
        assertOpened("07.05.2013 01:00", hours: hours, expected: false)
        assertOpened("07.05.2013 20:25", hours: hours, expected: true)
        assertOpened("07.05.2013 23:59", hours: hours, expected: true)
        assertOpened("08.05.2013 00:00", hours: hours, expected: true)
        assertOpened("08.05.2013 02:00", hours: hours, expected: false)

        hours = makeHours("Mo-Th 09:00-03:00; Fr-Sa 09:00-04:00; Su off")
        assertOpened("11.05.2015 08:59", hours: hours, expected: false)
        assertOpened("11.05.2015 09:01", hours: hours, expected: true)
        assertOpened("12.05.2015 02:59", hours: hours, expected: true)
        assertOpened("12.05.2015 03:00", hours: hours, expected: false)
        assertOpened("16.05.2015 03:59", hours: hours, expected: true)
        assertOpened("16.05.2015 04:01", hours: hours, expected: false)
        assertOpened("17.05.2015 01:00", hours: hours, expected: true)
        assertOpened("17.05.2015 04:01", hours: hours, expected: false)

        hours = makeHours("Tu-Th 07:00-2:00; Fr 17:00-4:00; Sa 18:00-05:00; Su,Mo off")
        assertOpened("11.05.2015 08:59", hours: hours, expected: false)
        assertOpened("11.05.2015 09:01", hours: hours, expected: false)
        assertOpened("12.05.2015 01:59", hours: hours, expected: false)
        assertOpened("12.05.2015 02:59", hours: hours, expected: false)
        assertOpened("12.05.2015 03:00", hours: hours, expected: false)
        assertOpened("13.05.2015 01:59", hours: hours, expected: true)
        assertOpened("13.05.2015 02:59", hours: hours, expected: false)
        assertOpened("16.05.2015 03:59", hours: hours, expected: true)
        assertOpened("16.05.2015 04:01", hours: hours, expected: false)
        assertOpened("17.05.2015 01:00", hours: hours, expected: true)
        assertOpened("17.05.2015 05:01", hours: hours, expected: false)

        hours = makeHours("May: 07:00-19:00")
        assertOpened("05.05.2013 12:00", hours: hours, expected: true)
        assertOpened("05.05.2013 05:00", hours: hours, expected: false)
        assertOpened("05.05.2013 21:00", hours: hours, expected: false)
        assertOpened("05.01.2013 12:00", hours: hours, expected: false)
        assertOpened("05.01.2013 05:00", hours: hours, expected: false)

        hours = makeHours("Apr-Sep 8:00-22:00; Oct-Mar 10:00-18:00")
        assertOpened("05.03.2013 15:00", hours: hours, expected: true)
        assertOpened("05.03.2013 20:00", hours: hours, expected: false)
        assertOpened("05.05.2013 20:00", hours: hours, expected: true)
        assertOpened("05.05.2013 23:00", hours: hours, expected: false)
        assertOpened("05.10.2013 15:00", hours: hours, expected: true)
        assertOpened("05.10.2013 20:00", hours: hours, expected: false)

        hours = makeHours("Mo-Fr: 9:00-13:00, 14:00-18:00")
        assertOpened("02.12.2015 12:00", hours: hours, expected: true)
        assertOpened("02.12.2015 13:30", hours: hours, expected: false)
        assertOpened("02.12.2015 16:00", hours: hours, expected: true)
        assertOpened("05.12.2015 16:00", hours: hours, expected: false)

        hours = makeHours("Mo-Su 07:00-23:00; Dec 25 08:00-20:00")
        assertOpened("25.12.2015 07:00", hours: hours, expected: false)
        assertOpened("24.12.2015 07:00", hours: hours, expected: true)
        assertOpened("24.12.2015 22:00", hours: hours, expected: true)
        assertOpened("25.12.2015 08:00", hours: hours, expected: true)
        assertOpened("25.12.2015 22:00", hours: hours, expected: false)

        hours = makeHours("Mo-Su 07:00-23:00; Dec 25 off")
        assertOpened("25.12.2015 14:00", hours: hours, expected: false)
        assertOpened("24.12.2015 08:00", hours: hours, expected: true)

        hours = makeHours("Mo-Su 07:00-23:00; Easter off; Dec 25 off")
        assertOpened("25.12.2015 14:00", hours: hours, expected: false)
        assertOpened("24.12.2015 08:00", hours: hours, expected: true)

        hours = makeHours("Mo-Fr 08:30-17:00; 12:00-12:40 off;")
        assertOpened("07.05.2017 14:00", hours: hours, expected: false)
        assertOpened("06.05.2017 12:15", hours: hours, expected: false)
        assertOpened("05.05.2017 14:00", hours: hours, expected: true)
        assertOpened("05.05.2017 12:15", hours: hours, expected: false)
        assertOpened("05.05.2017 12:00", hours: hours, expected: false)
        assertOpened("05.05.2017 11:45", hours: hours, expected: true)

        hours = makeHours("mo-fr 11:00-21:00; PH off")
        assertAssembled(hours, equals: "mo-fr 11:00-21:00; PH off")

        hours = makeHours("Mo-Fr 08:30-17:00; 12:00-12:40 off;")
        assertInfo("15.01.2018 09:00", hours: hours, equals: "Open until 12:00")
        assertInfo("15.01.2018 11:00", hours: hours, equals: "Will close at 12:00")
        assertInfo("15.01.2018 12:00", hours: hours, equals: "Will open at 12:40")

        hours = makeHours("Mo-Fr: 9:00-13:00, 14:00-18:00")
        assertInfo("15.01.2018 08:00", hours: hours, equals: "Will open at 09:00")
        assertInfo("15.01.2018 09:00", hours: hours, equals: "Open until 13:00")
        assertInfo("15.01.2018 12:00", hours: hours, equals: "Will close at 13:00")
        assertInfo("15.01.2018 13:10", hours: hours, equals: "Will open at 14:00")
        assertInfo("15.01.2018 14:00", hours: hours, equals: "Open until 18:00")
        assertInfo("15.01.2018 16:00", hours: hours, equals: "Will close at 18:00")
        assertInfo("15.01.2018 18:10", hours: hours, equals: "Will open tomorrow at 09:00")

        hours = makeHours("Mo-Sa 02:00-10:00; Th off")
        assertInfo("15.01.2018 23:00", hours: hours, equals: "Will open tomorrow at 02:00")

        hours = makeHours("Mo-Sa 23:00-02:00; Th off")
        assertInfo("15.01.2018 22:00", hours: hours, equals: "Will open at 23:00")
        assertInfo("15.01.2018 23:00", hours: hours, equals: "Open until 02:00")
        assertInfo("16.01.2018 00:30", hours: hours, equals: "Will close at 02:00")
        assertInfo("16.01.2018 02:00", hours: hours, equals: "Open from 23:00")

        hours = makeHours("Mo-Sa 08:30-17:00; Th off")
        assertInfo("17.01.2018 20:00", hours: hours, equals: "Will open on 08:30 Fri.")
        assertInfo("18.01.2018 05:00", hours: hours, equals: "Will open tomorrow at 08:30")
        assertInfo("20.01.2018 05:00", hours: hours, equals: "Open from 08:30")
        assertInfo("21.01.2018 05:00", hours: hours, equals: "Will open tomorrow at 08:30")
        assertInfo("22.01.2018 02:00", hours: hours, equals: "Open from 08:30")
        assertInfo("22.01.2018 04:00", hours: hours, equals: "Open from 08:30")
        assertInfo("22.01.2018 07:00", hours: hours, equals: "Will open at 08:30")
        assertInfo("23.01.2018 10:00", hours: hours, equals: "Open until 17:00")
        assertInfo("23.01.2018 16:00", hours: hours, equals: "Will close at 17:00")

        hours = makeHours("24/7")
        assertInfo("24.01.2018 02:00", hours: hours, equals: "Open 24/7")

        hours = makeHours("Mo-Su 07:00-23:00, Fr 08:00-20:00")
        assertOpened("15.01.2018 06:45", hours: hours, expected: false)
        assertOpened("15.01.2018 07:45", hours: hours, expected: true)
        assertOpened("15.01.2018 23:45", hours: hours, expected: false)
        assertOpened("19.01.2018 07:45", hours: hours, expected: false)
        assertOpened("19.01.2018 08:45", hours: hours, expected: true)
        assertOpened("19.01.2018 20:45", hours: hours, expected: false)

        hours = makeHours("07:00-01:00 open \"Restaurant\" || Mo 00:00-04:00,07:00-04:00; Tu-Th 07:00-04:00; Fr 07:00-24:00; Sa,Su 00:00-24:00 open \"McDrive\"")
        assertOpened("22.01.2018 00:30", hours: hours, expected: true)
        assertOpened("22.01.2018 08:00", hours: hours, expected: true)
        assertOpened("22.01.2018 03:30", hours: hours, expected: true)
        assertOpened("22.01.2018 05:00", hours: hours, expected: false)
        assertOpened("23.01.2018 05:00", hours: hours, expected: false)
        assertOpened("27.01.2018 05:00", hours: hours, expected: true)
        assertOpened("28.01.2018 05:00", hours: hours, expected: true)
        assertInfo("22.01.2018 05:00", hours: hours, equals: "Will open at 07:00 - Restaurant", sequenceIndex: 0)
        assertInfo("26.01.2018 00:00", hours: hours, equals: "Will close at 01:00 - Restaurant", sequenceIndex: 0)
        assertInfo("22.01.2018 05:00", hours: hours, equals: "Will open at 07:00 - McDrive", sequenceIndex: 1)
        assertInfo("22.01.2018 00:00", hours: hours, equals: "Open until 04:00 - McDrive", sequenceIndex: 1)
        assertInfo("22.01.2018 02:00", hours: hours, equals: "Will close at 04:00 - McDrive", sequenceIndex: 1)
        assertInfo("27.01.2018 02:00", hours: hours, equals: "Open until 24:00 - McDrive", sequenceIndex: 1)

        hours = makeHours("07:00-03:00 open \"Restaurant\" || 24/7 open \"McDrive\"")
        assertOpened("22.01.2018 02:00", hours: hours, expected: true)
        assertOpened("22.01.2018 17:00", hours: hours, expected: true)
        assertInfo("22.01.2018 05:00", hours: hours, equals: "Will open at 07:00 - Restaurant", sequenceIndex: 0)
        assertInfo("22.01.2018 04:00", hours: hours, equals: "Open 24/7 - McDrive", sequenceIndex: 1)

        hours = makeHours("Mo-Fr 12:00-15:00, Tu-Fr 17:00-23:00, Sa 12:00-23:00, Su 14:00-23:00")
        assertOpened("16.02.2018 14:00", hours: hours, expected: true)
        assertOpened("16.02.2018 16:00", hours: hours, expected: false)
        assertOpened("16.02.2018 17:00", hours: hours, expected: true)
        assertInfo("16.02.2018 9:45", hours: hours, equals: "Open from 12:00")
        assertInfo("16.02.2018 12:00", hours: hours, equals: "Open until 15:00")
        assertInfo("16.02.2018 14:00", hours: hours, equals: "Will close at 15:00")
        assertInfo("16.02.2018 16:00", hours: hours, equals: "Will open at 17:00")
        assertInfo("16.02.2018 18:00", hours: hours, equals: "Open until 23:00")

        hours = makeHours("Mo-Fr 08:00-12:00, Mo,Tu,Th 15:00-17:00; PH off")
        assertOpened("09.08.2019 15:00", hours: hours, expected: false)
        assertInfo("09.08.2019 15:00", hours: hours, equals: "Will open on 08:00 Mon.")

        hours = makeHours("Mo-Fr 10:00-21:00; Sa 12:00-23:00; PH \"Wird auf der Homepage bekannt gegeben.\"")
        assertAssembled(hours, equals: "Mo-Fr 10:00-21:00; Sa 12:00-23:00; PH - Wird auf der Homepage bekannt gegeben.")
    }

    func testComma() {
        configure(localeIdentifier: "en_US", twelveHour: true)

        let hours = makeHours("Mo-Fr 09:00-13:00,Tu 14:00-18:00, Th 14:00-17:00; We \"Nach Vereinbarung\"; Sa,Su,PH closed")
        assertOpened("24.03.2025 10:00", hours: hours, expected: true)
        assertOpened("24.03.2025 13:30", hours: hours, expected: false)
        assertOpened("24.03.2025 17:50", hours: hours, expected: false)
        assertOpened("25.03.2025 10:00", hours: hours, expected: true)
        assertOpened("25.03.2025 13:30", hours: hours, expected: false)
        assertOpened("25.03.2025 17:50", hours: hours, expected: true)
        assertInfo("24.03.2025 16:00", hours: hours, equals: "Will open tomorrow at 9:00 AM")
        assertInfo("25.03.2025 10:00", hours: hours, equals: "Open until 1:00 PM")
        assertInfo("25.03.2025 13:30", hours: hours, equals: "Will open at 2:00 PM")
        assertInfo("25.03.2025 17:50", hours: hours, equals: "Will close at 6:00 PM")
        assertInfo("25.03.2025 18:50", hours: hours, equals: "Will open on 9:00 AM Thu.")
    }

    func testAmPm() {
        configure(localeIdentifier: "en_US", twelveHour: true)

        var hours = makeHours("Mo-Fr: 9:00-13:00, 14:00-18:00")
        assertInfo("15.01.2018 08:00", hours: hours, equals: "Will open at 9:00 AM")
        assertInfo("15.01.2018 09:00", hours: hours, equals: "Open until 1:00 PM")
        assertInfo("15.01.2018 12:00", hours: hours, equals: "Will close at 1:00 PM")
        assertInfo("15.01.2018 13:10", hours: hours, equals: "Will open at 2:00 PM")
        assertInfo("15.01.2018 14:00", hours: hours, equals: "Open until 6:00 PM")
        assertInfo("15.01.2018 16:00", hours: hours, equals: "Will close at 6:00 PM")
        assertInfo("15.01.2018 18:10", hours: hours, equals: "Will open tomorrow at 9:00 AM")

        hours = makeHours("Mo-Fr 04:30-10:00, 07:30-23:00; Sa, Su, PH 13:30-23:00")
        assertAssembled(hours, equals: "Mon-Fri 4:30-10:00 AM, 7:30 AM-11:00 PM; Sat, Sun, PH 1:30-11:00 PM", localized: true)

        hours = makeHours("Mo-Fr 00:00-12:00, 12:00-24:00;")
        assertAssembled(hours, equals: "Mon-Fri 12:00 AM-12:00 PM, 12:00 PM-12:00 AM", localized: true)

        configure(localeIdentifier: "zh_HK", twelveHour: true)
        hours = makeHours("Mo-Fr 04:30-10:00, 07:30-23:00; Sa, Su, PH 13:30-23:00")
        assertAssembled(hours, equals: "週一-週五 上午4:30-10:00, 上午7:30-下午11:00; 週六, 週日, PH 下午1:30-11:00", localized: true)

        configure(localeIdentifier: "ar_SA", twelveHour: true)
        hours = makeHours("Mo-Fr 04:30-10:00, 07:30-23:00; Sa, Su, PH 13:30-23:00")
        assertAssembled(hours, equals: "اثنين-جمعة ٤:٣٠-١٠:٠٠ ص, ٧:٣٠ ص-١١:٠٠ م; سبت, أحد, PH ١:٣٠-١١:٠٠ م", localized: true)
    }

    func testYearFormats() {
        var hours = makeHours("2024 Jan-Dec")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("01.01.2025 00:00", hours: hours, expected: false)

        hours = makeHours("2024-2025 Jan 1-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("31.12.2025 23:59", hours: hours, expected: true)
        assertOpened("01.01.2026 00:00", hours: hours, expected: false)

        hours = makeHours("2024,2025 Jan 1-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("31.12.2025 23:59", hours: hours, expected: true)
        assertOpened("01.01.2026 00:00", hours: hours, expected: false)

        hours = makeHours("2024")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("01.01.2025 00:00", hours: hours, expected: false)

        hours = makeHours("2024,2026")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("15.06.2025 12:00", hours: hours, expected: false)
        assertOpened("01.01.2026 00:00", hours: hours, expected: true)
        assertOpened("31.12.2026 23:59", hours: hours, expected: true)
        assertOpened("01.01.2027 00:00", hours: hours, expected: false)

        hours = makeHours("2024,2026 Jan 1-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2024 23:59", hours: hours, expected: true)
        assertOpened("15.06.2025 12:00", hours: hours, expected: false)
        assertOpened("01.01.2026 00:00", hours: hours, expected: true)
        assertOpened("31.12.2026 23:59", hours: hours, expected: true)
        assertOpened("01.01.2027 00:00", hours: hours, expected: false)

        hours = makeHours("2024,2026-2027 Jan 1-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("15.06.2025 12:00", hours: hours, expected: false)
        assertOpened("01.01.2026 00:00", hours: hours, expected: true)
        assertOpened("31.12.2027 23:59", hours: hours, expected: true)
        assertOpened("01.01.2028 00:00", hours: hours, expected: false)

        hours = makeHours("2024-2025,2027-2028 Jan 1-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("31.12.2025 23:59", hours: hours, expected: true)
        assertOpened("15.06.2026 12:00", hours: hours, expected: false)
        assertOpened("01.01.2027 00:00", hours: hours, expected: true)
        assertOpened("31.12.2028 23:59", hours: hours, expected: true)
        assertOpened("01.01.2029 00:00", hours: hours, expected: false)

        hours = makeHours("2024,2026,2028 Jan 1-Dec 31")
        assertOpened("31.12.2023 23:59", hours: hours, expected: false)
        assertOpened("01.01.2024 00:00", hours: hours, expected: true)
        assertOpened("15.06.2025 12:00", hours: hours, expected: false)
        assertOpened("01.01.2026 00:00", hours: hours, expected: true)
        assertOpened("15.06.2027 12:00", hours: hours, expected: false)
        assertOpened("01.01.2028 00:00", hours: hours, expected: true)
        assertOpened("01.01.2029 00:00", hours: hours, expected: false)
    }

    func testTimeRestrictedOffRules() {
        // "off" rules with time ranges must only turn off their own time windows
        // and must not discard opening/closing times found by other rules (#22907)
        configure(localeIdentifier: "en_GB", twelveHour: false)

        var hours = makeHours("Mo-Fr 08:30-12:30,14:00-19:30; Sa 09:00-12:30; Jul-Aug 19:00-19:30 off; PH off")
        // Wednesday inside the Jul-Aug period
        assertOpened("02.07.2025 13:50", hours: hours, expected: false)
        assertInfo("02.07.2025 13:50", hours: hours, equals: "Will open at 14:00")
        assertInfo("02.07.2025 05:00", hours: hours, equals: "Open from 08:30")
        assertInfo("02.07.2025 10:00", hours: hours, equals: "Open until 12:30")
        assertInfo("02.07.2025 12:20", hours: hours, equals: "Will close at 12:30")
        // The "off" range shortens the evening interval.
        assertOpened("02.07.2025 14:05", hours: hours, expected: true)
        assertInfo("02.07.2025 14:05", hours: hours, equals: "Open until 19:00")
        assertOpened("02.07.2025 19:10", hours: hours, expected: false)
        assertInfo("02.07.2025 21:00", hours: hours, equals: "Will open tomorrow at 08:30")
        // Outside the Jul-Aug period the "off" rule has no effect.
        assertInfo("03.09.2025 13:50", hours: hours, equals: "Will open at 14:00")
        assertInfo("03.09.2025 14:05", hours: hours, equals: "Open until 19:30")

        // Lunch break: reopening time is the end of the "off" range.
        hours = makeHours("Mo-Fr 08:00-18:00; Mo-Fr 12:00-13:00 off")
        assertOpened("06.10.2025 12:30", hours: hours, expected: false)
        assertInfo("06.10.2025 12:30", hours: hours, equals: "Will open at 13:00")
        assertInfo("06.10.2025 10:30", hours: hours, equals: "Will close at 12:00")
        assertInfo("06.10.2025 14:00", hours: hours, equals: "Open until 18:00")

        // A passed "off" range must not affect the closing time anymore (#22931).
        hours = makeHours("Tu-Fr 08:00-17:00; Mo-Fr 12:00-13:00 off \"Lunch\"")
        assertInfo("07.10.2025 09:00", hours: hours, equals: "Open until 12:00 - Lunch")
        assertInfo("07.10.2025 12:30", hours: hours, equals: "Will open at 13:00 - Lunch")
        assertInfo("07.10.2025 15:00", hours: hours, equals: "Will close at 17:00")

        // Multiple "off" time ranges in one rule.
        hours = makeHours("Mo-Fr 08:00-20:00; Mo-Fr 10:00-10:30,15:00-15:30 off")
        assertInfo("06.10.2025 09:00", hours: hours, equals: "Will close at 10:00")
        assertInfo("06.10.2025 10:15", hours: hours, equals: "Will open at 10:30")
        assertInfo("06.10.2025 12:00", hours: hours, equals: "Open until 15:00")
        assertInfo("06.10.2025 16:00", hours: hours, equals: "Open until 20:00")

        // Overnight opening with an "off" window after midnight: the off start is 00:00
        // in the next calendar day, so it must still shorten the closing time before midnight.
        hours = makeHours("Mo-Su 20:00-02:00; Mo-Su 00:00-01:00 off")
        assertOpened("06.10.2025 23:00", hours: hours, expected: true)
        assertInfo("06.10.2025 23:00", hours: hours, equals: "Will close at 00:00")
        assertOpened("07.10.2025 00:30", hours: hours, expected: false)
        assertInfo("07.10.2025 00:30", hours: hours, equals: "Will open at 01:00")
        assertOpened("07.10.2025 01:30", hours: hours, expected: true)
        assertInfo("07.10.2025 01:30", hours: hours, equals: "Will close at 02:00")

        // Whole-day "off" rules by year/day-month ranges must discard the opening time of that day (#21780).
        hours = makeHours("Mo-Fr 09:00-20:00; Sa 09:00-18:00; 2025 Jan 07 - 2025 Feb 26 closed")
        assertOpened("23.01.2025 07:40", hours: hours, expected: false)
        assertInfo("23.01.2025 07:40", hours: hours, equals: "2025 Jan 7-2025 Feb 26 off")
        assertOpened("23.01.2025 12:00", hours: hours, expected: false)
        assertInfo("27.02.2025 09:30", hours: hours, equals: "Open until 20:00")
        assertInfo("06.01.2025 12:00", hours: hours, equals: "Open until 20:00")
    }

    func testMonthRuleOverride() {
        // Later month rules override the default rule also inside the default time window (#23457).
        configure(localeIdentifier: "en_GB", twelveHour: false)

        let hours = makeHours("07:00-17:00; Mar 07:00-19:00; Apr 07:00-21:00; May-Aug 07:00-22:00; Sep 07:00-21:00; Oct 07:00-19:00")
        assertOpened("12.09.2025 14:09", hours: hours, expected: true)
        assertInfo("12.09.2025 14:09", hours: hours, equals: "Open until 21:00")
        assertInfo("12.09.2025 18:00", hours: hours, equals: "Open until 21:00")
        assertInfo("12.09.2025 20:00", hours: hours, equals: "Will close at 21:00")
        assertOpened("12.09.2025 21:30", hours: hours, expected: false)
        assertInfo("12.09.2025 21:30", hours: hours, equals: "Will open tomorrow at 07:00")
        assertInfo("12.01.2025 14:09", hours: hours, equals: "Open until 17:00")
        assertInfo("12.06.2025 21:30", hours: hours, equals: "Will close at 22:00")
        assertInfo("12.03.2025 18:30", hours: hours, equals: "Will close at 19:00")
    }

    func testHolidayWithWeekday() {
        // "PH Su" means "public holidays falling on Sunday" and must not fill
        // the weekday range Mo-Su (#23990).
        configure(localeIdentifier: "en_GB", twelveHour: false)

        var hours = makeHours("Tu-Sa,PH 10:00-12:00,14:00-19:00; PH Su off")
        assertAssembled(hours, equals: "Tu-Sa, PH 10:00-12:00, 14:00-19:00; PH off")
        assertOpened("07.10.2025 11:00", hours: hours, expected: true) // Regular Tuesday must stay open.
        assertOpened("05.10.2025 11:00", hours: hours, expected: false) // Regular Sunday.
        assertOpened("06.10.2025 11:00", hours: hours, expected: false) // Monday.
        assertInfo("07.10.2025 11:00", hours: hours, equals: "Will close at 12:00")

        // Without holiday info the rule can not be applied to regular weekdays.
        hours = makeHours("PH Su 08:30-12:30")
        assertAssembled(hours, equals: "PH 08:30-12:30")
        assertOpened("06.10.2025 09:00", hours: hours, expected: false) // Monday.
        assertOpened("05.10.2025 09:00", hours: hours, expected: false) // Regular Sunday.

        hours = makeHours("SH Mo-Fr 10:00-14:00")
        assertOpened("06.10.2025 11:00", hours: hours, expected: false) // Regular Monday.
    }

    func testNthWeekdayOfMonth() {
        // Nth weekday of the month like "Su[1]", "Su[-1]" or "Su[1,3]" (#23990).
        configure(localeIdentifier: "en_GB", twelveHour: false)

        var hours = makeHours("Jul Su[1] 08:00-18:00")
        assertAssembled(hours, equals: "Jul Su[1] 08:00-18:00")
        assertOpened("06.07.2025 10:00", hours: hours, expected: true) // 1st Sunday of July.
        assertOpened("13.07.2025 10:00", hours: hours, expected: false) // 2nd Sunday.
        assertOpened("07.07.2025 10:00", hours: hours, expected: false) // Monday.
        assertOpened("01.06.2025 10:00", hours: hours, expected: false) // Sunday outside July.

        hours = makeHours("Nov Su[-1] 08:00-18:00")
        assertAssembled(hours, equals: "Nov Su[-1] 08:00-18:00")
        assertOpened("30.11.2025 10:00", hours: hours, expected: true) // Last Sunday of November.
        assertOpened("23.11.2025 10:00", hours: hours, expected: false) // 4th but not last Sunday.

        hours = makeHours("Su[1,3] 08:00-12:00")
        assertOpened("05.10.2025 09:00", hours: hours, expected: true) // 1st Sunday.
        assertOpened("12.10.2025 09:00", hours: hours, expected: false) // 2nd Sunday.
        assertOpened("19.10.2025 09:00", hours: hours, expected: true) // 3rd Sunday.

        // Full rule from #23990.
        hours = makeHours("Tu-Sa,PH 10:00-12:00,14:00-19:00; PH Su off; May 01,Dec 25 off; Jul Su[1] 08:00-18:00; Nov Su[4] 08:00-18:00")
        assertOpened("07.10.2025 11:00", hours: hours, expected: true) // Regular Tuesday.
        assertOpened("01.05.2025 11:00", hours: hours, expected: false) // May 1st.
        assertOpened("06.07.2025 09:00", hours: hours, expected: true) // 1st Sunday of July.
        assertOpened("23.11.2025 09:00", hours: hours, expected: true) // 4th Sunday of November.
        assertOpened("05.10.2025 11:00", hours: hours, expected: false) // Regular Sunday.

        // Library from #7857, the "Sa[1,3]" rule was parsed as "24/7" before.
        hours = makeHours("Jul-Aug Mo,Tu 13:00-19:00; Jul-Aug We-Fr 08:00-14:00; Jul-Aug Sa off; Jan-Jun,Sep-Dec Mo,Tu 13:00-19:00; Jan-Jun,Sep-Dec We-Fr 08:00-16:00; Jan-Jun,Sep-Dec Sa[1,3] 09:00-13:00; PH off")
        assertOpened("05.11.2019 05:00", hours: hours, expected: false) // Issue scenario: Tuesday 5 AM, was "open 24/7".
        assertOpened("05.11.2019 14:00", hours: hours, expected: true)
        assertOpened("01.11.2025 10:00", hours: hours, expected: true) // 1st Saturday of November.
        assertOpened("08.11.2025 10:00", hours: hours, expected: false) // 2nd Saturday.
        assertOpened("15.11.2025 10:00", hours: hours, expected: true) // 3rd Saturday.
        assertOpened("05.07.2025 10:00", hours: hours, expected: false) // Saturday in July is off.
        assertOpened("09.07.2025 09:00", hours: hours, expected: true) // Wednesday in July.
    }

    func testOvernightNextOpening() {
        // Overnight rules of other days must not report an opening time for today,
        // and a still running overnight session determines the closing time.
        configure(localeIdentifier: "en_GB", twelveHour: false)

        let hours = makeHours("Mo-Th,Su 09:00-00:30; Fr 09:00-16:30")
        // Friday evening: Saturday is closed, so the next opening is on Sunday
        // (was "Open from 09:00", which means "opens today").
        assertOpened("06.02.2026 21:00", hours: hours, expected: false)
        assertInfo("06.02.2026 21:00", hours: hours, equals: "Will open on 09:00 Sun.")
        assertInfo("06.02.2026 19:00", hours: hours, equals: "Will open on 09:00 Sun.")
        // Friday 00:15 is inside the Thursday session which ends 00:30
        // (was "Open until 16:30" from the Friday rule).
        assertOpened("06.02.2026 00:15", hours: hours, expected: true)
        assertInfo("06.02.2026 00:15", hours: hours, equals: "Will close at 00:30")
        // Unchanged behavior around it.
        assertInfo("06.02.2026 12:00", hours: hours, equals: "Open until 16:30")
        assertInfo("06.02.2026 15:00", hours: hours, equals: "Will close at 16:30")
        assertOpened("07.02.2026 12:00", hours: hours, expected: false)
        assertInfo("07.02.2026 12:00", hours: hours, equals: "Will open tomorrow at 09:00")
        // Sunday evening: the overnight session closes at 00:30 the next day, so the
        // "closing soon" warning must also trigger before midnight (was "Open until 00:30").
        assertOpened("08.02.2026 23:00", hours: hours, expected: true)
        assertInfo("08.02.2026 22:00", hours: hours, equals: "Open until 00:30") // 2.5 h to closing.
        assertInfo("08.02.2026 23:00", hours: hours, equals: "Will close at 00:30") // 1.5 h to closing.
        assertInfo("08.02.2026 23:50", hours: hours, equals: "Will close at 00:30") // 40 min to closing.
        assertInfo("09.02.2026 07:00", hours: hours, equals: "Will open at 09:00")
    }

    func testRealWorldSchedules() {
        // Real-world schedules (the kind actually tagged on OSM shops, bars, markets, museums)
        // exercising the fixes of this PR end to end: time-restricted "off", seasonal month
        // overrides, nth weekday of month and overnight next-open/close.
        configure(localeIdentifier: "en_GB", twelveHour: false)

        // Weekend-only nightclub, overnight into the next morning; next opening after the
        // last overnight day (Sat) skips the whole week to the following Friday.
        var hours = makeHours("Fr,Sa 20:00-04:00")
        assertAssembled(hours, equals: "Fr, Sa 20:00-04:00")
        assertInfo("03.01.2025 19:00", hours: hours, equals: "Will open at 20:00") // Fri, opens in 1 h.
        assertInfo("03.01.2025 23:30", hours: hours, equals: "Open until 04:00") // Fri night, closes 04:00.
        assertInfo("04.01.2025 02:00", hours: hours, equals: "Will close at 04:00") // Sat 02:00, Fri session.
        assertInfo("05.01.2025 01:00", hours: hours, equals: "Open until 04:00") // Sun 01:00, Sat session.
        assertOpened("05.01.2025 05:00", hours: hours, expected: false)
        assertInfo("05.01.2025 05:00", hours: hours, equals: "Will open on 20:00 Fri.") // Closed until next Fri.
        assertInfo("06.01.2025 12:00", hours: hours, equals: "Will open on 20:00 Fri.")

        // Neighbourhood bar, mix of overnight and non-overnight days; the "closing soon"
        // warning must trigger before midnight for the overnight days too.
        hours = makeHours("We-Th 18:00-01:00; Fr-Sa 18:00-03:00; Su 16:00-23:00")
        assertAssembled(hours, equals: "We, Th 18:00-01:00; Fr, Sa 18:00-03:00; Su 16:00-23:00")
        assertInfo("04.06.2025 23:30", hours: hours, equals: "Will close at 01:00") // Wed 23:30 -> 90 min to close.
        assertInfo("05.06.2025 00:30", hours: hours, equals: "Will close at 01:00") // Thu 00:30, Wed session.
        assertInfo("07.06.2025 02:00", hours: hours, equals: "Will close at 03:00") // Sat 02:00, Fri session.
        assertInfo("08.06.2025 22:00", hours: hours, equals: "Will close at 23:00") // Sun evening.
        assertOpened("08.06.2025 03:00", hours: hours, expected: false)
        assertInfo("08.06.2025 03:00", hours: hours, equals: "Open from 16:00") // Sun early morning, opens 16:00.
        assertInfo("10.06.2025 20:00", hours: hours, equals: "Will open tomorrow at 18:00") // Tue closed.

        // Ice-cream parlour with a reduced winter schedule that wraps the year end (Dec-Feb);
        // the winter rule must win inside the summer time window too (#23457 family).
        hours = makeHours("Mo-Su 12:00-22:00; Dec-Feb Mo-Su 13:00-18:00")
        assertInfo("15.01.2026 14:00", hours: hours, equals: "Open until 18:00") // Winter override.
        assertOpened("07.02.2026 12:30", hours: hours, expected: false)
        assertInfo("07.02.2026 12:30", hours: hours, equals: "Will open at 13:00") // 12:30 winter-closed.
        assertInfo("10.12.2025 20:00", hours: hours, equals: "Will open tomorrow at 13:00")
        assertInfo("20.06.2025 21:00", hours: hours, equals: "Will close at 22:00") // Summer.
        assertInfo("30.11.2025 19:00", hours: hours, equals: "Open until 22:00") // Nov still summer.

        // Museum with a Monday closing day and a wrap-around winter season (Nov-Mar).
        hours = makeHours("Tu-Su 10:00-18:00; Nov-Mar Tu-Su 10:00-16:00")
        assertInfo("14.02.2026 15:00", hours: hours, equals: "Will close at 16:00") // Winter.
        assertInfo("15.05.2025 17:00", hours: hours, equals: "Will close at 18:00") // Summer.
        assertOpened("08.06.2025 19:00", hours: hours, expected: false)
        assertInfo("08.06.2025 19:00", hours: hours, equals: "Will open on 10:00 Tue.") // Sun evening, Mon closed.
        assertInfo("20.01.2026 17:00", hours: hours, equals: "Will open tomorrow at 10:00")
        assertInfo("20.12.2025 07:30", hours: hours, equals: "Open from 10:00")

        // Pharmacy with a lunch closure; a passed lunch break must not shorten the afternoon
        // closing time (#22931) and the reopening is the end of the "off" range.
        hours = makeHours("Mo-Fr 08:30-18:30; Sa 09:00-13:00; Mo-Fr 13:00-14:00 off")
        assertAssembled(hours, equals: "Mo-Fr 08:30-18:30; Sa 09:00-13:00; Mo-Fr 13:00-14:00 off")
        assertInfo("02.06.2025 10:30", hours: hours, equals: "Open until 13:00") // Closes for lunch.
        assertOpened("02.06.2025 13:20", hours: hours, expected: false)
        assertInfo("02.06.2025 13:20", hours: hours, equals: "Will open at 14:00") // Lunch break.
        assertInfo("02.06.2025 15:00", hours: hours, equals: "Open until 18:30") // Afternoon, full closing time.
        assertInfo("02.06.2025 17:00", hours: hours, equals: "Will close at 18:30")
        assertInfo("07.06.2025 11:00", hours: hours, equals: "Will close at 13:00") // Saturday.
        assertInfo("08.06.2025 12:00", hours: hours, equals: "Will open tomorrow at 08:30")

        // Weekly farmers market plus a "first Sunday of the month" special during the season.
        hours = makeHours("We,Sa 07:00-13:00; Apr-Oct Su[1] 08:00-16:00")
        assertAssembled(hours, equals: "We, Sa 07:00-13:00; Apr-Oct Su[1] 08:00-16:00")
        assertOpened("06.07.2025 07:30", hours: hours, expected: false)
        assertInfo("06.07.2025 07:30", hours: hours, equals: "Will open at 08:00") // 1st Sunday of July.
        assertInfo("06.07.2025 09:00", hours: hours, equals: "Open until 16:00")
        assertInfo("06.07.2025 15:00", hours: hours, equals: "Will close at 16:00")
        assertOpened("13.07.2025 10:00", hours: hours, expected: false) // 2nd Sunday, no market.
        assertInfo("13.07.2025 10:00", hours: hours, equals: "Will open on 07:00 Wed.")
        assertInfo("04.10.2025 12:00", hours: hours, equals: "Will close at 13:00") // Saturday market.
        assertOpened("07.01.2025 08:00", hours: hours, expected: false) // January, out of season.

        // Rural church sharing a priest: mass on 1st/3rd/5th Sundays in the morning,
        // on 2nd/4th Sundays in the evening; the tricky 5th-Sunday occurrence must count.
        hours = makeHours("Su[1,3,5] 09:00-10:00; Su[2,4] 18:00-19:00")
        assertAssembled(hours, equals: "Su[1,3,5] 09:00-10:00; Su[2,4] 18:00-19:00")
        assertOpened("03.08.2025 09:30", hours: hours, expected: true) // 1st Sunday morning.
        assertInfo("03.08.2025 09:30", hours: hours, equals: "Will close at 10:00")
        assertOpened("10.08.2025 09:30", hours: hours, expected: false) // 2nd Sunday, no morning mass.
        assertInfo("10.08.2025 09:30", hours: hours, equals: "Open from 18:00")
        assertInfo("10.08.2025 18:30", hours: hours, equals: "Will close at 19:00") // 2nd Sunday evening.
        assertOpened("31.08.2025 09:45", hours: hours, expected: true) // 5th Sunday counts.
        assertInfo("31.08.2025 09:45", hours: hours, equals: "Will close at 10:00")
        assertInfo("06.08.2025 12:00", hours: hours, equals: "Will open on 18:00 Sun.") // Next is 2nd Sunday.

        // Bakery open every day including Sunday morning, closed on public holidays; the
        // trailing "PH off" must not disturb the regular Sunday hours.
        hours = makeHours("Mo-Fr 06:00-18:30; Sa 06:30-13:00; Su 07:30-11:00; PH off")
        assertAssembled(hours, equals: "Mo-Fr 06:00-18:30; Sa 06:30-13:00; Su 07:30-11:00; PH off")
        assertInfo("12.10.2025 08:00", hours: hours, equals: "Open until 11:00") // Sunday morning.
        assertInfo("12.10.2025 09:30", hours: hours, equals: "Will close at 11:00")
        assertOpened("12.10.2025 12:00", hours: hours, expected: false)
        assertInfo("12.10.2025 12:00", hours: hours, equals: "Will open tomorrow at 06:00")
        assertInfo("11.10.2025 13:30", hours: hours, equals: "Will open tomorrow at 07:30") // Sat -> Sun.
        assertInfo("10.10.2025 18:00", hours: hours, equals: "Will close at 18:30") // Friday.
        assertInfo("06.10.2025 03:00", hours: hours, equals: "Open from 06:00")

        // Self-service car wash with a reduced-noise winter evening off window; the seasonal
        // "off" must only shorten its own window and only in its months.
        hours = makeHours("Mo-Sa 07:00-21:00; Nov-Feb 19:00-21:00 off")
        assertInfo("15.01.2025 18:30", hours: hours, equals: "Will close at 19:00") // Winter, off shortens evening.
        assertInfo("16.07.2025 18:30", hours: hours, equals: "Open until 21:00") // Summer, no off.
        assertInfo("16.07.2025 19:30", hours: hours, equals: "Will close at 21:00")
        assertInfo("16.07.2025 04:30", hours: hours, equals: "Open from 07:00")
        assertInfo("15.01.2025 06:00", hours: hours, equals: "Will open at 07:00")
    }

    func testGetShortInfo() {
        configure(localeIdentifier: "en_GB", twelveHour: false)

        var hours = makeHours("24/7")
        assertShortInfo("16.02.2018 12:00", hours: hours, equals: "24/7")

        hours = makeHours("Mo-Fr 12:00-15:00, Tu-Fr 17:00-23:00, Sa 12:00-23:00, Su 14:00-23:00")
        assertShortInfo("16.02.2018 09:45", hours: hours, equals: "From 12:00")
        assertShortInfo("16.02.2018 12:00", hours: hours, equals: "Until 15:00")
        assertShortInfo("16.02.2018 14:00", hours: hours, equals: "Until 15:00")
        assertShortInfo("16.02.2018 16:00", hours: hours, equals: "From 17:00")

        hours = makeHours("Mo-Fr 09:00-18:00")
        assertShortInfo("18.02.2018 12:00", hours: hours, equals: "Tomorrow 09:00")

        hours = makeHours("Mo-Fr 08:00-12:00, Mo,Tu,Th 15:00-17:00; PH off")
        assertShortInfo("09.08.2019 15:00", hours: hours, equals: "From 08:00 Mon")

        hours = makeHours("Mo-Fr; PH off")
        assertShortInfo("09.08.2019 15:00", hours: hours, equals: "Mon-Fri")
    }

    private func configure(localeIdentifier: String?, twelveHour: Bool) {
        OpeningHoursParserTestSupport.configureLocaleIdentifier(localeIdentifier, twelveHourFormattingEnabled: twelveHour)
    }

    private func makeHours(_ openingHours: String) -> OpeningHoursParserTestSupport {
        OpeningHoursParserTestSupport(openingHoursString: openingHours)
    }

    private func assertOpened(_ dateTime: String, hours: OpeningHoursParserTestSupport, expected: Bool, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(hours.isOpened(at: dateTime), expected, "Unexpected opening state for \(dateTime)", file: file, line: line)
    }

    private func assertInfo(_ dateTime: String, hours: OpeningHoursParserTestSupport, equals expected: String, sequenceIndex: Int = -1, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(
            normalized(hours.info(at: dateTime, sequenceIndex: sequenceIndex)),
            normalized(expected),
            "Unexpected info for \(dateTime)",
            file: file,
            line: line
        )
    }

    private func assertShortInfo(_ dateTime: String, hours: OpeningHoursParserTestSupport, equals expected: String, sequenceIndex: Int = -1, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(
            normalized(hours.shortInfo(at: dateTime, sequenceIndex: sequenceIndex)),
            normalized(expected),
            "Unexpected short info for \(dateTime)",
            file: file,
            line: line
        )
    }

    private func assertAssembled(_ hours: OpeningHoursParserTestSupport, equals expected: String, localized: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        let actual = localized ? hours.localizedAssembledString() : hours.assembledString()
        XCTAssertEqual(normalized(actual), normalized(expected), file: file, line: line)
    }

    private func normalized(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .lowercased()
    }
}
