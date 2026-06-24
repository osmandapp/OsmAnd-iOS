//
//  AstroChartUtils.swift
//  OsmAnd Maps
//
//  Ported from Android AstroChartUtils.kt.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared
import UIKit

struct AstroChartDaySamples {
    let startMillis: Int64
    let endMillis: Int64
    let sunAltitudes: [Double]
    let objectAltitudes: [Double]
    let objectAzimuths: [Double]?
}

struct AstroChartCulmination {
    let time: Date?
    let altitude: Double?
}

enum AstroChartMath {
    static let dayMinutes = 24 * 60
    static let scheduleSampleStepMinutes = 5
    static let visibilitySampleCount = dayMinutes / scheduleSampleStepMinutes + 1
    static let scheduleSampleCount = dayMinutes / scheduleSampleStepMinutes + 1

    private struct HorizontalPoint {
        let altitude: Double
        let azimuth: Double
    }

    static func computeDaySamples(objectToRender: SkyObject,
                                  observer: Observer,
                                  startLocal: Date,
                                  endLocal: Date,
                                  sampleCount: Int,
                                  includeAzimuth: Bool) -> AstroChartDaySamples {
        let safeSamples = max(sampleCount, 2)
        let startMillis = millis(startLocal)
        let endMillis = millis(endLocal)
        let spanMillis = max(1, endMillis - startMillis)
        var objectAltitudes = Array(repeating: 0.0, count: safeSamples)
        var sunAltitudes = Array(repeating: 0.0, count: safeSamples)
        var objectAzimuths = includeAzimuth ? Array(repeating: 0.0, count: safeSamples) : nil

        for index in 0..<safeSamples {
            let fraction = Double(index) / Double(safeSamples - 1)
            let sampleMillis = startMillis + Int64(Double(spanMillis) * fraction)
            let sampleDate = Date(timeIntervalSince1970: TimeInterval(sampleMillis) / 1000.0)
            let objectHorizontal = calculateObjectHorizontal(objectToRender: objectToRender,
                                                             date: sampleDate,
                                                             observer: observer)
            objectAltitudes[index] = objectHorizontal.altitude
            objectAzimuths?[index] = objectHorizontal.azimuth
            sunAltitudes[index] = calculateBodyHorizontal(body: Body.sun,
                                                          date: sampleDate,
                                                          observer: observer).altitude
        }

        return AstroChartDaySamples(startMillis: startMillis,
                                    endMillis: endMillis,
                                    sunAltitudes: sunAltitudes,
                                    objectAltitudes: objectAltitudes,
                                    objectAzimuths: objectAzimuths)
    }

    static func findCulmination(obj: SkyObject,
                                observer: Observer,
                                startLocal: Date,
                                endLocal: Date) -> AstroChartCulmination {
        guard let coarseBest = sampleBestAltitudeTime(obj: obj,
                                                      observer: observer,
                                                      startLocal: startLocal,
                                                      endLocal: endLocal,
                                                      stepMinutes: culminationCoarseStepMinutes) else {
            return AstroChartCulmination(time: nil, altitude: nil)
        }

        var refineStart = coarseBest.addingTimeInterval(TimeInterval(-culminationCoarseStepMinutes * 60))
        var refineEnd = coarseBest.addingTimeInterval(TimeInterval(culminationCoarseStepMinutes * 60))
        if refineStart < startLocal {
            refineStart = startLocal
        }
        if refineEnd > endLocal {
            refineEnd = endLocal
        }

        let fineResult = sampleBestAltitudeTime(obj: obj,
                                                observer: observer,
                                                startLocal: refineStart,
                                                endLocal: refineEnd,
                                                stepMinutes: culminationFineStepMinutes)
        let culminationTime = fineResult ?? coarseBest
        return AstroChartCulmination(time: culminationTime,
                                     altitude: AstroUtils.altitude(obj, at: culminationTime, observer: observer))
    }

    private static func sampleBestAltitudeTime(obj: SkyObject,
                                               observer: Observer,
                                               startLocal: Date,
                                               endLocal: Date,
                                               stepMinutes: Int) -> Date? {
        var cursor = startLocal
        var bestTime: Date?
        var bestAltitude = -Double.infinity
        let step = TimeInterval(stepMinutes * 60)
        while cursor <= endLocal {
            let altitude = AstroUtils.altitude(obj, at: cursor, observer: observer)
            if altitude > bestAltitude {
                bestAltitude = altitude
                bestTime = cursor
            }
            cursor = cursor.addingTimeInterval(step)
        }
        return bestTime
    }

