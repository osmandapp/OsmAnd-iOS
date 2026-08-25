//
//  WidgetPanelAppearance.swift
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 14.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

enum WidgetPanelSizeMode: String, CaseIterable {
    case original = "ORIGINAL"
    case small = "SMALL"
    case medium = "MEDIUM"
    case large = "LARGE"

    var title: String {
        switch self {
        case .original: localizedString("shared_string_original")
        case .small: localizedString("rendering_value_small_name")
        case .medium: localizedString("rendering_value_medium_name")
        case .large: localizedString("shared_string_large")
        }
    }

    var icon: UIImage {
        switch self {
        case .original, .medium: .icCustom20HeightM
        case .small: .icCustom20HeightS
        case .large: .icCustom20HeightL
        }
    }

    var widgetSizeStyle: EOAWidgetSizeStyle? {
        switch self {
        case .original: nil
        case .small: .small
        case .medium: .medium
        case .large: .large
        }
    }
}

enum WidgetPanelIconMode: String, CaseIterable {
    case original = "ORIGINAL"
    case off = "OFF"
    case on = "ON"

    var title: String {
        switch self {
        case .original: localizedString("shared_string_original")
        case .on: localizedString("shared_string_on")
        case .off: localizedString("shared_string_off")
        }
    }
}

enum WidgetPanelTextColorKind: String {
    case primary
    case secondary
}

enum WidgetPanelTextColorMode: String, CaseIterable {
    case `default` = "DEFAULT"
    case automatic = "AUTOMATIC"
    case custom = "CUSTOM"

    var title: String {
        switch self {
        case .default: localizedString("shared_string_default")
        case .automatic: localizedString("shared_string_automatic")
        case .custom: localizedString("shared_string_custom")
        }
    }
}

enum WidgetPanelBackgroundMode: String, CaseIterable {
    case `default` = "DEFAULT"
    case transparent = "TRANSPARENT"
    case custom = "CUSTOM"

    var title: String {
        switch self {
        case .default: localizedString("shared_string_default")
        case .transparent: localizedString("shared_string_transparent")
        case .custom: localizedString("shared_string_custom")
        }
    }
}

enum WidgetPanelColorTarget {
    case primaryText
    case secondaryText
    case background
}

final class WidgetPanelAppearanceSettings {
    // Identifiers and enum raw values are part of the cross-platform profile export format.
    private enum ModePreference: String {
        case size
        case icon
        case primaryTextColor = "text_color"
        case secondaryTextColor = "secondary_text_color"
        case background
    }

    private let appMode: OAApplicationMode
    private let settings = OAAppSettings.sharedManager()

    init(appMode: OAApplicationMode) {
        self.appMode = appMode
    }

    static func defaultColor(for target: WidgetPanelColorTarget,
                             panel: WidgetsPanel,
                             nightMode: Bool) -> UIColor {
        let color: UIColor
        switch target {
        case .primaryText:
            color = panel.isPanelVertical ? .textColorPrimary : .widgetValue
        case .secondaryText:
            color = .textColorSecondary
        case .background:
            color = .widgetBg
        }
        let style: UIUserInterfaceStyle = nightMode ? .dark : .light
        return color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
    }

    func sizeMode(for panel: WidgetsPanel) -> WidgetPanelSizeMode {
        sizeMode(for: panel, appMode: appMode)
    }

    func setSizeMode(_ mode: WidgetPanelSizeMode, for panel: WidgetsPanel) {
        modePreference(.size, panel: panel, defaultValue: WidgetPanelSizeMode.original.rawValue)
            .set(mode.rawValue, mode: appMode)
    }

    func iconMode(for panel: WidgetsPanel) -> WidgetPanelIconMode {
        iconMode(for: panel, appMode: appMode)
    }

    func setIconMode(_ mode: WidgetPanelIconMode, for panel: WidgetsPanel) {
        modePreference(.icon, panel: panel, defaultValue: WidgetPanelIconMode.original.rawValue)
            .set(mode.rawValue, mode: appMode)
    }

    func primaryTextColorMode(for panel: WidgetsPanel) -> WidgetPanelTextColorMode {
        textColorMode(.primary, panel: panel)
    }

    func secondaryTextColorMode(for panel: WidgetsPanel) -> WidgetPanelTextColorMode {
        textColorMode(.secondary, panel: panel)
    }

