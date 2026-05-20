//
//  AstroDataProvider.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared
import SQLite3
import UIKit

protocol AstroDataProvider {
    func loadData(preferredLocale: String?) -> AstroDataSnapshot
    func clearCache()
}

final class AstroDataDbProvider: AstroDataProvider {
    private enum Constants {
        static let astroDir = "astro"
        static let extendedDb = "stars-articles.stardb"
        static let baseDb = "stars.db"
    }

    private var cachedSnapshot: AstroDataSnapshot?

    func loadData(preferredLocale: String?) -> AstroDataSnapshot {
        if let cachedSnapshot {
            return cachedSnapshot
        }

        for path in dbLookupPaths() {
            guard FileManager.default.fileExists(atPath: path),
                  let snapshot = loadDb(path: path, preferredLocale: preferredLocale),
                  !snapshot.objects.isEmpty else {
                continue
            }
            cachedSnapshot = snapshot
            return snapshot
        }

        let fallback = AstroDataSnapshot(objects: solarSystemObjects(),
                                         constellations: [],
                                         catalogs: [:],
                                         dbPath: nil,
                                         usedFallback: true)
        cachedSnapshot = fallback
        return fallback
    }

    func clearCache() {
        cachedSnapshot = nil
    }

    private func dbLookupPaths() -> [String] {
        guard let documentsPath = OsmAndApp.swiftInstance()?.documentsPath else {
            return []
        }
        let astroPath = documentsPath.appendingPathComponent(Constants.astroDir)
        return [
            astroPath.appendingPathComponent(Constants.extendedDb),
            astroPath.appendingPathComponent(Constants.baseDb)
        ]
    }

    private func loadDb(path: String, preferredLocale: String?) -> AstroDataSnapshot? {
        guard let db = SQLiteDatabase(path: path) else {
            return nil
        }

        let catalogs = loadCatalogs(db)
        let catalogIds = loadCatalogIds(db, catalogs: catalogs)
        let localizedNames = loadNames(db, preferredLocale: preferredLocale)
        let articles = loadArticles(db, preferredLocale: preferredLocale)
        var objects = loadObjects(db,
                                  catalogsByObjectId: catalogIds,
                                  localizedNames: localizedNames,
                                  articles: articles)

        if objects.isEmpty {
            objects = solarSystemObjects()
        }

        let constellations = objects
            .filter { $0.type == .constellation }
            .map {
                Constellation(id: $0.id,
                              name: $0.displayName,
                              centerWId: $0.centerWId,
                              lineObjectIds: $0.lineObjectIds,
                              rightAscension: $0.ra,
                              declination: $0.dec)
            }

        return AstroDataSnapshot(objects: objects,
                                 constellations: constellations,
                                 catalogs: catalogs,
                                 dbPath: path,
                                 usedFallback: false)
    }

    private func loadCatalogs(_ db: SQLiteDatabase) -> [String: Catalog] {
        var result: [String: Catalog] = [:]
        let rows = db.rows("SELECT catalogWid, catalogName FROM Catalogs")
        for row in rows {
            guard let wid = row.string("catalogWid"), let name = row.string("catalogName") else {
                continue
            }
            result[wid] = Catalog(catalogWid: wid, catalogName: name, catalogId: "")
        }
        return result
    }

    private func loadCatalogIds(_ db: SQLiteDatabase, catalogs: [String: Catalog]) -> [String: [Catalog]] {
        var result: [String: [Catalog]] = [:]
        let rows = db.rows("SELECT catalogWid, catalogId, wikidataid FROM CatalogIds")
        for row in rows {
            guard let catalogWid = row.string("catalogWid"),
                  let objectWid = row.string("wikidataid"),
                  let catalogId = row.string("catalogId") else {
                continue
            }
            let catalogName = catalogs[catalogWid]?.catalogName ?? catalogWid
            let catalog = Catalog(catalogWid: catalogWid, catalogName: catalogName, catalogId: catalogId)
            result[objectWid, default: []].append(catalog)
        }
        return result
    }

    private func loadNames(_ db: SQLiteDatabase, preferredLocale: String?) -> [String: String] {
        let priorities = localePriorities(preferredLocale)
        var ranked: [String: (rank: Int, name: String)] = [:]
        let rows = db.rows("SELECT wikidata, name, type FROM Names")
        for row in rows {
            guard let wid = row.string("wikidata"), let name = row.string("name") else {
                continue
            }
            let type = row.string("type")?.lowercased() ?? ""
            let rank = priorities.firstIndex(of: type) ?? priorities.count
            if ranked[wid] == nil || rank < ranked[wid]!.rank {
                ranked[wid] = (rank, name)
            }
        }
        return ranked.mapValues { $0.name }
    }

