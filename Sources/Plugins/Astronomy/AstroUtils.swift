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
            let equatorial = AstronomyKt.equator(body: body,
                                                time: time,
                                                observer: observer,
                                                equdate: EquatorEpoch.ofdate,
                                                aberration: Aberration.corrected)
            object.ra = equatorial.ra
            object.dec = equatorial.dec
            object.distanceAu = equatorial.dist
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

    static func bodyDisplayName(_ body: Body) -> String {
        if body === Body.sun {
            return localizedString("astro_sun")
        } else if body === Body.moon {
            return localizedString("astro_moon")
        } else if body === Body.mercury {
            return localizedString("astro_mercury")
        } else if body === Body.venus {
            return localizedString("astro_venus")
        } else if body === Body.mars {
            return localizedString("astro_mars")
        } else if body === Body.jupiter {
            return localizedString("astro_jupiter")
        } else if body === Body.saturn {
            return localizedString("astro_saturn")
        } else if body === Body.uranus {
            return localizedString("astro_uranus")
        } else if body === Body.neptune {
            return localizedString("astro_neptune")
        } else if body === Body.pluto {
            return localizedString("astro_pluto")
        } else {
            return body.name
        }
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
        case .star:
            let brightness = max(0.45, min(1.0, 1.0 - ((magnitude ?? 2.0) / 8.0)))
            return UIColor(red: brightness, green: brightness, blue: 1.0, alpha: 1.0)
        case .galaxy, .galaxyCluster:
            return UIColor(red: 0.52, green: 0.74, blue: 1.0, alpha: 1.0)
        case .nebula:
            return UIColor(red: 0.85, green: 0.45, blue: 0.95, alpha: 1.0)
        case .openCluster, .globularCluster:
            return UIColor(red: 0.50, green: 0.95, blue: 0.78, alpha: 1.0)
        case .blackHole:
            return UIColor(red: 0.95, green: 0.45, blue: 0.35, alpha: 1.0)
        case .constellation:
            return UIColor(red: 0.80, green: 0.86, blue: 1.0, alpha: 1.0)
        case .sun, .moon, .planet:
            return UIColor.white
        }
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
