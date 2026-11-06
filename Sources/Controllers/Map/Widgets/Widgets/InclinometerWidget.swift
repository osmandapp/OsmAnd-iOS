//
//  InclinometerWidget.swift
//  OsmAnd Maps
//
//  Created by Eugene Zmeuk on 02.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation
import AudioToolbox

@objc(OAInclinometerWidget)
@objcMembers
final class InclinometerWidget: OASimpleWidget, InclinometerListener {

    static let calibrationRowKey = "inclinometer_calibration"

    private static let noValue = "—"
    private static let zoneHysteresisDegrees: Float = 1
    private static let alertTonePause: TimeInterval = 0.35

    // Solid triangles: unlike the arrow glyphs, all four come from the same font and look alike
    private static let arrowFrontUp = "\u{25B2}"
    private static let arrowFrontDown = "\u{25BC}"
    private static let arrowRight = "\u{25B6}"
    private static let arrowLeft = "\u{25C0}"

    private enum TiltZone: Int, Comparable {
        case safe, warning, critical

        var color: UIColor {
            switch self {
            case .safe: return UIColor(rgb: 0x5BAF3F)
            case .warning: return UIColor(rgb: 0xF0B400)
            case .critical: return UIColor(rgb: 0xEE3232)
            }
        }

        static func < (lhs: TiltZone, rhs: TiltZone) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // Set once in init(with:…); initWithType: of the base class goes through init(frame:) first
    private(set) var widgetState: InclinometerWidgetState!
    private let sensor = InclinometerSensor.shared

    private var zone = TiltZone.safe
    private var hasValue = false
    private var angle: Float = 0
    private var cachedText: String?

