//
//  RouteInfoWidget.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 07.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class RouteInfoWidget: OASimpleWidget {
    private let oneHundredKmInMeters = 100_000
    private let hourInMilliseconds = 60 * 60 * 1000
    
    private var customId: String?
    private var widgetState: RouteInfoWidgetState
    private var defaultViewPref: OACommonWidgetDefaultView
    private var displayPriorityPref: OACommonWidgetDisplayPriority
    
    convenience init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        self.customId = customId
        widgetState = RouteInfoWidgetState(customId: customId, widgetParams: widgetParams)
        defaultViewPref = widgetState.defaultViewPref
        displayPriorityPref = widgetState.displayPriorityPref
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
    }
    
    override init(frame: CGRect) {
        let widgetState = RouteInfoWidgetState(customId: "", widgetParams: nil)
        self.widgetState = widgetState
        defaultViewPref = widgetState.defaultViewPref
        displayPriorityPref = widgetState.displayPriorityPref
        super.init(frame: frame)
        widgetType = .routeInfo
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String: Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let defaultViewState = widgetState.getDefaultView(appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
        let defaultViewRow = section.createNewRow()
        defaultViewRow.cellType = OAValueTableViewCell.getIdentifier()
        defaultViewRow.key = "value_pref"
        defaultViewRow.title = localizedString("shared_string_default_view")
        defaultViewRow.iconName = defaultViewState?.iconName ?? ""
        defaultViewRow.setObj(defaultViewPref, forKey: "pref")
        defaultViewRow.setObj(defaultViewState?.title ?? "", forKey: "value")
        defaultViewRow.setObj(getPossibleDefaultPrefValues(appMode), forKey: "possible_values")
        
        let displayPrioriyState = widgetState.getDisplayPriority(appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
        let displayPriorityRow = section.createNewRow()
        displayPriorityRow.cellType = OAButtonTableViewCell.getIdentifier()
        displayPriorityRow.title = localizedString("display_priority")
        displayPriorityRow.iconName = displayPrioriyState?.iconName ?? ""
        displayPriorityRow.setObj(displayPriorityPref, forKey: "pref")
        displayPriorityRow.setObj(displayPrioriyState?.key ?? "", forKey: "value")
        return data
    }
    
    override func getWidgetState() -> OAWidgetState? {
        widgetState
    }
    
    private func getPossibleDefaultPrefValues(_ appMode: OAApplicationMode) -> [OATableRowData] {
        var rows = [OATableRowData]()
        for mode in DisplayValue.allCases {
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.setObj(mode.key, forKey: "value")
            row.title = mode.title
            row.descr = getDescriptionWith(displayValue: mode)
            rows.append(row)
        }
        return rows
    }
    
    private func getDescriptionWith(displayValue: DisplayValue) -> String {
        var previewData: [DisplayValue: String] = [:]
        previewData[.arrivalTime] = getFormattedPreviewArrivalTime()
        previewData[.timeToGo] = formatDuration(timeLeft: hourInMilliseconds)
        previewData[.distance] = formatDistanceWith(meters: Float(oneHundredKmInMeters))
        return getDefaultViewSummary(defaultView: displayValue, previewData: previewData)
    }
    
    private func getDefaultViewSummary(defaultView: DisplayValue, previewData: [DisplayValue: String]) -> String {
        var fullText = ""

        for displayValue in DisplayValue.getValues(with: defaultView) {
            guard let value = previewData[displayValue] else { continue }
            fullText = fullText.isEmpty ? value : String(format: "%@ • %@", fullText, value)
        }

        return fullText
    }
    
    private func getFormattedPreviewArrivalTime() -> String {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 13
        components.minute = 0
        components.second = 0
        components.nanosecond = 0
        let date = calendar.date(from: components)!
        return formatArrivalTime(time: date.timeIntervalSince1970)
    }
    
    private func formatArrivalTime(time: Double) -> String {
        let toFindTime = TimeInterval(time)
        let dateFormatter = DateFormatter()
        let toFindDate = Date(timeIntervalSince1970: toFindTime)
        if !OAUtilities.is12HourTimeFormat() {
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: toFindDate)
        } else {
            dateFormatter.dateFormat = "h:mm"
            let timeStr = dateFormatter.string(from: toFindDate)
            dateFormatter.dateFormat = "a"
            let aStr = dateFormatter.string(from: toFindDate)
            return String(format: localizedString("ltr_or_rtl_combine_via_space"), timeStr, aStr)
        }
    }
    
    private func formatDuration(timeLeft: Int) -> String {
        OAOsmAndFormatter.getFormattedDuration(TimeInterval(timeLeft / 1000))
    }
    
    private func formatDistanceWith(meters: Float) -> String {
        OAOsmAndFormatter.getFormattedDistance(meters)
    }

    override func isEnabledShowIcon() -> Bool {
        false
    }
}
