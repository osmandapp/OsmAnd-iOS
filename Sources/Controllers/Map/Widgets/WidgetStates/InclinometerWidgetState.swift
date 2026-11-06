//
//  InclinometerWidgetState.swift
//  OsmAnd Maps
//
//  Created by Eugene Zmeuk on 02.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAInclinometerWidgetState)
@objcMembers
final class InclinometerWidgetState: OAWidgetState {

    static let thresholdAngles: [Int] = Array(stride(from: 5, through: 60, by: 5))

    private static let percentUnitsSuffix = "_percent_units"
    private static let warningAngleSuffix = "_warning_angle"
    private static let criticalAngleSuffix = "_critical_angle"
    private static let soundAlertSuffix = "_sound_alert"

    private static let defaultPitchWarningAngle = 25
    private static let defaultPitchCriticalAngle = 35
    private static let defaultRollWarningAngle = 20
    private static let defaultRollCriticalAngle = 30

    let widgetType: WidgetType
    let percentUnitsPref: OACommonBoolean
    let warningAnglePref: OACommonLong
    let criticalAnglePref: OACommonLong
    let soundAlertPref: OACommonBoolean

    init(widgetType: WidgetType, customId: String?, widgetParams: ([String: Any])? = nil) {
        self.widgetType = widgetType
        percentUnitsPref = Self.registerBoolPref(Self.prefId(widgetType, Self.percentUnitsSuffix, customId: customId),
                                                 baseId: Self.prefId(widgetType, Self.percentUnitsSuffix, customId: nil),
                                                 defValue: false, widgetParams: widgetParams)
        warningAnglePref = Self.registerAnglePref(Self.prefId(widgetType, Self.warningAngleSuffix, customId: customId),
                                                  baseId: Self.prefId(widgetType, Self.warningAngleSuffix, customId: nil),
                                                  defValue: widgetType == .inclinometerPitch ? Self.defaultPitchWarningAngle : Self.defaultRollWarningAngle,
                                                  widgetParams: widgetParams)
        criticalAnglePref = Self.registerAnglePref(Self.prefId(widgetType, Self.criticalAngleSuffix, customId: customId),
                                                   baseId: Self.prefId(widgetType, Self.criticalAngleSuffix, customId: nil),
                                                   defValue: widgetType == .inclinometerPitch ? Self.defaultPitchCriticalAngle : Self.defaultRollCriticalAngle,
                                                   widgetParams: widgetParams)
        soundAlertPref = Self.registerBoolPref(Self.prefId(widgetType, Self.soundAlertSuffix, customId: customId),
                                               baseId: Self.prefId(widgetType, Self.soundAlertSuffix, customId: nil),
                                               defValue: false, widgetParams: widgetParams)
    }

    override func getMenuTitle() -> String {
        widgetType.title
    }

    override func getSettingsIconId(_ night: Bool) -> String {
        widgetType.iconName
    }

    override func changeToNextState() {
        percentUnitsPref.set(!percentUnitsPref.get())
    }

    override func copyPrefs(_ appMode: OAApplicationMode, customId: String?) {
        copyPrefs(from: appMode, appMode: appMode, customId: customId)
    }

    override func copyPrefs(from fromAppMode: OAApplicationMode,
                            appMode toAppMode: OAApplicationMode,
                            customId: String?) {
        let copy = InclinometerWidgetState(widgetType: widgetType, customId: customId)
        copy.percentUnitsPref.set(percentUnitsPref.get(fromAppMode), mode: toAppMode)
        copy.warningAnglePref.set(warningAnglePref.get(fromAppMode), mode: toAppMode)
        copy.criticalAnglePref.set(criticalAnglePref.get(fromAppMode), mode: toAppMode)
        copy.soundAlertPref.set(soundAlertPref.get(fromAppMode), mode: toAppMode)
    }

    // The critical angle is kept at or above the warning angle
    func criticalAngle(_ appMode: OAApplicationMode? = nil) -> Int {
        let warning = appMode != nil ? warningAnglePref.get(appMode!) : warningAnglePref.get()
        let critical = appMode != nil ? criticalAnglePref.get(appMode!) : criticalAnglePref.get()
        return max(warning, critical)
    }

    private static func prefId(_ widgetType: WidgetType, _ suffix: String, customId: String?) -> String {
        let prefId = widgetType.id + suffix
        if let customId, !customId.isEmpty {
            return prefId + "_" + customId
        }
        return prefId
    }

    // A new widget is created with the values chosen on its settings screen, keyed by the preference id
    private static func widgetParam(_ widgetParams: ([String: Any])?, baseId: String) -> Any? {
        guard let widgetParams, let key = widgetParams.keys.first(where: { $0.hasPrefix(baseId) }) else {
            return nil
        }
        return widgetParams[key]
    }

    private static func registerBoolPref(_ prefId: String, baseId: String, defValue: Bool, widgetParams: ([String: Any])?) -> OACommonBoolean {
        let preference = OAAppSettings.sharedManager().registerBooleanPreference(prefId, defValue: defValue).makeProfile()
        if let param = widgetParam(widgetParams, baseId: baseId) {
            if let value = param as? Bool {
                preference.set(value)
            } else if let string = param as? String, let value = Bool(string) {
                preference.set(value)
            }
        }
        return preference
    }

    private static func registerAnglePref(_ prefId: String, baseId: String, defValue: Int, widgetParams: ([String: Any])?) -> OACommonLong {
        let preference = OAAppSettings.sharedManager().registerLongPreference(prefId, defValue: defValue).makeProfile()
        if let param = widgetParam(widgetParams, baseId: baseId) {
            if let value = param as? Int {
                preference.set(value)
            } else if let string = param as? String, let value = Int(string) {
                preference.set(value)
            }
        }
        return preference
    }
}
