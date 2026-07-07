//
//  StarMapSearchPreparedData.swift
//  OsmAnd Maps
//
//  Created by Codex on 06.06.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import Foundation
import OsmAndShared
import UIKit

struct StarMapSearchComputationContext {
    let observer: Observer
    let now: Date
    let dusk: Date
    let dawn: Date
}

struct StarMapSearchPreparedData {
    let entries: [StarMapSearchEntry]
    let catalogEntries: [StarMapCatalogEntry]
    let widToDisplayName: [String: String]
    let starConstellationNameByObjectId: [String: String]
    let computationContext: StarMapSearchComputationContext
}

final class StarMapSearchPreparedDataFactory {
    private let dataProvider: AstroDataProvider
    private let nightMode: Bool

    init(dataProvider: AstroDataProvider, nightMode: Bool) {
        self.dataProvider = dataProvider
        self.nightMode = nightMode
    }

    func create(parent: StarMapViewController?) -> StarMapSearchPreparedData {
        let objects = parent?.searchableObjects() ?? []
        let constellations = parent?.searchConstellations() ?? []
        let observer = parent?.searchObserver() ?? Observer(latitude: 0.0, longitude: 0.0, height: 0.0)
        let currentDate = parent?.searchCurrentDate() ?? Date()
        let computationContext = createComputationContext(observer: observer, date: currentDate)
        var widToDisplayName: [String: String] = [:]
        let starConstellationNameByObjectId = buildStarConstellationNameMap(
            objects: objects,
            constellations: constellations
        )
        let primaryIconColor = StarMapControlTheme.resolved(.iconColorDefault, nightMode: nightMode)

        var entries: [StarMapSearchEntry] = []
        for obj in objects {
            let displayName = obj.niceName()
            if !obj.wid.isEmpty {
                widToDisplayName[obj.wid] = displayName
            }
            entries.append(StarMapSearchEntry(objectRef: obj,
                                              displayName: displayName,
                                              magnitude: obj.magnitude,
                                              category: mapStarMapSearchCategory(obj),
                                              iconRes: AstroUtils.getObjectTypeIcon(obj.type),
                                              iconColor: obj.type.isSunSystem() ? obj.color : primaryIconColor,
                                              catalogWids: Set(obj.catalogs.map(\.wid))))
        }

        return StarMapSearchPreparedData(entries: entries,
                                         catalogEntries: buildCatalogEntries(preparedEntries: entries),
                                         widToDisplayName: widToDisplayName,
                                         starConstellationNameByObjectId: starConstellationNameByObjectId,
                                         computationContext: computationContext)
    }

    private func buildStarConstellationNameMap(objects: [SkyObject],
                                               constellations: [Constellation]) -> [String: String] {
        var hipToConstellationName: [Int: String] = [:]
        for constellation in constellations {
            let name = constellation.niceName()
            for (first, second) in constellation.lines {
                hipToConstellationName[first] = name
                hipToConstellationName[second] = name
            }
        }
        var result: [String: String] = [:]
        for object in objects where object.type == .STAR && object.hip > 0 {
            if let name = hipToConstellationName[object.hip] {
                result[object.id] = name
            }
        }
        return result
    }

    private func createComputationContext(observer: Observer, date: Date) -> StarMapSearchComputationContext {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart.addingTimeInterval(24 * 60 * 60)
        let twilight = AstroUtils.computeTwilight(startLocal: dayStart,
                                                  endLocal: dayEnd,
                                                  observer: observer,
                                                  timeZone: TimeZone.current)
        let dusk = twilight.civilDusk ?? calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayStart) ?? dayStart.addingTimeInterval(18 * 60 * 60)
        let dawnRaw = twilight.civilDawn
        let dawn: Date
        if let dawnRaw {
            dawn = dawnRaw > dusk ? dawnRaw : calendar.date(byAdding: .day, value: 1, to: dawnRaw) ?? dawnRaw.addingTimeInterval(24 * 60 * 60)
        } else {
            dawn = calendar.date(byAdding: .hour, value: 12, to: dusk) ?? dusk.addingTimeInterval(12 * 60 * 60)
        }
        return StarMapSearchComputationContext(observer: observer, now: date, dusk: dusk, dawn: dawn)
    }

    private func buildCatalogEntries(preparedEntries: [StarMapSearchEntry]) -> [StarMapCatalogEntry] {
        var objectCountByCatalogWid: [String: Int] = [:]
        for entry in preparedEntries {
            for catalogWid in entry.catalogWids {
                objectCountByCatalogWid[catalogWid, default: 0] += 1
            }
        }
        return dataProvider.getCatalogs().map { catalog in
            StarMapCatalogEntry(catalog: catalog,
                                displayName: catalog.name,
                                description: dataProvider.getAstroArticle(wikidataId: catalog.wid)?.description,
                                objectCount: objectCountByCatalogWid[catalog.wid] ?? 0)
        }
    }
}
