//
//  AstronomyModels.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import Foundation
import OsmAndShared
import UIKit

enum SkyObjectType: String, Codable, CaseIterable {
    case star
    case galaxy
    case blackHole
    case planet
    case sun
    case moon
    case nebula
    case openCluster
    case globularCluster
    case galaxyCluster
    case constellation

    var localizedName: String {
        switch self {
        case .star:
            return localizedString("astro_stars")
        case .galaxy:
            return localizedString("astro_galaxies")
        case .blackHole:
            return localizedString("astro_black_holes")
        case .planet:
            return localizedString("astro_planets")
        case .sun:
            return localizedString("astro_sun")
        case .moon:
            return localizedString("astro_moon")
        case .nebula:
            return localizedString("astro_nebulae")
        case .openCluster:
            return localizedString("astro_open_clusters")
        case .globularCluster:
            return localizedString("astro_globular_clusters")
        case .galaxyCluster:
            return localizedString("astro_galaxy_clusters")
        case .constellation:
            return localizedString("astro_constellations")
        }
    }

    static func fromDbType(_ value: String?) -> SkyObjectType? {
        switch value?.lowercased() {
        case "stars", "star":
            return .star
        case "galaxies", "galaxy":
            return .galaxy
        case "black_holes", "black_hole":
            return .blackHole
        case "nebulae", "nebula":
            return .nebula
        case "open_clusters", "open_cluster":
            return .openCluster
        case "globular_clusters", "globular_cluster":
            return .globularCluster
        case "galaxy_clusters", "galaxy_cluster":
            return .galaxyCluster
        case "constellations", "constellation":
            return .constellation
        case "solar_system", "planet":
            return .planet
        default:
            return nil
        }
    }
}

final class Catalog: NSObject {
    let catalogWid: String
    let catalogName: String
    let catalogId: String

    init(catalogWid: String, catalogName: String, catalogId: String) {
        self.catalogWid = catalogWid
        self.catalogName = catalogName
        self.catalogId = catalogId
        super.init()
    }
}

final class AstroArticle: NSObject {
    let wikidataId: String
    let language: String
    let title: String?
    let extract: String?
    let thumbnailUrl: String?
    let summaryJson: String?
    let mobileHtml: Data?

    init(wikidataId: String,
         language: String,
         title: String?,
         extract: String?,
         thumbnailUrl: String?,
         summaryJson: String?,
         mobileHtml: Data?) {
        self.wikidataId = wikidataId
        self.language = language
        self.title = title
        self.extract = extract
        self.thumbnailUrl = thumbnailUrl
        self.summaryJson = summaryJson
        self.mobileHtml = mobileHtml
        super.init()
    }
}

final class Constellation: NSObject {
    let id: String
    let name: String
    let centerWId: String?
    let lineObjectIds: [String]
    let linePairs: [(String, String)]
    var rightAscension: Double
    var declination: Double

    init(id: String,
         name: String,
         centerWId: String?,
         lineObjectIds: [String],
         rightAscension: Double,
         declination: Double) {
        self.id = id
        self.name = name
        self.centerWId = centerWId
        self.lineObjectIds = lineObjectIds
        var pairs: [(String, String)] = []
        var index = 0
        while index + 1 < lineObjectIds.count {
            pairs.append((lineObjectIds[index], lineObjectIds[index + 1]))
            index += 2
        }
        linePairs = pairs
        self.rightAscension = rightAscension
        self.declination = declination
        super.init()
    }
}

final class SkyObject: NSObject {
    let id: String
    let hip: Int?
    var catalogs: [Catalog]
    let wid: String?
    let centerWId: String?
    let type: SkyObjectType
    let body: Body?
    let name: String?
    var ra: Double
    var dec: Double
    let magnitude: Double?
    let color: UIColor
    let radius: Double?
    let distance: Double?
    let mass: Double?
    let lineObjectIds: [String]
    var localizedName: String?
    var azimuth: Double?
    var altitude: Double?
    var distanceAu: Double?
    var isFavorite = false
    var isDirection = false
    var isCelestialPath = false
    var colorIndex = 0
    var startAzimuth = 0.0
    var startAltitude = 0.0
    var targetAzimuth = 0.0
    var targetAltitude = 0.0
    var lastUpdateTime = Double.nan
    var article: AstroArticle?

    init(id: String,
         hip: Int? = nil,
         catalogs: [Catalog] = [],
         wid: String? = nil,
         centerWId: String? = nil,
         type: SkyObjectType,
         body: Body? = nil,
         name: String?,
         ra: Double,
         dec: Double,
         magnitude: Double? = nil,
         color: UIColor,
         radius: Double? = nil,
         distance: Double? = nil,
         mass: Double? = nil,
         lineObjectIds: [String] = [],
         localizedName: String? = nil) {
        self.id = id
        self.hip = hip
        self.catalogs = catalogs
        self.wid = wid
        self.centerWId = centerWId
        self.type = type
        self.body = body
        self.name = name
        self.ra = ra
        self.dec = dec
        self.magnitude = magnitude
        self.color = color
        self.radius = radius
        self.distance = distance
        self.mass = mass
        self.lineObjectIds = lineObjectIds
        self.localizedName = localizedName
        super.init()
    }

    var displayName: String {
        if let localizedName, !localizedName.isEmpty {
            return localizedName
        }
        if let name, !name.isEmpty {
            return name
        }
        if let hip {
            return "HIP \(hip)"
        }
        if let catalog = catalogs.first {
            return "\(catalog.catalogName) \(catalog.catalogId)"
        }
        if let wid, !wid.isEmpty {
            return wid
        }
        return type.localizedName
    }
}

struct AstroDataSnapshot {
    let objects: [SkyObject]
    let constellations: [Constellation]
    let catalogs: [String: Catalog]
    let dbPath: String?
    let usedFallback: Bool
}
