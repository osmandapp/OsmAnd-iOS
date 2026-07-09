//
//  AstronomyPluginSettings.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

struct AstronomyPluginSettings {
    enum DirectionColor: Int, CaseIterable {
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

    struct FavoriteConfig: Equatable {
        var id: String
    }

    struct DirectionConfig: Equatable {
        var id: String
        var colorIndex: Int = 0
    }

    struct CelestialPathConfig: Equatable {
        var id: String
    }

    struct CommonConfig: Equatable {
        var showRegularMap = false
    }
    
    struct MapViewPosition: Equatable {
        var azimuth: Double
        var altitude: Double
        var viewAngle: Double
        var roll: Double = 0
        var panX: Double = 0
        var panY: Double = 0
    }

    struct StarMapConfig: Equatable {
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
    private static let keyCommon = "common"
    private static let keyShowRegularMap = "showRegularMap"
    private static let keyStarMap = "star_map"
    private static let keyShowAzimuthal = "showAzimuthalGrid"
    private static let keyShowEquatorial = "showEquatorialGrid"
    private static let keyShowEcliptic = "showEclipticLine"
    private static let keyShowMeridian = "showMeridianLine"
    private static let keyShowEquator = "showEquatorLine"
    private static let keyShowGalactic = "showGalacticLine"
    private static let keyShowSun = "showSun"
    private static let keyShowMoon = "showMoon"
    private static let keyShowPlanets = "showPlanets"
    private static let keyShowFavorites = "showFavorites"
    private static let keyShowDirections = "showDirections"
    private static let keyShowCelestialPaths = "showCelestialPaths"
    private static let keyShowRedFilter = "showRedFilter"
    private static let keyShowConstellations = "showConstellations"
    private static let keyShowStars = "showStars"
    private static let keyShowGalaxies = "showGalaxies"
    private static let keyShowNebulae = "showNebulae"
    private static let keyShowOpenClusters = "showOpenClusters"
    private static let keyShowGlobularClusters = "showGlobularClusters"
    private static let keyShowGalaxyClusters = "showGalaxyClusters"
    private static let keyShowBlackHoles = "showBlackHoles"
    private static let keyIs2DMode = "is2DMode"
    private static let keyShowMagnitudeFilter = "showMagnitudeFilter"
    private static let keyMagnitudeFilter = "magnitudeFilter"
    private static let keyFavorites = "favorites"
    private static let keyDirections = "directions"
    private static let keyCelestialPaths = "celestialPaths"
    private static let keyId = "id"
    private static let keyColorIndex = "colorIndex"
    
    private static let keySavedMapPosition = "savedMapPosition"
    private static let keyLastAzimuth = "lastAzimuth"
    private static let keyLastAltitude = "lastAltitude"
    private static let keyLastViewAngle = "lastViewAngle"
    private static let keyLastRoll = "lastRoll"
    private static let keyLastPanX = "lastPanX"
    private static let keyLastPanY = "lastPanY"
    
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
        guard let root = settingsJsonUnlocked() else {
            return AstronomyPluginSettings()
        }
        var settings = AstronomyPluginSettings()
        settings.common = parseCommonConfig(root[Self.keyCommon] as? [String: Any])
        settings.starMap = parseStarMapConfig(root[Self.keyStarMap] as? [String: Any])
        return settings
    }

