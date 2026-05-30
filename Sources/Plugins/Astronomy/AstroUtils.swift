//
//  AstroUtils.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import Foundation
import OsmAndShared
import UIKit

enum AstroUtils {
    private static let customStarLock = NSLock()

    static let solarSystemWikidataIds: [String: Body] = [
        "Q525": Body.sun,
        "Q405": Body.moon,
        "Q308": Body.mercury,
        "Q313": Body.venus,
        "Q111": Body.mars,
        "Q319": Body.jupiter,
        "Q193": Body.saturn,
        "Q324": Body.uranus,
        "Q332": Body.neptune,
        "Q339": Body.pluto
    ]

    static func astronomyTime(from date: Date) -> Time {
        Time.companion.fromMillisecondsSince1970(millis: Int64(date.timeIntervalSince1970 * 1000.0))
    }

    static func observer(from location: CLLocation?) -> Observer {
        let coordinate = location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let altitude = location?.altitude.isFinite == true ? location?.altitude ?? 0 : 0
        return Observer(latitude: coordinate.latitude, longitude: coordinate.longitude, height: altitude)
    }

    static func horizontalPosition(for object: SkyObject, time: Time, observer: Observer) -> Topocentric? {
        if let body = object.body {
            let equatorial = AstronomyKt.equator(
                body: body,
                time: time,
                observer: observer,
                equdate: EquatorEpoch.ofdate,
                aberration: Aberration.corrected
            )
            object.ra = equatorial.ra
            object.dec = equatorial.dec
            object.distAu = equatorial.dist
            return AstronomyKt.horizon(time: time,
                                       observer: observer,
                                       ra: equatorial.ra,
                                       dec: equatorial.dec,
                                       refraction: Refraction.normal)
        }

        return AstronomyKt.horizon(time: time,
                                   observer: observer,
                                   ra: object.ra,
                                   dec: object.dec,
                                   refraction: Refraction.normal)
    }

    static func withCustomStar<T>(ra: Double, dec: Double, block: (Body) -> T) -> T {
        customStarLock.lock()
        defer { customStarLock.unlock() }
        AstronomyKt.defineStar(body: Body.star1, ra: ra, dec: dec, distanceLightYears: 1000.0)
        return block(Body.star1)
    }

    static func altitude(_ body: Body, at date: Date, observer: Observer) -> Double {
        let time = astronomyTime(from: date)
        let equatorial = AstronomyKt.equator(body: body,
                                             time: time,
                                             observer: observer,
                                             equdate: EquatorEpoch.ofdate,
                                             aberration: Aberration.corrected)
        let horizontal = AstronomyKt.horizon(time: time,
                                             observer: observer,
                                             ra: equatorial.ra,
                                             dec: equatorial.dec,
                                             refraction: Refraction.normal)
        return horizontal.altitude
    }

    static func altitude(_ object: SkyObject, at date: Date, observer: Observer) -> Double {
        if let body = object.body {
            return altitude(body, at: date, observer: observer)
        }
        return withCustomStar(ra: object.ra, dec: object.dec) { body in
            altitude(body, at: date, observer: observer)
        }
    }

    static func nextRiseSet(body: Body,
                            startSearch: Date,
                            observer: Observer,
                            windowStart: Date? = nil,
                            windowEnd: Date? = nil,
                            limitDays: Double = 2.0) -> (rise: Date?, set: Date?) {
        let searchStart = astronomyTime(from: startSearch)
        let nextRise = AstronomyKt.searchRiseSet(body: body,
                                                 observer: observer,
                                                 direction: Direction.rise,
                                                 startTime: searchStart,
                                                 limitDays: limitDays,
                                                 metersAboveGround: 0.0)
        let nextSet = AstronomyKt.searchRiseSet(body: body,
                                                observer: observer,
                                                direction: Direction.set,
                                                startTime: searchStart,
                                                limitDays: limitDays,
                                                metersAboveGround: 0.0)
        return (filterRiseSetDate(date(from: nextRise), windowStart: windowStart, windowEnd: windowEnd),
                filterRiseSetDate(date(from: nextSet), windowStart: windowStart, windowEnd: windowEnd))
    }

    static func nextRiseSet(object: SkyObject,
                            startSearch: Date,
                            observer: Observer,
                            windowStart: Date? = nil,
                            windowEnd: Date? = nil,
                            limitDays: Double = 2.0) -> (rise: Date?, set: Date?) {
        if let body = object.body {
            return nextRiseSet(body: body,
                               startSearch: startSearch,
                               observer: observer,
                               windowStart: windowStart,
                               windowEnd: windowEnd,
                               limitDays: limitDays)
        }
        return withCustomStar(ra: object.ra, dec: object.dec) { body in
            nextRiseSet(body: body,
                        startSearch: startSearch,
                        observer: observer,
                        windowStart: windowStart,
                        windowEnd: windowEnd,
                        limitDays: limitDays)
        }
    }

    static func date(from time: Time?) -> Date? {
        guard let time else {
            return nil
        }
        return Date(timeIntervalSince1970: TimeInterval(time.toMillisecondsSince1970()) / 1000.0)
    }

    private static func filterRiseSetDate(_ date: Date?, windowStart: Date?, windowEnd: Date?) -> Date? {
        guard let date else {
            return nil
        }
        if let windowStart, date < windowStart {
            return nil
        }
        if let windowEnd, date > windowEnd {
            return nil
        }
        return date
    }

