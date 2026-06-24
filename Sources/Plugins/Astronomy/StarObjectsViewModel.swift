//
//  StarObjectsViewModel.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

final class StarObjectsViewModel {
    private let provider: AstroDataProvider
    private(set) var settings: AstronomyPluginSettings

    var onDataChanged: (() -> Void)?
    private(set) var skyObjects: [SkyObject] = []
    private(set) var constellations: [Constellation] = []

    init(provider: AstroDataProvider, settings: AstronomyPluginSettings) {
        self.provider = provider
        self.settings = settings
    }

    func updateSettings(_ settings: AstronomyPluginSettings) {
        self.settings = settings
        applyObjectSettings()
        onDataChanged?()
    }

    func load(preferredLocale: String?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            let objects = provider.getSkyObjects(preferredLocale: preferredLocale)
            let constellations = provider.getConstellations(preferredLocale: preferredLocale)
            DispatchQueue.main.async {
                self.applyObjectSettings(to: objects + constellations.map { $0 as SkyObject })
                let favoriteOrder = Dictionary(uniqueKeysWithValues: self.settings.starMap.favorites.enumerated().map { ($0.element.id, $0.offset) })
                self.skyObjects = objects.sorted { (favoriteOrder[$0.id] ?? Int.max) < (favoriteOrder[$1.id] ?? Int.max) }
                self.constellations = constellations.sorted { (favoriteOrder[$0.id] ?? Int.max) < (favoriteOrder[$1.id] ?? Int.max) }
                self.onDataChanged?()
            }
        }
    }

    private func applyObjectSettings(to objects: [SkyObject]? = nil) {
        let targetObjects: [SkyObject]
        if let providedObjects = objects {
            targetObjects = providedObjects
        } else {
            targetObjects = skyObjects + constellations.map { $0 as SkyObject }
        }

        let favoritesMap = Dictionary(uniqueKeysWithValues: settings.starMap.favorites.map { ($0.id, $0) })
        let directionsMap = Dictionary(uniqueKeysWithValues: settings.starMap.directions.map { ($0.id, $0) })
        let celestialPathsMap = Dictionary(uniqueKeysWithValues: settings.starMap.celestialPaths.map { ($0.id, $0) })
        for object in targetObjects {
            object.isFavorite = favoritesMap[object.id] != nil
            object.showDirection = directionsMap[object.id] != nil
            object.showCelestialPath = celestialPathsMap[object.id] != nil
            if let direction = directionsMap[object.id] {
                object.colorIndex = direction.colorIndex
            } else {
                object.colorIndex = 0
            }
        }
    }
}
