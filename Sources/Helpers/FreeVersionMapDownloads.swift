//
//  FreeVersionMapDownloads.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

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
    
    func replaceFreeRegion(_ region: OAWorldRegion) {
        lock.lock()
        defer { lock.unlock() }
        guard let regionId = region.regionId else { return }
        edit { values in
            values[Self.regionKey] = regionId
            values[Self.replacesKey] = (values[Self.replacesKey] as? Int ?? 0) + 1
        }
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
