//
//  SkyObject.swift
//  OsmAnd Maps
//
//  Created by Codex on 20.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared
import UIKit

enum SkyObjectType: String, Codable, CaseIterable {
    case STAR
    case GALAXY
    case BLACK_HOLE
    case PLANET
    case SUN
    case MOON
    case NEBULA
    case OPEN_CLUSTER
    case GLOBULAR_CLUSTER
    case GALAXY_CLUSTER
    case CONSTELLATION

    static let star = SkyObjectType.STAR
    static let galaxy = SkyObjectType.GALAXY
    static let blackHole = SkyObjectType.BLACK_HOLE
    static let planet = SkyObjectType.PLANET
    static let sun = SkyObjectType.SUN
    static let moon = SkyObjectType.MOON
    static let nebula = SkyObjectType.NEBULA
    static let openCluster = SkyObjectType.OPEN_CLUSTER
    static let globularCluster = SkyObjectType.GLOBULAR_CLUSTER
    static let galaxyCluster = SkyObjectType.GALAXY_CLUSTER
    static let constellation = SkyObjectType.CONSTELLATION

    var titleKey: String {
        switch self {
        case .STAR:
            return "astro_type_star"
        case .GALAXY:
            return "astro_type_galaxy"
        case .BLACK_HOLE:
            return "astro_type_black_hole"
        case .PLANET:
            return "astro_type_planet"
        case .SUN:
            return "astro_type_star"
        case .MOON:
            return "astro_type_satellite"
        case .NEBULA:
            return "astro_type_nebula"
        case .OPEN_CLUSTER:
            return "astro_type_open_cluster"
        case .GLOBULAR_CLUSTER:
            return "astro_type_globular_cluster"
        case .GALAXY_CLUSTER:
            return "astro_type_galaxy_cluster"
        case .CONSTELLATION:
            return "astro_type_constellation"
        }
    }

    var localizedName: String {
        switch self {
        case .STAR:
            return localizedString("astro_stars")
        case .GALAXY:
            return localizedString("astro_galaxies")
        case .BLACK_HOLE:
            return localizedString("astro_black_holes")
        case .PLANET:
            return localizedString("astro_planets")
        case .SUN:
            return localizedString("astro_sun")
        case .MOON:
            return localizedString("astro_moon")
        case .NEBULA:
            return localizedString("astro_nebulae")
        case .OPEN_CLUSTER:
            return localizedString("astro_open_clusters")
        case .GLOBULAR_CLUSTER:
            return localizedString("astro_globular_clusters")
        case .GALAXY_CLUSTER:
            return localizedString("astro_galaxy_clusters")
        case .CONSTELLATION:
            return localizedString("astro_constellations")
        }
    }

    func isSunSystem() -> Bool {
        self == .SUN || self == .MOON || self == .PLANET
    }

    static func fromDbType(_ value: String?) -> SkyObjectType? {
        switch value?.lowercased() {
        case "stars", "star":
            return .STAR
        case "galaxies", "galaxy":
            return .GALAXY
        case "black_holes", "black_hole":
            return .BLACK_HOLE
        case "nebulae", "nebula":
            return .NEBULA
        case "open_clusters", "open_cluster":
            return .OPEN_CLUSTER
        case "globular_clusters", "globular_cluster":
            return .GLOBULAR_CLUSTER
        case "galaxy_clusters", "galaxy_cluster":
            return .GALAXY_CLUSTER
        case "constellations", "constellation":
            return .CONSTELLATION
        case "solar_system", "planet":
            return .PLANET
        default:
            return nil
        }
    }
}

class SkyObject: NSObject {
    private static let hdCatalogWid = "Q111130"
    private static let hicCatalogWid = "Q28914996"
    private static let hipCatalogWid = "Q537199"

