//
//  EpsgCatalogRepository.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import SQLite3

final class EpsgCatalogRepository {

    static let shared = EpsgCatalogRepository()

    private static let defaultListLimit = 1000
    private static let defaultSearchLimit = 50
    private static let maxQueryLimit = 5000

    private static let supportedProjectionMethods = "'9807', '9809', '9815'"
    private static let supportedHelmertMethods = "'9603', '9606', '9607'"
    private static let maxTransformCandidates = 16
    private static let maxGridCacheSize = 64

    private static let baseSelect = """
        SELECT crs.code, crs.name, group_concat(DISTINCT e.name), crs.deprecated \
        FROM projected_crs crs \
        LEFT JOIN usage u ON u.object_table_name = 'projected_crs' \
        AND u.object_auth_name = crs.auth_name AND u.object_code = crs.code \
        LEFT JOIN extent e ON e.auth_name = u.extent_auth_name AND e.code = u.extent_code \
        AND IFNULL(e.deprecated, 0) = 0 
        """

    private static let gridBaseSelect = """
        SELECT crs.code, crs.name, group_concat(DISTINCT e.name), crs.deprecated \
        FROM projected_crs crs \
        JOIN conversion c ON c.auth_name = crs.conversion_auth_name AND c.code = crs.conversion_code \
        LEFT JOIN usage u ON u.object_table_name = 'projected_crs' \
        AND u.object_auth_name = crs.auth_name AND u.object_code = crs.code \
        LEFT JOIN extent e ON e.auth_name = u.extent_auth_name AND e.code = u.extent_code \
        AND IFNULL(e.deprecated, 0) = 0 
        """

    private static let supportedAreaFilter = """
        AND NOT EXISTS (SELECT 1 FROM usage area_usage \
        JOIN extent area_extent ON area_extent.auth_name = area_usage.extent_auth_name \
        AND area_extent.code = area_usage.extent_code \
        WHERE area_usage.object_table_name = 'projected_crs' \
        AND area_usage.object_auth_name = crs.auth_name AND area_usage.object_code = crs.code \
        AND IFNULL(area_extent.deprecated, 0) = 0 \
        AND area_extent.west_lon > area_extent.east_lon) 
        """

    private static let gridSupportedFilter = """
        WHERE crs.auth_name = 'EPSG' AND IFNULL(crs.deprecated, 0) = 0 \
        AND c.method_auth_name = 'EPSG' AND c.method_code IN (\(supportedProjectionMethods)) \
        \(supportedAreaFilter)\
        AND ((crs.geodetic_crs_auth_name = 'EPSG' AND crs.geodetic_crs_code = '4326') \
        OR EXISTS (SELECT 1 FROM helmert_transformation h \
        WHERE h.auth_name = 'EPSG' AND IFNULL(h.deprecated, 0) = 0 \
        AND h.source_crs_auth_name = crs.geodetic_crs_auth_name \
        AND h.source_crs_code = crs.geodetic_crs_code \
        AND h.target_crs_auth_name = 'EPSG' AND h.target_crs_code = '4326' \
        AND h.method_auth_name = 'EPSG' AND h.method_code IN (\(supportedHelmertMethods)))) 
        """

    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    private let gridLock = NSLock()
    private var gridDefinitionCache: [Int: EpsgGridDefinition] = [:]
    private var unsupportedGridCodes = Set<Int>()

    private init() {}

    // MARK: - Public CRS

