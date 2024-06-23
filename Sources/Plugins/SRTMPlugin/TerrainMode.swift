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

    static let hillshadePrefix: String = "hillshade_main_"
    static let hillshadeScndPrefix = "hillshade_color_"
    static let colorSlopePrefix = "slope_"
    static let heightPrefix = "height_"

    private static let defaultKey = "default"
    private static var terrainModes: [TerrainMode]?

    enum TerrainType: String {
        case hillshade
        case slope
        case height
    }

    let type: TerrainType
    var translateName: String

    private let minZoom: OACommonInteger
    private let maxZoom: OACommonInteger
    private let transparency: OACommonInteger
    private let key: String

    init(_ key: String, translateName: String, type: TerrainType) {
        self.type = type
        self.key = key
        self.translateName = translateName
        let settings = OAAppSettings.sharedManager()!
        minZoom = settings.registerIntPreference(key + "_min_zoom", defValue: 3).makeProfile()
        maxZoom = settings.registerIntPreference(key + "_max_zoom", defValue: 17).makeProfile()
        transparency = settings.registerIntPreference(key + "_transparency", defValue: type == .hillshade ? 100 : 80).makeProfile()
    }

    static var values: [TerrainMode] {
        if let terrainModes {
            return terrainModes
        }

        let hillshade = TerrainMode(defaultKey,
                                    translateName: localizedString("shared_string_hillshade"),
                                    type: .hillshade)
        let slope = TerrainMode(defaultKey,
                                translateName: localizedString("shared_string_slope"),
                                type: .slope)

        var tms: [TerrainMode] = [hillshade, slope]
        let dir = "\(NSHomeDirectory())/Documents/Resources/\(CLR_PALETTE_DIR)"
        if let files = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            for file in files {
                guard file.hasSuffix(TXT_EXT) else { continue }

                let nm = file
                if nm.hasPrefix(hillshadePrefix) {
                    let key = String(nm.substring(from: hillshadePrefix.length).dropLast(TXT_EXT.length))
                    let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
                    if key != defaultKey {
                        tms.append(TerrainMode(key, translateName: name, type: .hillshade))
                    }
                } else if nm.hasPrefix(colorSlopePrefix) {
                    let key = String(nm.substring(from: colorSlopePrefix.length).dropLast(TXT_EXT.length))
                    let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
                    if key != defaultKey {
                        tms.append(TerrainMode(key, translateName: name, type: .slope))
                    }
                } else if nm.hasPrefix(heightPrefix) {
                    let key = String(nm.substring(from: heightPrefix.count).dropLast(TXT_EXT.count))
                    let name = OAUtilities.capitalizeFirstLetter(key).replacingOccurrences(of: "_", with: " ")
                    if key != defaultKey {
                        tms.append(TerrainMode(key, translateName: name, type: .height))
                    }
                }
            }
        }
        terrainModes = tms
        return tms
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
        if key == Self.defaultKey {
            return type.rawValue.lowercased()
        }
        return key
    }

    func getCacheFileName() -> String {
        type.rawValue.lowercased() + ".cache"
    }

    func setZoomValues(minZoom: Int32, maxZoom: Int32) {
        self.minZoom.set(minZoom)
        self.maxZoom.set(maxZoom)
    }

    func setTransparency(_ transparency: Int32) {
        self.transparency.set(transparency)
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

    func getDescription() -> String {
        translateName
    }

    func isTransparencySetting(_ setting: OACommonInteger) -> Bool {
        setting == transparency
    }

    func isZoomSetting(_ setting: OACommonInteger) -> Bool {
        setting == minZoom || setting == maxZoom
    }
}
