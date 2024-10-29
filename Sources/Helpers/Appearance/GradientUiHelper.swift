//
//  GradientUiHelper.swift
//  OsmAnd Maps
//
//  Created by Skalii on 01.08.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts

@objcMembers
final class GradientUiHelper: NSObject {

    final class AxisValueFormatterLocal: AxisValueFormatter {

        private let formatClosure: (Double, AxisBase?) -> String
        
        init(formatClosure: @escaping (Double, AxisBase?) -> String) {
            self.formatClosure = formatClosure
        }
        
        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            return formatClosure(value, axis)
        }
    }

    static let maxAltitudeAddition = 50.0

    static func formatTerrainTypeValues(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = (value >= 10) ? 0 : 1
        formatter.maximumFractionDigits = formatter.minimumFractionDigits
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US_POSIX")
        var formattedValue = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        if formattedValue.hasSuffix("\(formatter.decimalSeparator ?? ".")0") {
            formattedValue.removeLast(2)
        }
        return formattedValue
    }

    static func getGradientTypeFormatterFor(terrainType: TerrainType, analysis: GpxTrackAnalysis?) -> AxisValueFormatter {
        Self.getGradientTypeFormatter(terrainType, analysis: analysis)
    }

    static func getGradientTypeFormatter(_ gradientType: Any, analysis: GpxTrackAnalysis?) -> AxisValueFormatter {
        if let terrainType = gradientType as? TerrainType {
            return getTerrainTypeFormatter(terrainType)
        }
        return getColorizationTypeFormatter(gradientType as! ColorizationType, analysis: analysis)
    }

    private static func getTerrainTypeFormatter(_ terrainType: TerrainType) -> AxisValueFormatter {
        return AxisValueFormatterLocal { (value, axis) in
            var stringValue = Self.formatTerrainTypeValues(value)
            var typeValue = ""
            switch terrainType {
            case .slope:
                typeValue = "°"
            case .height:
                if let formattedValue = OAOsmAndFormatter.getFormattedAlt(value, mc: OAAppSettings.sharedManager().metricSystem.get()) {
                    if let lastSpaceIndex = formattedValue.lastIndex(of: " ") {
                        stringValue = String(formattedValue[..<lastSpaceIndex])
                        typeValue = String(formattedValue[formattedValue.index(after: lastSpaceIndex)...])
                    } else {
                        stringValue = formattedValue
                    }
                }
            default:
                break
            }
            if let axis, axis.entries.count >= 1, (value == axis.entries.first || value == axis.entries.last) {
                return "\(stringValue) \(typeValue)"
            }
            return stringValue
        }
    }

    private static func getColorizationTypeFormatter(_ colorizationType: ColorizationType, analysis: GpxTrackAnalysis?) -> AxisValueFormatter {
        return AxisValueFormatterLocal { (value, axis) in
            var stringValue = Self.formatValue(value, multiplier: 100)
            var type = "%"
            if let analysis = analysis {
                switch colorizationType {
                case .speed:
                    if analysis.maxSpeed != 0 {
                        type = OASpeedConstant.toShortString(OAAppSettings.sharedManager().speedSystem.get())
                        stringValue = Self.formatValue(value, multiplier: analysis.maxSpeed)
                    }
                case .elevation:
                    let minElevation = analysis.minElevation
                    let maxElevation = analysis.maxElevation + maxAltitudeAddition
                    if minElevation != 99999.0 && maxElevation != -100.0 {
                        let calculatedValue = value == 0 ? minElevation : minElevation + (value * (maxElevation - minElevation))
                        if let formattedValue = OAOsmAndFormatter.getFormattedAlt(calculatedValue, mc: OAAppSettings.sharedManager().metricSystem.get()) {
                            if let lastSpaceIndex = formattedValue.lastIndex(of: " ") {
                                stringValue = String(formattedValue[..<lastSpaceIndex])
                                type = String(formattedValue[formattedValue.index(after: lastSpaceIndex)...])
                            } else {
                                stringValue = formattedValue
                            }
                        }
                    }
                default:
                    break
                }
            }
            if let axis, axis.entries.count >= 1, (value == axis.entries.first || value == axis.entries.last) {
                return "\(stringValue) \(type)"
            }
            return stringValue
        }
    }

    private static func formatValue(_ value: Double, multiplier: Float) -> String {
        let formatter = NumberFormatter()
        formatter.positiveFormat = "#"
        return formatter.string(from: NSNumber(value: value * Double(multiplier))) ?? ""
    }
}
