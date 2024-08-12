//
//  GradientColorsCollection.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

typealias TerrainType = TerrainMode.TerrainType

@objcMembers
final class GradientColorsCollection: ColorsCollection {

    private struct GradientData {
        let typeName: String
        let paletteName: String
        let index: Int
    }

    private static let attrTypeName = "type_name"
    private static let attrPaletteName = "palette_name"
    private static let attrIndex = "index"

    let gradientType: Any

    private var gradientPalettes: [String: [Any]]
    private var preference: OACommonString
    private var type: String = ""

    init(gradientType: Any) {
        self.gradientType = gradientType
        preference = OAAppSettings.sharedManager().gradientPalettes
        gradientPalettes = ColorPaletteHelper.shared.getPalletsForType(gradientType)

        if let gradientType = gradientType as? ColorizationType {
            type = gradientType.name
        } else if let gradientType = gradientType as? TerrainType {
            type = gradientType.name
        }

        super.init()
        loadColors()
    }

    convenience init(colorizationType: ColorizationType) {
        self.init(gradientType: colorizationType)
    }

    convenience init(terrainType: TerrainType) {
        self.init(gradientType: terrainType)
    }
    
    override func updateColor(_ paletteColor: PaletteColor?, newValue: Any?, save: Bool) -> PaletteColor? {
        if let paletteGradientColor = paletteColor as? PaletteGradientColor {
            if let gradientType = gradientType as? ColorizationType {
                if let newColorPalette = ColorPaletteHelper.shared.getGradientColorPaletteSync(gradientType, gradientPaletteName: paletteGradientColor.paletteName) {
                    paletteGradientColor.colorPalette = newColorPalette
                }
            } else if gradientType is TerrainType,
                      let terrainType = TerrainType.allCases.first(where: { $0.name == paletteGradientColor.typeName }),
                      let terrainMode = TerrainMode.getMode(terrainType, keyName: paletteGradientColor.paletteName),
                      let newColorPalette = ColorPaletteHelper.shared.getGradientColorPalette(terrainMode.getMainFile()) {
                paletteGradientColor.colorPalette = newColorPalette
            }
        }
        if save && paletteColor != nil {
            saveColors()
        }
        return paletteColor
    }
    
    override func getPaletteColor(byFileName fileName: String, new: Bool = false) -> PaletteColor? {
        var colorizationStringId = ""

        switch gradientType {
        case is ColorizationType:
            colorizationStringId = fileName.removePrefix(ColorPaletteHelper.routePrefix)
        case is TerrainType:
            colorizationStringId = fileName
        default:
            return nil
        }
        colorizationStringId = colorizationStringId.removeSufix(TXT_EXT)

        guard !colorizationStringId.isEmpty, let typeName = getTypeName(colorizationStringId) else { return nil }
        if new {
            if let colorPalette = ColorPaletteHelper.shared.getGradientColorPalette(fileName),
               let lastModified = colorPalette.lastModified {
                return PaletteGradientColor(typeName: typeName.0,
                                            paletteName: typeName.1,
                                            colorPalette: colorPalette,
                                            initialIndex: Int(lastModified.timeIntervalSince1970))
            }
        } else {
            return getPaletteColor(byType: typeName.0, name: typeName.1)
        }
        return nil
    }

    func isTerrainType() -> Bool {
        gradientType is TerrainType
    }

    func getFileNamePrefix() -> String? {
        if gradientType is ColorizationType {
            return ColorPaletteHelper.routePrefix
        } else if let terrainType = gradientType as? TerrainType {
            if terrainType == TerrainType.hillshade {
                return TerrainMode.hillshadePrefix
            } else if terrainType == TerrainType.height {
                return TerrainMode.heightPrefix
            } else {
                return TerrainMode.colorSlopePrefix
            }
        }
        return nil
    }

    func getPaletteColor(byName name: String) -> PaletteGradientColor? {
        return getPaletteColors().first {
            guard let gradientPaletteColor = $0 as? PaletteGradientColor else { return false }
            return gradientPaletteColor.paletteName == name
        } as? PaletteGradientColor
    }

    func getPaletteColor(byType type: String, name: String) -> PaletteGradientColor? {
        return getPaletteColors().first {
            guard let gradientPaletteColor = $0 as? PaletteGradientColor else { return false }
            return gradientPaletteColor.typeName == type && gradientPaletteColor.paletteName == name
        } as? PaletteGradientColor
    }

