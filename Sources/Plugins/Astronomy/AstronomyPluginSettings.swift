//
//  AstronomyPluginSettings.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

struct AstronomyPluginSettings: Codable {
    static let storageKey = "astronomy_settings"

    struct Common: Codable {
        var showRegularMap = false
    }

    struct Direction: Codable {
        var objectId: String
        var colorIndex: Int
    }

    struct StarMap: Codable {
        var showAzimuthalGrid = true
        var showEquatorialGrid = false
        var showEclipticLine = false
        var showMeridianLine = false
        var showEquatorLine = false
        var showGalacticLine = false
        var showFavorites = true
        var showDirections = true
        var showCelestialPaths = true
        var showRedFilter = false
        var showSun = true
        var showMoon = true
        var showPlanets = true
        var showConstellations = false
        var showStars = false
        var showGalaxies = false
        var showNebulae = false
        var showOpenClusters = false
        var showGlobularClusters = false
        var showGalaxyClusters = false
        var showBlackHoles = false
        var is2DMode = false
        var showMagnitudeFilter = false
        var magnitudeFilter: Double?
        var favorites: [String] = []
        var directions: [Direction] = []
        var celestialPaths: [String] = []
    }

    var common = Common()
    var starMap = StarMap()

    static func load() -> AstronomyPluginSettings {
        guard let json = UserDefaults.standard.string(forKey: storageKey),
              let data = json.data(using: .utf8),
              let settings = try? JSONDecoder().decode(AstronomyPluginSettings.self, from: data) else {
            return AstronomyPluginSettings()
        }
        return settings
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self),
              let json = String(data: data, encoding: .utf8) else {
            return
        }
        UserDefaults.standard.set(json, forKey: Self.storageKey)
    }

    func isObjectTypeVisible(_ type: SkyObjectType) -> Bool {
        switch type {
        case .sun:
            return starMap.showSun
        case .moon:
            return starMap.showMoon
        case .planet:
            return starMap.showPlanets
        case .constellation:
            return starMap.showConstellations
        case .star:
            return starMap.showStars
        case .galaxy:
            return starMap.showGalaxies
        case .nebula:
            return starMap.showNebulae
        case .openCluster:
            return starMap.showOpenClusters
        case .globularCluster:
            return starMap.showGlobularClusters
        case .galaxyCluster:
            return starMap.showGalaxyClusters
        case .blackHole:
            return starMap.showBlackHoles
        }
    }
}

