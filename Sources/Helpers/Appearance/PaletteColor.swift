//
//  PaletteColor.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.07.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

typealias ColorValue = ColorPalette.ColorValue

@objcMembers
class PaletteColor: NSObject {

    static private var lastGeneratedId: Int64 = 0

    let id: Int64

    var color: Int {
        get {
            return colorValue.clr
        }
        set {
            colorValue = ColorValue(val: colorValue.val, clr: newValue)
        }
    }

    private(set) var colorValue: ColorValue

    init(_ colorValue: ColorValue) {
        self.colorValue = colorValue
        self.id = Self.generateUniqueId()
    }

    init(color: Int) {
        self.colorValue = ColorValue(clr: color)
        self.id = Self.generateUniqueId()
    }

    static private func generateUniqueId() -> Int64 {
        if lastGeneratedId == 0 {
            lastGeneratedId = Int64(Date().timeIntervalSince1970)
        } else {
            lastGeneratedId += 1
        }
        return lastGeneratedId
    }

    func getIndex() -> Int {
        Int(colorValue.val)
    }

    func setIndex(_ index: Int) {
        colorValue.setValue(Double(index))
    }

    func duplicate(_ suffix: String? = nil) -> PaletteColor {
        PaletteColor(colorValue)
    }

    func toHumanString() -> String {
        localizedString("shared_string_custom")
    }
}