    func setTextColorMode(_ mode: WidgetPanelTextColorMode,
                          kind: WidgetPanelTextColorKind,
                          for panel: WidgetsPanel) {
        let preference: ModePreference = kind == .primary ? .primaryTextColor : .secondaryTextColor
        modePreference(preference, panel: panel, defaultValue: WidgetPanelTextColorMode.default.rawValue)
            .set(mode.rawValue, mode: appMode)
    }

    func backgroundMode(for panel: WidgetsPanel) -> WidgetPanelBackgroundMode {
        backgroundMode(for: panel, appMode: appMode)
    }

    func setBackgroundMode(_ mode: WidgetPanelBackgroundMode, for panel: WidgetsPanel) {
        modePreference(.background, panel: panel, defaultValue: WidgetPanelBackgroundMode.default.rawValue)
            .set(mode.rawValue, mode: appMode)
    }

    func color(for target: WidgetPanelColorTarget, panel: WidgetsPanel, nightMode: Bool) -> UIColor {
        color(for: target, panel: panel, appMode: appMode, nightMode: nightMode)
    }

    func setColor(_ color: UIColor,
                  for target: WidgetPanelColorTarget,
                  panel: WidgetsPanel,
                  nightMode: Bool) {
        colorPreference(target, panel: panel, nightMode: nightMode)
            .set(Int32(truncatingIfNeeded: color.toARGBNumber()), mode: appMode)
    }

    func setCustomColor(_ color: UIColor,
                        for target: WidgetPanelColorTarget,
                        panel: WidgetsPanel,
                        nightMode: Bool) {
        setColor(color, for: target, panel: panel, nightMode: nightMode)
        switch target {
        case .primaryText:
            setTextColorMode(.custom, kind: .primary, for: panel)
        case .secondaryText:
            setTextColorMode(.custom, kind: .secondary, for: panel)
        case .background:
            setBackgroundMode(.custom, for: panel)
        }
    }

    func reset(panel: WidgetsPanel) {
        allPreferences(panel: panel).forEach { $0.resetMode(toDefault: appMode) }
    }

    func copy(from sourcePanel: WidgetsPanel, to targetPanel: WidgetsPanel) {
        copy(from: appMode, sourcePanel: sourcePanel, to: targetPanel)
    }

    func copy(from sourceAppMode: OAApplicationMode, panel: WidgetsPanel) {
        copy(from: sourceAppMode, sourcePanel: panel, to: panel)
    }

    private func textColorMode(_ kind: WidgetPanelTextColorKind,
                               panel: WidgetsPanel) -> WidgetPanelTextColorMode {
        textColorMode(kind, panel: panel, appMode: appMode)
    }

    private func textColorMode(_ kind: WidgetPanelTextColorKind,
                               panel: WidgetsPanel,
                               appMode: OAApplicationMode) -> WidgetPanelTextColorMode {
        let preference: ModePreference = kind == .primary ? .primaryTextColor : .secondaryTextColor
        let value = modePreference(preference,
                                   panel: panel,
                                   defaultValue: WidgetPanelTextColorMode.default.rawValue).get(appMode)
        return WidgetPanelTextColorMode(rawValue: value) ?? .default
    }

    private func copy(from sourceAppMode: OAApplicationMode,
                      sourcePanel: WidgetsPanel,
                      to targetPanel: WidgetsPanel) {
        setSizeMode(sizeMode(for: sourcePanel, appMode: sourceAppMode), for: targetPanel)
        setIconMode(iconMode(for: sourcePanel, appMode: sourceAppMode), for: targetPanel)
        setTextColorMode(textColorMode(.primary, panel: sourcePanel, appMode: sourceAppMode),
                         kind: .primary,
                         for: targetPanel)
        setTextColorMode(textColorMode(.secondary, panel: sourcePanel, appMode: sourceAppMode),
                         kind: .secondary,
                         for: targetPanel)
        setBackgroundMode(backgroundMode(for: sourcePanel, appMode: sourceAppMode), for: targetPanel)

        for target in [WidgetPanelColorTarget.primaryText, .secondaryText, .background] {
            for nightMode in [false, true] {
                let color = color(for: target,
                                  panel: sourcePanel,
                                  appMode: sourceAppMode,
                                  nightMode: nightMode)
                colorPreference(target, panel: targetPanel, nightMode: nightMode)
                    .set(Int32(truncatingIfNeeded: color.toARGBNumber()), mode: appMode)
            }
        }
    }

