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

    init(provider: AstroDataProvider, settings: AstronomyPluginSettings) {
        self.provider = provider
        self.settings = settings
    }

    var visibleObjects: [SkyObject] {
        guard let objects = state.dataSnapshot?.objects else {
            return []
        }
        return objects.filter { object in
            guard settings.isObjectTypeVisible(object.type) else {
                return false
            }
            if settings.starMap.showMagnitudeFilter,
               let maxMagnitude = settings.starMap.magnitudeFilter,
               let magnitude = object.magnitude,
               magnitude > maxMagnitude {
                return false
            }
            return object.altitude != nil && object.azimuth != nil
        }
    }

    var positionedObjects: [SkyObject] {
        state.dataSnapshot?.objects.filter { $0.altitude != nil && $0.azimuth != nil } ?? []
    }

    var constellations: [Constellation] {
        state.dataSnapshot?.constellations ?? []
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
                self.state.dataSnapshot = snapshot
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
            object.startAzimuth = object.azimuth ?? horizontal.azimuth
            object.startAltitude = object.altitude ?? horizontal.altitude
            object.azimuth = AstroUtils.normalizedDegrees(horizontal.azimuth)
            object.altitude = horizontal.altitude
            object.targetAzimuth = object.azimuth ?? 0
            object.targetAltitude = object.altitude ?? 0
            object.lastUpdateTime = time.tt
        }
        applyObjectSettings(to: objects)
        onDataChanged?()
    }

    private func applyObjectSettings(to objects: [SkyObject]? = nil) {
        guard let objects = objects ?? state.dataSnapshot?.objects else {
            return
        }

        let favoriteIds = Set(settings.starMap.favorites)
        let pathIds = Set(settings.starMap.celestialPaths)
        for object in objects {
            let ids = matchingIds(for: object)
            object.isFavorite = !favoriteIds.isDisjoint(with: ids)
            object.isCelestialPath = !pathIds.isDisjoint(with: ids)
            if let direction = settings.starMap.directions.first(where: { ids.contains($0.objectId) }) {
                object.isDirection = true
                object.colorIndex = direction.colorIndex
            } else {
                object.isDirection = false
                object.colorIndex = 0
            }
        }
    }

    private func matchingIds(for object: SkyObject) -> Set<String> {
        var ids: Set<String> = [object.id]
        if let wid = object.wid {
            ids.insert(wid)
        }
        if let hip = object.hip {
            ids.insert(String(hip))
        }
        if let name = object.name {
            ids.insert(name)
        }
        for catalog in object.catalogs {
            ids.insert(catalog.catalogId)
            ids.insert("\(catalog.catalogName)\(catalog.catalogId)")
            ids.insert("\(catalog.catalogName) \(catalog.catalogId)")
        }
        return ids
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
