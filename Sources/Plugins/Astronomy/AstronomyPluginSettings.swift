//
//  AstronomyPluginSettings.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

struct AstronomyPluginSettings: Codable {
    enum DirectionColor: Int, CaseIterable, Codable {
        case BLUE
        case GREEN
        case ORANGE
        case RED
        case YELLOW
        case TEAL
        case PURPLE

        var color: UIColor {
            switch self {
            case .BLUE:
                return .systemBlue
            case .GREEN:
                return .systemGreen
            case .ORANGE:
                return .systemOrange
            case .RED:
                return .systemRed
            case .YELLOW:
                return .systemYellow
            case .TEAL:
                return .systemTeal
            case .PURPLE:
                return .systemPurple
            }
        }
    }

    struct FavoriteConfig: Equatable, Codable {
        var id: String
    }

    struct DirectionConfig: Equatable, Codable {
        var id: String
        var colorIndex: Int = 0
    }

    struct CelestialPathConfig: Equatable, Codable {
        var id: String
    }

    struct CommonConfig: Equatable, Codable {
        var showRegularMap = false
    }
    
    struct MapViewPosition: Equatable, Codable {
        var azimuth: Double
        var altitude: Double
        var viewAngle: Double
        var roll: Double = 0
        var panX: Double = 0
        var panY: Double = 0
    }

    struct StarMapConfig: Equatable, Codable {
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
        var favorites: [FavoriteConfig] = []
        var directions: [DirectionConfig] = []
        var celestialPaths: [CelestialPathConfig] = []
        var savedMapPosition: MapViewPosition? = nil
    }

    static let storageKey = "astronomy_settings"
    
    private static let storageQueue = DispatchQueue(label: "net.osmand.astronomy.settings")

    var common = CommonConfig()
    var starMap = StarMapConfig()

    static func load() -> AstronomyPluginSettings {
        storageQueue.sync {
            loadUnlocked()
        }
    }

    func save() {
        Self.storageQueue.sync {
            Self.saveUnlocked(self)
        }
    }

    private static func loadUnlocked() -> AstronomyPluginSettings {
        UserDefaults.standard.object(AstronomyPluginSettings.self, with: storageKey) ?? AstronomyPluginSettings()
    }

    private static func saveUnlocked(_ settings: AstronomyPluginSettings) {
        UserDefaults.standard.set(object: settings, forKey: storageKey)
    }

    func getCommonConfig() -> CommonConfig {
        common
    }

    mutating func setCommonConfig(_ config: CommonConfig) {
        self = Self.storageQueue.sync {
            var settings = Self.loadUnlocked()
            settings.common = config
            Self.saveUnlocked(settings)
            return settings
        }
    }

    func getStarMapConfig() -> StarMapConfig {
        starMap
    }

    mutating func setStarMapConfig(_ config: StarMapConfig) {
        self = Self.storageQueue.sync {
            var settings = Self.loadUnlocked()
            settings.starMap = config
            Self.saveUnlocked(settings)
            return settings
        }
    }

    @discardableResult
    mutating func updateStarMapConfig(_ transform: (StarMapConfig) -> StarMapConfig) -> StarMapConfig {
        let result = Self.storageQueue.sync {
            var settings = Self.loadUnlocked()
            let updated = transform(settings.starMap)
            if updated != settings.starMap {
                settings.starMap = updated
                Self.saveUnlocked(settings)
            }
            return (settings, updated)
        }
        self = result.0
        return result.1
    }

    mutating func addFavorite(id: String) {
        updateStarMapConfig { config in
            guard !config.favorites.contains(where: { $0.id == id }) else {
                return config
            }
            var updated = config
            updated.favorites.append(FavoriteConfig(id: id))
            return updated
        }
    }

    mutating func removeFavorite(id: String) {
        updateStarMapConfig { config in
            var updated = config
            updated.favorites.removeAll { $0.id == id }
            return updated
        }
    }

    mutating func addDirection(id: String) -> Int {
        var resultColor = 0
        updateStarMapConfig { config in
            if let direction = config.directions.first(where: { $0.id == id }) {
                resultColor = direction.colorIndex
                return config
            }
            let maxColor = config.directions.map(\.colorIndex).max() ?? -1
            let nextColor = (maxColor + 1) % DirectionColor.allCases.count
            resultColor = nextColor
            var updated = config
            updated.directions.append(DirectionConfig(id: id, colorIndex: nextColor))
            return updated
        }
        return resultColor
    }

    mutating func removeDirection(id: String) {
        updateStarMapConfig { config in
            var updated = config
            updated.directions.removeAll { $0.id == id }
            return updated
        }
    }

    mutating func addCelestialPath(id: String) {
        updateStarMapConfig { config in
            guard !config.celestialPaths.contains(where: { $0.id == id }) else {
                return config
            }
            var updated = config
            updated.celestialPaths.append(CelestialPathConfig(id: id))
            return updated
        }
    }

    mutating func removeCelestialPath(id: String) {
        updateStarMapConfig { config in
            var updated = config
            updated.celestialPaths.removeAll { $0.id == id }
            return updated
        }
    }
}
