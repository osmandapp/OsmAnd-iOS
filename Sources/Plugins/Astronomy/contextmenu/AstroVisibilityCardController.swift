//
//  AstroVisibilityCardController.swift
//  OsmAnd Maps
//
//  Ported from Android AstroVisibilityCardController.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import Foundation
import OsmAndShared
import UIKit

final class AstroVisibilityCardController {
    private static let citySearchRadiusMeters = 50 * 1000

    private(set) var skyObject: SkyObject?
    private(set) var observer: Observer?
    private(set) var date: Date = Date()
    private(set) var timeZone: TimeZone = .current

    private(set) var riseTime: String?
    private(set) var culminationTime: String?
    private(set) var setTime: String?
    private(set) var locationText = ""
    private(set) var culminationColor = UIColor.clear
    private(set) var titleText = localizedString("astro_today_visibility")
    private(set) var showResetButton = false
    private(set) var cursorReferenceTimeMillis: Int64 = 0

    var onDataChanged: (() -> Void)?

    private var lastLocationKey: String?
    private var graphSnapshot: AstroVisibilityGraphSnapshot?
    private var graphObjectId: String?
    private var graphObserverLat = Double.nan
    private var graphObserverLon = Double.nan
    private var graphObserverHeight = Double.nan
    private var computeWorkItem: DispatchWorkItem?
    private var locationWorkItem: DispatchWorkItem?
    private let titleDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEEEMMMMd")
        return formatter
    }()

    func update(skyObject: SkyObject?,
                observer: Observer?,
                date: Date,
                timeZone: TimeZone,
                cursorReferenceTimeMillis: Int64,
                isTodayVisibility: Bool) {
        self.skyObject = skyObject
        self.observer = observer
        self.date = normalizedDay(date, timeZone: timeZone)
        self.timeZone = timeZone
        self.cursorReferenceTimeMillis = cursorReferenceTimeMillis
        titleDateFormatter.timeZone = timeZone
        titleText = isTodayVisibility
            ? localizedString("astro_today_visibility")
            : titleDateFormatter.string(from: self.date)
        showResetButton = !isTodayVisibility

        guard let skyObject, let observer else {
            cancelPendingWork()
            riseTime = nil
            culminationTime = nil
            setTime = nil
            locationText = ""
            culminationColor = .clear
            graphSnapshot = nil
            graphObjectId = nil
            graphObserverLat = .nan
            graphObserverLon = .nan
            graphObserverHeight = .nan
            return
        }

        let startLocal = noon(on: self.date, timeZone: timeZone)
        let endLocal = startLocal.addingTimeInterval(24 * 60 * 60)
        let riseSet = AstroUtils.nextRiseSet(object: skyObject,
                                             startSearch: startLocal,
                                             observer: observer,
                                             windowStart: startLocal,
                                             windowEnd: endLocal)
        let culmination = AstroChartMath.findCulmination(obj: skyObject,
                                                         observer: observer,
                                                         startLocal: startLocal,
                                                         endLocal: endLocal)
        let timeFormatter = createTimeFormatter(timeZone: timeZone)

        riseTime = riseSet.rise.map { timeFormatter.string(from: $0) }
        culminationTime = culmination.time.map { timeFormatter.string(from: $0) }
        setTime = riseSet.set.map { timeFormatter.string(from: $0) }
        culminationColor = AstroChartColorPalette().colorForObjectAltitude(culmination.altitude ?? 0.0)
        maybeRecomputeGraph(skyObject: skyObject, observer: observer, date: self.date, timeZone: timeZone)

        let location = resolveLocationTarget(observer: observer)
        let locationKey = String(format: "%.6f,%.6f", location.coordinate.latitude, location.coordinate.longitude)
        if lastLocationKey != locationKey || locationText.isEmpty {
            lastLocationKey = locationKey
            locationText = formatCoordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            onDataChanged?()
            requestLocationText(location: location, key: locationKey)
        }
    }

    func buildItem() -> AstroVisibilityCardItem? {
        guard skyObject != nil, observer != nil else {
            return nil
        }
        return AstroVisibilityCardItem(graph: graphSnapshot,
                                       cursorReferenceTimeMillis: cursorReferenceTimeMillis,
                                       riseTime: riseTime,
                                       culminationTime: culminationTime,
                                       setTime: setTime,
                                       locationText: locationText,
                                       culminationColor: culminationColor,
                                       titleText: titleText,
                                       showResetButton: showResetButton)
    }

    func cancelPendingWork() {
        computeWorkItem?.cancel()
        computeWorkItem = nil
        locationWorkItem?.cancel()
        locationWorkItem = nil
    }

    private func maybeRecomputeGraph(skyObject: SkyObject,
                                     observer: Observer,
                                     date: Date,
                                     timeZone: TimeZone) {
        let graphStartMillis = millis(noon(on: date, timeZone: timeZone))
        let graphMatchesState = graphSnapshot?.timeZone == timeZone &&
            graphSnapshot?.startMillis == graphStartMillis &&
            graphObjectId == skyObject.id &&
            graphObserverLat == observer.latitude &&
            graphObserverLon == observer.longitude &&
            graphObserverHeight == observer.height
        if graphMatchesState {
            return
        }

        computeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            let snapshot = self.computeGraphSnapshot(skyObject: skyObject,
                                                     observer: observer,
                                                     date: date,
                                                     timeZone: timeZone)
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      !(self.computeWorkItem?.isCancelled ?? true),
                      self.skyObject?.id == skyObject.id,
                      self.observer?.latitude == observer.latitude,
                      self.observer?.longitude == observer.longitude,
                      self.observer?.height == observer.height,
                      self.date == date,
                      self.timeZone == timeZone else {
                    return
                }
                self.graphSnapshot = snapshot
                self.graphObjectId = skyObject.id
                self.graphObserverLat = observer.latitude
                self.graphObserverLon = observer.longitude
                self.graphObserverHeight = observer.height
                self.onDataChanged?()
            }
        }
        computeWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }

    private func computeGraphSnapshot(skyObject: SkyObject,
                                      observer: Observer,
                                      date: Date,
                                      timeZone: TimeZone) -> AstroVisibilityGraphSnapshot {
        let startLocal = noon(on: date, timeZone: timeZone)
        let endLocal = startLocal.addingTimeInterval(24 * 60 * 60)
        let samples = AstroChartMath.computeDaySamples(objectToRender: skyObject,
                                                       observer: observer,
                                                       startLocal: startLocal,
                                                       endLocal: endLocal,
                                                       sampleCount: AstroChartMath.visibilitySampleCount,
                                                       includeAzimuth: true)
        return AstroVisibilityGraphSnapshot(startMillis: samples.startMillis,
                                            endMillis: samples.endMillis,
                                            timeZone: timeZone,
                                            objectAltitudes: samples.objectAltitudes,
                                            objectAzimuths: samples.objectAzimuths ?? Array(repeating: 0.0, count: samples.objectAltitudes.count),
                                            sunAltitudes: samples.sunAltitudes)
    }

    private func formatCoordinates(latitude: Double, longitude: Double) -> String {
        let latDir = localizedString(latitude >= 0.0 ? "north_abbreviation" : "south_abbreviation")
        let lonDir = localizedString(longitude >= 0.0 ? "east_abbreviation" : "west_abbreviation")
        return String(format: "%.2f° %@, %.2f° %@",
                      locale: Locale(identifier: "en_US_POSIX"),
                      abs(latitude),
                      latDir,
                      abs(longitude),
                      lonDir)
    }

    private func createTimeFormatter(timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = .current
        formatter.dateFormat = OAUtilities.is12HourTimeFormat() ? "h:mm a" : "HH:mm"
        return formatter
    }

    private func resolveLocationTarget(observer: Observer) -> CLLocation {
        if let trackingUtilities = OAMapViewTrackingUtilities.instance(),
           trackingUtilities.isMapLinkedToLocation(),
           let lastKnownLocation = OsmAndApp.swiftInstance()?.locationServices?.lastKnownLocation {
            return lastKnownLocation
        }
        if let mapLocation = OARootViewController.instance()?.mapPanel?.mapViewController.getMapLocation() {
            return mapLocation
        }
        return CLLocation(latitude: observer.latitude, longitude: observer.longitude)
    }

    private func requestLocationText(location: CLLocation, key: String) {
        locationWorkItem?.cancel()
        let coordinate = location.coordinate
        let coords = formatCoordinates(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapPanel = OARootViewController.instance()?.mapPanel
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }
            let address = mapPanel?.findRoadName(byLat: coordinate.latitude, lon: coordinate.longitude)
            let resolved = self.extractCity(address) ?? coords
            DispatchQueue.main.async { [weak self] in
                guard let self,
                      !(self.locationWorkItem?.isCancelled ?? true),
                      self.lastLocationKey == key else {
                    return
                }
                let changed = self.locationText != resolved
                self.locationText = resolved
                self.locationWorkItem = nil
                if changed {
                    self.onDataChanged?()
                }
            }
        }
        locationWorkItem = workItem
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
    }

    private func extractCity(_ address: String?) -> String? {
        guard var normalized = address?.trimmingCharacters(in: .whitespacesAndNewlines),
              !normalized.isEmpty else {
            return nil
        }
        let nearPrefix = "\(localizedString("shared_string_near")) "
        if normalized.hasPrefix(nearPrefix) {
            normalized.removeFirst(nearPrefix.count)
            normalized = normalized.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let city = normalized.components(separatedBy: ",").last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return city.isEmpty ? nil : city
    }

    private func normalizedDay(_ date: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.startOfDay(for: date)
    }

    private func noon(on date: Date, timeZone: TimeZone) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let start = calendar.startOfDay(for: date)
        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: start) ?? start.addingTimeInterval(12 * 60 * 60)
    }

    private func millis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }
}
