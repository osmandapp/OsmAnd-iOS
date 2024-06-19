//
//  ColorsPaletteUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc
@objcMembers
final class ColorsPaletteUtils: NSObject {

    static let kRoutePrefix = "route_"
    static let kWeatherPrefix = "weather_"
    static let kUserPalettePrefix = "user_palette_"

    static func getPaletteName(_ filePath: String) -> String {
        var fileName = filePath.lastPathComponent()
        var prefix: String?

        if fileName.hasPrefix(Self.kRoutePrefix) {
            prefix = Self.kRoutePrefix
        } else if fileName.hasPrefix(Self.kWeatherPrefix) {
            prefix = Self.kWeatherPrefix
        } else if fileName.hasPrefix(Self.kUserPalettePrefix) {
            prefix = Self.kUserPalettePrefix
        }

        if let prefix {
            fileName = fileName.replacingOccurrences(of: prefix, with: "")
        }

        fileName = fileName.replacingOccurrences(of: TXT_EXT, with: "")
        return fileName.components(separatedBy: "_").map { OAUtilities.capitalizeFirstLetter($0) }.joined(separator: " ")
    }

    static func getPaletteTypeName(_ filePath: String) -> String {
        let fileName = filePath.lastPathComponent()

        if fileName.hasPrefix(Self.kRoutePrefix) {
            return localizedString("layer_route")
        } else if fileName.hasPrefix(Self.kWeatherPrefix) {
            return localizedString("shared_string_weather")
        } else if fileName.hasPrefix(Self.kUserPalettePrefix) {
            return localizedString("user_palette")
        } else {
            return localizedString("shared_string_terrain")
        }
    }
}
