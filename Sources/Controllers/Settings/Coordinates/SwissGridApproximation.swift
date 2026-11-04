//
//  SwissGridApproximation.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 12.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum SwissGridApproximation {

    static func convertLV95ToWGS84(easting: Double, northing: Double) -> (lat: Double, lon: Double) {
        let yPrime = (easting - 2_600_000) / 1_000_000
        let xPrime = (northing - 1_200_000) / 1_000_000
        return (latitudeToWGS84(x: xPrime, y: yPrime), longitudeToWGS84(x: xPrime, y: yPrime))
    }

    static func convertLV03ToWGS84(easting: Double, northing: Double) -> (lat: Double, lon: Double) {
        let yPrime = (easting - 600_000) / 1_000_000
        let xPrime = (northing - 200_000) / 1_000_000
        return (latitudeToWGS84(x: xPrime, y: yPrime), longitudeToWGS84(x: xPrime, y: yPrime))
    }

    static func convertWGS84ToLV03(lat: Double, lon: Double) -> (easting: Double, northing: Double) {
        let lv95 = convertWGS84ToLV95(lat: lat, lon: lon)
        return (lv95.easting - 2_000_000, lv95.northing - 1_000_000)
    }

    static func convertWGS84ToLV95(lat: Double, lon: Double) -> (easting: Double, northing: Double) {
        let phiPrime = (decimalToSexagesimalSeconds(lat) - 169_028.66) / 10_000
        let lambdaPrime = (decimalToSexagesimalSeconds(lon) - 26_782.5) / 10_000

        let easting = 2_600_072.37
            + 211_455.93 * lambdaPrime
            - 10_938.51 * lambdaPrime * phiPrime
            - 0.36 * lambdaPrime * phiPrime * phiPrime
            - 44.54 * lambdaPrime * lambdaPrime * lambdaPrime

        let northing = 1_200_147.07
            + 308_807.95 * phiPrime
            + 3_745.25 * lambdaPrime * lambdaPrime
            + 76.63 * phiPrime * phiPrime
            - 194.56 * lambdaPrime * lambdaPrime * phiPrime
            + 119.79 * phiPrime * phiPrime * phiPrime

        return (easting, northing)
    }

    private static func latitudeToWGS84(x: Double, y: Double) -> Double {
        let latitudeSec = 16.9023892
            + 3.238272 * x
            - 0.270978 * y * y
            - 0.002528 * x * x
            - 0.0447 * y * y * x
            - 0.0140 * x * x * x
        return latitudeSec * 100 / 36
    }

    private static func longitudeToWGS84(x: Double, y: Double) -> Double {
        let longitudeSec = 2.6779094
            + 4.728982 * y
            + 0.791484 * y * x
            + 0.1306 * y * x * x
            - 0.0436 * y * y * y
        return longitudeSec * 100 / 36
    }

    private static func decimalToSexagesimalSeconds(_ decimal: Double) -> Double {
        let degree = floor(decimal)
        let minutes = floor((decimal - degree) * 60)
        let seconds = (((decimal - degree) * 60) - minutes) * 60
        return seconds + minutes * 60 + degree * 3600
    }
}
