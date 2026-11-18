//
//  FreeVersionMapDownloads.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 05.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

enum ReplaceAnswer: String {
    case ok
    case requestEmail = "request_email"
    case no
    
    static func parse(_ response: Data?) -> ReplaceAnswer? {
        guard let response else { return nil }
        guard let json = (try? JSONSerialization.jsonObject(with: response)) as? [String: Any] else {
            NSLog("Replace response: %@", String(data: response, encoding: .utf8) ?? "")
            return nil
        }
        
        return ReplaceAnswer(rawValue: (json["status"] as? String ?? "").lowercased()) ?? .no
    }
}

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
    private static let pendingRegionsKey = "pendingRegions"
    private static let replacementPathsKey = "replacementPaths"
    private static let migratedKey = "migrated"
    private static let federations: Set<String> = ["northamerica_us", "northamerica_canada", "russia", "southamerica_brazil", "asia_india", "asia_china", "australia-oceania-all_australia-oceania"]
    private static let replaceURL = "https://osmand.net/api/replace-download-map"
    private static let registerEmailURL = "https://osmand.net/subscription/register_email"
    
    var isFreeVersion: Bool {
        !OAIAPHelper.isPaidVersion()
    }
    
    var replacesCount: Int {
        preference(Self.replacesKey) as? Int ?? 0
    }
    
    var freeRegion: OAWorldRegion? {
        lock.lock()
        defer { lock.unlock() }
        migrateIfNeeded()
        guard let regionId = preference(Self.regionKey) as? String, !regionId.isEmpty else { return nil }
        return OsmAndApp.swiftInstance().worldRegion?.getFlattenedSubregion(regionId)
    }
    
    private let lock = NSRecursiveLock()
    private var preferences: [String: Any]?
    private var canWritePreferences = true
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
        if isFreeVersion, let region = itemRegion(item) {
            storeFreeRegion(region)
        }
    }
    
    func replaceFreeRegion(_ region: OAWorldRegion, deletingMaps: ([OAResourceSwiftItem]) -> Void) -> Bool {
        guard let regionId = region.regionId, let maps = collectMapsToDelete(region) else { return false }
        let items = maps.flatMap(\.items)
        let paths = OAObfFileList.pathsByResourceId(for: items.map { $0.resourceId() })
        let documents = OsmAndApp.swiftInstance().documentsPath + "/"
        guard paths.count == items.count, paths.values.allSatisfy({ $0.hasPrefix(documents) }) else { return false }
        var tracked = [String: String]()
        let prepared = edit(requiresPersistence: true) { values in
            tracked = values[Self.replacementPathsKey] as? [String: String] ?? [:]
            for (id, path) in paths {
                tracked[id] = String(path.dropFirst(documents.count))
            }
            values[Self.replacementPathsKey] = tracked
            values[Self.pendingRegionsKey] = [values[Self.regionKey] as? String ?? "", regionId]
        }

        guard prepared else { return false }
        deletingMaps(items)
        let remaining = tracked.filter { id, path in
            guard access(documents + path, F_OK) == 0 || errno != ENOENT else { return false }
            let mapRegion = OsmAndApp.swiftInstance().worldRegion?.getDataByDownloadName(downloadName(id))
            return mapRegion?.isInPurchasedArea() != true && !OAResourcesUISwiftHelper.isFreeRepositoryResource(id)
        }

        guard remaining.keys.allSatisfy({ regionByDownloadName(downloadName($0))?.regionId == regionId }) else { return false }
        return edit(requiresPersistence: true) { values in
            if values[Self.regionKey] as? String != regionId {
                values[Self.regionKey] = regionId
                values[Self.replacesKey] = (values[Self.replacesKey] as? Int ?? 0) + 1
            }
            values.removeValue(forKey: Self.pendingRegionsKey)
            values[Self.replacementPathsKey] = remaining.isEmpty ? nil : remaining
        }
    }
    
    func check(_ items: [OAResourceSwiftItem]) -> FreeRegionCheck {
        guard isFreeVersion, isRegionsLoaded else { return FreeRegionCheck(freeRegion: nil, freeItems: items, otherRegions: []) }
        var freeRegion = self.freeRegion
        var freeItems: [OAResourceSwiftItem] = []
        var otherRegions: [OAWorldRegion] = []
        for item in items {
            let region = itemRegion(item)
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
        guard let region = itemRegion(item), !item.isInstalled() else { return true }
        guard let freeRegion else {
            storeFreeRegion(region)
            return true
        }
        
        return region == freeRegion
    }
    
    func requestReplace(from: OAWorldRegion, to: OAWorldRegion, onAnswer: @escaping (ReplaceAnswer?) -> Void) {
        if let fromId = from.regionId, let toId = to.regionId,
           preference(Self.pendingRegionsKey) as? [String] == [fromId, toId] {
            DispatchQueue.main.async { onAnswer(.ok) }
            return
        }

        let app: OsmAndAppProtocol = OsmAndApp.swiftInstance()
        var params: [String: String] = ["os": "ios", "package": Bundle.main.bundleIdentifier ?? "", "version": OAAppVersion.getVersion(), "lang": app.getLanguageCode(), "nd": String(app.getAppInstalledDays()), "ns": String(app.getAppExecCount())]
        if let aid = app.getUserIosId(), !aid.isEmpty {
            params["aid"] = aid
        }

        let attribution = NSMutableDictionary()
        InstallAttribution.addParams(attribution)
        params.merge(attribution as? [String: String] ?? [:]) { $1 }
        params["from"] = from.regionId
        params["to"] = to.regionId
        params["replaces"] = String(replacesCount)
        params["email"] = String(OAAppSettings.sharedManager().emailSubscribed.get())
        sendRequest(Self.replaceURL, params: params, post: false) { onAnswer(ReplaceAnswer.parse($0)) }
    }
    
    func registerEmail(_ email: String, onRegistered: @escaping (Bool) -> Void) {
        var params = ["os": "ios", "email": email]
        if let aid = OsmAndApp.swiftInstance().getUserIosId(), !aid.isEmpty {
            params["aid"] = aid
        }

        sendRequest(Self.registerEmailURL, params: params, post: true) { result in
            let registered = self.isEmailRegistered(email, result)
            if registered {
                OAAppSettings.sharedManager().emailSubscribed.set(true)
            }
            onRegistered(registered)
        }
    }
    
    func collectMapsToDelete(_ newRegion: OAWorldRegion) -> [(region: OAWorldRegion, items: [OAResourceSwiftItem])]? {
        guard let items = OAResourcesUISwiftHelper.getInstalledMapResources() else { return nil }
        return collectLocalMaps(items).filter { $0.key.regionId != newRegion.regionId }.sorted { $0.key.compare($1.key) == .orderedAscending }.map { (region: $0.key, items: $0.value) }
    }

    func canInstallMap(_ resourceId: String) -> Bool {
        guard isFreeVersion, replacesCount > 0, let region = regionByDownloadName(downloadName(resourceId)), let freeRegion else { return true }
        return region == freeRegion
    }
    
    func cancelDownloads(otherThan newRegion: OAWorldRegion) {
        let tasks = OsmAndApp.swiftInstance().downloadsManager.downloadTasks(withKeyPrefix: "resource:") as? [OADownloadTask] ?? []
        for task in tasks {
            if let item = OAResourcesUISwiftHelper.getResourceFrom(task), let region = itemRegion(item), region.regionId != newRegion.regionId {
                task.cancel()
            }
        }
    }
    
    private func sendRequest(_ url: String, params: [String: String], post: Bool, onResult: @escaping (Data?) -> Void) {
        OANetworkUtilities.sendRequest(withUrl: url, params: params, post: post) { data, response, _ in
            let result = (response as? HTTPURLResponse)?.statusCode == 200 ? data : nil
            DispatchQueue.main.async {
                onResult(result)
            }
        }
    }
    
    private func isEmailRegistered(_ email: String, _ response: Data?) -> Bool {
        guard let response else { return false }
        guard let json = (try? JSONSerialization.jsonObject(with: response)) as? [String: Any] else {
            NSLog("Register email response: %@", String(data: response, encoding: .utf8) ?? "")
            return false
        }
        
        return email.caseInsensitiveCompare(json["email"] as? String ?? "") == .orderedSame
    }
    
    private func itemRegion(_ item: OAResourceSwiftItem) -> OAWorldRegion? {
        isCountedInDownloads(item) ? regionByDownloadName(downloadName(item.resourceId())) : nil
    }
    
    private func isCountedInDownloads(_ item: OAResourceSwiftItem) -> Bool {
        let type = item.resourceType()
        return (type == .mapRegion || type == .roadMapRegion) && !item.isFree()
    }
    
    private func downloadName(_ resourceId: String) -> String {
        String(resourceId.prefix { $0 != "." })
    }
    
    private func regionByDownloadName(_ downloadName: String) -> OAWorldRegion? {
        guard !downloadName.isEmpty, let region = OsmAndApp.swiftInstance().worldRegion?.getDataByDownloadName(downloadName), !region.isInPurchasedArea() else { return nil }
        return freeRegionOf(region)
    }
    
    private func freeRegionOf(_ region: OAWorldRegion) -> OAWorldRegion? {
        let country = countryRegion(region)
        if let country, Self.federations.contains(country.regionId), country != region {
            var state = region
            while let superregion = state.superregion, superregion != country {
                state = superregion
            }
            return state
        }
        
        return country
    }
    
    private func countryRegion(_ region: OAWorldRegion) -> OAWorldRegion? {
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
    
    private func collectLocalMaps(_ items: [OAResourceSwiftItem]) -> [OAWorldRegion: [OAResourceSwiftItem]] {
        var result: [OAWorldRegion: [OAResourceSwiftItem]] = [:]
        for item in items.sorted(by: { $0.resourceId() < $1.resourceId() }) {
            if let region = regionByDownloadName(downloadName(item.resourceId())) {
                result[region, default: []].append(item)
            }
        }
        
        return result
    }
    
    private func migrateIfNeeded() {
        guard preference(Self.migratedKey) as? Bool != true, isFreeVersion, isRegionsLoaded, let items = OAResourcesUISwiftHelper.getInstalledMapResources() else { return }
        edit { $0[Self.migratedKey] = true }
        guard (preference(Self.regionKey) as? String ?? "").isEmpty else { return }
        let mapSizes = collectLocalMaps(items).mapValues { items in items.reduce(0) { $0 + $1.size() } }
        if let region = locationRegion(Array(mapSizes.keys)) ?? mapSizes.max(by: { $0.value < $1.value })?.key {
            storeFreeRegion(region)
        }
    }
    
    private func locationRegion(_ candidates: [OAWorldRegion]) -> OAWorldRegion? {
        guard let location = OsmAndApp.swiftInstance().locationServices?.lastKnownLocation, !candidates.isEmpty else { return nil }
        let regions = OsmAndApp.swiftInstance().worldRegion?.getWorldRegions(at: location.coordinate.latitude, longitude: location.coordinate.longitude) ?? []
        return regions.lazy.compactMap { self.freeRegionOf($0) }.first { candidates.contains($0) }
    }
    
    private func storeFreeRegion(_ region: OAWorldRegion) {
        guard let regionId = region.regionId else { return }
        edit { $0[Self.regionKey] = regionId }
    }
    
    private func loadPreferences() -> [String: Any] {
        if let preferences { return preferences }
        var values: [String: Any] = [:]
        let url = preferencesURL
        if access(url.path, F_OK) == 0 || errno != ENOENT {
            do {
                let data = try Data(contentsOf: url)
                guard let loadedValues = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
                    throw CocoaError(.propertyListReadCorrupt)
                }
                values = loadedValues
            } catch {
                canWritePreferences = false
                NSLog("Failed to read the free region: %@", error.localizedDescription)
            }
        }
        
        preferences = values
        return values
    }
    
    private func preference(_ key: String) -> Any? {
        lock.lock()
        defer { lock.unlock() }
        return loadPreferences()[key]
    }
    
    @discardableResult private func edit(requiresPersistence: Bool = false, _ change: (inout [String: Any]) -> Void) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        var values = loadPreferences()
        change(&values)
        if !requiresPersistence {
            preferences = values
        }

        guard canWritePreferences else { return false }
        var url = preferencesURL
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: values, format: .xml, options: 0)
            try data.write(to: url, options: .atomic)
        } catch {
            NSLog("Failed to save the free region: %@", error.localizedDescription)
            return false
        }

        preferences = values
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        do {
            try url.setResourceValues(resourceValues)
        } catch {
            NSLog("Failed to exclude free region preferences from backup: %@", error.localizedDescription)
        }

        return true
    }
}