    static func bodyName(_ body: Body) -> String {
        bodyDisplayName(body)
    }

    static func bodyDisplayName(_ body: Body) -> String {
        if body === Body.sun {
            return localizedString("astro_name_sun")
        } else if body === Body.moon {
            return localizedString("astro_name_moon")
        } else if body === Body.mercury {
            return localizedString("astro_name_mercury")
        } else if body === Body.venus {
            return localizedString("astro_name_venus")
        } else if body === Body.mars {
            return localizedString("astro_name_mars")
        } else if body === Body.jupiter {
            return localizedString("astro_name_jupiter")
        } else if body === Body.saturn {
            return localizedString("astro_name_saturn")
        } else if body === Body.uranus {
            return localizedString("astro_name_uranus")
        } else if body === Body.neptune {
            return localizedString("astro_name_neptune")
        } else if body === Body.pluto {
            return localizedString("astro_name_pluto")
        } else {
            return body.name
        }
    }

    static func bodyColor(_ body: Body) -> UIColor {
        color(for: body)
    }

    static func color(for body: Body) -> UIColor {
        if body === Body.sun {
            return UIColor(red: 1.0, green: 0.69, blue: 0.20, alpha: 1.0)
        } else if body === Body.moon {
            return UIColor(white: 0.88, alpha: 1.0)
        } else if body === Body.mars {
            return UIColor(red: 0.95, green: 0.36, blue: 0.22, alpha: 1.0)
        } else if body === Body.jupiter {
            return UIColor(red: 0.95, green: 0.73, blue: 0.48, alpha: 1.0)
        } else if body === Body.saturn {
            return UIColor(red: 0.95, green: 0.82, blue: 0.52, alpha: 1.0)
        } else if body === Body.neptune || body === Body.uranus {
            return UIColor(red: 0.42, green: 0.73, blue: 1.0, alpha: 1.0)
        } else {
            return UIColor(red: 0.87, green: 0.90, blue: 1.0, alpha: 1.0)
        }
    }

    static func color(for type: SkyObjectType, magnitude: Double?) -> UIColor {
        switch type {
        case .STAR:
            let brightness = max(0.45, min(1.0, 1.0 - ((magnitude ?? 2.0) / 8.0)))
            return UIColor(red: brightness, green: brightness, blue: 1.0, alpha: 1.0)
        case .GALAXY, .GALAXY_CLUSTER:
            return UIColor(red: 0.52, green: 0.74, blue: 1.0, alpha: 1.0)
        case .NEBULA:
            return UIColor(red: 0.85, green: 0.45, blue: 0.95, alpha: 1.0)
        case .OPEN_CLUSTER, .GLOBULAR_CLUSTER:
            return UIColor(red: 0.50, green: 0.95, blue: 0.78, alpha: 1.0)
        case .BLACK_HOLE:
            return UIColor(red: 0.95, green: 0.45, blue: 0.35, alpha: 1.0)
        case .CONSTELLATION:
            return UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1.0)
        case .SUN, .MOON, .PLANET:
            return UIColor.white
        }
    }

    static func getObjectTypeIcon(_ type: SkyObjectType) -> String {
        switch type {
        case .STAR:
            return "ic_action_favorites"
        case .GALAXY, .GALAXY_CLUSTER:
            return "ic_action_planet"
        case .BLACK_HOLE:
            return "ic_action_target"
        case .SUN:
            return "ic_action_sun"
        case .MOON:
            return "ic_action_moon"
        case .PLANET:
            return "ic_action_planet"
        case .NEBULA:
            return "ic_action_cloud"
        case .OPEN_CLUSTER, .GLOBULAR_CLUSTER:
            return "ic_action_group"
        case .CONSTELLATION:
            return "ic_action_telescope"
        }
    }

    static func getObjectTypeName(_ type: SkyObjectType) -> String {
        localizedString(type.titleKey)
    }

    static func calculateConstellationCenter(_ constellation: Constellation, skyObjectMap: [Int: SkyObject]) -> (Double, Double)? {
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        var count = 0
        var uniqueStars = Set<Int>()
        for (first, second) in constellation.lines {
            uniqueStars.insert(first)
            uniqueStars.insert(second)
        }

        for id in uniqueStars {
            guard let star = skyObjectMap[id] else {
                continue
            }
            let raRad = star.ra * 15.0 * .pi / 180.0
            let decRad = star.dec * .pi / 180.0
            sumX += cos(decRad) * cos(raRad)
            sumY += cos(decRad) * sin(raRad)
            sumZ += sin(decRad)
            count += 1
        }

        guard count > 0 else {
            return nil
        }

        let avgX = sumX / Double(count)
        let avgY = sumY / Double(count)
        let avgZ = sumZ / Double(count)
        let hyp = sqrt(avgX * avgX + avgY * avgY)
        let decRad = atan2(avgZ, hyp)
        var raRad = atan2(avgY, avgX)
        if raRad < 0 {
            raRad += 2 * .pi
        }
        return (raRad * 180.0 / .pi / 15.0, decRad * 180.0 / .pi)
    }

    static func normalizedDegrees(_ degrees: Double) -> Double {
        var value = degrees.truncatingRemainder(dividingBy: 360.0)
        if value < 0 {
            value += 360.0
        }
        return value
    }

    static func shortestAngleDelta(from source: Double, to target: Double) -> Double {
        var delta = normalizedDegrees(target) - normalizedDegrees(source)
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        return delta
    }

    static func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
