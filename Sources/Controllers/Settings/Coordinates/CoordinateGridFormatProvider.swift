//
//  CoordinateGridFormatProvider.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 20.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared

final class CoordinateGridFormatProvider {
    private let repository: EpsgCatalogRepository
    private var resolvedFormats = [String: CoordinateGridFormat]()
    private var unsupportedFormats = Set<String>()
    private let lock = NSLock()

    init(repository: EpsgCatalogRepository = CoordinateFormatHelper.epsgCatalog) {
        self.repository = repository
    }

    func resolve(_ formatId: String?) -> CoordinateGridFormat? {
        lock.lock()
        defer { lock.unlock() }

        guard let normalizedId = normalizeId(formatId) else { return nil }
        if let cached = resolvedFormats[normalizedId] { return cached }
        if unsupportedFormats.contains(normalizedId) { return nil }

        let builtIn = GridFormat.from(formatId: normalizedId)
        let epsgCode = builtIn?.epsgCode?.intValue ?? CoordinateFormatIds.epsgCode(normalizedId)

        let resolved: CoordinateGridFormat?
        if let code = epsgCode {
            resolved = resolveProjectedFormat(normalizedId, epsgCode: code, builtIn: builtIn)
        } else {
            resolved = builtIn.map {
                CoordinateGridFormat(
                    id: normalizedId,
                    projectionRaw: OAGridFormatMappingBridge.projectionRaw(forGridFormatRaw: $0.rawValue),
                    formatRaw: OAGridFormatMappingBridge.formatRaw(forGridFormatRaw: $0.rawValue),
                    needSuffixes: $0.needSuffixes,
                    projectionParameters: nil
                )
            }
        }

        if let resolved {
            resolvedFormats[normalizedId] = resolved
        } else {
            unsupportedFormats.insert(normalizedId)
        }
        return resolved
    }

    func isSupported(_ formatId: String?) -> Bool {
        resolve(formatId) != nil
    }

    func filterSupportedIds(_ formatIds: [String]) -> [String] {
        var result = [String]()
        var seen = Set<String>()
        for id in formatIds {
            guard let normalizedId = normalizeId(id),
                  isSupported(normalizedId),
                  !seen.contains(normalizedId) else { continue }
            seen.insert(normalizedId)
            result.append(normalizedId)
        }
        return result
    }

    // MARK: - Private

    private func normalizeId(_ formatId: String?) -> String? {
        if let normalized = CoordinateFormatIds.normalize(formatId) { return normalized }
        // legacy enum names: "DMS", "UTM", …
        guard let value = formatId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else { return nil }
        return GridFormat.allCases.first { "\($0)".caseInsensitiveCompare(value) == .orderedSame }?.formatId
    }

    private func resolveProjectedFormat(
        _ formatId: String,
        epsgCode: Int,
        builtIn: GridFormat?
    ) -> CoordinateGridFormat? {
        guard let definition = repository.getGridDefinition(code: Int32(epsgCode)),
              let projectionRaw = OAGridFormatMappingBridge
                  .projectionRaw(forEpsgMethodCode: definition.projectionMethodCode)?.int32Value,
              let params = resolveProjectionParameters(definition, projectionRaw: projectionRaw) else {
            return nil
        }
        return CoordinateGridFormat(
            id: formatId,
            projectionRaw: projectionRaw,
            formatRaw: OAGridFormatMappingBridge.decimalFormatRaw(),
            needSuffixes: builtIn?.needSuffixes ?? false,
            projectionParameters: params
        )
    }

    private func resolveProjectionParameters(
        _ definition: EpsgGridDefinition,
        projectionRaw: Int32
    ) -> CoordinateGridProjectionParameters? {
        guard let constants = readProjectionConstants(Int(definition.epsgCode), projectionRaw: projectionRaw) else {
            return nil
        }
        if definition.usesWgs84 {
            return constants.withEllipsoid(.identity, operationCode: nil)
        }
        for operationCode in definition.transformationCodes.map(\.intValue) {
            if let ellipsoid = readEllipsoidParameters(Int(definition.epsgCode), operationCode: operationCode) {
                return constants.withEllipsoid(ellipsoid, operationCode: operationCode)
            }
        }
        return nil
    }

    private func readProjectionConstants(
        _ epsgCode: Int,
        projectionRaw: Int32
    ) -> CoordinateGridProjectionConstants? {
        guard let constants = OAEpsgCoordinateTransformer.sharedInstance()
            .constants(forCode: epsgCode, projectionRaw: Int(projectionRaw)) else {
            return nil
        }
        return CoordinateGridProjectionConstants(
            lonBounds: CoordinateGridPoint(x: constants.lonMin, y: constants.lonMax),
            latBounds: CoordinateGridPoint(x: constants.latMin, y: constants.latMax),
            semiMajorAxisAndInverseFlattening: CoordinateGridPoint(
                x: constants.semiMajor,
                y: constants.invFlattening
            ),
            refLonLat: CoordinateGridPoint(x: constants.refLon, y: constants.refLat),
            falseEastingAndNorthing: CoordinateGridPoint(
                x: constants.falseEasting,
                y: constants.falseNorthing
            ),
            scaleFactor: CoordinateGridPoint(x: constants.scaleFactor, y: constants.scaleFactorY)
        )
    }

    private func readEllipsoidParameters(
        _ epsgCode: Int,
        operationCode: Int
    ) -> CoordinateGridEllipsoidParameters? {
        guard let parameters = OAEpsgCoordinateTransformer.sharedInstance()
            .ellipsoidParameters(forCode: epsgCode, operationCode: operationCode) else {
            return nil
        }
        return CoordinateGridEllipsoidParameters(
            translationsXY: CoordinateGridPoint(x: parameters.translationsX, y: parameters.translationsY),
            translationsZW: CoordinateGridPoint(x: parameters.translationsZ, y: parameters.translationsW),
            rotationsXY: CoordinateGridPoint(x: parameters.rotationsX, y: parameters.rotationsY),
            rotationsZScale: CoordinateGridPoint(x: parameters.rotationsZ, y: parameters.scale)
        )
    }

}

private struct CoordinateGridProjectionConstants {
    let lonBounds: CoordinateGridPoint
    let latBounds: CoordinateGridPoint
    let semiMajorAxisAndInverseFlattening: CoordinateGridPoint
    let refLonLat: CoordinateGridPoint
    let falseEastingAndNorthing: CoordinateGridPoint
    let scaleFactor: CoordinateGridPoint

    func withEllipsoid(
        _ ellipsoid: CoordinateGridEllipsoidParameters,
        operationCode: Int?
    ) -> CoordinateGridProjectionParameters {
        CoordinateGridProjectionParameters(
            lonBounds: lonBounds,
            latBounds: latBounds,
            semiMajorAxisAndInverseFlattening: semiMajorAxisAndInverseFlattening,
            refLonLat: refLonLat,
            falseEastingAndNorthing: falseEastingAndNorthing,
            scaleFactor: scaleFactor,
            ellipsoidParameters: ellipsoid,
            operationCode: operationCode
        )
    }
}
