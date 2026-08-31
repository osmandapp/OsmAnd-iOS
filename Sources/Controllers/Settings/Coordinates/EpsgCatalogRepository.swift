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

    private static let baseSelect = """
        SELECT crs.code, crs.name, group_concat(DISTINCT e.name), crs.deprecated \
        FROM projected_crs crs \
        LEFT JOIN usage u ON u.object_table_name = 'projected_crs' \
        AND u.object_auth_name = crs.auth_name AND u.object_code = crs.code \
        LEFT JOIN extent e ON e.auth_name = u.extent_auth_name AND e.code = u.extent_code \
        AND IFNULL(e.deprecated, 0) = 0 
        """
    
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private init() {}

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
        sqlite3_bind_int(stmt, 1, Int32(max(limit, 1)))
        return readAll(stmt)
    }

    func search(_ query: String?, limit: Int = defaultSearchLimit) -> [CoordinateFormat] {
        let normalized = normalizeSearchQuery(query)
        guard !normalized.isEmpty, let db = openConnection() else { return [] }
        defer { sqlite3_close(db) }

        let numeric = normalized.allSatisfy(\.isNumber)
        let exactCode = numeric ? normalized : ""
        let codePrefix = numeric ? "\(normalized)%" : ""
        let likeQuery = "%\(normalized.lowercased())%"

        let sql = Self.baseSelect + """
            WHERE crs.auth_name = 'EPSG' AND IFNULL(crs.deprecated, 0) = 0 AND (\
            crs.code = ? OR crs.code LIKE ? OR lower(crs.name) LIKE ? \
            OR lower(IFNULL(crs.description, '')) LIKE ? OR lower(IFNULL(e.name, '')) LIKE ? \
            OR lower(IFNULL(e.description, '')) LIKE ?) \
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
        sqlite3_bind_int(stmt, Int32(args.count + 1), Int32(max(limit, 1)))
        return readAll(stmt)
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
}
