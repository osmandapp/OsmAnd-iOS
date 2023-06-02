//
//  ColorItem.swift
//  OsmAnd Maps
//
//  Created by Skalii on 03.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAColorItem)
@objcMembers
class ColorItem: NSObject {

    var key: String?
    var value: Int
    var id: Int = -1
    var isDefault: Bool
    var sortedPosition: Int = -1
    private var hexColor: String? = nil

    init(key: String?, value: Int, isDefault: Bool) {
        self.key = key
        self.value = value
        self.isDefault = isDefault
    }

    convenience init(hexColor: String) {
        let colorValue: Int = Int(UIColor.toNumber(from: hexColor))
        self.init(key: ColorItem.generateKey(colorValue: colorValue), value: colorValue, isDefault: false)
        self.hexColor = hexColor
    }

    func setValue(newValue: Int) {
        self.key = ColorItem.generateKey(colorValue: newValue)
        self.value = newValue
        hexColor = getColor().toHexARGBString()
    }
    
    func generateId() {
        id = value + sortedPosition
    }

    func getTitle() -> String? {
        if key == nil { return nil }
        var title: String = localizedString(key)
        if title == key {
            title = localizedString("rendering_value_" + key! + "_name")
        }
        return title
    }

    func getColor() -> UIColor {
        return colorFromARGB(value)
    }

    func getHexColor() -> String {
        return hexColor != nil ? hexColor! : getColor().toHexARGBString()
    }

    static func generateKey(colorValue: Int) -> String? {
        switch (colorValue) {
            case 0x3F51B5:
                return "rendering_value_purple_name"
            case 0x43A047:
                return "rendering_value_green_name"
            case 0xffb300:
                return "rendering_value_yellow_name"
            case 0xff5722:
                return "rendering_value_orange_name"
            case 0x607d8b:
                return "col_gray"
            case 0xe91e63:
                return "rendering_value_red_name"
            case 0x2196f3:
                return "rendering_value_blue_name"
            case 0x9c27b0:
                return "shared_string_color_magenta"
            default:
                return nil;
        }
    }

    override func isEqual(_ object: Any?) -> Bool
    {
        if let other = object as? ColorItem {
            return self.key == other.key && self.value == other.value && self.id == other.id && self.isDefault == other.isDefault && self.sortedPosition == other.sortedPosition && self.hexColor == other.hexColor
        } else {
            return false
        }
    }

    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(key)
        hasher.combine(value)
        hasher.combine(id)
        hasher.combine(isDefault)
        hasher.combine(sortedPosition)
        hasher.combine(hexColor)
        return hasher.finalize()
    }
}
