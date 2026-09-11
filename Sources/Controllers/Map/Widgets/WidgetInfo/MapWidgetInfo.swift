//
//  MapWidgetInfo.swift
//  OsmAnd Maps
//
//  Created by Paul on 03.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAMapWidgetInfo)
@objcMembers
class MapWidgetInfo: NSObject, Comparable {
    
    static let DELIMITER = "__"
    static let INVALID_ID = 0
    
    static func widgetsVisibility(_ appMode: OAApplicationMode,
                                  screenLayoutMode: NSNumber?) -> [String] {
        let widgetsVisibilityString = visibilityPreference(screenLayoutMode).get(appMode)
        guard !widgetsVisibilityString.isEmpty else {
            return []
        }
        return widgetsVisibilityString.components(separatedBy: SETTINGS_SEPARATOR).filter { !$0.isEmpty }
    }

    private static func visibilityPreference(_ screenLayoutMode: NSNumber?) -> OACommonString {
        OAAppSettings.sharedManager().mapInfoControls(screenLayoutMode)
    }

    let key: String
    let widget: OABaseWidgetView
    let appMode: OAApplicationMode
    let screenLayoutMode: ScreenLayoutMode
    
    var widgetPanel: WidgetsPanel
    var priority: Int
    var pageIndex: Int
    
    private let settingsIconId: String
    private let message: String
    private let widgetState: OAWidgetState?
    
    init(key: String,
         widget: OABaseWidgetView,
         settingsIconId: String,
         message: String,
         page: Int,
         order: Int,
         widgetPanel: WidgetsPanel,
         appMode: OAApplicationMode,
         screenLayoutMode: ScreenLayoutMode) {
        self.key = key
        self.widget = widget
        self.appMode = appMode
        self.screenLayoutMode = screenLayoutMode
        self.widgetState = widget.storedWidgetState()
        self.settingsIconId = settingsIconId
        self.message = message
        self.pageIndex = page
        self.priority = order
        self.widgetPanel = widgetPanel
    }
    
    func isCustomWidget() -> Bool {
        return key.contains(MapWidgetInfo.DELIMITER)
    }
    
    func storedWidgetState() -> OAWidgetState? {
        return widgetState
    }
    
    func getSettingsIconId(nightMode: Bool) -> String {
        if let widgetState, let settingsIconId = widgetState.getSettingsIconId(nightMode) {
            return settingsIconId
        } else {
            return settingsIconId
        }
    }
    
    func getMapIconId(nightMode: Bool) -> String? {
        if let textInfoWidget = widget as? OATextInfoWidget {
            return textInfoWidget.getIconName()
        }
        return nil
    }
    
    func isIconPainted() -> Bool {
        let dayMapIconId = getMapIconId(nightMode: false)
        let nightMapIconId = getMapIconId(nightMode: true)
        let daySettingsIconId = getSettingsIconId(nightMode: false)
        let nightSettingsIconId = getSettingsIconId(nightMode: true)
        if let dayMapIconId, let nightMapIconId {
            return dayMapIconId != nightMapIconId
        } else {
            return daySettingsIconId != nightSettingsIconId
        }
    }
    
    func widgetType() -> WidgetType? {
        widget.widgetType
    }
    
    func isExternal() -> Bool {
        widget.isExternal()
    }
    
    func getTitle() -> String {
        getMessage()
    }
    
    func getStateIndependentTitle() -> String {
        message
    }
    
    func getMessage() -> String {
        widgetState?.getMenuTitle() ?? message
    }
    
    func getWidgetTitle() -> String {
        widgetState?.getWidgetTitle() ?? getMessage()
    }
    
    func getWidgetDefaultTitle() -> String {
        widgetState?.getWidgetDefaultTitle() ?? ""
    }
    