    private static func calculateObjectHorizontal(objectToRender: SkyObject,
                                                  date: Date,
                                                  observer: Observer) -> HorizontalPoint {
        if let body = objectToRender.body {
            return calculateBodyHorizontal(body: body, date: date, observer: observer)
        }
        return AstroUtils.withCustomStar(ra: objectToRender.ra, dec: objectToRender.dec) { body in
            calculateBodyHorizontal(body: body, date: date, observer: observer)
        }
    }

    private static func calculateBodyHorizontal(body: Body,
                                                date: Date,
                                                observer: Observer) -> HorizontalPoint {
        let time = AstroUtils.astronomyTime(from: date)
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
        return HorizontalPoint(altitude: horizontal.altitude, azimuth: AstroUtils.normalizedDegrees(horizontal.azimuth))
    }

    private static func millis(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000.0).rounded())
    }

    private static let culminationCoarseStepMinutes = 10
    private static let culminationFineStepMinutes = 1
}

final class AstroChartColorPalette {
    private let sunGt15: UIColor
    private let sun6To15: UIColor
    private let sun0To6: UIColor
    private let sunM6To0: UIColor
    private let sunM12ToM6: UIColor
    private let sunLtM12: UIColor
    let fillGt45: UIColor
    let fill15To45: UIColor
    let fill0To15: UIColor
    let fillLt0: UIColor

    init(sunGt15: UIColor = UIColor(rgbValue: 0x80A0FF),
         sun6To15: UIColor = UIColor(rgbValue: 0x668CFF),
         sun0To6: UIColor = UIColor(rgbValue: 0x2E62FF),
         sunM6To0: UIColor = UIColor(rgbValue: 0x0034CC),
         sunM12ToM6: UIColor = UIColor(rgbValue: 0x00134D),
         sunLtM12: UIColor = UIColor(rgbValue: 0x020D2C),
         fillGt45: UIColor = UIColor(rgbValue: 0xF3FF5A),
         fill15To45: UIColor = UIColor(rgbValue: 0xF7D750),
         fill0To15: UIColor = UIColor(rgbValue: 0xFB5934),
         fillLt0: UIColor = UIColor(rgbValue: 0x8E24AA)) {
        self.sunGt15 = sunGt15
        self.sun6To15 = sun6To15
        self.sun0To6 = sun0To6
        self.sunM6To0 = sunM6To0
        self.sunM12ToM6 = sunM12ToM6
        self.sunLtM12 = sunLtM12
        self.fillGt45 = fillGt45
        self.fill15To45 = fill15To45
        self.fill0To15 = fill0To15
        self.fillLt0 = fillLt0
    }

    func colorForSunAltitude(_ altitude: Double) -> UIColor {
        if altitude >= 15.0 {
            return sunGt15
        } else if altitude >= 6.0 {
            return sun6To15
        } else if altitude >= 0.0 {
            return sun0To6
        } else if altitude >= -6.0 {
            return sunM6To0
        } else if altitude >= -12.0 {
            return sunM12ToM6
        } else {
            return sunLtM12
        }
    }

    func colorForObjectAltitude(_ altitude: Double) -> UIColor {
        if altitude >= 45.0 {
            return fillGt45
        } else if altitude >= 15.0 {
            return fill15To45
        } else if altitude >= 0.0 {
            return fill0To15
        } else {
            return fillLt0
        }
    }

    func colorForPositiveObjectAltitude(_ altitude: Double) -> UIColor {
        let transitionHalf = Self.objectGradientTransitionDegrees / 2.0
        if altitude >= 45.0 + transitionHalf {
            return fillGt45
        } else if altitude >= 45.0 - transitionHalf {
            return blend(from: fill15To45,
                         to: fillGt45,
                         ratio: (altitude - (45.0 - transitionHalf)) / (2.0 * transitionHalf))
        } else if altitude >= 15.0 + transitionHalf {
            return fill15To45
        } else if altitude >= 15.0 - transitionHalf {
            return blend(from: fill0To15,
                         to: fill15To45,
                         ratio: (altitude - (15.0 - transitionHalf)) / (2.0 * transitionHalf))
        } else {
            return fill0To15
        }
    }

    private func blend(from: UIColor, to: UIColor, ratio: Double) -> UIColor {
        let clamped = max(0.0, min(1.0, ratio))
        var fr: CGFloat = 0
        var fg: CGFloat = 0
        var fb: CGFloat = 0
        var fa: CGFloat = 0
        var tr: CGFloat = 0
        var tg: CGFloat = 0
        var tb: CGFloat = 0
        var ta: CGFloat = 0
        from.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        to.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        let r = fr + (tr - fr) * CGFloat(clamped)
        let g = fg + (tg - fg) * CGFloat(clamped)
        let b = fb + (tb - fb) * CGFloat(clamped)
        let a = fa + (ta - fa) * CGFloat(clamped)
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    static let objectGradientTransitionDegrees = 15.0
}