    private func sizeMode(for panel: WidgetsPanel, appMode: OAApplicationMode) -> WidgetPanelSizeMode {
        let value = modePreference(.size,
                                   panel: panel,
                                   defaultValue: WidgetPanelSizeMode.original.rawValue).get(appMode)
        return WidgetPanelSizeMode(rawValue: value) ?? .original
    }

    private func iconMode(for panel: WidgetsPanel, appMode: OAApplicationMode) -> WidgetPanelIconMode {
        let value = modePreference(.icon,
                                   panel: panel,
                                   defaultValue: WidgetPanelIconMode.original.rawValue).get(appMode)
        return WidgetPanelIconMode(rawValue: value) ?? .original
    }

    private func backgroundMode(for panel: WidgetsPanel,
                                appMode: OAApplicationMode) -> WidgetPanelBackgroundMode {
        let preference = modePreference(.background,
                                        panel: panel,
                                        defaultValue: WidgetPanelBackgroundMode.default.rawValue)
        if !preference.isSet(for: appMode), settings.transparentMapTheme.get(appMode) {
            return .transparent
        }
        return WidgetPanelBackgroundMode(rawValue: preference.get(appMode)) ?? .default
    }

    private func color(for target: WidgetPanelColorTarget,
                       panel: WidgetsPanel,
                       appMode: OAApplicationMode,
                       nightMode: Bool) -> UIColor {
        UIColor(argb: Int(colorPreference(target, panel: panel, nightMode: nightMode).get(appMode)))
    }

    private func allPreferences(panel: WidgetsPanel) -> [OACommonPreference] {
        [
            modePreference(.size, panel: panel, defaultValue: WidgetPanelSizeMode.original.rawValue),
            modePreference(.icon, panel: panel, defaultValue: WidgetPanelIconMode.original.rawValue),
            modePreference(.primaryTextColor,
                           panel: panel,
                           defaultValue: WidgetPanelTextColorMode.default.rawValue),
            modePreference(.secondaryTextColor,
                           panel: panel,
                           defaultValue: WidgetPanelTextColorMode.default.rawValue),
            modePreference(.background, panel: panel, defaultValue: WidgetPanelBackgroundMode.default.rawValue),
            colorPreference(.primaryText, panel: panel, nightMode: false),
            colorPreference(.primaryText, panel: panel, nightMode: true),
            colorPreference(.secondaryText, panel: panel, nightMode: false),
            colorPreference(.secondaryText, panel: panel, nightMode: true),
            colorPreference(.background, panel: panel, nightMode: false),
            colorPreference(.background, panel: panel, nightMode: true)
        ]
    }

    private func modePreference(_ preference: ModePreference,
                                panel: WidgetsPanel,
                                defaultValue: String) -> OACommonString {
        settings.registerStringPreference("widget_panel_\(preference.rawValue)_mode_\(panel.preferenceSuffix)",
                                          defValue: defaultValue).makeProfile()
    }

    private func colorPreference(_ target: WidgetPanelColorTarget,
                                 panel: WidgetsPanel,
                                 nightMode: Bool) -> OACommonInteger {
        let key: String
        switch target {
        case .primaryText: key = "text_color"
        case .secondaryText: key = "secondary_text_color"
        case .background: key = "background_color"
        }
        let theme = nightMode ? "night" : "day"
        let defaultColor = Self.defaultColor(for: target, panel: panel, nightMode: nightMode)
        return settings.registerIntPreference("widget_panel_\(key)_\(theme)_\(panel.preferenceSuffix)",
                                              defValue: Int32(truncatingIfNeeded: defaultColor.toARGBNumber()))
            .makeProfile()
    }
}

@objc(OAResolvedWidgetPanelAppearance) final class ResolvedWidgetPanelAppearance: NSObject {
    @objc let primaryTextColor: UIColor
    @objc let secondaryTextColor: UIColor
    @objc let backgroundColor: UIColor
    @objc let dividerColor: UIColor
    @objc let textOutlineColor: UIColor
    @objc let textOutlineWidth: CGFloat
    @objc let transparent: Bool