    func getDefaultGradientPalette() -> PaletteGradientColor? {
        getPaletteColor(byName: PaletteGradientColor.defaultName)
    }

    func getPaletteColors() -> [PaletteColor] {
        getColors(.lastUsedTime)
    }

    override func loadColorsInLastUsedOrder() throws {
        var addedPaletteIds = Set<String>()
        let loadedPreference = readPaletteColorsPreference()

        for gradientData in loadedPreference {
            let index = gradientData.index
            let typeName = gradientData.typeName
            let paletteName = gradientData.paletteName
            if let paletteInfo = gradientPalettes[paletteName],
               let palette = paletteInfo.first as? ColorPalette {
                let gradientColor = PaletteGradientColor(typeName: typeName, paletteName: paletteName, colorPalette: palette, initialIndex: index)
                addToLastUsedOrder(gradientColor)
                addedPaletteIds.insert(gradientColor.stringId)
            }
        }

        for (key, pair) in gradientPalettes {
            if let palette = pair.first as? ColorPalette, let creationTime = pair.last as? Int64 {
                let gradientColor = PaletteGradientColor(typeName: type, paletteName: key, colorPalette: palette, initialIndex: Int(creationTime))
                let id = gradientColor.stringId
                if !addedPaletteIds.contains(id) {
                    addToLastUsedOrder(gradientColor)
                    addedPaletteIds.insert(id)
                }
            }
        }
    }

    private func getTypeName(_ stringId: String) -> (String, String)? {
        var prefix = ""
        if gradientType is TerrainType, let terrainPrefix = getFileNamePrefix() {
            prefix = terrainPrefix
        } else {
            prefix += "\(type)\(ColorPaletteHelper.gradientIdSplitter)"
        }
        guard stringId.hasPrefix(prefix) else { return nil }
        var name = stringId.removePrefix(prefix)
        if gradientType is TerrainType,
           (name == TerrainMode.altitudeDefaultKey || name == TerrainMode.defaultKey) {
                name = type
        }
        return (type, name)
    }

    private func readPaletteColorsPreference() -> [GradientData] {
        let jsonAsString = preference.get()
        preference.resetToDefault()
        var res = [GradientData]()

        if let jsonAsString, !jsonAsString.isEmpty {
            do {
                if let data = jsonAsString.data(using: .utf8) {
                    let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                    res = Self.readFromJson(json, type: type)
                }
            } catch {
                debugPrint("Error while reading palette colors from JSON: \(error)")
            }
        }
        return res
    }

    private static func readFromJson(_ json: [String: Any], type: String) -> [GradientData] {
        guard let typeGradients = json[type] as? [[String: Any]] else {
            return []
        }

        var res = [GradientData]()
        for itemJson in typeGradients {
            if let typeName = itemJson[attrTypeName] as? String,
               let paletteName = itemJson[attrPaletteName] as? String,
               let index = itemJson[attrIndex] as? Int {
                res.append(GradientData(typeName: typeName, paletteName: paletteName, index: index))
            }
        }
        return res
    }

    override func saveColors() {
        for paletteColor in originalOrder {
            if let index = originalOrder.firstIndex(where: { $0.id == paletteColor.id }) {
                paletteColor.setIndex(index + 1)
            }
        }

        let savedGradientPreferences = preference.get()
        do {
            var jsonObject: [String: Any]
            if let savedGradientPreferences,
               !savedGradientPreferences.isEmpty,
               let data = savedGradientPreferences.data(using: .utf8) {
                jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            } else {
                jsonObject = [String: Any]()
            }
            Self.writeToJson(&jsonObject, paletteColors: lastUsedOrder, type: type)
            let newGradientPreferences = String(data: try JSONSerialization.data(withJSONObject: jsonObject, options: []), encoding: .utf8)!
            preference.set(newGradientPreferences)
        } catch {
            debugPrint("Error while saving palette colors to JSON: \(error)")
        }
    }

    private static func writeToJson(_ jsonObject: inout [String: Any], paletteColors: [PaletteColor], type: String) {
        var jsonArray = [[String: Any]]()
        for paletteColor in paletteColors {
            if let gradientColor = paletteColor as? PaletteGradientColor {
                var itemObject = [String: Any]()
                itemObject[attrTypeName] = gradientColor.typeName
                itemObject[attrPaletteName] = gradientColor.paletteName
                itemObject[attrIndex] = gradientColor.getIndex()
                jsonArray.append(itemObject)
            }
        }
        jsonObject[type] = jsonArray
    }
}