    let id: String
    let hip: Int
    var catalogs: [Catalog]
    let wid: String
    let centerWId: String?
    let type: SkyObjectType
    let body: Body?
    let name: String
    var ra: Double
    var dec: Double
    let magnitude: Double
    let color: UIColor
    var radius: Double?
    var distance: Double?
    var mass: Double?
    var localizedName: String?
    var azimuth: Double
    var altitude: Double
    var distAu: Double
    var isFavorite: Bool
    var showDirection: Bool
    var showCelestialPath: Bool
    var colorIndex: Int
    var startAzimuth: Double
    var startAltitude: Double
    var targetAzimuth: Double
    var targetAltitude: Double
    var lastUpdateTime: Double
    var article: AstroArticle?
    var lineObjectIds: [String]

    var distanceAu: Double {
        get { distAu }
        set { distAu = newValue }
    }

    var isDirection: Bool {
        get { showDirection }
        set { showDirection = newValue }
    }

    var isCelestialPath: Bool {
        get { showCelestialPath }
        set { showCelestialPath = newValue }
    }

    var displayName: String {
        getDisplayName()
    }

    override var hash: Int {
        id.hashValue
    }

    override var description: String {
        "SkyObject(id='\(id)', name='\(name)', type=\(type))"
    }

    init(id: String,
         hip: Int,
         catalogs: [Catalog] = [],
         wid: String,
         centerWId: String? = nil,
         type: SkyObjectType,
         body: Body?,
         name: String,
         ra: Double,
         dec: Double,
         magnitude: Double,
         color: UIColor,
         radius: Double? = nil,
         distance: Double? = nil,
         mass: Double? = nil,
         localizedName: String? = nil,
         lineObjectIds: [String] = []) {
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
        self.localizedName = localizedName
        self.azimuth = 0
        self.altitude = 0
        self.distAu = 0
        self.isFavorite = false
        self.showDirection = false
        self.showCelestialPath = false
        self.colorIndex = 0
        self.startAzimuth = 0
        self.startAltitude = 0
        self.targetAzimuth = 0
        self.targetAltitude = 0
        self.lastUpdateTime = -1
        self.lineObjectIds = lineObjectIds
        super.init()
    }

    convenience init(id: String,
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
        self.init(id: id,
                  hip: hip ?? -1,
                  catalogs: catalogs,
                  wid: wid ?? "",
                  centerWId: centerWId,
                  type: type,
                  body: body,
                  name: name ?? "",
                  ra: ra,
                  dec: dec,
                  magnitude: magnitude ?? 25,
                  color: color,
                  radius: radius,
                  distance: distance,
                  mass: mass,
                  localizedName: localizedName,
                  lineObjectIds: lineObjectIds)
    }

    func niceName() -> String {
        getDisplayName()
    }

    func hasMissingPrimaryName() -> Bool {
        getPrimaryDisplayName() == nil
    }

    func getDisplayName() -> String {
        if let primaryName = getPrimaryDisplayName() {
            return primaryName
        }
        if let catalogName = getCatalogFallbackName() {
            return catalogName
        }
        if let hipName = getHipFallbackName() {
            return hipName
        }
        if !wid.isEmpty {
            return wid
        }
        return name
    }

    private func getPrimaryDisplayName() -> String? {
        if let localizedName, !localizedName.isEmpty {
            return localizedName
        }
        if !name.isEmpty && name.caseInsensitiveCompare(wid) != .orderedSame {
            return name
        }
        return nil
    }

    private func getCatalogFallbackName() -> String? {
        var catalogId = catalogs.first { $0.wid == Self.hdCatalogWid }?.catalogId
        if catalogId?.isEmpty == false {
            return catalogId
        }

        catalogId = catalogs.first { $0.wid == Self.hicCatalogWid }?.catalogId
        if catalogId?.isEmpty == false {
            return catalogId
        }

        catalogId = catalogs.first { $0.wid == Self.hipCatalogWid }?.catalogId
        if catalogId?.isEmpty == false {
            return catalogId
        }
        return nil
    }

    private func getHipFallbackName() -> String? {
        hip > 0 ? "HIP \(hip)" : nil
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? SkyObject else {
            return false
        }
        return id == other.id
    }
}
