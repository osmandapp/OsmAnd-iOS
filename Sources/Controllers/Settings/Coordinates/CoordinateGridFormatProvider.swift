//
//  CoordinateGridFormatProvider.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 20.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

final class CoordinateGridFormatProvider {
    private let repository: EpsgCatalogRepository
    private var resolvedFormats = [String: CoordinateGridFormat]()
    private var unsupportedFormats = Set<String>()
    private let lock = NSLock()

    init(repository: EpsgCatalogRepository = .shared) {
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
        if epsgCode == nil {
            resolved = builtIn.map {
                CoordinateGridFormat(
                    id: normalizedId,
                    projectionRaw: OAGridFormatMappingBridge.projectionRaw(forGridFormatRaw: $0.rawValue),
                    formatRaw: OAGridFormatMappingBridge.formatRaw(forGridFormatRaw: $0.rawValue),
                    needSuffixes: $0.needSuffixes,
                    projectionParameters: nil
                )
            }
        } else if let code = epsgCode {
            resolved = resolveProjectedFormat(normalizedId, epsgCode: code, builtIn: builtIn)
        } else {
            resolved = nil
        }

        if let resolved {
            resolvedFormats[normalizedId] = resolved
        } else {
            unsupportedFormats.insert(normalizedId)
        }
        return resolved
    }

    func isSupported(_ formatId: String?) -> Bool {
        guard let normalizedId = normalizeId(formatId) else { return false }
        let builtIn = GridFormat.from(formatId: normalizedId)
        let epsgCode = builtIn?.epsgCode?.intValue ?? CoordinateFormatIds.epsgCode(normalizedId)
        if epsgCode == nil {
            return builtIn != nil
        }
        return repository.getGridDefinition(epsgCode!) != nil
    }

    func filterSupportedIds(_ formatIds: [String]) -> [String] {
        var result = [String]()
        var seen = Set<String>()
        for id in formatIds {
            guard let n = normalizeId(id), isSupported(n), !seen.contains(n) else { continue }
            seen.insert(n)
            result.append(n)
        }
        return result
    }

    // MARK: - Private

    private func normalizeId(_ formatId: String?) -> String? {
        if let n = CoordinateFormatIds.normalize(formatId) { return n }
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
        guard let definition = repository.getGridDefinition(epsgCode),
              let projectionRaw = OAGridFormatMappingBridge
                  .projectionRaw(forEpsgMethodCode: Int32(definition.projectionMethodCode))?.int32Value,
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
        guard let constants = readProjectionConstants(definition.epsgCode, projectionRaw: projectionRaw) else {
            return nil
        }
        if definition.usesWgs84 {
            return constants.withEllipsoid(.identity, operationCode: nil)
        }
        for op in definition.transformationCodes {
            if let ellipsoid = readEllipsoidParameters(definition.epsgCode, operationCode: op) {
                return constants.withEllipsoid(ellipsoid, operationCode: op)
            }
        }
        return nil
    }

    private func readProjectionConstants(
        _ epsgCode: Int,
        projectionRaw: Int32
    ) -> CoordinateGridProjectionConstants? {
        guard let c = OAEpsgCoordinateTransformer.sharedInstance()
            .constants(forCode: epsgCode, projectionRaw: Int(projectionRaw)) else {
            return nil
        }
        return CoordinateGridProjectionConstants(
            lonBounds: CoordinateGridPoint(x: c.lonMin, y: c.lonMax),
            latBounds: CoordinateGridPoint(x: c.latMin, y: c.latMax),
            semiMajorAxisAndInverseFlattening: CoordinateGridPoint(x: c.semiMajor, y: c.invFlattening),
            refLonLat: CoordinateGridPoint(x: c.refLon, y: c.refLat),
            falseEastingAndNorthing: CoordinateGridPoint(x: c.falseEasting, y: c.falseNorthing),
            scaleFactor: CoordinateGridPoint(x: c.scaleFactor, y: c.scaleFactorY)
        )
    }

    private func readEllipsoidParameters(
        _ epsgCode: Int,
        operationCode: Int
    ) -> CoordinateGridEllipsoidParameters? {
        guard let p = OAEpsgCoordinateTransformer.sharedInstance()
            .ellipsoidParameters(forCode: epsgCode, operationCode: operationCode) else {
            return nil
        }
        return CoordinateGridEllipsoidParameters(
            translationsXY: CoordinateGridPoint(x: p.translationsX, y: p.translationsY),
            translationsZW: CoordinateGridPoint(x: p.translationsZ, y: p.translationsW),
            rotationsXY: CoordinateGridPoint(x: p.rotationsX, y: p.rotationsY),
            rotationsZScale: CoordinateGridPoint(x: p.rotationsZ, y: p.scale)
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
