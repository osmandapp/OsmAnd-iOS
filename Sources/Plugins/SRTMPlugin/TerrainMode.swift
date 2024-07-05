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

    @objc enum TerrainType: Int32 {
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
    }

    @objcMembers
    final class TerrainTypeWrapper: NSObject {

        static func getNameFor(type: TerrainType) -> String {
            type.name
        }
    }

    static let defaultKey = "default"
    static let altitudeDefaultKey = "altitude_default"
    static let hillshadePrefix: String = "hillshade_main_"
    static let hillshadeScndPrefix = "hillshade_color_"
    static let colorSlopePrefix = "slope_"
    static let heightPrefix = "height_"

    static var values: [TerrainMode] {
        guard let terrainModes else {
            Self.reloadTerrainModes()
            return terrainModes ?? []
        }
        return terrainModes
    }

    private static var terrainModes: [TerrainMode]?

    let type: TerrainType

    private let minZoom: OACommonInteger
    private let maxZoom: OACommonInteger
    private let transparency: OACommonInteger
    private let key: String

    var translateName: String

    init(_ key: String, type: TerrainType, translateName: String) {
        self.key = key
        self.type = type
        self.translateName = translateName

        let settings = OAAppSettings.sharedManager()!
        minZoom = settings.registerIntPreference(key + "_min_zoom", defValue: 3).makeProfile()
        maxZoom = settings.registerIntPreference(key + "_max_zoom", defValue: 17).makeProfile()
        transparency = settings.registerIntPreference(key + "_transparency", defValue: type == .hillshade ? 100 : 80).makeProfile()
    }

    static func getMode(_ type: TerrainType, keyName: String) -> TerrainMode? {
        if let terrainModes {
            for mode in terrainModes where mode.type == type && mode.getKeyName() == keyName {
                return mode
            }
        }
        return nil
    }

    static func getDefaultMode(_ type: TerrainType) -> TerrainMode? {
        if let terrainModes {
            for mode in terrainModes where mode.type == type && mode.isDefaultMode() {
                return mode
            }
        }
        return nil
    }

    static func getByKey(_ key: String) -> TerrainMode? {
        return terrainModes?.first { $0.getKeyName() == key }
            ?? terrainModes?.first { $0.type == .hillshade }
    }

    static func isModeExist(_ key: String) -> Bool {
        terrainModes?.contains { $0.getKeyName() == key } ?? false
    }

    private static func reloadTerrainModes() {
        var modes = [TerrainMode]()
        modes.append(TerrainMode(defaultKey, type: .hillshade, translateName: localizedString("shared_string_hillshade")))
        modes.append(TerrainMode(defaultKey, type: .slope, translateName: localizedString("shared_string_slope")))

        let prefixes = [
            Pair(hillshadePrefix, TerrainType.hillshade.rawValue),
            Pair(colorSlopePrefix, TerrainType.slope.rawValue),
            Pair(heightPrefix, TerrainType.height.rawValue)
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

    private static func getTerrainMode(by file: String, prefix: Pair<String, Int32>) -> TerrainMode? {
        if file.hasPrefix(prefix.first) {
            let key = String(file.substring(from: prefix.first.length).dropLast(TXT_EXT.length))
            let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
            if key != defaultKey, let type = TerrainType(rawValue: prefix.second) {
                return TerrainMode(key, type: type, translateName: name)
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
        if type == .height {
            prefix = Self.heightPrefix
        } else if type == .slope {
            prefix = Self.colorSlopePrefix
        } else {
            prefix = Self.hillshadePrefix
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
        self.minZoom.set(minZoom)
        self.maxZoom.set(maxZoom)
    }

    func setZoomValues(minZoom: Int32, maxZoom: Int32, mode: OAApplicationMode) {
        self.minZoom.set(minZoom, mode: mode)
        self.maxZoom.set(maxZoom, mode: mode)
    }

    func setTransparency(_ transparency: Int32) {
        self.transparency.set(transparency)
    }

    func setTransparency(_ transparency: Int32, mode: OAApplicationMode) {
        self.transparency.set(transparency, mode: mode)
    }

    func getTransparency() -> Int32 {
        transparency.get()
    }

    func resetZoomsToDefault() {
        minZoom.resetToDefault()
        maxZoom.resetToDefault()
    }

    func resetTransparencyToDefault() {
        transparency.resetToDefault()
    }

    func getMinZoom() -> Int32 {
        minZoom.get()
    }

    func getMaxZoom() -> Int32 {
        maxZoom.get()
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
        setting == transparency
    }

    func isZoomSetting(_ setting: OACommonInteger) -> Bool {
        setting == minZoom || setting == maxZoom
    }
}
