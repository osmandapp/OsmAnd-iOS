import Foundation

extension PlanRouteAnalyzeViewController {
    static let accessibilityIntegerMeasurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        formatter.unitOptions = .providedUnit
        formatter.locale = .current
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter
    }()
    static let accessibilityDecimalMeasurementFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .long
        formatter.unitOptions = .providedUnit
        formatter.locale = .current
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    static let accessibilityListFormatter: ListFormatter = {
        let formatter = ListFormatter()
        formatter.locale = .current
        return formatter
    }()
    static let accessibilityNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: OAUtilities.currentLang() ?? Locale.current.identifier)
        return formatter
    }()
}
