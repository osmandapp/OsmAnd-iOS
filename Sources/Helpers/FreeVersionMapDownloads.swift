//
//  FreeVersionMapDownloads.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class FreeRegionCheck: NSObject {
    let freeRegion: OAWorldRegion?
    let freeItems: [OAResourceSwiftItem]
    let otherRegions: [OAWorldRegion]
    
    var isAllFree: Bool {
        otherRegions.isEmpty
    }
    
    init(freeRegion: OAWorldRegion?, freeItems: [OAResourceSwiftItem], otherRegions: [OAWorldRegion]) {
        self.freeRegion = freeRegion
        self.freeItems = freeItems
        self.otherRegions = otherRegions
    }
}

@objcMembers
final class FreeVersionMapDownloads: NSObject {
    static let shared = FreeVersionMapDownloads()
    
    private static let preferencesName = "net.osmand.free_region"
    private static let regionKey = "region"
    private static let replacesKey = "replaces"
    private static let federations: Set<String> = ["northamerica_us", "northamerica_canada", "russia", "southamerica_brazil", "asia_india", "asia_china", "australia-oceania-all_australia-oceania"]
    
    var isFreeVersion: Bool {
        !OAIAPHelper.isPaidVersion()
    }
    
    var replacesCount: Int {
        preference(Self.replacesKey) as? Int ?? 0
    }
    
    var freeRegion: OAWorldRegion? {
        lock.lock()
        defer { lock.unlock() }
        guard let regionId = preference(Self.regionKey) as? String, !regionId.isEmpty else { return nil }
        return OsmAndApp.swiftInstance().worldRegion?.getFlattenedSubregion(regionId)
    }
    
    private let lock = NSRecursiveLock()
    private var preferences: [String: Any]?
    private var isRegionsLoaded: Bool {
        OsmAndApp.swiftInstance().worldRegion != nil
    }
    
    private var preferencesURL: URL {
        URL(fileURLWithPath: OsmAndApp.swiftInstance().dataPath).appendingPathComponent(Self.preferencesName + ".plist")
    }
    
    private override init() {}
    
    func chooseFreeRegion(_ item: OAResourceSwiftItem) {
        lock.lock()
        defer { lock.unlock() }
        if isFreeVersion, let region = getItemRegion(item) {
            storeFreeRegion(region)
        }
    }
    
    func replaceFreeRegion(_ region: OAWorldRegion) {
        lock.lock()
        defer { lock.unlock() }
        guard let regionId = region.regionId else { return }
        edit { values in
            values[Self.regionKey] = regionId
            values[Self.replacesKey] = (values[Self.replacesKey] as? Int ?? 0) + 1
        }
    }
    
    func check(_ items: [OAResourceSwiftItem]) -> FreeRegionCheck {
        guard isFreeVersion, isRegionsLoaded else { return FreeRegionCheck(freeRegion: nil, freeItems: items, otherRegions: []) }
        var freeRegion = self.freeRegion
        var freeItems: [OAResourceSwiftItem] = []
        var otherRegions: [OAWorldRegion] = []
        for item in items {
            let region = getItemRegion(item)
            if freeRegion == nil {
                freeRegion = region
            }
            if region == nil || region == freeRegion || item.isInstalled() {
                freeItems.append(item)
            } else if let region, !otherRegions.contains(region) {
                otherRegions.append(region)
            }
        }
        
        return FreeRegionCheck(freeRegion: freeRegion, freeItems: freeItems, otherRegions: otherRegions)
    }
    
    func canDownload(_ item: OAResourceSwiftItem) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard isFreeVersion, isRegionsLoaded else { return true }
        guard let region = getItemRegion(item), !item.isInstalled() else { return true }
        guard let freeRegion else {
            storeFreeRegion(region)
            return true
        }
        
        return region == freeRegion
    }
    
    func collectMapsToDelete(_ newRegion: OAWorldRegion) -> [(region: OAWorldRegion, items: [OAResourceSwiftItem])] {
        collectLocalMaps().filter { $0.key.regionId != newRegion.regionId }.sorted { $0.key.compare($1.key) == .orderedAscending }.map { (region: $0.key, items: $0.value) }
    }
    
    private func getItemRegion(_ item: OAResourceSwiftItem) -> OAWorldRegion? {
        isCountedInDownloads(item) ? getRegionByDownloadName(getDownloadName(item.resourceId())) : nil
    }
    
    private func isCountedInDownloads(_ item: OAResourceSwiftItem) -> Bool {
        let type = item.resourceType()
        return (type == .mapRegion || type == .roadMapRegion) && !item.isFree()
    }
    
    private func getDownloadName(_ resourceId: String) -> String {
        String(resourceId.prefix { $0 != "." })
    }
    
    private func getRegionByDownloadName(_ downloadName: String) -> OAWorldRegion? {
        guard !downloadName.isEmpty, let region = OsmAndApp.swiftInstance().worldRegion?.getDataByDownloadName(downloadName), !region.isInPurchasedArea() else { return nil }
        return getFreeRegionOf(region)
    }
    
    private func getFreeRegionOf(_ region: OAWorldRegion) -> OAWorldRegion? {
        let country = getCountryRegion(region)
        if let country, Self.federations.contains(country.regionId), country != region {
            var state = region
            while let superregion = state.superregion, superregion != country {
                state = superregion
            }
            return state
        }
        
        return country
    }
    
    private func getCountryRegion(_ region: OAWorldRegion) -> OAWorldRegion? {
        if region.isContinent() { return nil }
        var current = region
        while let parent = current.superregion {
            if parent.isContinent() || parent.regionId == nil {
                return current
            }
            current = parent
        }
        
        return nil
    }
    
    private func collectLocalMaps() -> [OAWorldRegion: [OAResourceSwiftItem]] {
        var result: [OAWorldRegion: [OAResourceSwiftItem]] = [:]
        let items = OAResourcesUISwiftHelper.getInstalledMapResources().sorted { $0.resourceId() < $1.resourceId() }
        for item in items {
            if let region = getRegionByDownloadName(getDownloadName(item.resourceId())) {
                result[region, default: []].append(item)
            }
        }
        
        return result
    }
    
    private func storeFreeRegion(_ region: OAWorldRegion) {
        guard let regionId = region.regionId else { return }
        edit { $0[Self.regionKey] = regionId }
    }
    
    private func loadPreferences() -> [String: Any]? {
        if let preferences { return preferences }
        let url = preferencesURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            preferences = [:]
            return preferences
        }
        do {
            let data = try Data(contentsOf: url)
            guard let values = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
                NSLog("Failed to read the free region: invalid preferences format")
                return nil
            }
            preferences = values
            return preferences
        } catch {
            NSLog("Failed to read the free region: %@", error.localizedDescription)
            return nil
        }
    }
    
    private func preference(_ key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        return loadPreferences()?[key]
    }
    
    private func edit(_ change: (inout [String: Any]) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard var values = loadPreferences() else { return }
        change(&values)
        preferences = values
        var url = preferencesURL
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try url.setResourceValues(resourceValues)
        } catch {
            NSLog("Failed to save the free region: %@", error.localizedDescription)
        }
    }
}
