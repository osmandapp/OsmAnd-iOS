//
//  AstroDataDbProvider.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared
import SQLite3
import UIKit

final class AstroDataDbProvider: AstroDataProvider {
    private enum Constants {
        static let astroDir = "astro"
        static let databaseName = "stars.db"
        static let databaseNameExtended = "stars-articles.stardb"
        static let queryChunkSize = 900
    }

    override func getSkyObjectsImpl(preferredLocale: String?) -> [SkyObject] {
        guard let db = openDatabase() else {
            var objects: [SkyObject] = []
            getPlanets(&objects)
            return objects
        }

        var objects: [SkyObject] = []
        let rows = db.rows("""
        SELECT wikidata, name, type, ra, dec, mag, hip, radius, distance, mass, centerwid
        FROM Objects
        WHERE type != ?
        """, arguments: ["constellations"])
        for row in rows {
            guard let typeStr = row.string("type"),
                  var type = SkyObjectType.fromDbType(typeStr),
                  let originalName = row.string("name") else {
                continue
            }

            let wikidata = row.string("wikidata") ?? ""
            var body: Body?
            var color = getTypeColor(type)

            if typeStr == "solar_system" {
                body = getBody(wid: wikidata)
                guard let body else {
                    continue
                }
                type = body === Body.sun ? .SUN : (body === Body.moon ? .MOON : .PLANET)
                color = AstroUtils.bodyColor(body)
            }

            objects.append(SkyObject(id: generateId(type: type, name: originalName),
                                     hip: row.int("hip") ?? -1,
                                     wid: wikidata,
                                     centerWId: row.string("centerwid"),
                                     type: type,
                                     body: body,
                                     name: originalName,
                                     ra: row.double("ra") ?? 0,
                                     dec: row.double("dec") ?? 0,
                                     magnitude: row.double("mag") ?? 25,
                                     color: color,
                                     radius: row.double("radius"),
                                     distance: row.double("distance"),
                                     mass: row.double("mass")))
        }

        loadLocalizedNames(db: db, preferredLocale: preferredLocale, objects: objects)
        loadCatalogs(db: db, objects: objects)

        if objects.isEmpty {
            getPlanets(&objects)
        }
        return objects
    }

    override func getCatalogsImpl() -> [Catalog] {
        guard let db = openDatabase() else {
            return []
        }

        return db.rows("SELECT catalogWid, catalogName FROM Catalogs").compactMap { row in
            guard let wid = row.string("catalogWid"), let name = row.string("catalogName") else {
                return nil
            }
            return Catalog(wid: wid, name: name, catalogId: "")
        }
    }

    override func getConstellationsImpl(preferredLocale: String?) -> [Constellation] {
        guard let db = openDatabase() else {
            return []
        }

        var constellations: [Constellation] = []
        let rows = db.rows("""
        SELECT name, wikidata, lines
        FROM Objects
        WHERE type = ?
        """, arguments: ["constellations"])
        for row in rows {
            guard let name = row.string("name") else {
                continue
            }
            let lines = parseLines(row.string("lines"))
            if !lines.isEmpty {
                constellations.append(Constellation(
                    name: name,
                    wid: row.string("wikidata") ?? "",
                    lines: lines
                ))
            }
        }
        loadLocalizedNames(db: db, preferredLocale: preferredLocale, objects: constellations)
        loadCatalogs(db: db, objects: constellations)
        return constellations
    }

