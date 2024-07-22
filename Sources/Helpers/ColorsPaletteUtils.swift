//
//  ColorsPaletteUtils.swift
//  OsmAnd Maps
//
//  Created by Skalii on 17.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objcMembers
final class ColorsPaletteUtils: NSObject {

    private static let kRoutePrefix = "route_"
    private static let kWeatherPrefix = "weather_"
    private static let kUserPalettePrefix = "user_palette_"
    private static let prefixes = [kRoutePrefix, kWeatherPrefix, kUserPalettePrefix]

    static func getPaletteName(_ filePath: String) -> String {
        var fileName = filePath.lastPathComponent()
        for prefix in prefixes where fileName.hasPrefix(prefix) {
            fileName = String(fileName.dropFirst(prefix.count))
            break
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
