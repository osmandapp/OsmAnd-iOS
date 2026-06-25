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
import QuartzCore
import UIKit

enum AstroIcon {
    static func template(_ name: String) -> UIImage? {
        UIImage.templateImageNamed(name)
    }

    static func original(_ name: String) -> UIImage? {
        UIImage(named: name)?.withRenderingMode(.alwaysOriginal)
    }

    static func template(_ name: String, size: CGSize) -> UIImage? {
        guard let image = template(name) else {
            return nil
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysTemplate)
    }

    static func layeredTemplate(baseName: String,
                                baseColor: UIColor,
                                overlayName: String,
                                overlayColor: UIColor,
                                size: CGSize = CGSize(width: 24, height: 24)) -> UIImage? {
        guard let base = template(baseName),
              let overlay = template(overlayName) else {
            return template(baseName)
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            base.withTintColor(baseColor, renderingMode: .alwaysOriginal).draw(in: CGRect(origin: .zero, size: size))
            overlay.withTintColor(overlayColor, renderingMode: .alwaysOriginal).draw(in: CGRect(origin: .zero, size: size))
        }.withRenderingMode(.alwaysTemplate)
    }
}

private final class AstroRedFilterOverlayView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        isUserInteractionEnabled = false
        backgroundColor = UIColor(named: "mapNightFilter")!
        layer.compositingFilter = "multiplyBlendMode"
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = superview?.layer.cornerRadius ?? 0
        layer.masksToBounds = layer.cornerRadius > 0
    }
}

enum AstroRedFilter {
    private static let overlayTag = 0xA570

    static func apply(_ enabled: Bool, to views: UIView?...) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for view in views {
            apply(enabled, to: view)
        }
        CATransaction.commit()
    }

    private static func apply(_ enabled: Bool, to view: UIView?) {
        guard let view else {
            return
        }
        if enabled {
            let overlay: AstroRedFilterOverlayView
            if let existing = view.viewWithTag(overlayTag) as? AstroRedFilterOverlayView {
                overlay = existing
            } else {
                overlay = AstroRedFilterOverlayView(frame: view.bounds)
                overlay.tag = overlayTag
                overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                view.addSubview(overlay)
            }
            overlay.frame = view.bounds
            overlay.setNeedsLayout()
            overlay.layoutIfNeeded()
            view.bringSubviewToFront(overlay)
        } else {
            view.viewWithTag(overlayTag)?.removeFromSuperview()
        }
    }
}

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

    struct Twilight {
        let sunrise: Date?
        let sunset: Date?
        let civilDawn: Date?
        let civilDusk: Date?
        let nauticalDawn: Date?
        let nauticalDusk: Date?
        let astroDawn: Date?
        let astroDusk: Date?
    }

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

    static func computeTwilight(startLocal: Date,
                                endLocal: Date,
                                observer: Observer,
                                timeZone: TimeZone) -> Twilight {
        func findAlt(direction: Direction, degrees: Double) -> Date? {
            let startTime = astronomyTime(from: startLocal)
            let time = AstronomyKt.searchAltitude(body: Body.sun,
                                                  observer: observer,
                                                  direction: direction,
                                                  startTime: startTime,
                                                  limitDays: 2.0,
                                                  altitude: degrees)
            return date(from: time)
        }
        let searchStart = astronomyTime(from: startLocal)
        let sunrise = AstronomyKt.searchRiseSet(body: Body.sun,
                                                observer: observer,
                                                direction: Direction.rise,
                                                startTime: searchStart,
                                                limitDays: 2.0,
                                                metersAboveGround: 0.0)
        let sunset = AstronomyKt.searchRiseSet(body: Body.sun,
                                               observer: observer,
                                               direction: Direction.set,
                                               startTime: searchStart,
                                               limitDays: 2.0,
                                               metersAboveGround: 0.0)
        return Twilight(sunrise: date(from: sunrise),
                        sunset: date(from: sunset),
                        civilDawn: findAlt(direction: .rise, degrees: -6.0),
                        civilDusk: findAlt(direction: .set, degrees: -6.0),
                        nauticalDawn: findAlt(direction: .rise, degrees: -12.0),
                        nauticalDusk: findAlt(direction: .set, degrees: -12.0),
                        astroDawn: findAlt(direction: .rise, degrees: -18.0),
                        astroDusk: findAlt(direction: .set, degrees: -18.0))
    }

    static func formatLocalTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = .current
        return formatter.string(from: date)
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
            return UIColor(named: "solarSun")!
        } else if body === Body.moon {
            return UIColor(named: "solarMoon")!
        } else if body === Body.mars {
            return UIColor(named: "solarMars")!
        } else if body === Body.jupiter {
            return UIColor(named: "solarJupiter")!
        } else if body === Body.saturn {
            return UIColor(named: "solarSaturn")!
        } else if body === Body.neptune || body === Body.uranus {
            return UIColor(named: "solarUranusNeptune")!
        } else {
            return UIColor(red: 0.87, green: 0.90, blue: 1.0, alpha: 1.0)
        }
    }

    static func color(for type: SkyObjectType, magnitude: Double?) -> UIColor {
        switch type {
        case .STAR:
            return UIColor(named: "starDot")!
        case .GALAXY, .GALAXY_CLUSTER:
            return UIColor(named: "deepSkyGalaxyDot")!
        case .NEBULA:
            return UIColor(named: "deepSkyNebulaDot")!
        case .OPEN_CLUSTER, .GLOBULAR_CLUSTER:
            return UIColor(named: "deepSkyClusterDot")!
        case .BLACK_HOLE:
            return UIColor(named: "deepSkyBlackHoleDot")!
        case .CONSTELLATION:
            return UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1.0)
        case .SUN, .MOON, .PLANET:
            return UIColor.white
        }
    }

    static func getObjectTypeIcon(_ type: SkyObjectType) -> String {
        switch type {
        case .SUN:
            return "ic_custom_sun"
        case .MOON:
            return "ic_custom_moon"
        case .PLANET:
            return "ic_action_ufo"
        case .STAR:
            return "ic_custom_favorites"
        case .GALAXY, .GALAXY_CLUSTER:
            return "ic_world_globe_dark"
        case .NEBULA:
            return "ic_custom_clouds"
        case .BLACK_HOLE:
            return "ic_action_circle"
        case .CONSTELLATION:
            return "ic_custom_celestial_path"
        case .OPEN_CLUSTER, .GLOBULAR_CLUSTER:
            return "ic_custom_favorites"
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