    override func getAstroArticleImpl(wikidataId: String, lang: String? = nil) -> AstroArticle? {
        guard let db = openDatabase() else {
            return nil
        }

        let bestLang = localeLanguage(lang)
        let rows = db.rows("""
        SELECT wikidata, lang, title, extract, thumbnail_url, summary_json, mobile_html
        FROM Wikipedia
        WHERE wikidata = ? AND (lang = ? OR lang = ?)
        """, arguments: [wikidataId, bestLang, "en"])

        var bestArticle: AstroArticle?
        var enArticle: AstroArticle?
        for row in rows {
            let rowLang = row.string("lang") ?? ""
            let article = AstroArticle(wikidata: wikidataId,
                                       lang: rowLang,
                                       title: row.string("title") ?? "",
                                       description: row.string("extract") ?? "",
                                       thumbnailUrl: row.string("thumbnail_url"),
                                       summaryJson: row.string("summary_json"),
                                       mobileHtml: row.data("mobile_html"))
            if rowLang == bestLang {
                bestArticle = article
            }
            if rowLang == "en" {
                enArticle = article
            }
        }
        return bestArticle ?? enArticle
    }

    private func openDatabase() -> SQLiteDatabase? {
        for path in databaseLookupPaths() where FileManager.default.fileExists(atPath: path) {
            if let db = SQLiteDatabase(path: path) {
                return db
            }
        }
        if let path = Bundle.main.path(forResource: "stars", ofType: "db", inDirectory: "Shipped"),
           let db = SQLiteDatabase(path: path) {
            return db
        }
        return nil
    }

    private func databaseLookupPaths() -> [String] {
        guard let documentsPath = OsmAndApp.swiftInstance()?.documentsPath else {
            return []
        }
        let astroDir = documentsPath.appendingPathComponent(RESOURCES_DIR).appendingPathComponent(Constants.astroDir)
        return [
            astroDir.appendingPathComponent(Constants.databaseNameExtended),
            astroDir.appendingPathComponent(Constants.databaseName)
        ]
    }

    private func loadLocalizedNames(db: SQLiteDatabase, preferredLocale: String?, objects: [SkyObject]) {
        let wikidataIds = uniqueWikidataIds(from: objects)
        guard !wikidataIds.isEmpty else {
            return
        }

        let targets = localePriorities(preferredLocale)
        var namesMap: [String: [String: String]] = [:]
        for chunk in chunked(wikidataIds, size: Constants.queryChunkSize) {
            let placeholders = Array(repeating: "?", count: chunk.count).joined(separator: ",")
            let rows = db.rows("""
            SELECT wikidata, name, type
            FROM Names
            WHERE wikidata IN (\(placeholders))
            """, arguments: chunk)
            for row in rows {
                guard let wid = row.string("wikidata"),
                      let name = row.string("name"),
                      let type = row.string("type") else {
                    continue
                }
                let types = type.split(separator: ",").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: " \"")) }
                for target in types where targets.contains(target) {
                    namesMap[wid, default: [:]][target] = name
                }
            }
        }

        for object in objects where !object.wid.isEmpty {
            guard let names = namesMap[object.wid] else {
                continue
            }
            for target in targets {
                if let name = names[target] {
                    object.localizedName = name
                    break
                }
            }
        }
    }

    private func loadCatalogs(db: SQLiteDatabase, objects: [SkyObject]) {
        let wikidataIds = uniqueWikidataIds(from: objects)
        guard !wikidataIds.isEmpty else {
            return
        }

        let catalogs = Dictionary(uniqueKeysWithValues: getCatalogs().map { ($0.wid, $0) })
        var allCatalogsMap: [String: [Catalog]] = [:]
        for chunk in chunked(wikidataIds, size: Constants.queryChunkSize) {
            let placeholders = Array(repeating: "?", count: chunk.count).joined(separator: ",")
            let rows = db.rows("""
            SELECT catalogWid, catalogId, wikidataid
            FROM CatalogIds
            WHERE wikidataid IN (\(placeholders))
            """, arguments: chunk)
            for row in rows {
                guard let wikiId = row.string("wikidataid"),
                      let catalogWid = row.string("catalogWid"),
                      let catalogId = row.string("catalogId"),
                      let baseCatalog = catalogs[catalogWid] else {
                    continue
                }
                allCatalogsMap[wikiId, default: []].append(Catalog(wid: baseCatalog.wid,
                                                                   name: baseCatalog.name,
                                                                   catalogId: catalogId))
            }
        }

        for object in objects where !object.wid.isEmpty {
            if let catalogs = allCatalogsMap[object.wid], !catalogs.isEmpty {
                object.catalogs = catalogs
            }
        }
    }

    private func getBody(wid: String) -> Body? {
        AstroUtils.solarSystemWikidataIds[wid]
    }

    private func localeLanguage(_ preferredLocale: String?) -> String {
        let locale = preferredLocale ?? OsmAndApp.swiftInstance()?.getLanguageCode() ?? Locale.current.languageCode ?? "en"
        return locale.split(separator: "-").first.map(String.init)?.lowercased() ?? "en"
    }

    private func localePriorities(_ preferredLocale: String?) -> [String] {
        let lang = localeLanguage(preferredLocale)
        return [lang, "\(lang)wiki", "en", "enwiki", "mul"]
    }

    private func uniqueWikidataIds(from objects: [SkyObject]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for object in objects where !object.wid.isEmpty && seen.insert(object.wid).inserted {
            result.append(object.wid)
        }
        return result
    }

    private func chunked<T>(_ values: [T], size: Int) -> [[T]] {
        stride(from: 0, to: values.count, by: size).map {
            Array(values[$0..<min($0 + size, values.count)])
        }
    }
}