    func resolveTitle(params: [String: Any]?) -> String? {
        let widgetView = widget
        let baseTitle = widgetView.widgetType?.title ?? getTitle()
        let format = localizedString("ltr_or_rtl_combine_via_colon")
        
        func intFromParams(_ key: String) -> Int? {
            guard let params, let rawStr = params[key] as? String, let raw = Int(rawStr) else { return nil }
            return raw
        }
        
        func fallbackTitle() -> String {
            (widgetView as? BaseRecordingWidget)?.getResolvedTitleForList() ?? baseTitle
        }
        
        switch widgetView.widgetType {
        case .tripRecordingDistance:
            if let raw = intFromParams(TripRecordingDistanceWidgetState.prefDistanceModeId) {
                let mode = TripRecordingDistanceMode(rawValue: raw) ?? .totalDistance
                return String(format: format, baseTitle, localizedString(mode.titleKey))
            }
            return fallbackTitle()
        case .tripRecordingUphill, .tripRecordingDownhill:
            if let raw = intFromParams(TripRecordingElevationWidgetState.prefUphillWidgetModeId) {
                let mode = TripRecordingElevationMode(rawValue: raw) ?? .total
                let isUphill = widgetView.widgetType == .tripRecordingUphill
                return String(format: format, baseTitle, localizedString(mode.titleKey(isUphill: isUphill)))
            }
            return fallbackTitle()
        case .tripRecordingAverageSlope:
            if let raw = intFromParams(TripRecordingSlopeWidgetState.prefAverageSlopeModeId) {
                let mode = AverageSlopeMode(rawValue: raw) ?? .lastUphill
                return String(format: format, baseTitle, localizedString(mode.titleKey))
            }
            return fallbackTitle()
        case .tripRecordingMaxSpeed:
            if let raw = intFromParams(TripRecordingMaxSpeedWidgetState.prefMaxSpeedModeId) {
                let mode = MaxSpeedMode(rawValue: raw) ?? .total
                return String(format: format, baseTitle, localizedString(mode.titleKey))
            }
            return fallbackTitle()
        case .tripRecordingMovingTime:
            if let raw = intFromParams(TripRecordingMovingTimeWidgetState.prefMovingTimeModeId) {
                let mode = TripRecordingMovingTimeMode(rawValue: raw) ?? .total
                return String(format: format, baseTitle, localizedString(mode.titleKey))
            }
            return fallbackTitle()
        default:
            return baseTitle
        }
    }
    
    func resolveIconName(params: [String: Any]?) -> String? {
        let widgetView = widget

        func intFromParams(_ key: String) -> Int? {
            guard let params, let string = params[key] as? String, let value = Int(string) else { return nil }
            return value
        }
        
        switch widgetView.widgetType {
        case .sunPosition:
            if let sunState = storedWidgetState() as? OASunriseSunsetWidgetState {
                return sunState.getWidgetIconName()
            }
            return widgetView.widgetType?.iconName
        case .tripRecordingDistance:
            if let raw = intFromParams(TripRecordingDistanceWidgetState.prefDistanceModeId), let mode = TripRecordingDistanceMode(rawValue: raw) {
                return mode.iconName
            }
            return (widgetView as? TripRecordingDistanceWidget)?.getIconName() ?? widgetView.widgetType?.iconName
        case .tripRecordingUphill, .tripRecordingDownhill:
            let isUphill = widgetView.widgetType == .tripRecordingUphill
            if let raw = intFromParams(TripRecordingElevationWidgetState.prefUphillWidgetModeId), let mode = TripRecordingElevationMode(rawValue: raw) {
                return mode.iconName(isUphill: isUphill)
            }
            if isUphill, let uphill = widgetView as? TripRecordingUphillWidget {
                return uphill.getIconName()
            }
            if !isUphill, let downhill = widgetView as? TripRecordingDownhillWidget {
                return downhill.getIconName()
            }
            return widgetView.widgetType?.iconName
        case .tripRecordingAverageSlope:
            if let raw = intFromParams(TripRecordingSlopeWidgetState.prefAverageSlopeModeId), let mode = AverageSlopeMode(rawValue: raw) {
                return mode.iconName
            }
            return (widgetView as? TripRecordingSlopeWidget)?.getIconName() ?? widgetView.widgetType?.iconName
        case .tripRecordingMaxSpeed:
            if let raw = intFromParams(TripRecordingMaxSpeedWidgetState.prefMaxSpeedModeId), let mode = MaxSpeedMode(rawValue: raw) {
                return mode.iconName
            }
            return (widgetView as? TripRecordingMaxSpeedWidget)?.getIconName() ?? widgetView.widgetType?.iconName
        case .tripRecordingMovingTime:
            if let raw = intFromParams(TripRecordingMovingTimeWidgetState.prefMovingTimeModeId), let mode = TripRecordingMovingTimeMode(rawValue: raw) {
                return mode.iconName
            }
            return (widgetView as? TripRecordingMovingTimeWidget)?.getIconName() ?? widgetView.widgetType?.iconName
        default:
            return widgetView.widgetType?.iconName
        }
    }
    
    func getExternalProviderPackage() -> String? {
        nil
    }
    
    func getUpdatedPanel() -> WidgetsPanel {
        let screenLayoutMode = OAAppSettings.sharedManager().useSeparateLayouts.get(appMode)
            ? NSNumber(value: self.screenLayoutMode.rawValue)
            : nil
        return getUpdatedPanel(appMode, screenLayoutMode: screenLayoutMode)
    }

