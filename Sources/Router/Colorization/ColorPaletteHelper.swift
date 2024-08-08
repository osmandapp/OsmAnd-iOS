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
    static let weatherPrefix = "weather_"
    static let gradientIdSplitter = "_"
    static let colorPalettesUpdatedNotification = NSNotification.Name("ColorPalettesUpdated")

    static let updatedFileKey = "updatedFile"
    static let deletedFileKey = "deletedFile"
    static let createdFileKey = "createdFile"

    private var app: OsmAndAppProtocol
    private var directoryObserver: DirectoryObserver
    private var cachedColorPalette = ConcurrentDictionary<String, ColorPalette>()

    private override init() {
        app = OsmAndApp.swiftInstance()

        let notificationName = NSNotification.Name("ColorPaletteDicrectoryUpdated")
        directoryObserver = DirectoryObserver(app.colorsPalettePath, notificationName: notificationName)
        directoryObserver.startObserving()

        super.init()

        NotificationCenter.default.addObserver(self, selector: #selector(onColorPaletteDirectoryUpdated(_ :)), name: notificationName, object: nil)
    }

    @objc private func onColorPaletteDirectoryUpdated(_ notification: Notification) {
        if let path = notification.object as? String {
            do {
                var colorPaletteFilesUpdated = [String: String]()
                let files = try FileManager.default.contentsOfDirectory(atPath: path)
                let deletedPalettes = cachedColorPalette.getAllKeys().filter { !files.contains($0) }
                for deletedPalette in deletedPalettes {
                    colorPaletteFilesUpdated[deletedPalette] = Self.deletedFileKey
                    cachedColorPalette.removeValue(forKey: deletedPalette)
                }
                for file in files {
                    let colorPaletteFileName = file.lastPathComponent()
                    let cachedPalette = cachedColorPalette.getValue(forKey: colorPaletteFileName)
                    if let cachedPalette {
                        let attributes = try FileManager.default.attributesOfItem(atPath: getColorPaletteDir().appendingPathComponent(colorPaletteFileName))
                        if attributes[.modificationDate] as? Date != cachedPalette.lastModified {
                            if parseGradientColorPalette(colorPaletteFileName) != nil {
                                colorPaletteFilesUpdated[colorPaletteFileName] = Self.updatedFileKey
                            }
                        }
                    } else {
                        if parseGradientColorPalette(colorPaletteFileName) != nil {
                            colorPaletteFilesUpdated[colorPaletteFileName] = Self.createdFileKey
                        }
                    }
                }
                if colorPaletteFilesUpdated.keys.contains(where: { !$0.hasPrefix(Self.routePrefix) && !$0.hasPrefix(Self.weatherPrefix) && colorPaletteFilesUpdated[$0] != Self.updatedFileKey }) {
                    TerrainMode.reloadTerrainModes()
                }
                NotificationCenter.default.post(name: Self.colorPalettesUpdatedNotification, object: colorPaletteFilesUpdated)
            } catch {
                debugPrint("Error updated color palette contents of: \(path)")
            }
        }
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

    func requireGradientColorPaletteSync(_ colorizationType: ColorizationType, gradientPaletteName: String) -> ColorPalette {
        guard let colorPalette = getGradientColorPaletteSync(colorizationType, gradientPaletteName: gradientPaletteName), isValidPalette(colorPalette) else {
            return OARouteColorize.getDefaultPalette(colorizationType.rawValue)
        }
        return colorPalette
    }

    func getGradientColorPaletteSync(_ colorizationType: ColorizationType, gradientPaletteName: String) -> ColorPalette? {
        getGradientColorPalette(Self.getRoutePaletteFileName(colorizationType, gradientPaletteName: gradientPaletteName))
    }

    func getGradientColorPaletteSync(with modeKey: String) -> ColorPalette? {
        getGradientColorPalette(modeKey)
    }

    func getGradientColorPalette(_ colorPaletteFileName: String) -> ColorPalette? {
        guard let cachedPalette = cachedColorPalette.getValue(forKey: colorPaletteFileName) else {
            return parseGradientColorPalette(colorPaletteFileName)
        }
        return cachedPalette
    }

    private func parseGradientColorPalette(_ colorPaletteFileName: String) -> ColorPalette? {
        if colorPaletteFileName.hasSuffix(TXT_EXT) {
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
            if let colorPalette = getGradientColorPalette(fileName),
               FileManager.default.fileExists(atPath: filePath) {
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
