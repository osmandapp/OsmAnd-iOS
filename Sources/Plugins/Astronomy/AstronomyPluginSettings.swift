//
//  AstronomyPluginSettings.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import UIKit

final class AstronomyPluginSettings {
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

    struct FavoriteConfig: Equatable, Codable {
        var id: String
    }

    struct DirectionConfig: Equatable, Codable {
        var id: String
        var colorIndex: Int = 0

        init(id: String, colorIndex: Int = 0) {
            self.id = id
            self.colorIndex = colorIndex
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            colorIndex = try container.decodeIfPresent(Int.self, forKey: .colorIndex) ?? 0
        }
    }

    struct CelestialPathConfig: Equatable, Codable {
        var id: String
    }

    struct CommonConfig: Equatable, Codable {
        var showRegularMap = false

        init(showRegularMap: Bool = false) {
            self.showRegularMap = showRegularMap
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            showRegularMap = try container.decodeIfPresent(Bool.self, forKey: .showRegularMap) ?? false
        }
    }

    struct MapViewPosition: Equatable, Codable {
        var azimuth: Double
        var altitude: Double
        var viewAngle: Double
        var roll: Double = 0
        var panX: Double = 0
        var panY: Double = 0

        init(azimuth: Double, altitude: Double, viewAngle: Double, roll: Double = 0, panX: Double = 0, panY: Double = 0) {
            self.azimuth = azimuth
            self.altitude = altitude
            self.viewAngle = viewAngle
            self.roll = roll
            self.panX = panX
            self.panY = panY
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            azimuth = try container.decode(Double.self, forKey: .azimuth)
            altitude = try container.decode(Double.self, forKey: .altitude)
            viewAngle = try container.decode(Double.self, forKey: .viewAngle)
            roll = try container.decodeIfPresent(Double.self, forKey: .roll) ?? 0
            panX = try container.decodeIfPresent(Double.self, forKey: .panX) ?? 0
            panY = try container.decodeIfPresent(Double.self, forKey: .panY) ?? 0
        }
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
        var savedMapPosition: MapViewPosition?