    private func loadArticles(_ db: SQLiteDatabase, preferredLocale: String?) -> [String: AstroArticle] {
        let priorities = localePriorities(preferredLocale)
        var ranked: [String: (rank: Int, article: AstroArticle)] = [:]
        let rows = db.rows("SELECT wikidata, lang, title, extract, thumbnail_url, summary_json, mobile_html FROM Wikipedia")
        for row in rows {
            guard let wid = row.string("wikidata") else {
                continue
            }
            let language = row.string("lang")?.lowercased() ?? ""
            let rank = priorities.firstIndex(of: language) ?? priorities.count
            let article = AstroArticle(wikidataId: wid,
                                       language: language,
                                       title: row.string("title"),
                                       extract: row.string("extract"),
                                       thumbnailUrl: row.string("thumbnail_url"),
                                       summaryJson: row.string("summary_json"),
                                       mobileHtml: row.data("mobile_html"))
            if ranked[wid] == nil || rank < ranked[wid]!.rank {
                ranked[wid] = (rank, article)
            }
        }
        return ranked.mapValues { $0.article }
    }

    private func loadObjects(_ db: SQLiteDatabase,
                             catalogsByObjectId: [String: [Catalog]],
                             localizedNames: [String: String],
                             articles: [String: AstroArticle]) -> [SkyObject] {
        let sql = """
        SELECT wikidata, name, type, ra, dec, lines, mag, hip, radius, distance, mass, centerwid
        FROM Objects
        """
        var objects = solarSystemObjects()
        let rows = db.rows(sql)
        for row in rows {
            guard let wid = row.string("wikidata") ?? row.string("name"),
                  let dbType = row.string("type"),
                  let objectType = SkyObjectType.fromDbType(dbType) else {
                continue
            }

            if objectType == .planet,
               let wikidata = row.string("wikidata"),
               AstroUtils.solarSystemWikidataIds[wikidata] != nil {
                continue
            }

            let magnitude = row.double("mag")
            let lines = parseLineObjectIds(row.string("lines"))
            let object = SkyObject(id: wid,
                                   hip: row.int("hip"),
                                   catalogs: catalogsByObjectId[wid] ?? [],
                                   wid: row.string("wikidata"),
                                   centerWId: row.string("centerwid"),
                                   type: objectType,
                                   name: row.string("name") ?? row.string("lines"),
                                   ra: row.double("ra") ?? 0,
                                   dec: row.double("dec") ?? 0,
                                   magnitude: magnitude,
                                   color: AstroUtils.color(for: objectType, magnitude: magnitude),
                                   radius: row.double("radius"),
                                   distance: row.double("distance"),
                                   mass: row.double("mass"),
                                   lineObjectIds: lines,
                                   localizedName: localizedNames[wid])
            object.article = articles[wid]
            objects.append(object)
        }
        return objects
    }

    private func solarSystemObjects() -> [SkyObject] {
        let bodies: [(String, SkyObjectType, Body)] = [
            ("Q525", .sun, Body.sun),
            ("Q405", .moon, Body.moon),
            ("Q308", .planet, Body.mercury),
            ("Q313", .planet, Body.venus),
            ("Q111", .planet, Body.mars),
            ("Q319", .planet, Body.jupiter),
            ("Q193", .planet, Body.saturn),
            ("Q324", .planet, Body.uranus),
            ("Q332", .planet, Body.neptune),
            ("Q339", .planet, Body.pluto)
        ]

        return bodies.map { item in
            let (id, type, body) = item
            return SkyObject(id: id,
                      wid: id,
                      type: type,
                      body: body,
                      name: AstroUtils.bodyDisplayName(body),
                      ra: 0,
                      dec: 0,
                      magnitude: nil,
                      color: AstroUtils.color(for: body),
                      localizedName: AstroUtils.bodyDisplayName(body))
        }
    }

    private func localePriorities(_ preferredLocale: String?) -> [String] {
        let language = (preferredLocale ?? Locale.current.languageCode ?? "en").lowercased()
        return [
            language,
            "\(language)wiki",
            "en",
            "enwiki",
            "mul",
            ""
        ]
    }

    private func parseLineObjectIds(_ value: String?) -> [String] {
        guard let value else {
            return []
        }
        return value
            .components(separatedBy: CharacterSet(charactersIn: "[],;| \n\t"))
            .filter { !$0.isEmpty }
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

    func rows(_ sql: String) -> [SQLiteRow] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK, let statement else {
            return []
        }
        defer {
            sqlite3_finalize(statement)
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
