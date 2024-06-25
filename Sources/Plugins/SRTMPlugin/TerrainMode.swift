//
//  TerrainMode.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc
@objcMembers
final class TerrainMode: NSObject {

    enum TerrainType: String {
        case hillshade
        case slope
        case height
    }

    static let defaultKey = "default"
    static let altitudeDefaultKey = "altitude_default"
    static let hillshadePrefix: String = "hillshade_main_"
    static let hillshadeScndPrefix = "hillshade_color_"
    static let colorSlopePrefix = "slope_"
    static let heightPrefix = "height_"

    let type: TerrainType

    private let minZoom: OACommonInteger
    private let maxZoom: OACommonInteger
    private let transparency: OACommonInteger
    private let key: String

    static var values: [TerrainMode] {
        if let terrainModes {
            return terrainModes
        }
        Self.reloadTerrainModes()
        return terrainModes ?? []
    }

    private static var terrainModes: [TerrainMode]?

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

    static func reloadTerrainModes() {
        var modes = [TerrainMode]()
        modes.append(TerrainMode(defaultKey, type: .hillshade, translateName: localizedString("shared_string_hillshade")))
        modes.append(TerrainMode(defaultKey, type: .slope, translateName: localizedString("shared_string_slope")))
        
        if let dir = OsmAndApp.swiftInstance().colorsPalettePath,
           let files = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            for file in files {
                guard file.hasSuffix(TXT_EXT) else { continue }

                let nm = file
                if nm.hasPrefix(hillshadePrefix) {
                    let key = String(nm.substring(from: hillshadePrefix.length).dropLast(TXT_EXT.length))
                    let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
                    if key != defaultKey {
                        modes.append(TerrainMode(key, type: .hillshade, translateName: name))
                    }
                } else if nm.hasPrefix(colorSlopePrefix) {
                    let key = String(nm.substring(from: colorSlopePrefix.length).dropLast(TXT_EXT.length))
                    let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
                    if key != defaultKey {
                        modes.append(TerrainMode(key, type: .slope, translateName: name))
                    }
                } else if nm.hasPrefix(heightPrefix) {
                    let key = String(nm.substring(from: heightPrefix.count).dropLast(TXT_EXT.count))
                    let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
                    if key != defaultKey {
                        modes.append(TerrainMode(key, type: .height, translateName: name))
                    }
                }
            }
        }
        terrainModes = modes
    }

    static func getMode(_ type: TerrainType, keyName: String) -> TerrainMode? {
        if let terrainModes {
            for mode in terrainModes {
                if mode.type == type && mode.getKeyName() == keyName {
                    return mode
                }
            }
        }
        return nil
    }

    static func getDefaultMode(_ type: TerrainType) -> TerrainMode? {
        if let terrainModes {
            for mode in terrainModes {
                if mode.type == type && mode.isDefaultMode() {
                    return mode
                }
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
            return type.rawValue
        }
        return key
    }

    func isDefaultMode() -> Bool {
        type == .height ? key == Self.altitudeDefaultKey : key == Self.defaultKey
    }

    func getCacheFileName() -> String {
        type.rawValue + ".cache"
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
        if type == .hillshade {
            return localizedString("shared_string_hillshade")
        } else if type == .slope {
            return localizedString("shared_string_slope")
        } else {
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
