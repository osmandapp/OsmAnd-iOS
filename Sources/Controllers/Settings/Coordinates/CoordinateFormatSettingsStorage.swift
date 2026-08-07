//
//  CoordinateFormatSettingsStorage.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 07.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class CoordinateFormatSettingsStorage: NSObject {

    static let legacyFormatId = "coordinates_format"
    static let preferredFormatIdsId = "preferred_coordinate_format_ids"
    static let recentFormatIdsId = "recently_added_coordinate_format_ids"
    static let maxRecentFormatIds = 5

    private let settings: OAAppSettings
    private let preferredPreference: OACommonStringList
    private let recentPreference: OACommonStringList

    init(settings: OAAppSettings,
         preferredPreference: OACommonStringList,
         recentPreference: OACommonStringList) {
        self.settings = settings
        self.preferredPreference = preferredPreference
        self.recentPreference = recentPreference
        super.init()
    }

    // MARK: - Preferred

    func getPreferredIds() -> [String] {
        getPreferredIds(settings.currentMode)
    }

    func getPreferredIds(_ mode: OAApplicationMode) -> [String] {
        sanitizePreferredIds(preferredPreference.get(mode))
    }

    @discardableResult
    func setPreferredIds(_ mode: OAApplicationMode, ids: [String]) -> Bool {
        let sanitized = sanitizePreferredIds(ids)
        preferredPreference.set(sanitized, mode: mode)
        syncLegacyFormat(mode, primaryId: sanitized.first)
        return true
    }

    func getPrimaryId(_ mode: OAApplicationMode) -> String {
        getPreferredIds(mode).first ?? CoordinateFormatIds.builtinDdd
    }

    @discardableResult
    func resetPreferredIds(_ mode: OAApplicationMode) -> Bool {
        setPreferredIds(mode, ids: CoordinateFormatIds.defaultFormatIds)
    }

    @discardableResult
    func copyPreferredIds(from fromMode: OAApplicationMode, to toMode: OAApplicationMode) -> Bool {
        setPreferredIds(toMode, ids: getPreferredIds(fromMode))
    }

    @discardableResult
    func addPreferredId(_ mode: OAApplicationMode, id: String) -> Bool {
        guard let normalized = CoordinateFormatIds.normalize(id) else { return false }
        var ids = getPreferredIds(mode)
        guard !ids.contains(normalized) else { return false }
        ids.append(normalized)
        return setPreferredIds(mode, ids: ids)
    }

    func isPreferredIdsSet(for mode: OAApplicationMode) -> Bool {
        preferredPreference.isSet(for: mode)
    }

    // MARK: - Recent

    func getRecentIds() -> [String] {
        sanitizeIds(recentPreference.get(),
                    fallbackIds: [],
                    maxCount: Self.maxRecentFormatIds)
    }

    @discardableResult
    func addRecentId(_ id: String) -> Bool {
        guard let normalized = CoordinateFormatIds.normalize(id) else { return false }
        var ids = getRecentIds()
        ids.removeAll { $0 == normalized }
        ids.insert(normalized, at: 0)
        if ids.count > Self.maxRecentFormatIds {
            ids = Array(ids.prefix(Self.maxRecentFormatIds))
        }
        recentPreference.set(ids)
        return true
    }

    // MARK: - Migration

    func migrateIfNeeded() {
        for mode in OAApplicationMode.allPossibleValues() {
            if !isPreferredIdsSet(for: mode) {
                let legacy = Int(settings.settingGeoFormat.get(mode))
                setPreferredIds(mode, ids: Self.legacyPreferredIds(legacyFormat: legacy))
            }
        }
    }

    static func legacyPreferredIds(legacyFormat: Int) -> [String] {
        var ids = [String]()
        var seen = Set<String>()
        if let primary = CoordinateFormatIds.fromOldFormat(legacyFormat) {
            ids.append(primary)
            seen.insert(primary)
        }
        for id in CoordinateFormatIds.allBuiltInFormatIds where !seen.contains(id) {
            ids.append(id)
            seen.insert(id)
        }
        return ids
    }

    // MARK: - Private

    private func sanitizePreferredIds(_ ids: [String]?) -> [String] {
        sanitizeIds(ids, fallbackIds: CoordinateFormatIds.defaultFormatIds)
    }

    private func sanitizeIds(_ ids: [String]?, fallbackIds: [String], maxCount: Int = .max) -> [String] {
        var sanitized = [String]()
        var seen = Set<String>()
        for id in ids ?? [] {
            guard let normalized = CoordinateFormatIds.normalize(id),
                  !seen.contains(normalized),
                  sanitized.count < maxCount else { continue }
            sanitized.append(normalized)
            seen.insert(normalized)
        }
        if sanitized.isEmpty {
            return fallbackIds
        }
        return sanitized
    }

    private func syncLegacyFormat(_ mode: OAApplicationMode, primaryId: String?) {
        guard let builtin = BuiltInCoordinateFormat.fromId(primaryId) else { return }
        settings.settingGeoFormat.set(Int32(builtin.legacyFormat), mode: mode)
    }
}
