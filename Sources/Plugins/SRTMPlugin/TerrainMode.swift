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

        var name: String {
            switch self {
            case .hillshade: "hillshade"
            case .slope: "slope"
            case .height: "height"
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
    }

    static let defaultKey = "default"
    static let altitudeDefaultKey = "altitude_default"
    static let hillshadePrefix: String = "hillshade_main_"
    static let hillshadeScndPrefix = "hillshade_color_"
    static let colorSlopePrefix = "slope_"
    static let heightPrefix = "height_"

    private static let queue = DispatchQueue(label: "TerrainModeValuesQueue")

    static var values: [TerrainMode] {
        guard let terrainModes else {
            Self.reloadTerrainModes()
            return terrainModes ?? []
        }
        return terrainModes
    }

    private static var terrainModes: [TerrainMode]?

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

        let settings = OAAppSettings.sharedManager()!
        minZoomPref = settings.registerIntPreference(key + "_min_zoom", defValue: Int32(terrainMinSupportedZoom)).makeProfile()
        maxZoomPref = settings.registerIntPreference(key + "_max_zoom", defValue: Int32(terrainMaxSupportedZoom)).makeProfile()
        transparencyPref = settings.registerIntPreference(key + "_transparency", defValue: Int32(type == .hillshade ? hillshadeDefaultTrasparency : defaultTrasparency)).makeProfile()
    }

    static func getMode(_ type: TerrainType, keyName: String) -> TerrainMode? {
        queue.sync {
            guard let terrainModes else {
                return nil
            }
            for mode in terrainModes where mode.type == type && mode.getKeyName() == keyName {
                return mode
            }
            return nil
        }
    }

    static func getDefaultMode(_ type: TerrainType) -> TerrainMode? {
        queue.sync {
            guard let terrainModes else {
                return nil
            }
            for mode in terrainModes where mode.type == type && mode.isDefaultMode() {
                return mode
            }
            return nil
        }
    }

    static func getByKey(_ key: String) -> TerrainMode? {
        queue.sync {
            return terrainModes?.first { $0.getKeyName() == key }
            ?? terrainModes?.first { $0.type == .hillshade }
        }
    }

    static func getKeyByPaletteName(_ name: String) -> String? {
        queue.sync {
            terrainModes?.first(where: { $0.getKeyName() == name })?.key
        }
    }

    static func isModeExist(_ key: String) -> Bool {
        queue.sync {
            terrainModes?.contains { $0.getKeyName() == key } ?? false
        }
    }

    static func reloadTerrainModes() {
        queue.sync {
            var modes = [TerrainMode]()
            modes.append(TerrainMode(defaultKey, type: .hillshade, translateName: localizedString("shared_string_hillshade")))
            modes.append(TerrainMode(defaultKey, type: .slope, translateName: localizedString("shared_string_slope")))
            
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
                            modes.append(terrainMode)
                        }
                    }
                }
            }
            terrainModes = modes
        }
    }

    private static func getTerrainMode(by file: String, prefix: Pair<String, TerrainType>) -> TerrainMode? {
        if file.hasPrefix(prefix.first) {
            let key = String(file.substring(from: prefix.first.length).dropLast(TXT_EXT.length))
            let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
            if key != defaultKey {
                return TerrainMode(key, type: prefix.second, translateName: name)
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

    func getMainFile() -> String {
        let prefix: String
        switch type {
        case .hillshade:
            prefix = Self.hillshadePrefix
        case .slope:
            prefix = Self.colorSlopePrefix
        case .height:
            prefix = Self.heightPrefix
        }
        return prefix + key + TXT_EXT
    }

    func getSecondFile() -> String {
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

    func getDescription() -> String {
        switch type {
        case .hillshade:
            return localizedString("shared_string_hillshade")
        case .slope:
            return localizedString("shared_string_slope")
        case .height:
            return localizedString("altitude")
        }
    }

    func isTransparencySetting(_ setting: OACommonInteger) -> Bool {
        setting == transparencyPref
    }

    func isZoomSetting(_ setting: OACommonInteger) -> Bool {
        setting == minZoomPref || setting == maxZoomPref
    }
}