    func getByCode(_ code: Int) -> CoordinateFormat? {
        guard code > 0, let db = openConnection() else { return nil }
        defer { sqlite3_close(db) }

        let sql = Self.baseSelect + """
            WHERE crs.auth_name = 'EPSG' AND crs.code = ? AND IFNULL(crs.deprecated, 0) = 0 \
            GROUP BY crs.code, crs.name, crs.deprecated
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, String(code), -1, transient)
        return sqlite3_step(stmt) == SQLITE_ROW ? readFormat(stmt) : nil
    }

    func resolveFormat(_ id: String) -> CoordinateFormat {
        guard let code = CoordinateFormatIds.epsgCode(id) else {
            return .unknown(id: id)
        }
        return getByCode(code) ?? .unresolvedEpsg(code: code)
    }

    func listAll(limit: Int = defaultListLimit) -> [CoordinateFormat] {
        guard let db = openConnection() else { return [] }
        defer { sqlite3_close(db) }

        let sql = Self.baseSelect + """
            WHERE crs.auth_name = 'EPSG' AND IFNULL(crs.deprecated, 0) = 0 \
            GROUP BY crs.code, crs.name, crs.deprecated \
            ORDER BY crs.name \
            LIMIT ?
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }
        bindLimit(stmt, index: 1, limit: limit)
        return readAll(stmt)
    }

    func search(_ query: String?, limit: Int = defaultSearchLimit) -> [CoordinateFormat] {
        let normalized = normalizeSearchQuery(query)
        guard !normalized.isEmpty, let db = openConnection() else { return [] }
        defer { sqlite3_close(db) }

        let numeric = normalized.allSatisfy(\.isNumber)
        let exactCode = numeric ? normalized : ""
        let codePrefix = numeric ? "\(normalized)%" : ""
        let likeQuery = "%\(escapeLike(normalized.lowercased()))%"

        let sql = Self.baseSelect + """
            WHERE crs.auth_name = 'EPSG' AND IFNULL(crs.deprecated, 0) = 0 AND (\
            crs.code = ? OR crs.code LIKE ? OR lower(crs.name) LIKE ? ESCAPE '\\' \
            OR lower(IFNULL(crs.description, '')) LIKE ? ESCAPE '\\' \
            OR lower(IFNULL(e.name, '')) LIKE ? ESCAPE '\\' \
            OR lower(IFNULL(e.description, '')) LIKE ? ESCAPE '\\') \
            GROUP BY crs.code, crs.name, crs.deprecated \
            ORDER BY CASE WHEN crs.code = ? THEN 0 WHEN crs.code LIKE ? THEN 1 ELSE 2 END, crs.name \
            LIMIT ?
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        let args = [exactCode, codePrefix, likeQuery, likeQuery, likeQuery, likeQuery, exactCode, codePrefix]
        for (i, arg) in args.enumerated() {
            sqlite3_bind_text(stmt, Int32(i + 1), arg, -1, transient)
        }
        bindLimit(stmt, index: Int32(args.count + 1), limit: limit)
        return readAll(stmt)
    }

    // MARK: - Grid

    func getGridDefinition(_ code: Int) -> EpsgGridDefinition? {
        guard code > 0 else { return nil }

        gridLock.lock()
        if unsupportedGridCodes.contains(code) {
            gridLock.unlock()
            return nil
        }
        if let cached = gridDefinitionCache[code] {
            gridLock.unlock()
            return cached
        }
        gridLock.unlock()

        guard let db = openConnection() else { return nil }
        defer { sqlite3_close(db) }

        let sql = """
            SELECT c.method_code, crs.geodetic_crs_auth_name, crs.geodetic_crs_code \
            FROM projected_crs crs \
            JOIN conversion c ON c.auth_name = crs.conversion_auth_name AND c.code = crs.conversion_code \
            WHERE crs.auth_name = 'EPSG' AND crs.code = ? AND IFNULL(crs.deprecated, 0) = 0 \
            AND c.method_auth_name = 'EPSG' AND c.method_code IN (\(Self.supportedProjectionMethods)) \
            \(Self.supportedAreaFilter)\
            ORDER BY CAST(c.method_code AS INTEGER), c.code \
            LIMIT 1
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, String(code), -1, transient)

        let step = sqlite3_step(stmt)
        guard step == SQLITE_ROW else {
            if step == SQLITE_DONE {
                markUnsupported(code)
            }
            return nil
        }

        guard let methodStr = columnString(stmt, 0),
              let methodCode = Int(methodStr),
              let baseAuth = columnString(stmt, 1), !baseAuth.isEmpty,
              let baseCode = columnString(stmt, 2), !baseCode.isEmpty else {
            markUnsupported(code)
            return nil
        }

        let usesWgs84 = baseAuth == "EPSG" && baseCode == "4326"
        let transforms: [Int]
        if usesWgs84 {
            transforms = []
        } else {
            guard let queried = queryTransformationCodes(db, baseAuth: baseAuth, baseCode: baseCode) else {
                return nil
            }
            if queried.isEmpty {
                markUnsupported(code)
                return nil
            }
            transforms = queried
        }

        let def = EpsgGridDefinition(
            epsgCode: code,
            projectionMethodCode: methodCode,
            usesWgs84: usesWgs84,
            transformationCodes: transforms
        )
        cacheDefinition(def)
        return def
    }

    func listGridFormats(limit: Int = defaultListLimit) -> [CoordinateFormat] {
        queryGridFormats(query: nil, limit: limit)
    }

    func searchGridFormats(_ query: String?, limit: Int = defaultSearchLimit) -> [CoordinateFormat] {
        let normalized = normalizeSearchQuery(query)
        return normalized.isEmpty
            ? listGridFormats(limit: limit)
            : queryGridFormats(query: normalized, limit: limit)
    }

    // MARK: - Grid Private

    private func queryGridFormats(query: String?, limit: Int) -> [CoordinateFormat] {
        guard let db = openConnection() else { return [] }
        defer { sqlite3_close(db) }

        let normalized = query ?? ""
        let numeric = !normalized.isEmpty && normalized.allSatisfy(\.isNumber)
        let exactCode = numeric ? normalized : ""
        let codePrefix = numeric ? "\(normalized)%" : ""
        let likeQuery = "%\(escapeLike(normalized.lowercased()))%"

        let queryFilter: String
        let orderBy: String
        if normalized.isEmpty {
            queryFilter = ""
            orderBy = "ORDER BY crs.name "
        } else {
            queryFilter = """
                AND (crs.code = ? OR crs.code LIKE ? OR lower(crs.name) LIKE ? ESCAPE '\\' \
                OR lower(IFNULL(crs.description, '')) LIKE ? ESCAPE '\\' \
                OR lower(IFNULL(e.name, '')) LIKE ? ESCAPE '\\' \
                OR lower(IFNULL(e.description, '')) LIKE ? ESCAPE '\\') 
                """
            orderBy = "ORDER BY CASE WHEN crs.code = ? THEN 0 WHEN crs.code LIKE ? THEN 1 ELSE 2 END, crs.name "
        }

        let sql = Self.gridBaseSelect + Self.gridSupportedFilter + queryFilter +
            "GROUP BY crs.code, crs.name, crs.deprecated " + orderBy + "LIMIT ?"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var bindIndex: Int32 = 1
        if !normalized.isEmpty {
            let args = [exactCode, codePrefix, likeQuery, likeQuery, likeQuery, likeQuery, exactCode, codePrefix]
            for arg in args {
                sqlite3_bind_text(stmt, bindIndex, arg, -1, transient)
                bindIndex += 1
            }
        }
        bindLimit(stmt, index: bindIndex, limit: limit)
        return readAll(stmt)
    }

    private func queryTransformationCodes(
        _ db: OpaquePointer?,
        baseAuth: String,
        baseCode: String
    ) -> [Int]? {
        let sql = """
            SELECT h.code FROM helmert_transformation h \
            WHERE h.auth_name = 'EPSG' AND IFNULL(h.deprecated, 0) = 0 \
            AND h.source_crs_auth_name = ? AND h.source_crs_code = ? \
            AND h.target_crs_auth_name = 'EPSG' AND h.target_crs_code = '4326' \
            AND h.method_auth_name = 'EPSG' AND h.method_code IN (\(Self.supportedHelmertMethods)) \
            ORDER BY CASE WHEN lower(IFNULL(h.description, '')) LIKE '%replaced by%' THEN 1 ELSE 0 END, \
            CASE WHEN h.accuracy IS NULL THEN 1 ELSE 0 END, h.accuracy, CAST(h.code AS INTEGER) \
            LIMIT \(Self.maxTransformCandidates)
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return nil }
        defer { sqlite3_finalize(stmt) }
        sqlite3_bind_text(stmt, 1, baseAuth, -1, transient)
        sqlite3_bind_text(stmt, 2, baseCode, -1, transient)

        var result = [Int]()
        while true {
            let step = sqlite3_step(stmt)
            if step == SQLITE_DONE { break }
            guard step == SQLITE_ROW else { return nil }
            if let s = columnString(stmt, 0), let code = Int(s) {
                result.append(code)
            }
        }
        return result
    }

    private func markUnsupported(_ code: Int) {
        gridLock.lock()
        unsupportedGridCodes.insert(code)
        gridLock.unlock()
    }

    private func cacheDefinition(_ def: EpsgGridDefinition) {
        gridLock.lock()
        if gridDefinitionCache.count >= Self.maxGridCacheSize {
            gridDefinitionCache.removeAll(keepingCapacity: true)
        }
        gridDefinitionCache[def.epsgCode] = def
        gridLock.unlock()
    }

    // MARK: - Private

    private func openConnection() -> OpaquePointer? {
        let lib = NSHomeDirectory() + "/Library/Application Support/proj/proj.db"
        let path = FileManager.default.fileExists(atPath: lib)
            ? lib
            : Bundle.main.path(forResource: "proj", ofType: "db")
        guard let path else { return nil }

        var db: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(path, &db, flags, nil) == SQLITE_OK else {
            if let db { sqlite3_close(db) }
            return nil
        }
        return db
    }

    private func readAll(_ stmt: OpaquePointer?) -> [CoordinateFormat] {
        var result = [CoordinateFormat]()
        while sqlite3_step(stmt) == SQLITE_ROW {
            result.append(readFormat(stmt))
        }
        return result
    }

    private func readFormat(_ stmt: OpaquePointer?) -> CoordinateFormat {
        let code = Int(columnString(stmt, 0) ?? "") ?? 0
        let name = columnString(stmt, 1)
        let area = columnString(stmt, 2)
        let deprecated = sqlite3_column_type(stmt, 3) != SQLITE_NULL && sqlite3_column_int(stmt, 3) != 0
        return .epsg(code: code, title: name, subtitle: area, isDeprecated: deprecated)
    }

    private func columnString(_ stmt: OpaquePointer?, _ index: Int32) -> String? {
        guard sqlite3_column_type(stmt, index) != SQLITE_NULL,
              let cString = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: cString)
    }

    private func normalizeSearchQuery(_ query: String?) -> String {
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let prefix = CoordinateFormatIds.epsgPrefix
        if trimmed.lowercased().hasPrefix(prefix) {
            return String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        return trimmed
    }

    private func escapeLike(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    private func bindLimit(_ stmt: OpaquePointer?, index: Int32, limit: Int) {
        let clamped = min(max(limit, 1), Self.maxQueryLimit)
        sqlite3_bind_int(stmt, index, Int32(clamped))
    }
}