    private static func saveUnlocked(_ settings: AstronomyPluginSettings) {
        var root: [String: Any] = [:]
        root[Self.keyCommon] = [
            Self.keyShowRegularMap: settings.common.showRegularMap
        ]
        root[Self.keyStarMap] = Self.serializeStarMapConfig(settings.starMap)
        guard let data = try? JSONSerialization.data(withJSONObject: root),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        UserDefaults.standard.set(string, forKey: Self.storageKey)
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

    private static func settingsJsonUnlocked() -> [String: Any]? {
        guard let json = UserDefaults.standard.string(forKey: storageKey),
              !json.isEmpty,
              let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return root
    }

    private static func parseCommonConfig(_ json: [String: Any]?) -> CommonConfig {
        CommonConfig(showRegularMap: bool(json?[keyShowRegularMap], fallback: false))
    }

    private static func parseStarMapConfig(_ json: [String: Any]?) -> StarMapConfig {
        var nextColor = 0
        return StarMapConfig(showAzimuthalGrid: bool(json?[keyShowAzimuthal], fallback: true),
                             showEquatorialGrid: bool(json?[keyShowEquatorial], fallback: false),
                             showEclipticLine: bool(json?[keyShowEcliptic], fallback: false),
                             showMeridianLine: bool(json?[keyShowMeridian], fallback: false),
                             showEquatorLine: bool(json?[keyShowEquator], fallback: false),
                             showGalacticLine: bool(json?[keyShowGalactic], fallback: false),
                             showFavorites: bool(json?[keyShowFavorites], fallback: true),
                             showDirections: bool(json?[keyShowDirections], fallback: true),
                             showCelestialPaths: bool(json?[keyShowCelestialPaths], fallback: true),
                             showRedFilter: bool(json?[keyShowRedFilter], fallback: false),
                             showSun: bool(json?[keyShowSun], fallback: true),
                             showMoon: bool(json?[keyShowMoon], fallback: true),
                             showPlanets: bool(json?[keyShowPlanets], fallback: true),
                             showConstellations: bool(json?[keyShowConstellations], fallback: false),
                             showStars: bool(json?[keyShowStars], fallback: false),
                             showGalaxies: bool(json?[keyShowGalaxies], fallback: false),
                             showNebulae: bool(json?[keyShowNebulae], fallback: false),
                             showOpenClusters: bool(json?[keyShowOpenClusters], fallback: false),
                             showGlobularClusters: bool(json?[keyShowGlobularClusters], fallback: false),
                             showGalaxyClusters: bool(json?[keyShowGalaxyClusters], fallback: false),
                             showBlackHoles: bool(json?[keyShowBlackHoles], fallback: false),
                             is2DMode: bool(json?[keyIs2DMode], fallback: false),
                             showMagnitudeFilter: bool(json?[keyShowMagnitudeFilter], fallback: false),
                             magnitudeFilter: double(json?[keyMagnitudeFilter]),
                             favorites: parseItems(json?[keyFavorites]) { FavoriteConfig(id: $0) },
                             directions: parseItems(json?[keyDirections]) { item, id in
                                 defer { nextColor += 1 }
                                 return DirectionConfig(id: id,
                                                        colorIndex: int(item[keyColorIndex], fallback: nextColor % DirectionColor.allCases.count))
                             },
                             celestialPaths: parseItems(json?[keyCelestialPaths]) { CelestialPathConfig(id: $0) },
                             savedMapPosition: parseMapViewPosition(json?[keySavedMapPosition] as? [String: Any]))
    }
    
    private static func parseMapViewPosition(_ json: [String: Any]?) -> MapViewPosition? {
        guard let json,
              let azimuth = double(json[keyLastAzimuth]),
              let altitude = double(json[keyLastAltitude]),
              let viewAngle = double(json[keyLastViewAngle]) else {
            return nil
        }
        return MapViewPosition(
            azimuth: azimuth,
            altitude: altitude,
            viewAngle: viewAngle,
            roll: double(json[keyLastRoll]) ?? 0,
            panX: double(json[keyLastPanX]) ?? 0,
            panY: double(json[keyLastPanY]) ?? 0
        )
    }

    private static func serializeStarMapConfig(_ config: StarMapConfig) -> [String: Any] {
        var json: [String: Any] = [
            keyShowAzimuthal: config.showAzimuthalGrid,
            keyShowEquatorial: config.showEquatorialGrid,
            keyShowEcliptic: config.showEclipticLine,
            keyShowMeridian: config.showMeridianLine,
            keyShowEquator: config.showEquatorLine,
            keyShowGalactic: config.showGalacticLine,
            keyShowFavorites: config.showFavorites,
            keyShowDirections: config.showDirections,
            keyShowCelestialPaths: config.showCelestialPaths,
            keyShowRedFilter: config.showRedFilter,
            keyShowSun: config.showSun,
            keyShowMoon: config.showMoon,
            keyShowPlanets: config.showPlanets,
            keyShowConstellations: config.showConstellations,
            keyShowStars: config.showStars,
            keyShowGalaxies: config.showGalaxies,
            keyShowNebulae: config.showNebulae,
            keyShowOpenClusters: config.showOpenClusters,
            keyShowGlobularClusters: config.showGlobularClusters,
            keyShowGalaxyClusters: config.showGalaxyClusters,
            keyShowBlackHoles: config.showBlackHoles,
            keyIs2DMode: config.is2DMode,
            keyShowMagnitudeFilter: config.showMagnitudeFilter
        ]
        if let magnitudeFilter = config.magnitudeFilter {
            json[keyMagnitudeFilter] = magnitudeFilter
        }
        if !config.favorites.isEmpty {
            json[keyFavorites] = config.favorites.map { [keyId: $0.id] }
        }
        if !config.directions.isEmpty {
            json[keyDirections] = config.directions.map { [keyId: $0.id, keyColorIndex: $0.colorIndex] }
        }
        if !config.celestialPaths.isEmpty {
            json[keyCelestialPaths] = config.celestialPaths.map { [keyId: $0.id] }
        }
        if let pos = config.savedMapPosition {
            json[keySavedMapPosition] = [
                keyLastAzimuth: pos.azimuth,
                keyLastAltitude: pos.altitude,
                keyLastViewAngle: pos.viewAngle,
                keyLastRoll: pos.roll,
                keyLastPanX: pos.panX,
                keyLastPanY: pos.panY
            ]
        }
        return json
    }

    private static func parseItems<T>(_ value: Any?, factory: (String) -> T) -> [T] {
        guard let array = value as? [[String: Any]] else {
            return []
        }
        return array.compactMap { item in
            guard let id = item[keyId] as? String, !id.isEmpty else {
                return nil
            }
            return factory(id)
        }
    }

    private static func parseItems<T>(_ value: Any?, factory: ([String: Any], String) -> T) -> [T] {
        guard let array = value as? [[String: Any]] else {
            return []
        }
        return array.compactMap { item in
            guard let id = item[keyId] as? String, !id.isEmpty else {
                return nil
            }
            return factory(item, id)
        }
    }

    private static func bool(_ value: Any?, fallback defaultValue: Bool) -> Bool {
        if let value = value as? Bool {
            return value
        }
        if let value = value as? NSNumber {
            return value.boolValue
        }
        return defaultValue
    }

    private static func int(_ value: Any?, fallback defaultValue: Int) -> Int {
        if let value = value as? Int {
            return value
        }
        if let value = value as? NSNumber {
            return value.intValue
        }
        if let value = value as? String {
            return Int(value) ?? defaultValue
        }
        return defaultValue
    }

    private static func double(_ value: Any?) -> Double? {
        if let value = value as? Double {
            return value.isNaN ? nil : value
        }
        if let value = value as? NSNumber {
            let double = value.doubleValue
            return double.isNaN ? nil : double
        }
        if let value = value as? String, let double = Double(value) {
            return double.isNaN ? nil : double
        }
        return nil
    }
}