    init(with widgetState: InclinometerWidgetState, customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        super.init(type: widgetState.widgetType)
        self.widgetState = widgetState
        setIconFor(widgetType)
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        setText(Self.noValue, subtext: nil)
        onClickFunction = { [weak self] _ in
            guard let self else { return }
            // the units are switched either by tap or from the widget settings
            self.widgetState.changeToNextState()
            self.updateText(force: true)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func storedWidgetState() -> OAWidgetState? {
        widgetState
    }

    override func updateInfo() -> Bool {
        if sensor.isSensorAvailable {
            sensor.requestUpdates(self)
        }
        if hasValue {
            // the thresholds or the units may have been changed in the settings
            if Thread.isMainThread {
                refreshValue()
            } else {
                DispatchQueue.main.async { [weak self] in self?.refreshValue() }
            }
        }
        return true
    }

    private func refreshValue() {
        updateZone()
        updateText(force: false)
    }

    // MARK: - InclinometerListener

    func onInclinationChanged(pitch: Float, roll: Float) {
        angle = widgetType == .inclinometerPitch ? pitch : roll
        hasValue = true
        updateZone()
        updateText(force: false)
    }

    var isInclinometerActive: Bool {
        if window != nil {
            return !isHidden
        }
        // Not attached yet (right after the controls were recreated) or detached: keep the
        // updates while this instance is still the enabled widget of the registry
        guard let registry = OAMapWidgetRegistry.sharedInstance() else {
            return false
        }
        let appMode = OAAppSettings.sharedManager().applicationMode.get()
        return registry.getAllWidgets().contains { $0.widget === self && $0.isEnabledForAppMode(appMode) }
    }

    // MARK: - Value

    private func updateText(force: Bool) {
        let text = Self.formatAngle(angle, percentUnits: widgetState.percentUnitsPref.get())
        let direction = Self.directionArrow(widgetType, degrees: angle)
        let fullText = direction != nil ? text + " " + direction! : text
        if force || fullText != cachedText {
            cachedText = fullText
            // the arrow is part of the value, so it has the full text height and the zone color
            setText(fullText, subtext: nil)
            applyZoneColor()
        }
    }

    static func formatAngle(_ degrees: Float, percentUnits: Bool) -> String {
        let value = Int((percentUnits ? InclinometerSensor.toPercent(degrees) : degrees).magnitude.rounded())
        return percentUnits ? "\(value)%" : "\(value)°"
    }

    // Arrow showing where the vehicle leans: up/down for the front (pitch), left/right for the lowered side (roll)
    static func directionArrow(_ widgetType: WidgetType?, degrees: Float) -> String? {
        if Int(degrees.magnitude.rounded()) == 0 {
            return nil
        }
        if widgetType == .inclinometerPitch {
            return degrees > 0 ? arrowFrontUp : arrowFrontDown
        }
        return degrees > 0 ? arrowRight : arrowLeft
    }

    private func updateZone() {
        let tilt = angle.magnitude
        let warningAngle = Float(widgetState.warningAnglePref.get())
        let criticalAngle = Float(widgetState.criticalAngle())
        let newZone: TiltZone
        switch zone {
        case .safe:
            newZone = tilt >= criticalAngle ? .critical : tilt >= warningAngle ? .warning : .safe
        case .warning:
            newZone = tilt >= criticalAngle ? .critical
                : tilt < warningAngle - Self.zoneHysteresisDegrees ? .safe : .warning
        case .critical:
            newZone = tilt >= criticalAngle - Self.zoneHysteresisDegrees ? .critical
                : tilt >= warningAngle ? .warning : .safe
        }
        if newZone != zone {
            let escalated = newZone > zone
            zone = newZone
            applyZoneColor()
            if escalated, widgetState.soundAlertPref.get() {
                Self.playAlert(beeps: newZone == .critical ? 2 : 1)
            }
        }
    }

    // MARK: - Colors

    override func configureSimpleLayout() {
        super.configureSimpleLayout()
        applyZoneColor()
    }

    private func applyZoneColor() {
        guard hasValue else {
            return
        }
        if isSimpleLayout {
            valueLabel?.textColor = zone.color
        } else if let attributedText = textView.attributedText, let cachedText {
            // the legacy layout paints the value through the attributed string
            let string = NSMutableAttributedString(attributedString: attributedText)
            let range = (string.string as NSString).range(of: cachedText)
            if range.location != NSNotFound {
                string.addAttribute(.foregroundColor, value: zone.color, range: range)
                textView.attributedText = string
            }
        }
    }

    // MARK: - Sound

    private static func playAlert(beeps: Int) {
        guard let path = Bundle.main.path(forResource: "ding", ofType: "aiff") else {
            return
        }
        var soundId: SystemSoundID = 0
        guard AudioServicesCreateSystemSoundID(URL(fileURLWithPath: path) as CFURL, &soundId) == kAudioServicesNoError else {
            return
        }
        for i in 0..<beeps {
            DispatchQueue.main.asyncAfter(deadline: .now() + alertTonePause * Double(i)) {
                if i == beeps - 1 {
                    AudioServicesPlaySystemSoundWithCompletion(soundId) {
                        AudioServicesDisposeSystemSoundID(soundId)
                    }
                } else {
                    AudioServicesPlaySystemSound(soundId)
                }
            }
        }
    }

    // MARK: - Settings

    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String: Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()

        let unitsSection = data.createNewSection()
        unitsSection.headerText = localizedString("shared_string_settings")
        unitsSection.footerText = localizedString("switch_units_by_tapping_on_widget")
        let unitsRow = unitsSection.createNewRow()
        unitsRow.cellType = OAValueTableViewCell.getIdentifier()
        unitsRow.key = "value_pref"
        unitsRow.title = localizedString("inclinometer_slope_unit")
        unitsRow.setObj(widgetState.percentUnitsPref, forKey: "pref")
        let percentUnits = boolValue(widgetState.percentUnitsPref, appMode: appMode,
                                     widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
        unitsRow.setObj(localizedString(percentUnits ? "shared_string_percent" : "shared_string_degrees"), forKey: "value")
        unitsRow.setObj(unitsPossibleValues(), forKey: "possible_values")

        let alertsSection = data.createNewSection()
        alertsSection.headerText = localizedString("shared_string_alerts")
        alertsSection.footerText = localizedString("inclinometer_sound_alert_desc")
        addAngleRow(to: alertsSection, title: localizedString("inclinometer_warning_angle"), pref: widgetState.warningAnglePref,
                    appMode: appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
        addAngleRow(to: alertsSection, title: localizedString("inclinometer_critical_angle"), pref: widgetState.criticalAnglePref,
                    appMode: appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
        let soundRow = alertsSection.createNewRow()
        soundRow.cellType = OASwitchTableViewCell.getIdentifier()
        soundRow.title = localizedString("inclinometer_sound_alert")
        soundRow.setObj(widgetState.soundAlertPref, forKey: "pref")

        let calibrationSection = data.createNewSection()
        calibrationSection.headerText = localizedString("inclinometer_calibration")
        calibrationSection.footerText = localizedString("inclinometer_calibration_applies_to_all")
        let calibrationRow = calibrationSection.createNewRow()
        calibrationRow.cellType = OAValueTableViewCell.getIdentifier()
        calibrationRow.key = Self.calibrationRowKey
        calibrationRow.title = localizedString("inclinometer_calibration")
        calibrationRow.setObj(Self.calibrationStatus(), forKey: "value")

        return data
    }

    override func handleRowSelected(_ item: OATableRowData, viewController: WidgetConfigurationViewController) -> Bool {
        guard item.key == Self.calibrationRowKey else {
            return false
        }
        let sheet = UIAlertController(title: localizedString("inclinometer_calibration"),
                                      message: localizedString("inclinometer_calibration_desc"),
                                      preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: localizedString(sensor.isCalibrated ? "inclinometer_recalibrate" : "inclinometer_calibrate"),
                                      style: .default) { [weak self, weak viewController] _ in
            guard let self, let viewController else { return }
            // the settings screen may be the only reader of the sensor, give it a moment to deliver a value
            self.sensor.requestUpdates(self)
            let saved = self.sensor.calibrate()
            OAUtilities.showToast(localizedString(saved ? "inclinometer_calibration_saved" : "inclinometer_sensor_unavailable"),
                                  details: nil, duration: 2, in: viewController.view)
            viewController.onWidgetStateChanged()
        })
        if sensor.isCalibrated {
            sheet.addAction(UIAlertAction(title: localizedString("inclinometer_reset_calibration"), style: .destructive) { [weak self, weak viewController] _ in
                self?.sensor.resetCalibration()
                viewController?.onWidgetStateChanged()
            })
        }
        sheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        viewController.present(sheet, animated: true)
        return true
    }

    static func calibrationStatus() -> String {
        let sensor = InclinometerSensor.shared
        if !sensor.isSensorAvailable {
            return localizedString("inclinometer_sensor_unavailable")
        }
        guard let offset = sensor.calibrationOffset else {
            return localizedString("inclinometer_not_calibrated")
        }
        let offsetText = String(format: localizedString("inclinometer_calibration_offset"),
                                formatOffset(offset.pitch), formatOffset(offset.roll))
        return String(format: localizedString("ltr_or_rtl_combine_via_bold_point"),
                      localizedString("inclinometer_calibrated"), offsetText)
    }

    static func formatOffset(_ degrees: Float) -> String {
        let rounded = degrees.magnitude < 0.05 ? 0 : degrees
        return String(format: "%.1f°", rounded)
    }

    private func addAngleRow(to section: OATableSectionData, title: String, pref: OACommonLong, appMode: OAApplicationMode,
                             widgetConfigurationParams: [String: Any]?, isCreate: Bool) {
        let row = section.createNewRow()
        row.cellType = OAValueTableViewCell.getIdentifier()
        row.key = "value_pref"
        row.title = title
        row.setObj(pref, forKey: "pref")
        var currentValue = Int(pref.defValue)
        if let param = Self.widgetParam(widgetConfigurationParams, pref: pref) {
            if let value = param as? Int {
                currentValue = value
            } else if let string = param as? String, let value = Int(string) {
                currentValue = value
            }
        } else if !isCreate {
            currentValue = pref.get(appMode)
        }
        row.setObj(Self.formatThreshold(currentValue), forKey: "value")

        let sliderRow = OATableRowData()
        sliderRow.key = "values"
        sliderRow.cellType = OASegmentSliderTableViewCell.getIdentifier()
        sliderRow.title = title
        var values = [Int: String]()
        for angle in InclinometerWidgetState.thresholdAngles {
            values[angle] = Self.formatThreshold(angle)
        }
        sliderRow.setObj(values, forKey: "values")
        row.setObj([sliderRow], forKey: "possible_values")
    }

    private func unitsPossibleValues() -> [OATableRowData] {
        var rows = [OATableRowData]()
        for percent in [false, true] {
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.setObj(percent ? "true" : "false", forKey: "value")
            row.title = localizedString(percent ? "shared_string_percent" : "shared_string_degrees")
            rows.append(row)
        }
        return rows
    }

    private func boolValue(_ pref: OACommonBoolean, appMode: OAApplicationMode,
                           widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> Bool {
        if let param = Self.widgetParam(widgetConfigurationParams, pref: pref) {
            if let value = param as? Bool {
                return value
            }
            if let string = param as? String, let value = Bool(string) {
                return value
            }
        }
        return isCreate ? pref.defValue : pref.get(appMode)
    }

    private static func widgetParam(_ widgetConfigurationParams: [String: Any]?, pref: OACommonPreference) -> Any? {
        guard let widgetConfigurationParams,
              let key = widgetConfigurationParams.keys.first(where: { $0 == pref.key || pref.key.hasPrefix($0) }) else {
            return nil
        }
        return widgetConfigurationParams[key]
    }

    private static func formatThreshold(_ degrees: Int) -> String {
        "\(degrees)°"
    }
}
