//
//  CoordinateGridFormat.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 20.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

struct CoordinateGridPoint {
    static let zero = CoordinateGridPoint(x: 0, y: 0)

    let x: Double
    let y: Double
}

struct CoordinateGridEllipsoidParameters {
    static let identity = CoordinateGridEllipsoidParameters(
        translationsXY: .zero,
        translationsZW: .zero,
        rotationsXY: .zero,
        rotationsZScale: CoordinateGridPoint(x: 0, y: 1)
    )

    let translationsXY: CoordinateGridPoint
    let translationsZW: CoordinateGridPoint
    let rotationsXY: CoordinateGridPoint
    let rotationsZScale: CoordinateGridPoint
}

struct CoordinateGridProjectionParameters {
    let lonBounds: CoordinateGridPoint
    let latBounds: CoordinateGridPoint
    let semiMajorAxisAndInverseFlattening: CoordinateGridPoint
    let refLonLat: CoordinateGridPoint
    let falseEastingAndNorthing: CoordinateGridPoint
    let scaleFactor: CoordinateGridPoint
    let ellipsoidParameters: CoordinateGridEllipsoidParameters
    let operationCode: Int?
}

struct CoordinateGridFormat {
    let id: String
    let projectionRaw: Int32
    let formatRaw: Int32
    let needSuffixes: Bool
    let projectionParameters: CoordinateGridProjectionParameters?

    var granularity: Float? {
        OAGridFormatMappingBridge.granularity(forProjectionRaw: projectionRaw)?.floatValue
    }

    var maxZoom: Int32? {
        OAGridFormatMappingBridge.maxZoom(forProjectionRaw: projectionRaw)?.int32Value
    }
}
