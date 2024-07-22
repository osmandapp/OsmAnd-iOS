//
//  ColorPaletteHelper.swift
//  OsmAnd Maps
//
//  Created by Skalii on 02.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ColorPaletteHelper: NSObject {

    static let shared = ColorPaletteHelper()
    static let gradientIdSplitter = "_"

    private var app: OsmAndAppProtocol
    private var cachedColorPalette = [String: ColorPalette]()

    private override init() {
        app = OsmAndApp.swiftInstance()
    }

    func getPalletsForType(_ gradientType: Any) -> [String: [Any]] {
        var colorPalettes = [String: [Any]]()
        if let gradientType = gradientType as? ColorizationType {
            colorPalettes = getColorizationTypePallets(gradientType)
        } else if let gradientType = gradientType as? TerrainType {
            colorPalettes = getTerrainModePallets(gradientType)
        }
        return colorPalettes
    }

    func requireGradientColorPaletteSync(_ colorizationType: ColorizationType, gradientPaletteName: String) -> ColorPalette {
        guard let colorPalette = getGradientColorPaletteSync(colorizationType, gradientPaletteName: gradientPaletteName), isValidPalette(colorPalette) else {
            return OARouteColorize.getDefaultPalette(colorizationType.rawValue)
        }
        return colorPalette
    }

    func getGradientColorPaletteSync(_ colorizationType: ColorizationType, gradientPaletteName: String) -> ColorPalette? {
        getGradientColorPaletteSync(colorizationType, gradientPaletteName: gradientPaletteName, refresh: false)
    }

    func getGradientColorPaletteSync(_ colorizationType: ColorizationType, gradientPaletteName: String, refresh: Bool) -> ColorPalette? {
        getGradientColorPalette("route_\(colorizationType.name)_\(gradientPaletteName)\(TXT_EXT)", refresh: refresh)
    }

    func getGradientColorPaletteSyncWithModeKey(_ modeKey: String) -> ColorPalette? {
        getGradientColorPalette(modeKey)
    }

    func getGradientColorPalette(_ colorPaletteFileName: String) -> ColorPalette? {
        getGradientColorPalette(colorPaletteFileName, refresh: false)
    }

    func getGradientColorPalette(_ colorPaletteFileName: String, refresh: Bool) -> ColorPalette? {
        if let cachedPalette = cachedColorPalette[colorPaletteFileName], !refresh {
            return cachedPalette
        }
        let filePath = getColorPaletteDir().appendingPathComponent(colorPaletteFileName)
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                let colorPalette = try ColorPalette.parseColorPalette(from: filePath)
                cachedColorPalette[colorPaletteFileName] = colorPalette
                return colorPalette
            } catch {
                debugPrint("Error reading color file: \(error)")
            }
        }
        return nil
    }

    private func getColorizationTypePallets(_ type: ColorizationType) -> [String: [Any]] {
        var colorPalettes: [String: [Any]] = [:]
        let colorTypePrefix = "route_\(type.name)_"
        do {
            let colorFiles = try FileManager.default.contentsOfDirectory(atPath: getColorPaletteDir())
            for fileName in colorFiles where fileName.hasPrefix(colorTypePrefix) && fileName.hasSuffix(TXT_EXT) {
                let colorPalleteName = fileName.replacingOccurrences(of: colorTypePrefix, with: "").replacingOccurrences(of: TXT_EXT, with: "")
                if let colorPalette = getGradientColorPalette(fileName) {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: getColorPaletteDir().appendingPathComponent(fileName))
                    let modificationDate = fileAttributes[.modificationDate] as! Date
                    colorPalettes[colorPalleteName] = [colorPalette, Int64(modificationDate.timeIntervalSince1970)]
                }
            }
        } catch {
            debugPrint("Error reading color palette directory: \(error)")
        }
        return colorPalettes
    }

    private func getTerrainModePallets(_ type: TerrainType) -> [String: [Any]] {
        var colorPalettes: [String: [Any]] = [:]
        for mode in TerrainMode.values where mode.type == type {
            let fileName = mode.getMainFile()
            let filePath = getColorPaletteDir().appendingPathComponent(fileName)
            if let colorPalette = getGradientColorPalette(fileName), FileManager.default.fileExists(atPath: filePath) {
                let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath)
                let modificationDate = fileAttributes?[.modificationDate] as? Date
                colorPalettes[mode.getKeyName()] = [colorPalette, Int64(modificationDate?.timeIntervalSince1970 ?? 0)]
            }
        }
        return colorPalettes
    }

    private func isValidPalette(_ palette: ColorPalette?) -> Bool {
        guard let palette else {
            return false
        }
        return palette.colorValues.count >= 2
    }

    private func getColorPaletteDir() -> String {
        app.colorsPalettePath
    }
}