        init(
            showAzimuthalGrid: Bool = true,
            showEquatorialGrid: Bool = false,
            showEclipticLine: Bool = false,
            showMeridianLine: Bool = false,
            showEquatorLine: Bool = false,
            showGalacticLine: Bool = false,
            showFavorites: Bool = true,
            showDirections: Bool = true,
            showCelestialPaths: Bool = true,
            showRedFilter: Bool = false,
            showSun: Bool = true,
            showMoon: Bool = true,
            showPlanets: Bool = true,
            showConstellations: Bool = false,
            showStars: Bool = false,
            showGalaxies: Bool = false,
            showNebulae: Bool = false,
            showOpenClusters: Bool = false,
            showGlobularClusters: Bool = false,
            showGalaxyClusters: Bool = false,
            showBlackHoles: Bool = false,
            is2DMode: Bool = false,
            showMagnitudeFilter: Bool = false,
            magnitudeFilter: Double? = nil,
            favorites: [FavoriteConfig] = [],
            directions: [DirectionConfig] = [],
            celestialPaths: [CelestialPathConfig] = [],
            savedMapPosition: MapViewPosition? = nil
        ) {
            self.showAzimuthalGrid = showAzimuthalGrid
            self.showEquatorialGrid = showEquatorialGrid
            self.showEclipticLine = showEclipticLine
            self.showMeridianLine = showMeridianLine
            self.showEquatorLine = showEquatorLine
            self.showGalacticLine = showGalacticLine
            self.showFavorites = showFavorites
            self.showDirections = showDirections
            self.showCelestialPaths = showCelestialPaths
            self.showRedFilter = showRedFilter
            self.showSun = showSun
            self.showMoon = showMoon
            self.showPlanets = showPlanets
            self.showConstellations = showConstellations
            self.showStars = showStars
            self.showGalaxies = showGalaxies
            self.showNebulae = showNebulae
            self.showOpenClusters = showOpenClusters
            self.showGlobularClusters = showGlobularClusters
            self.showGalaxyClusters = showGalaxyClusters
            self.showBlackHoles = showBlackHoles
            self.is2DMode = is2DMode
            self.showMagnitudeFilter = showMagnitudeFilter
            self.magnitudeFilter = magnitudeFilter
            self.favorites = favorites
            self.directions = directions
            self.celestialPaths = celestialPaths
            self.savedMapPosition = savedMapPosition
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            showAzimuthalGrid = try container.decodeIfPresent(Bool.self, forKey: .showAzimuthalGrid) ?? true
            showEquatorialGrid = try container.decodeIfPresent(Bool.self, forKey: .showEquatorialGrid) ?? false
            showEclipticLine = try container.decodeIfPresent(Bool.self, forKey: .showEclipticLine) ?? false
            showMeridianLine = try container.decodeIfPresent(Bool.self, forKey: .showMeridianLine) ?? false
            showEquatorLine = try container.decodeIfPresent(Bool.self, forKey: .showEquatorLine) ?? false
            showGalacticLine = try container.decodeIfPresent(Bool.self, forKey: .showGalacticLine) ?? false
            showFavorites = try container.decodeIfPresent(Bool.self, forKey: .showFavorites) ?? true
            showDirections = try container.decodeIfPresent(Bool.self, forKey: .showDirections) ?? true
            showCelestialPaths = try container.decodeIfPresent(Bool.self, forKey: .showCelestialPaths) ?? true
            showRedFilter = try container.decodeIfPresent(Bool.self, forKey: .showRedFilter) ?? false
            showSun = try container.decodeIfPresent(Bool.self, forKey: .showSun) ?? true
            showMoon = try container.decodeIfPresent(Bool.self, forKey: .showMoon) ?? true
            showPlanets = try container.decodeIfPresent(Bool.self, forKey: .showPlanets) ?? true
            showConstellations = try container.decodeIfPresent(Bool.self, forKey: .showConstellations) ?? false
            showStars = try container.decodeIfPresent(Bool.self, forKey: .showStars) ?? false
            showGalaxies = try container.decodeIfPresent(Bool.self, forKey: .showGalaxies) ?? false
            showNebulae = try container.decodeIfPresent(Bool.self, forKey: .showNebulae) ?? false
            showOpenClusters = try container.decodeIfPresent(Bool.self, forKey: .showOpenClusters) ?? false
            showGlobularClusters = try container.decodeIfPresent(Bool.self, forKey: .showGlobularClusters) ?? false
            showGalaxyClusters = try container.decodeIfPresent(Bool.self, forKey: .showGalaxyClusters) ?? false
            showBlackHoles = try container.decodeIfPresent(Bool.self, forKey: .showBlackHoles) ?? false
            is2DMode = try container.decodeIfPresent(Bool.self, forKey: .is2DMode) ?? false
            showMagnitudeFilter = try container.decodeIfPresent(Bool.self, forKey: .showMagnitudeFilter) ?? false
            magnitudeFilter = try container.decodeIfPresent(Double.self, forKey: .magnitudeFilter)
            favorites = try container.decodeIfPresent([FavoriteConfig].self, forKey: .favorites) ?? []
            directions = try container.decodeIfPresent([DirectionConfig].self, forKey: .directions) ?? []
            celestialPaths = try container.decodeIfPresent([CelestialPathConfig].self, forKey: .celestialPaths) ?? []
            savedMapPosition = try container.decodeIfPresent(MapViewPosition.self, forKey: .savedMapPosition)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(showAzimuthalGrid, forKey: .showAzimuthalGrid)
            try container.encode(showEquatorialGrid, forKey: .showEquatorialGrid)
            try container.encode(showEclipticLine, forKey: .showEclipticLine)
            try container.encode(showMeridianLine, forKey: .showMeridianLine)
            try container.encode(showEquatorLine, forKey: .showEquatorLine)
            try container.encode(showGalacticLine, forKey: .showGalacticLine)
            try container.encode(showFavorites, forKey: .showFavorites)
            try container.encode(showDirections, forKey: .showDirections)
            try container.encode(showCelestialPaths, forKey: .showCelestialPaths)
            try container.encode(showRedFilter, forKey: .showRedFilter)
            try container.encode(showSun, forKey: .showSun)
            try container.encode(showMoon, forKey: .showMoon)
            try container.encode(showPlanets, forKey: .showPlanets)
            try container.encode(showConstellations, forKey: .showConstellations)
            try container.encode(showStars, forKey: .showStars)
            try container.encode(showGalaxies, forKey: .showGalaxies)
            try container.encode(showNebulae, forKey: .showNebulae)
            try container.encode(showOpenClusters, forKey: .showOpenClusters)
            try container.encode(showGlobularClusters, forKey: .showGlobularClusters)
            try container.encode(showGalaxyClusters, forKey: .showGalaxyClusters)
            try container.encode(showBlackHoles, forKey: .showBlackHoles)
            try container.encode(is2DMode, forKey: .is2DMode)
            try container.encode(showMagnitudeFilter, forKey: .showMagnitudeFilter)
            
            try container.encodeIfPresent(magnitudeFilter, forKey: .magnitudeFilter)
            if !favorites.isEmpty {
                try container.encode(favorites, forKey: .favorites)
            }
            if !directions.isEmpty {
                try container.encode(directions, forKey: .directions)
            }
            if !celestialPaths.isEmpty {
                try container.encode(celestialPaths, forKey: .celestialPaths)
            }
            try container.encodeIfPresent(savedMapPosition, forKey: .savedMapPosition)
        }

