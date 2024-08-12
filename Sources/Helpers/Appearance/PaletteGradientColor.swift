//
//  PaletteGradientColor.swift
//  OsmAnd Maps
//
//  Created by Skalii on 18.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class PaletteGradientColor: PaletteColor {

    static let defaultName = "default"

    var colorPalette: ColorPalette

    private(set) var stringId: String
    private(set) var typeName: String
    private(set) var paletteName: String
    private var index: Int

    init(typeName: String, paletteName: String, colorPalette: ColorPalette, initialIndex: Int) {
        self.stringId = "\(typeName)\(ColorPaletteHelper.gradientIdSplitter)\(paletteName)"
        self.typeName = typeName
        self.paletteName = paletteName
        self.colorPalette = colorPalette
        self.index = initialIndex
        super.init(color: 0)
    }

    override func getIndex() -> Int {
        index
    }

    override func setIndex(_ index: Int) {
        self.index = index
    }

    override func duplicate(_ suffix: String? = nil) -> PaletteColor {
        let colorPalette = self.colorPalette
        colorPalette.lastModified = Date()
        var paletteName = self.paletteName
        if paletteName == typeName {
            paletteName = typeName == TerrainType.height.name
                ? TerrainMode.altitudeDefaultKey
                : TerrainMode.defaultKey
        }
        return PaletteGradientColor(typeName: typeName,
                                    paletteName: "\(paletteName)\(suffix ?? "")",
                                    colorPalette: colorPalette,
                                    initialIndex: index + 1)
    }

    override func toHumanString() -> String {
        OAUtilities.capitalizeFirstLetter(paletteName.replacingOccurrences(of: ColorPaletteHelper.gradientIdSplitter, with: " "))
    }
}