    func getUpdatedPanel(_ appMode: OAApplicationMode,
                         screenLayoutMode: NSNumber?) -> WidgetsPanel {
        fatalError("Subclass must override")
    }
    
    func isEnabledForAppMode(_ appMode: OAApplicationMode) -> Bool {
        let screenLayoutMode = OAAppSettings.sharedManager().useSeparateLayouts.get(appMode)
            ? NSNumber(value: self.screenLayoutMode.rawValue)
            : nil
        return isEnabledForAppMode(appMode, screenLayoutMode: screenLayoutMode)
    }

    func isEnabledForAppMode(_ appMode: OAApplicationMode, screenLayoutMode: NSNumber?) -> Bool {
        isEnabledForAppMode(appMode,
                            widgetsVisibility: Self.widgetsVisibility(appMode,
                                                                      screenLayoutMode: screenLayoutMode))
    }

    func isEnabledForAppMode(_ appMode: OAApplicationMode, widgetsVisibility: [String]) -> Bool {
        if widgetsVisibility.contains(key) || widgetsVisibility.contains(COLLAPSED_PREFIX + key) {
            return true
        } else if widgetsVisibility.contains(HIDE_PREFIX + key) {
            return false
        }
        return WidgetsAvailabilityHelper.isWidgetVisibleByDefault(widgetId: key, appMode: appMode)
    }
    
    func getSettingsData(_ appMode: OAApplicationMode, _ widgetConfigurationParams: [String: Any]?, isCreate: Bool) -> OATableDataModel? {
        widget.getSettingsData(appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
    }
    
    func getSettingsDataForSimpleWidget(_ appMode: OAApplicationMode, widgetsPanel: WidgetsPanel, _ widgetConfigurationParams: [String: Any]?) -> OATableDataModel? {
        widget.getSettingsData(forSimpleWidget: appMode, widgetsPanel: widgetsPanel, widgetConfigurationParams: widgetConfigurationParams)
    }
    
    func handleRowSelected(_ item: OATableRowData, viewController: WidgetConfigurationViewController) -> Bool {
        return widget.handleRowSelected(item, viewController: viewController)
    }
    
    func enableDisableForMode(_ appMode: OAApplicationMode, enabled: NSNumber?) {
        let screenLayoutMode = OAAppSettings.sharedManager().useSeparateLayouts.get(appMode)
            ? NSNumber(value: self.screenLayoutMode.rawValue)
            : nil
        enableDisableForMode(appMode, enabled: enabled, screenLayoutMode: screenLayoutMode)
    }

    func enableDisableForMode(_ appMode: OAApplicationMode,
                              enabled: NSNumber?,
                              screenLayoutMode: NSNumber?) {
        var widgetsVisibility = Self.widgetsVisibility(appMode,
                                                       screenLayoutMode: screenLayoutMode)
        widgetsVisibility.removeAll(where: { $0 == key })
        widgetsVisibility.removeAll(where: { $0 == HIDE_PREFIX + key })
        widgetsVisibility.removeAll(where: { $0 == COLLAPSED_PREFIX + key })

        if let enabled, (!isCustomWidget() || enabled.boolValue) {
            widgetsVisibility.append(enabled.boolValue ? key : HIDE_PREFIX + key)
        }

        var newVisibilityString = ""
        for visibility in widgetsVisibility {
            newVisibilityString.append(visibility + SETTINGS_SEPARATOR)
        }

        Self.visibilityPreference(screenLayoutMode).set(newVisibilityString, mode: appMode)

        if let settingsPref = widget.getWidgetSettingsPref(toReset: appMode),
           enabled == nil || enabled?.boolValue == false {
            settingsPref.resetMode(toDefault: appMode)
        }
    }

    override func isEqual(_ obj: Any?) -> Bool {
        guard let other = obj as? MapWidgetInfo else {
            return false
        }
        return key == other.key && getMessage() == other.getMessage()
    }
    
    override var hash: Int {
        var hasher = Hasher()
        hasher.combine(message)
        hasher.combine(key)
        hasher.combine(widget)
        hasher.combine(priority)
        hasher.combine(pageIndex)
        hasher.combine(widgetPanel)
        return hasher.finalize()
    }

    static func < (lhs: MapWidgetInfo, rhs: MapWidgetInfo) -> Bool {
        if lhs.isEqual(rhs) {
            return false
        }
        if lhs.pageIndex != rhs.pageIndex {
            return lhs.pageIndex < rhs.pageIndex
        }
        if lhs.priority != rhs.priority {
            return lhs.priority < rhs.priority
        }
        if lhs.key != rhs.key {
            return lhs.key < rhs.key
        }
        return lhs.message < rhs.message
    }

    override var description: String {
        return key
    }
}