        private enum CodingKeys: String, CodingKey {
            case showAzimuthalGrid
            case showEquatorialGrid
            case showEclipticLine
            case showMeridianLine
            case showEquatorLine
            case showGalacticLine
            case showFavorites
            case showDirections
            case showCelestialPaths
            case showRedFilter
            case showSun
            case showMoon
            case showPlanets
            case showConstellations
            case showStars
            case showGalaxies
            case showNebulae
            case showOpenClusters
            case showGlobularClusters
            case showGalaxyClusters
            case showBlackHoles
            case is2DMode
            case showMagnitudeFilter
            case magnitudeFilter
            case favorites
            case directions
            case celestialPaths
            case savedMapPosition
        }
    }

    private struct SettingsStorage: Codable {
        var common: CommonConfig?
        var starMap: StarMapConfig?

        enum CodingKeys: String, CodingKey {
            case common
            case starMap = "star_map"
        }
    }

    private struct RecentChipDTO: Codable {
        var label: String
        var objectId: String?
    }

    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    var common = CommonConfig()
    var starMap = StarMapConfig()

    private let settingsPref: OACommonString?
    private let recentPref: OACommonString?
    private let lock = NSLock()

    init(settingsPref: OACommonString, recentPref: OACommonString? = nil) {
        self.settingsPref = settingsPref
        self.recentPref = recentPref
        reloadFromPreference()
    }

    init() {
        self.settingsPref = nil
        self.recentPref = nil
    }

    func copyForUI() -> AstronomyPluginSettings {
        let copy = AstronomyPluginSettings()
        copy.common = common
        copy.starMap = starMap
        return copy
    }

    func reloadFromPreference() {
        lock.lock()
        defer { lock.unlock() }
        let storage = readStorageUnlocked()
        common = storage.common ?? CommonConfig()
        starMap = storage.starMap ?? StarMapConfig()
    }

    func getCommonConfig() -> CommonConfig {
        lock.lock()
        defer { lock.unlock() }
        let config = readStorageUnlocked().common ?? CommonConfig()
        common = config
        return config
    }

    func setCommonConfig(_ config: CommonConfig) {
        lock.lock()
        defer { lock.unlock() }
        var storage = readStorageUnlocked()
        storage.common = config
        writeStorageUnlocked(storage)
        common = config
    }

