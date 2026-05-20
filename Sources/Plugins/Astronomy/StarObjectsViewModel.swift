//
//  StarObjectsViewModel.swift
//  OsmAnd Maps
//
//  Created by Codex on 19.05.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import CoreLocation
import Foundation
import OsmAndShared
import UIKit

final class StarObjectsViewModel {
    let state = StarChartState()
    private let provider: AstroDataProvider
    private(set) var settings: AstronomyPluginSettings

    var onDataChanged: (() -> Void)?

    var visibleObjects: [SkyObject] {
        guard let objects = state.dataSnapshot?.objects else {
            return []
        }
        return objects.filter { object in
            guard settings.isObjectTypeVisible(object.type) else {
                return false
            }
            if let maxMagnitude = settings.starMap.magnitudeFilter,
               object.magnitude > maxMagnitude {
                return false
            }
            return true
        }
    }

    var positionedObjects: [SkyObject] {
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
                self.updatePositions(date: self.state.date, location: self.state.location)
                self.onDataChanged?()
            }
        }
    }

    func updatePositions(date: Date, location: CLLocation?) {
        state.date = date
        state.location = location
        guard let objects = state.dataSnapshot?.objects else {
            return
        }

        let time = AstroUtils.astronomyTime(from: date)
        let observer = AstroUtils.observer(from: location)
        for object in objects {
            guard let horizontal = AstroUtils.horizontalPosition(for: object, time: time, observer: observer) else {
                continue
            }
            object.startAzimuth = object.azimuth
            object.startAltitude = object.altitude
            object.azimuth = AstroUtils.normalizedDegrees(horizontal.azimuth)
            object.altitude = horizontal.altitude
            object.targetAzimuth = object.azimuth
            object.targetAltitude = object.altitude
            object.lastUpdateTime = time.tt
        }
        applyObjectSettings(to: objects + constellations.map { $0 as SkyObject })
        onDataChanged?()
    }

    private func applyObjectSettings(to objects: [SkyObject]? = nil) {
        guard let objects = objects ?? state.dataSnapshot?.objects else {
            return
        }

        let favoritesMap = Dictionary(uniqueKeysWithValues: settings.starMap.favorites.map { ($0.id, $0) })
        let directionsMap = Dictionary(uniqueKeysWithValues: settings.starMap.directions.map { ($0.id, $0) })
        let celestialPathsMap = Dictionary(uniqueKeysWithValues: settings.starMap.celestialPaths.map { ($0.id, $0) })
        for object in objects {
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

    func selectNearestObject(to point: CGPoint, in view: StarView) {
        var nearest: SkyObject?
        var nearestDistance = CGFloat.greatestFiniteMagnitude
        for object in visibleObjects {
            guard let projected = view.project(object: object) else {
                continue
            }
            let distance = hypot(projected.x - point.x, projected.y - point.y)
            if distance < nearestDistance {
                nearestDistance = distance
                nearest = object
            }
        }
        state.selectedObject = nearestDistance < 34 ? nearest : nil
        onDataChanged?()
    }
}
