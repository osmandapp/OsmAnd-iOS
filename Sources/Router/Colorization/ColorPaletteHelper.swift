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
    static let routePrefix = "route_"
    static let gradientIdSplitter = "_"

    private var app: OsmAndAppProtocol
    private var cachedColorPalette = ConcurrentDictionary<String, ColorPalette>()

    private override init() {
        app = OsmAndApp.swiftInstance()
    }

    static func getRoutePaletteFileName(_ colorizationType: ColorizationType, gradientPaletteName: String) -> String {
        "\(routePrefix)\(colorizationType.name)\(gradientIdSplitter)\(gradientPaletteName)\(TXT_EXT)"
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

    func requireGradientColorPaletteSync(_ colorizationType: ColorizationType, gradientPaletteName: String, error: NSErrorPointer) -> ColorPalette {
        guard let colorPalette = getGradientColorPaletteSync(colorizationType, gradientPaletteName: gradientPaletteName, error: error), isValidPalette(colorPalette) else {
            return OARouteColorize.getDefaultPalette(colorizationType.rawValue)
        }
        return colorPalette
    }

    func getGradientColorPaletteSync(_ colorizationType: ColorizationType, gradientPaletteName: String, error: NSErrorPointer) -> ColorPalette? {
        getGradientColorPalette(Self.getRoutePaletteFileName(colorizationType, gradientPaletteName: gradientPaletteName), error: error)
    }

    func getGradientColorPaletteSyncWithModeKey(_ modeKey: String, error: NSErrorPointer) -> ColorPalette? {
        getGradientColorPalette(modeKey, error: error)
    }

    func getGradientColorPalette(_ colorPaletteFileName: String, error: NSErrorPointer) -> ColorPalette? {
        if isColorPaletteUpdated(colorPaletteFileName, error: error) {
            return parseGradientColorPalette(colorPaletteFileName)
        }
        return cachedColorPalette.getValue(forKey: colorPaletteFileName)
    }

    func isColorPaletteUpdated(_ colorPaletteFileName: String, error: NSErrorPointer) -> Bool {
        guard let cachedPalette = cachedColorPalette.getValue(forKey: colorPaletteFileName) else {
            return true
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: getColorPaletteDir().appendingPathComponent(colorPaletteFileName))
            return attributes[.modificationDate] as? Date != cachedPalette.lastModified
        } catch let err as NSError {
            error?.pointee = err
            return false
        }
    }

    private func parseGradientColorPalette(_ colorPaletteFileName: String) -> ColorPalette? {
        let filePath = getColorPaletteDir().appendingPathComponent(colorPaletteFileName)
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                let colorPalette = try ColorPalette.parseColorPalette(from: filePath)
                cachedColorPalette.setValue(colorPalette, forKey: colorPaletteFileName)
                return colorPalette
            } catch {
                debugPrint("Error reading color file: \(error)")
            }
        }
        return nil
    }

    private func getColorizationTypePallets(_ type: ColorizationType) -> [String: [Any]] {
        var colorPalettes: [String: [Any]] = [:]
        let colorTypePrefix = "\(Self.routePrefix)\(type.name)\(Self.gradientIdSplitter)"
        do {
            let colorFiles = try FileManager.default.contentsOfDirectory(atPath: getColorPaletteDir())
            for fileName in colorFiles where fileName.hasPrefix(colorTypePrefix) && fileName.hasSuffix(TXT_EXT) {
                let colorPalleteName = fileName.replacingOccurrences(of: colorTypePrefix, with: "").replacingOccurrences(of: TXT_EXT, with: "")
                var error: NSError?
                if let colorPalette = getGradientColorPalette(fileName, error: &error) {
                    let fileAttributes = try FileManager.default.attributesOfItem(atPath: getColorPaletteDir().appendingPathComponent(fileName))
                    let modificationDate = fileAttributes[.modificationDate] as! Date
                    colorPalettes[colorPalleteName] = [colorPalette, Int64(modificationDate.timeIntervalSince1970)]
                } else if let error {
                    debugPrint("Error reading color palette file: \(error.description)")
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
            var error: NSError?
            if let colorPalette = getGradientColorPalette(fileName, error: &error), FileManager.default.fileExists(atPath: filePath) {
                let fileAttributes = try? FileManager.default.attributesOfItem(atPath: filePath)
                let modificationDate = fileAttributes?[.modificationDate] as? Date
                colorPalettes[mode.getKeyName()] = [colorPalette, Int64(modificationDate?.timeIntervalSince1970 ?? 0)]
            } else if let error {
                debugPrint("Error reading color palette file: \(error.description)")
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