    init(primaryTextColor: UIColor,
         secondaryTextColor: UIColor,
         backgroundColor: UIColor,
         dividerColor: UIColor,
         textOutlineColor: UIColor,
         textOutlineWidth: CGFloat,
         transparent: Bool) {
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.backgroundColor = backgroundColor
        self.dividerColor = dividerColor
        self.textOutlineColor = textOutlineColor
        self.textOutlineWidth = textOutlineWidth
        self.transparent = transparent
    }
}

@objc(OAWidgetPanelAppearanceResolver) final class WidgetPanelAppearanceResolver: NSObject {
    @objc(resolveForPanel:appMode:nightMode:) static func resolve(
        panel: WidgetsPanel,
        appMode: OAApplicationMode,
        nightMode: Bool
    ) -> ResolvedWidgetPanelAppearance {
        let settings = WidgetPanelAppearanceSettings(appMode: appMode)
        let backgroundMode = settings.backgroundMode(for: panel)
        let transparent = backgroundMode == .transparent
        var backgroundColor = WidgetPanelAppearanceSettings.defaultColor(for: .background,
                                                                         panel: panel,
                                                                         nightMode: nightMode)
        if transparent {
            backgroundColor = .clear
        } else if backgroundMode == .custom {
            backgroundColor = settings.color(for: .background, panel: panel, nightMode: nightMode)
        }

        let accents = dynamicAccents(for: backgroundColor)
        let primaryTextColor: UIColor
        switch settings.primaryTextColorMode(for: panel) {
        case .default:
            primaryTextColor = WidgetPanelAppearanceSettings.defaultColor(for: .primaryText,
                                                                          panel: panel,
                                                                          nightMode: nightMode)
        case .automatic:
            primaryTextColor = transparent
                ? WidgetPanelAppearanceSettings.defaultColor(for: .primaryText,
                                                             panel: panel,
                                                             nightMode: nightMode)
                : accents.primary
        case .custom:
            primaryTextColor = settings.color(for: .primaryText, panel: panel, nightMode: nightMode)
        }

        let secondaryTextColor: UIColor
        switch settings.secondaryTextColorMode(for: panel) {
        case .default:
            secondaryTextColor = WidgetPanelAppearanceSettings.defaultColor(for: .secondaryText,
                                                                            panel: panel,
                                                                            nightMode: nightMode)
        case .automatic:
            secondaryTextColor = transparent
                ? WidgetPanelAppearanceSettings.defaultColor(for: .secondaryText,
                                                             panel: panel,
                                                             nightMode: nightMode)
                : accents.secondary
        case .custom:
            secondaryTextColor = settings.color(for: .secondaryText, panel: panel, nightMode: nightMode)
        }

        let dividerColor = transparent
            ? WidgetPanelAppearanceSettings.defaultColor(for: .secondaryText,
                                                         panel: panel,
                                                         nightMode: nightMode).withAlphaComponent(0.2)
            : accents.divider
        let opaqueBackground = backgroundColor.cgColor.alpha >= 0.999
        let textOutlineColor: UIColor = isLight(primaryTextColor) ? .black : .white
        return ResolvedWidgetPanelAppearance(primaryTextColor: primaryTextColor,
                                             secondaryTextColor: secondaryTextColor,
                                             backgroundColor: backgroundColor,
                                             dividerColor: dividerColor,
                                             textOutlineColor: textOutlineColor,
                                             textOutlineWidth: opaqueBackground ? 0 : 4,
                                             transparent: transparent)
    }

    private static func dynamicAccents(for backgroundColor: UIColor) -> (primary: UIColor,
                                                                          secondary: UIColor,
                                                                          divider: UIColor) {
        let useWhite = !isLight(backgroundColor)
        let primary: UIColor = useWhite ? .white : .black
        return (primary, primary.withAlphaComponent(0.6), primary.withAlphaComponent(useWhite ? 0.2 : 0.1))
    }

    private static func isLight(_ color: UIColor) -> Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: nil) else { return false }
        func linear(_ component: CGFloat) -> CGFloat {
            component <= 0.03928 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue) > 0.5
    }
}

extension WidgetsPanel {
    var preferenceSuffix: String {
        if self == .leftPanel { return "left" }
        if self == .rightPanel { return "right" }
        if self == .topPanel { return "top" }
        return "bottom"
    }
}
