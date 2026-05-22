//
//  GradientFormatter.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import DGCharts

public enum RelativeConstants: CaseIterable {
    case min
    case average
    case max

    var value: Int {
        switch self {
        case .min:
            0
        case .average:
            50
        case .max:
            100
        }
    }

    var shortNameResId: String {
        switch self {
        case .min:
            "shared_string_min"
        case .average:
            "average"
        case .max:
            "shared_string_max"
        }
    }

    var longNameResId: String {
        switch self {
        case .min:
            "shared_string_minimum"
        case .average:
            "average"
        case .max:
            "shared_string_maximum"
        }
    }

    var summaryResId: String {
        switch self {
        case .min:
            "relative_gradient_point_min_summary"
        case .average:
            "relative_gradient_point_avg_summary"
        case .max:
            "relative_gradient_point_m_summary"
        }
    }

    func name(useFullName: Bool) -> String {
        Localization.shared.getString(key: useFullName ? longNameResId : shortNameResId)
    }

    func summary() -> String {
        Localization.shared.getString(key: summaryResId)
    }

    static func valueOfRatio(_ ratio: Float) -> RelativeConstants? {
        let targetValue = Int(round(ratio * 100))
        return allCases.first { $0.value == targetValue }
    }
}

@objcMembers
final class GradientFormatter: NSObject {

    private final class AxisValueFormatterLocal: AxisValueFormatter {
        private let formatClosure: (Double, AxisBase?) -> String

        init(formatClosure: @escaping (Double, AxisBase?) -> String) {
            self.formatClosure = formatClosure
        }

        func stringForValue(_ value: Double, axis: AxisBase?) -> String {
            formatClosure(value, axis)
        }
    }

    struct RealDataLimits {
        let minValue: Float
        let maxValue: Float
        let units: any MeasurementUnit
    }

    private static let maxAltitudeAddition: Float = 50
    private static let decimalFormat: NumberFormatter = {
        let decimalFormat = NumberFormatter()
        decimalFormat.numberStyle = .decimal
        decimalFormat.minimumFractionDigits = 0
        decimalFormat.maximumFractionDigits = 2
        return decimalFormat
    }()

    static func getAxisFormatter(paletteCategory: GradientPaletteCategory) -> AxisValueFormatter {
        getAxisFormatter(fileType: paletteCategory.getFileType(), realDataLimits: nil)
    }

    static func getAxisFormatter(fileType: GradientFileType, analysis: GpxTrackAnalysis?) -> AxisValueFormatter {
        let unitType = fileType.category.measureUnitType
        let limits = analysis.flatMap {
            calculateRealDataLimits(analysis: $0, unitType: unitType)
        }

        return getAxisFormatter(fileType: fileType, realDataLimits: limits)
    }

    @nonobjc static func getAxisFormatter(fileType: GradientFileType, realDataLimits: RealDataLimits?) -> AxisValueFormatter {
        AxisValueFormatterLocal { value, axis in
            // Use epsilon comparison to avoid float precision issues
            let isFirstValue = axis?.entries.first.map { abs($0 - value) < 0.001 } ?? false
            return formatValue(value: Float(value), fileType: fileType, showUnits: isFirstValue, realDataLimits: realDataLimits)
        }
    }

