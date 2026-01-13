//
//  ButtonAppearanceParams.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 17.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ButtonAppearanceParams: NSObject {
    var iconName: String?
    var size: Int32
    var opacity: Double
    var cornerRadius: Int32
    var glassStyle: Int32
    
    init(iconName: String?, size: Int32, opacity: Double, cornerRadius: Int32, glassStyle: Int32) {
        self.iconName = iconName
        self.size = size
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.glassStyle = glassStyle
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ButtonAppearanceParams else {
            return false
        }
        return iconName == other.iconName && size == other.size && opacity == other.opacity && cornerRadius == other.cornerRadius && glassStyle == other.glassStyle
    }
}
