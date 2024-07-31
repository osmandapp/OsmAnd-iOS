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

    init(_ gradientType: Any) {
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
        self.init(colorizationType)
    }

    convenience init(terrainType: TerrainType) {
        self.init(terrainType)
    }

    func hasRouteGradientPalette(by fileName: String) -> Bool {
        return getPaletteColors().contains { paletteColor in
            guard let gradientColor = paletteColor as? PaletteGradientColor else { return false }
            let expectedFileName = ColorPaletteHelper.routePrefix + gradientColor.stringId + TXT_EXT
            return fileName == expectedFileName
        }
    }

    func hasTerrainGradientPalette(by fileName: String) -> Bool {
        guard gradientType is TerrainType else { return false }
        let prefixes = [TerrainMode.hillshadePrefix, TerrainMode.colorSlopePrefix, TerrainMode.heightPrefix]
        return getPaletteColors().contains { paletteColor in
            guard let gradientColor = paletteColor as? PaletteGradientColor else { return false }
            guard let key = TerrainMode.getKeyByPaletteName(gradientColor.paletteName) else { return false }
            return prefixes.contains(where: { $0 + key + TXT_EXT == fileName })
        }
    }

    func getPaletteColors() -> [PaletteColor] {
        getColors(.lastUsedTime)
    }

    func getDefaultGradientPalette() -> PaletteGradientColor? {
        return getGradientPalette(by: PaletteGradientColor.defaultName)
    }

    func getGradientPalette(by name: String) -> PaletteGradientColor? {
        for paletteColor in getPaletteColors() {
            if let gradientColor = paletteColor as? PaletteGradientColor,
               gradientColor.paletteName == name {
                return gradientColor
            }
        }
        return nil
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

    private func readPaletteColorsPreference() -> [GradientData] {
        let jsonAsString = preference.get()
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