    @nonobjc static func formatValue(value: Float, fileType: GradientFileType, showUnits: Bool, realDataLimits: RealDataLimits? = nil) -> String {
        let context = PlatformUtil.shared.getOsmAndContext()
        var displayUnits = fileType.displayUnitsType.getUnit(mc: context.getMetricSystem(), am: context.getAltitudeMetric(), sc: context.getSpeedSystem(), ac: context.getAngularSystem(), tu: context.getTemperatureUnits())
        var baseUnits = fileType.baseUnits
        let valueStr: String
        let unitsSrt: String
        if fileType.rangeType == GradientRangeType.relative {
            if let realDataLimits {
                // SCENARIO 1: Relative + Real Data (Contextual Preview)
                // We map the 0..1 ratio to real physical values (e.g., speed, altitude).
                // 1. Source: Track analysis data is always in SI Base Units (m/s, meters).
                baseUnits = realDataLimits.units

                // 2. Target: user's preferred units (km/h, mph) instead of "%".
                displayUnits = fileType.category.measureUnitType.getUnit(mc: context.getMetricSystem(), am: context.getAltitudeMetric(), sc: context.getSpeedSystem(), ac: context.getAngularSystem(), tu: context.getTemperatureUnits())

                let range = realDataLimits.maxValue - realDataLimits.minValue
                let calculatedBaseValue = realDataLimits.minValue + (value * range)
                let valueInDisplayUnits = displayUnits.from(value: Double(calculatedBaseValue), sourceUnit: baseUnits)
                valueStr = decimalFormat.string(from: NSNumber(value: valueInDisplayUnits)) ?? ""
                unitsSrt = displayUnits.getSymbol()
            } else {
                // SCENARIO 2: Relative + No Data (Abstract Preview)
                // Show constants (Min/Max) or percentages.
                let constant = RelativeConstants.valueOfRatio(value)
                if let constant, fileType.useNamedConstants {
                    valueStr = constant.name(useFullName: false)
                    unitsSrt = ""
                } else {
                    let valueInDisplayUnits = displayUnits.from(value: Double(value), sourceUnit: baseUnits)
                    valueStr = decimalFormat.string(from: NSNumber(value: valueInDisplayUnits)) ?? ""
                    unitsSrt = displayUnits.getSymbol()
                }
            }
        } else {
            // SCENARIO 3: Fixed Values
            // Direct conversion from stored base units to display units.
            let valueInDisplayUnits = displayUnits.from(value: Double(value), sourceUnit: baseUnits)
            valueStr = fileType.category.isTerrainRelated() ? formatTerrainTypeValues(value: Float(valueInDisplayUnits)) : decimalFormat.string(from: NSNumber(value: valueInDisplayUnits)) ?? ""
            unitsSrt = displayUnits.getSymbol()
        }

        return showUnits && !unitsSrt.isEmpty ? String(format: localizedString("ltr_or_rtl_combine_via_space"), valueStr, unitsSrt) : valueStr
    }

    static func formatSimpleValue(value: Float, fileType: GradientFileType) -> String {
        fileType.category.isTerrainRelated() ? formatTerrainTypeValues(value: value) : decimalFormat.string(from: NSNumber(value: value)) ?? ""
    }

    static func getAdjustedPalette(originalPalette: OsmAndShared.ColorPalette, analysis: GpxTrackAnalysis?, fileType: GradientFileType) -> OsmAndShared.ColorPalette {
        guard let analysis else { return originalPalette }
        // Calculate actual track limits (e.g. 0..120 km/h)
        guard let limits = calculateRealDataLimits(analysis: analysis, unitType: fileType.category.measureUnitType) else { return originalPalette }
        // Validate limits and adjust the palette to fit strictly within the track's min/max
        return limits.maxValue <= limits.minValue ? originalPalette : originalPalette.adjustToRange(min: Double(limits.minValue), max: Double(limits.maxValue))
    }

    private static func formatTerrainTypeValues(value: Float) -> String {
        let format = NumberFormatter()
        format.numberStyle = .decimal
        format.minimumFractionDigits = 0
        format.maximumFractionDigits = value >= 10 ? 0 : 1
        let formattedValue = format.string(from: NSNumber(value: value)) ?? "\(value)"
        return formattedValue.hasSuffix(".0") ? String(formattedValue.dropLast(2)) : formattedValue
    }

    private static func calculateRealDataLimits(analysis: GpxTrackAnalysis, unitType: MeasureUnitType) -> RealDataLimits? {
        var result: RealDataLimits?
        if unitType == MeasureUnitType.speed {
            if analysis.maxSpeed > 0 {
                result = RealDataLimits(minValue: analysis.minSpeed, maxValue: analysis.maxSpeed, units: SpeedUnits.metersPerSecond)
            }
        } else if unitType == MeasureUnitType.altitude {
            let min = analysis.minElevation
            let max = analysis.maxElevation + Double(maxAltitudeAddition)
            guard let minDefault = GpxParameter.minElevation.defaultValue as? Double, let maxDefault = GpxParameter.maxElevation.defaultValue as? Double else { return nil }
            if min != minDefault && max != maxDefault {
                result = RealDataLimits(minValue: Float(min), maxValue: Float(max), units: LengthUnits.meters)
            }
        } else {
            debugPrint("GradientFormatter: real data preview is not supported for unit type \(unitType)")
        }

        return result
    }
}