    func getStarMapConfig() -> StarMapConfig {
        lock.lock()
        defer { lock.unlock() }
        let config = readStorageUnlocked().starMap ?? StarMapConfig()
        starMap = config
        return config
    }

    func setStarMapConfig(_ config: StarMapConfig) {
        lock.lock()
        defer { lock.unlock() }
        var storage = readStorageUnlocked()
        storage.starMap = config
        writeStorageUnlocked(storage)
        starMap = config
    }

    @discardableResult func updateStarMapConfig(_ transform: (StarMapConfig) -> StarMapConfig) -> StarMapConfig {
        lock.lock()
        defer { lock.unlock() }
        var storage = readStorageUnlocked()
        let current = storage.starMap ?? StarMapConfig()
        let updated = transform(current)
        if updated != current {
            storage.starMap = updated
            writeStorageUnlocked(storage)
        }
        starMap = updated
        return updated
    }

    func addFavorite(id: String) {
        updateStarMapConfig { config in
            guard !config.favorites.contains(where: { $0.id == id }) else {
                return config
            }
            var updated = config
            updated.favorites.append(FavoriteConfig(id: id))
            return updated
        }
    }

    func removeFavorite(id: String) {
        updateStarMapConfig { config in
            var updated = config
            updated.favorites.removeAll { $0.id == id }
            return updated
        }
    }

    func addDirection(id: String) -> Int {
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

    func removeDirection(id: String) {
        updateStarMapConfig { config in
            var updated = config
            updated.directions.removeAll { $0.id == id }
            return updated
        }
    }

    func addCelestialPath(id: String) {
        updateStarMapConfig { config in
            guard !config.celestialPaths.contains(where: { $0.id == id }) else {
                return config
            }
            var updated = config
            updated.celestialPaths.append(CelestialPathConfig(id: id))
            return updated
        }
    }

    func removeCelestialPath(id: String) {
        updateStarMapConfig { config in
            var updated = config
            updated.celestialPaths.removeAll { $0.id == id }
            return updated
        }
    }

    // MARK: - Recently viewed (global, all profiles)

    func getRecentChips() -> [StarMapRecentChip] {
        lock.lock()
        defer { lock.unlock() }
        return readRecentChipsUnlocked()
    }

    func setRecentChips(_ chips: [StarMapRecentChip]) {
        lock.lock()
        defer { lock.unlock() }
        writeRecentChipsUnlocked(chips)
    }

    // MARK: - Codable I/O

    private func readStorageUnlocked() -> SettingsStorage {
        guard let settingsPref else {
            return SettingsStorage()
        }
        let str = settingsPref.get()
        guard !str.isEmpty, let data = str.data(using: .utf8) else {
            return SettingsStorage()
        }
        return (try? Self.decoder.decode(SettingsStorage.self, from: data)) ?? SettingsStorage()
    }

    private func writeStorageUnlocked(_ storage: SettingsStorage) {
        guard let settingsPref else {
            return
        }
        guard let data = try? Self.encoder.encode(storage),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        settingsPref.set(string)
    }

    private func readRecentChipsUnlocked() -> [StarMapRecentChip] {
        guard let recentPref else {
            return []
        }
        let str = recentPref.get()
        guard !str.isEmpty,
              let data = str.data(using: .utf8),
              let dtos = try? Self.decoder.decode([RecentChipDTO].self, from: data) else {
            return []
        }
        return dtos.compactMap { dto in
            let label = dto.label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !label.isEmpty else {
                return nil
            }
            return StarMapRecentChip(label: label, objectId: dto.objectId)
        }
    }

    private func writeRecentChipsUnlocked(_ chips: [StarMapRecentChip]) {
        guard let recentPref else {
            return
        }
        let dtos = chips.map { RecentChipDTO(label: $0.label, objectId: $0.objectId) }
        guard let data = try? Self.encoder.encode(dtos),
              let string = String(data: data, encoding: .utf8) else {
            return
        }
        recentPref.set(string)
    }
}
