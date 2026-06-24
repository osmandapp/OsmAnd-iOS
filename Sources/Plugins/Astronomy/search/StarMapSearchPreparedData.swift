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
        let objects = parent?.getSearchableObjects() ?? []
        let observer = parent?.getSearchObserver() ?? Observer(latitude: 0.0, longitude: 0.0, height: 0.0)
        let currentDate = parent?.getSearchCurrentDate() ?? Date()
        let computationContext = createComputationContext(observer: observer, date: currentDate)
        var widToDisplayName: [String: String] = [:]
        let primaryIconColor = StarMapControlTheme.resolved(.iconColorDefault, nightMode: nightMode)

        let entries = objects.map { obj in
            if !obj.wid.isEmpty {
                widToDisplayName[obj.wid] = obj.niceName()
            }
            return StarMapSearchEntry(objectRef: obj,
                                      displayName: obj.niceName(),
                                      magnitude: obj.magnitude,
                                      category: mapStarMapSearchCategory(obj),
                                      iconRes: AstroUtils.getObjectTypeIcon(obj.type),
                                      iconColor: obj.type.isSunSystem() ? obj.color : primaryIconColor,
                                      catalogWids: Set(obj.catalogs.map(\.wid)))
        }

        return StarMapSearchPreparedData(entries: entries,
                                         catalogEntries: buildCatalogEntries(preparedEntries: entries),
                                         widToDisplayName: widToDisplayName,
                                         computationContext: computationContext)
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
