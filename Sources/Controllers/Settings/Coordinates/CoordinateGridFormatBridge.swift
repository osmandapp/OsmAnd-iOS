//
//  CoordinateGridFormatBridge.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 20.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class CoordinateGridFormatInfo: NSObject {
    let formatId: String
    let projectionRaw: Int32
    let formatRaw: Int32
    let needSuffixes: Bool
    let granularity: NSNumber?
    let maxZoom: NSNumber?

    let hasProjectionParameters: Bool
    let lonMin: Double
    let lonMax: Double
    let latMin: Double
    let latMax: Double
    let semiMajor: Double
    let invFlattening: Double
    let refLon: Double
    let refLat: Double
    let falseEasting: Double
    let falseNorthing: Double
    let scaleFactor: Double
    let scaleFactorY: Double
    let translationsX: Double
    let translationsY: Double
    let translationsZ: Double
    let translationsW: Double
    let rotationsX: Double
    let rotationsY: Double
    let rotationsZ: Double
    let ellipsoidScale: Double

    init(from format: CoordinateGridFormat) {
        formatId = format.id
        projectionRaw = format.projectionRaw
        formatRaw = format.formatRaw
        needSuffixes = format.needSuffixes
        if let g = format.granularity {
            granularity = NSNumber(value: g)
        } else {
            granularity = nil
        }
        if let maxZoomValue = format.maxZoom {
            maxZoom = NSNumber(value: maxZoomValue)
        } else {
            maxZoom = nil
        }

        if let parameters = format.projectionParameters {
            hasProjectionParameters = true
            lonMin = parameters.lonBounds.x
            lonMax = parameters.lonBounds.y
            latMin = parameters.latBounds.x
            latMax = parameters.latBounds.y
            semiMajor = parameters.semiMajorAxisAndInverseFlattening.x
            invFlattening = parameters.semiMajorAxisAndInverseFlattening.y
            refLon = parameters.refLonLat.x
            refLat = parameters.refLonLat.y
            falseEasting = parameters.falseEastingAndNorthing.x
            falseNorthing = parameters.falseEastingAndNorthing.y
            scaleFactor = parameters.scaleFactor.x
            scaleFactorY = parameters.scaleFactor.y
            let ellipsoid = parameters.ellipsoidParameters
            translationsX = ellipsoid.translationsXY.x
            translationsY = ellipsoid.translationsXY.y
            translationsZ = ellipsoid.translationsZW.x
            translationsW = ellipsoid.translationsZW.y
            rotationsX = ellipsoid.rotationsXY.x
            rotationsY = ellipsoid.rotationsXY.y
            rotationsZ = ellipsoid.rotationsZScale.x
            ellipsoidScale = ellipsoid.rotationsZScale.y
        } else {
            hasProjectionParameters = false
            lonMin = 0
            lonMax = 0
            latMin = 0
            latMax = 0
            semiMajor = 0
            invFlattening = 0
            refLon = 0
            refLat = 0
            falseEasting = 0
            falseNorthing = 0
            scaleFactor = 0
            scaleFactorY = 0
            translationsX = 0
            translationsY = 0
            translationsZ = 0
            translationsW = 0
            rotationsX = 0
            rotationsY = 0
            rotationsZ = 0
            ellipsoidScale = 1
        }
        super.init()
    }
}

@objcMembers
final class CoordinateGridFormatBridge: NSObject {
    @objc static func resolveInfo(_ formatId: String?) -> CoordinateGridFormatInfo? {
        let provider = CoordinateFormatHelper.gridFormatProvider
        let format = provider.resolve(formatId)
            ?? provider.resolve(CoordinateFormatIds.builtinDdd)
        return format.map { CoordinateGridFormatInfo(from: $0) }
    }
}
