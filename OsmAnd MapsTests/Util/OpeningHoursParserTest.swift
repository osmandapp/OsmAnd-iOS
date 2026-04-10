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

        configure(localeIdentifier: "zh", twelveHour: true)
        hours = makeHours("Mo-Fr 04:30-10:00, 07:30-23:00; Sa, Su, PH 13:30-23:00")
        assertAssembled(hours, equals: "周一-周五 4:30-10:00, 07:30-23:00; 周六, 周日, ph 1:30-23:00", localized: true)

        configure(localeIdentifier: "ar", twelveHour: true)
        hours = makeHours("Mo-Fr 04:30-10:00, 07:30-23:00; Sa, Su, PH 13:30-23:00")
        assertAssembled(hours, equals: "اثنين-جمعة 4:30-10:00 ص, 7:30 ص-11:00 م; سبت, أحد, PH 1:30-11:00 م", localized: true)
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

    func testGetShortInfo() {
        configure(localeIdentifier: "en_GB", twelveHour: false)

        var hours = makeHours("24/7")
        assertShortInfo("16.02.2018 12:00", hours: hours, equals: "24/7")

        hours = makeHours("Mo-Fr 12:00-15:00, Tu-Fr 17:00-23:00, Sa 12:00-23:00, Su 14:00-23:00")
        assertShortInfo("16.02.2018 09:45", hours: hours, equals: "12:00")
        assertShortInfo("16.02.2018 12:00", hours: hours, equals: "Until 15:00")
        assertShortInfo("16.02.2018 14:00", hours: hours, equals: "Until 15:00")
        assertShortInfo("16.02.2018 16:00", hours: hours, equals: "17:00")

        hours = makeHours("Mo-Fr 09:00-18:00")
        assertShortInfo("18.02.2018 12:00", hours: hours, equals: "Tomorrow 09:00")

        hours = makeHours("Mo-Fr 08:00-12:00, Mo,Tu,Th 15:00-17:00; PH off")
        assertShortInfo("09.08.2019 15:00", hours: hours, equals: "08:00 Mon")
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
