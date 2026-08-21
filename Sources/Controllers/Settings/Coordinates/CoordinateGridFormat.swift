//
//  CoordinateGridFormat.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 20.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

struct CoordinateGridPoint {
    let x: Double
    let y: Double
    static let zero = CoordinateGridPoint(x: 0, y: 0)
}

struct CoordinateGridEllipsoidParameters {
    let translationsXY: CoordinateGridPoint
    let translationsZW: CoordinateGridPoint
    let rotationsXY: CoordinateGridPoint
    let rotationsZScale: CoordinateGridPoint

    static let identity = CoordinateGridEllipsoidParameters(
        translationsXY: .zero,
        translationsZW: .zero,
        rotationsXY: .zero,
        rotationsZScale: CoordinateGridPoint(x: 0, y: 1)
    )
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
    let projection: OAProjection
    let format: OAFormat
    let needSuffixes: Bool
    let projectionParameters: CoordinateGridProjectionParameters?

    var granularity: Float? {
        switch projection {
        case .olc, .mls: return 3.0
        default: return nil
        }
    }
}

struct EpsgGridDefinition {
    let epsgCode: Int
    let projectionMethodCode: Int
    let usesWgs84: Bool
    let transformationCodes: [Int]
}
