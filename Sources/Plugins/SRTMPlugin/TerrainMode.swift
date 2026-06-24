//
//  TerrainMode.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class TerrainMode: NSObject {

    @objc enum TerrainType: Int32, Comparable, CaseIterable {
        case hillshade
        case slope
        case height
        case terrainShadows

        var name: String {
            switch self {
            case .hillshade: "hillshade"
            case .slope: "slope"
            case .height: "height"
            case .terrainShadows: "terrainShadows"
            }
        }
        
        func toPaletteCategory() -> GradientPaletteCategory? {
            switch self {
            case .hillshade:
                    .terrainHillshade
            case .slope:
                    .terrainSlope
            case .height:
                    .terrainAltitude
            case .terrainShadows:
                nil
            }
        }

        static func < (a: TerrainType, b: TerrainType) -> Bool {
            return a.rawValue < b.rawValue
        }
    }

    @objc 
    @objcMembers
    final class TerrainTypeWrapper: NSObject {

        static func getNameFor(type: TerrainType) -> String {
            type.name
        }
    
        static func valueOf(typeName: String) -> TerrainType {
            TerrainType.allCases.first { $0.name == typeName } ?? .hillshade
        }

        static func toPaletteCategory(type: TerrainType) -> GradientPaletteCategory? {
            type.toPaletteCategory()
        }
    }

    static let defaultKey = PaletteConstants.shared.DEFAULT_NAME
    static let altitudeDefaultKey = PaletteConstants.shared.ALTITUDE_DEFAULT_NAME
    static let hillshadePrefix: String = "hillshade_main_"
    static let hillshadeScndPrefix = "hillshade_color_"
    static let colorSlopePrefix = "slope_"
    static let heightPrefix = "height_"

    static var values: [TerrainMode] {
        guard let terrains = terrainModes?.asArray() as? [TerrainMode] else {
            Self.reloadTerrainModes()
            return terrainModes?.asArray() as? [TerrainMode] ?? []
        }
        return terrains
    }

    private static var terrainModes: ConcurrentArray<TerrainMode>?

    let type: TerrainType

    private let minZoomPref: OACommonInteger
    private let maxZoomPref: OACommonInteger
    private let transparencyPref: OACommonInteger
    private let key: String

    var translateName: String

    init(_ key: String, type: TerrainType, translateName: String) {
        self.key = key
        self.type = type
        self.translateName = translateName

        let settings = OAAppSettings.sharedManager()
        minZoomPref = settings.registerIntPreference(type.name + "_min_zoom", defValue: Int32(terrainMinSupportedZoom)).makeProfile()
        maxZoomPref = settings.registerIntPreference(type.name + "_max_zoom", defValue: Int32(terrainMaxSupportedZoom)).makeProfile()
        transparencyPref = settings.registerIntPreference(type.name + "_transparency", defValue: Int32(type == .hillshade || type == .terrainShadows ? hillshadeDefaultTrasparency : defaultTrasparency)).makeProfile()
    }

    static func getMode(_ type: TerrainType, keyName: String) -> TerrainMode? {
        guard let terrainModes else {
            return nil
        }

        var terrainMode: TerrainMode?
        terrainModes.forEach { mode in
            if mode.type == type && mode.isIdentifiedBy(keyName) {
                terrainMode = mode
                return
            }
        }

        return terrainMode
    }

    static func getDefaultMode(_ type: TerrainType) -> TerrainMode? {
        guard let terrainModes else {
            return nil
        }

        var terrainMode: TerrainMode?
        terrainModes.forEach { mode in
            if mode.type == type && mode.isDefaultMode() {
                terrainMode = mode
                return
            }
        }

        return terrainMode
    }

    static func byKey(_ key: String) -> TerrainMode? {
        return terrainModes?.first { $0.isIdentifiedBy(key) }
        ?? terrainModes?.first { $0.type == .hillshade }
    }

    static func getKeyByPaletteName(_ name: String) -> String? {
        terrainModes?.first(where: { $0.isIdentifiedBy(name) })?.key
    }

    static func isModeExist(_ key: String) -> Bool {
        terrainModes?.contains { $0.isIdentifiedBy(key) } ?? false
    }

    static func reloadTerrainModes() {
        if terrainModes == nil {
            terrainModes = ConcurrentArray()
        }
        guard let terrainModes else { return }

        var newTerrainModes = [
            TerrainMode(defaultKey, type: .hillshade, translateName: localizedString("shared_string_hillshade")),
            TerrainMode(defaultKey, type: .slope, translateName: localizedString("shared_string_slope")),
            TerrainMode(defaultKey, type: .terrainShadows, translateName: localizedString("terrain_shadows"))
        ]
        let prefixes = [
            Pair(hillshadePrefix, TerrainType.hillshade),
            Pair(colorSlopePrefix, TerrainType.slope),
            Pair(heightPrefix, TerrainType.height)
        ]
        if let dir = OsmAndApp.swiftInstance().colorsPalettePath,
           let files = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            for file in files where file.hasSuffix(TXT_EXT) {
                for prefix in prefixes {
                    if let terrainMode = getTerrainMode(by: file, prefix: prefix) {
                        newTerrainModes.append(terrainMode)
                    }
                }
            }
        }
        terrainModes.replaceAll(with: newTerrainModes)
    }

    private static func getTerrainMode(by file: String, prefix: Pair<String, TerrainType>) -> TerrainMode? {
        if file.hasPrefix(prefix.first) {
            let key = String(file.substring(from: prefix.first.length).dropLast(TXT_EXT.length))
            let name = OAUtilities.capitalizeFirstLetter(key)?.replacingOccurrences(of: "_", with: " ")
            if key != defaultKey {
                return TerrainMode(key, type: prefix.second, translateName: name ?? "")
            }
        }
        return nil
    }

    func isHillshade() -> Bool {
        type == .hillshade
    }

    func isSlope() -> Bool {
        type == .slope
    }
    
    func isTerrainShadows() -> Bool {
        type == .terrainShadows
    }
    
    func isHeight() -> Bool {
        type == .height
    }

    func mainFile() -> String {
        let prefix: String
        switch type {
        case .hillshade:
            prefix = Self.hillshadePrefix
        case .slope:
            prefix = Self.colorSlopePrefix
        case .height:
            prefix = Self.heightPrefix
        default:
            return ""
        }
        return prefix + key + TXT_EXT
    }

    func secondFile() -> String {
        (isHillshade() ? Self.hillshadeScndPrefix : "") + key + TXT_EXT
    }

    func getKeyName() -> String {
        if key == Self.defaultKey || key == Self.altitudeDefaultKey {
            return type.name
        }
        return key
    }

    func isDefaultMode() -> Bool {
        type == .height ? key == Self.altitudeDefaultKey : key == Self.defaultKey
    }

    func isDefaultDuplicatedMode() -> Bool {
        let defaultKey = type == .height ? Self.altitudeDefaultKey : Self.defaultKey
        return key.hasPrefix(defaultKey + " ") || key.hasPrefix(defaultKey + "_")
    }

    func getCacheFileName() -> String {
        type.name + ".cache"
    }

    func setZoomValues(minZoom: Int32, maxZoom: Int32) {
        self.minZoomPref.set(minZoom)
        self.maxZoomPref.set(maxZoom)
    }

    func setZoomValues(minZoom: Int32, maxZoom: Int32, mode: OAApplicationMode) {
        self.minZoomPref.set(minZoom, mode: mode)
        self.maxZoomPref.set(maxZoom, mode: mode)
        self.minZoomPref.getProfileDefaultValue(mode)
    }

    func setTransparency(_ transparency: Int32) {
        self.transparencyPref.set(transparency)
    }

    func setTransparency(_ transparency: Int32, mode: OAApplicationMode) {
        self.transparencyPref.set(transparency, mode: mode)
    }

    func getTransparency() -> Int32 {
        transparencyPref.get()
    }

    func resetZoomsToDefault() {
        minZoomPref.resetToDefault()
        maxZoomPref.resetToDefault()
    }

    func resetTransparencyToDefault() {
        transparencyPref.resetToDefault()
    }

    func getMinZoom() -> Int32 {
        minZoomPref.get()
    }

    func getMaxZoom() -> Int32 {
        maxZoomPref.get()
    }

    func getDefaultDescription() -> String {
        translateName
    }

    func isIdentifiedBy(_ searchKey: String) -> Bool {
        key == searchKey || getKeyName() == searchKey
    }

    func getDescription() -> String {
        switch type {
        case .hillshade:
            return localizedString("shared_string_hillshade")
        case .slope:
            return localizedString("shared_string_slope")
        case .height:
            return localizedString("altitude")
        case .terrainShadows:
            return localizedString("terrain_shadows")
        }
    }

    func isTransparencySetting(_ setting: OACommonInteger) -> Bool {
        setting == transparencyPref
    }
    
    func isTransparencySettingKey(_ key: String) -> Bool {
        key == transparencyPref.key
    }

    func isZoomSetting(_ setting: OACommonInteger) -> Bool {
        setting == minZoomPref || setting == maxZoomPref
    }
    
    func isZoomSettingKey(_ key: String) -> Bool {
        key == minZoomPref.key || key == maxZoomPref.key
    }
}
