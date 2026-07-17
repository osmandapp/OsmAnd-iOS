//
//  AstroScheduleCardController.swift
//  OsmAnd Maps
//
//  Ported from Android AstroScheduleCardController.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

final class AstroScheduleCardController {
    static let periodDays = 7
    private static let sampleCount = AstroChartMath.scheduleSampleCount
    private static let setSearchLimitDays = 5.0

    private(set) var skyObject: SkyObject?
    private(set) var observer: Observer?
    private(set) var timeZone: TimeZone = .current
    private(set) var periodStart: Date = Date()
    private(set) var rangeLabel = ""
    private(set) var days: [AstroScheduleDayItem] = []
    private(set) var showResetPeriodButton = false

    var onDataChanged: (() -> Void)?
    
    private let rangeFormatter: DateIntervalFormatter = {
        let formatter = DateIntervalFormatter()
        formatter.locale = .current
        formatter.dateTemplate = "d MMM"
        return formatter
    }()

    private var computeWorkItem: DispatchWorkItem?
    private var lastObjectId: String?
    private var lastObserverLat = Double.nan
    private var lastObserverLon = Double.nan
    private var lastObserverHeight = Double.nan
    private var lastPeriodStart: Date?
    private var lastTimeZone: TimeZone?
    private var lastShowResetPeriodButton = false

    func update(skyObject: SkyObject?,
                observer: Observer?,
                periodStart: Date,
                timeZone: TimeZone,
                showResetPeriodButton: Bool) {
        self.skyObject = skyObject
        self.observer = observer
        self.periodStart = normalizedDay(periodStart, timeZone: timeZone)
        self.timeZone = timeZone
        self.showResetPeriodButton = showResetPeriodButton
        rangeFormatter.timeZone = timeZone

        guard let skyObject, let observer else {
            computeWorkItem?.cancel()
            rangeLabel = ""
            days = []
            lastObjectId = nil
            lastObserverLat = .nan
            lastObserverLon = .nan
            lastObserverHeight = .nan
            lastPeriodStart = nil
            lastTimeZone = nil
            lastShowResetPeriodButton = false
            onDataChanged?()
            return
        }

        let calendar = makeCalendar(timeZone: timeZone)
        let periodEnd = calendar.date(byAdding: .day,
                                      value: Self.periodDays - 1,
                                      to: self.periodStart) ?? self.periodStart
        rangeLabel = rangeFormatter.string(from: self.periodStart, to: periodEnd).replacingOccurrences(of: "—", with: " - ")
        let computationMatchesState =
            lastObjectId == skyObject.id &&
            lastObserverLat == observer.latitude &&
            lastObserverLon == observer.longitude &&
            lastObserverHeight == observer.height &&
            lastPeriodStart == self.periodStart &&
            lastTimeZone == timeZone &&
            lastShowResetPeriodButton == showResetPeriodButton &&
            !days.isEmpty
        if computationMatchesState {
            return
        }

        computeWorkItem?.cancel()
        let periodStartCopy = self.periodStart
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            let entries = self.buildPeriodEntries(obj: skyObject,
                                                  observer: observer,
                                                  periodStart: periodStartCopy,
                                                  timeZone: timeZone)
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      !(self.computeWorkItem?.isCancelled ?? true),
                      self.skyObject?.id == skyObject.id,
                      self.observer?.latitude == observer.latitude,
                      self.observer?.longitude == observer.longitude,
                      self.observer?.height == observer.height,
                      self.periodStart == periodStartCopy,
                      self.timeZone == timeZone else {
                    return
                }
                self.days = entries
                self.lastObjectId = skyObject.id
                self.lastObserverLat = observer.latitude
                self.lastObserverLon = observer.longitude
                self.lastObserverHeight = observer.height
                self.lastPeriodStart = periodStartCopy
                self.lastTimeZone = timeZone
                self.lastShowResetPeriodButton = showResetPeriodButton
                self.onDataChanged?()
            }
        }
        computeWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }

    func buildItem() -> AstroScheduleCardItem? {
        guard skyObject != nil, observer != nil else {
            return nil
        }
        return AstroScheduleCardItem(periodStart: periodStart,
                                     rangeLabel: rangeLabel,
                                     days: days,
                                     showResetPeriodButton: showResetPeriodButton)
    }

    func cancelPendingWork() {
        computeWorkItem?.cancel()
        computeWorkItem = nil
    }

    private func buildPeriodEntries(obj: SkyObject,
                                    observer: Observer,
                                    periodStart: Date,
                                    timeZone: TimeZone) -> [AstroScheduleDayItem] {
        let calendar = makeCalendar(timeZone: timeZone)
        return (0..<Self.periodDays).map { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: periodStart) ?? periodStart
            return buildDayEntry(obj: obj, observer: observer, day: day, timeZone: timeZone)
        }
    }

    private func buildDayEntry(obj: SkyObject,
                               observer: Observer,
                               day: Date,
                               timeZone: TimeZone) -> AstroScheduleDayItem {
        let startLocal = normalizedDay(day, timeZone: timeZone)
        let endLocal = startLocal.addingTimeInterval(24 * 60 * 60)
        let dayEndInclusive = endLocal.addingTimeInterval(-0.001)
        let riseSet = AstroUtils.nextRiseSet(object: obj,
                                             startSearch: startLocal,
                                             observer: observer,
                                             windowStart: startLocal,
                                             windowEnd: dayEndInclusive)
        let setTime = riseSet.rise.flatMap {
            AstroUtils.nextRiseSet(object: obj,
                                   startSearch: $0,
                                   observer: observer,
                                   limitDays: Self.setSearchLimitDays).set
        }
        let setDayOffset = setTime.map { dayOffset(from: startLocal, to: $0, timeZone: timeZone) } ?? 0
        let samples = AstroChartMath.computeDaySamples(objectToRender: obj,
                                                       observer: observer,
                                                       startLocal: startLocal,
                                                       endLocal: endLocal,
                                                       sampleCount: Self.sampleCount,
                                                       includeAzimuth: false)
        let timeFormatter = createTimeFormatter(timeZone: timeZone)
        return AstroScheduleDayItem(date: day,
                                    riseTime: riseSet.rise.map { timeFormatter.string(from: $0) },
                                    setTime: setTime.map { timeFormatter.string(from: $0) },
                                    setDayOffset: max(0, setDayOffset),
                                    graph: AstroScheduleDayGraphSnapshot(sunAltitudes: samples.sunAltitudes,
                                                                        objectAltitudes: samples.objectAltitudes))
    }

    private func dayOffset(from start: Date, to end: Date, timeZone: TimeZone) -> Int {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let from = calendar.startOfDay(for: start)
        let to = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    private func createTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = OAUtilities.is12HourTimeFormat() ? "h:mm a" : "HH:mm"
        return formatter
    }

    private func normalizedDay(_ date: Date, timeZone: TimeZone) -> Date {
        makeCalendar(timeZone: timeZone).startOfDay(for: date)
    }

    private func makeCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar
    }
}