private enum SQLiteValue {
    case int(Int)
    case double(Double)
    case string(String)
    case data(Data)
    case null
}

private struct SQLiteRow {
    let values: [String: SQLiteValue]

    func string(_ key: String) -> String? {
        switch values[key] {
        case .string(let value):
            return value
        case .int(let value):
            return String(value)
        case .double(let value):
            return String(value)
        default:
            return nil
        }
    }

    func int(_ key: String) -> Int? {
        switch values[key] {
        case .int(let value):
            return value
        case .double(let value):
            return Int(value)
        case .string(let value):
            return Int(value)
        default:
            return nil
        }
    }

    func double(_ key: String) -> Double? {
        switch values[key] {
        case .double(let value):
            return value
        case .int(let value):
            return Double(value)
        case .string(let value):
            return Double(value)
        default:
            return nil
        }
    }

    func data(_ key: String) -> Data? {
        switch values[key] {
        case .data(let value):
            return value
        case .string(let value):
            return value.data(using: .utf8)
        default:
            return nil
        }
    }
}

private final class SQLiteDatabase {
    private var handle: OpaquePointer?
    private let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init?(path: String) {
        guard sqlite3_open_v2(path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            if handle != nil {
                sqlite3_close(handle)
            }
            return nil
        }
    }

    deinit {
        sqlite3_close(handle)
    }

    func rows(_ sql: String, arguments: [String] = []) -> [SQLiteRow] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            return []
        }
        defer {
            sqlite3_finalize(statement)
        }

        for (index, argument) in arguments.enumerated() {
            guard sqlite3_bind_text(statement, Int32(index + 1), argument, -1, transient) == SQLITE_OK else {
                return []
            }
        }

        var result: [SQLiteRow] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            let count = sqlite3_column_count(statement)
            var values: [String: SQLiteValue] = [:]
            for index in 0..<count {
                guard let namePointer = sqlite3_column_name(statement, index) else {
                    continue
                }
                let name = String(cString: namePointer)
                values[name] = value(statement, index: index)
            }
            result.append(SQLiteRow(values: values))
        }
        return result
    }

    private func value(_ statement: OpaquePointer, index: Int32) -> SQLiteValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER:
            return .int(Int(sqlite3_column_int64(statement, index)))
        case SQLITE_FLOAT:
            return .double(sqlite3_column_double(statement, index))
        case SQLITE_TEXT:
            guard let text = sqlite3_column_text(statement, index) else {
                return .null
            }
            let cString = UnsafeRawPointer(text).assumingMemoryBound(to: CChar.self)
            return .string(String(cString: cString))
        case SQLITE_BLOB:
            guard let bytes = sqlite3_column_blob(statement, index) else {
                return .null
            }
            return .data(Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, index))))
        default:
            return .null
        }
    }
}
