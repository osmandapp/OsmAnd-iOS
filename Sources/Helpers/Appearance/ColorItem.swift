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

    let key: String?
    var value: Int
    var id: Int = -1
    let isDefault: Bool
    var sortedPosition: Int = -1
    private var hexColor: String? = nil

    init(key: String?, value: Int, isDefault: Bool) {
        self.key = key
        self.value = value
        self.isDefault = isDefault
    }

    convenience init(hexColor: String) {
        self.init(key: nil, value: Int(OAUtilities.colorToNumber(from: hexColor)), isDefault: false)
        self.hexColor = hexColor
    }

    func setValue(newValue: Int) {
        self.value = newValue
        hexColor = getColor().toHexARGBString()
    }
    
    func generateId() {
        id = value + sortedPosition
    }

    func getTitle() -> String? {
        if key == nil { return nil }
        return localizedString(key)
    }

    func getColor() -> UIColor {
        return colorFromARGB(value)
    }

    func getHexColor() -> String {
        return hexColor != nil ? hexColor! : getColor().toHexARGBString()
    }

    override func isEqual(_ object: Any?) -> Bool
    {
        if let other = object as? ColorItem {
            return self.key == other.key && self.value == other.value && self.id == other.id && self.isDefault == other.isDefault && self.sortedPosition == other.sortedPosition
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
        return hasher.finalize()
    }
}
