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
    
    private(set) var stringId: String
    private(set) var typeName: String
    private(set) var paletteName: String
    private(set) var colorPalette: ColorPalette
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

    override func toHumanString() -> String {
        OAUtilities.capitalizeFirstLetter(paletteName.replacingOccurrences(of: ColorPaletteHelper.gradientIdSplitter, with: " "))
    }
}
