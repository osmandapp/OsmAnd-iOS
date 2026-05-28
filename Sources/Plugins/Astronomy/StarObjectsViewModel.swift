//
//  StarObjectsViewModel.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation

final class StarObjectsViewModel {
    let state = StarChartState()
    private let provider: AstroDataProvider
    private(set) var settings: AstronomyPluginSettings

    var onDataChanged: (() -> Void)?

    var skyObjects: [SkyObject] {
        state.dataSnapshot?.objects ?? []
    }

    var constellations: [Constellation] {
        state.dataSnapshot?.constellations ?? []
    }

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
            let snapshot = provider.loadData(preferredLocale: preferredLocale)
            DispatchQueue.main.async {
                self.applyObjectSettings(to: snapshot.objects + snapshot.constellations.map { $0 as SkyObject })
                let favoriteOrder = Dictionary(uniqueKeysWithValues: self.settings.starMap.favorites.enumerated().map { ($0.element.id, $0.offset) })
                let sortedObjects = snapshot.objects.sorted { (favoriteOrder[$0.id] ?? Int.max) < (favoriteOrder[$1.id] ?? Int.max) }
                let sortedConstellations = snapshot.constellations.sorted { (favoriteOrder[$0.id] ?? Int.max) < (favoriteOrder[$1.id] ?? Int.max) }
                self.state.dataSnapshot = AstroDataSnapshot(objects: sortedObjects,
                                                            constellations: sortedConstellations,
                                                            catalogs: snapshot.catalogs,
                                                            dbPath: snapshot.dbPath,
                                                            usedFallback: snapshot.usedFallback)
                self.onDataChanged?()
            }
        }
    }

    private func applyObjectSettings(to objects: [SkyObject]? = nil) {
        let targetObjects: [SkyObject]
        if let providedObjects = objects {
            targetObjects = providedObjects
        } else if let snapshot = state.dataSnapshot {
            targetObjects = snapshot.objects + snapshot.constellations.map { $0 as SkyObject }
        } else {
            return
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
