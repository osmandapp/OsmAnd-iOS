//
//  RouteInfoWidget.swift
//  OsmAnd
//
//  Created by Vladyslav Lysenko on 07.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class RouteInfoWidget: OASimpleWidget {
    @IBOutlet private var firstLineLeftLabel: OutlineLabel!
    @IBOutlet private var secondLineLeftLabel: OutlineLabel!
    @IBOutlet private var firstLineRightLabel: OutlineLabel!
    @IBOutlet private var secondLineRightLabel: OutlineLabel!
    @IBOutlet private var secondaryBlockStackView: UIStackView!
    @IBOutlet private var secondaryDividerView: UIView!
    @IBOutlet private var navigationButtonView: UIView!
    @IBOutlet private var buttonArrowImageView: UIImageView!
    @IBOutlet private var leftViewButtonWidthConstraint: NSLayoutConstraint!
    @IBOutlet private var leftViewButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet private var leftViewButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var secondLineBottomConstraint: NSLayoutConstraint!
    @IBOutlet private var widgetHeightConstraint: NSLayoutConstraint!
    @IBOutlet private var trailingConstraint: NSLayoutConstraint!
    @IBOutlet private var showButton: UIButton!
    
    private static let oneHundredKmInMeters: Int32 = 100_000
    private static let hourInSeconds: TimeInterval = 60 * 60
    
    private var customId: String?
    private var widgetState: RouteInfoWidgetState
    private var defaultViewPref: OACommonWidgetDefaultView
    private var displayPriorityPref: OACommonWidgetDisplayPriority
    private var isForceUpdate: Bool
    private var cachedRouteInfo: [DestinationInfo] = []
    private var cachedDefaultView: RouteInfoDisplayValue?
    private var cachedDisplayPriority: RouteInfoDisplayPriority?
    private var hasSecondaryData: Bool
    private var cachedMetricSystem: Int?
    private let calculator: RouteInfoCalculator
    private let updateIntervalSeconds = TimeInterval(TimeToNavigationPointWidget.UPDATE_INTERVAL_SECONDS)
    // swiftlint:disable force_unwrapping
    private let settings = OAAppSettings.sharedManager()!
    private lazy var widgetView = Bundle.main.loadNibNamed("RouteInfoWidget", owner: self, options: nil)![0] as! UIView
    // swiftlint:enable force_unwrapping
    
    private var hasSecondaryDataValue: Bool {
        cachedRouteInfo.count > 1
    }
    
    private var hasEnoughWidth: Bool {
        frame.size.width > 250
    }
    
    private var trailingSpace: CGFloat {
        !hasEnoughWidth ? 6 : 16
    }
    
    private var minValueFontSize: CGFloat {
        !hasEnoughWidth && isSmallSize ? 14 : 16
    }
    
    private var valueTextColor: UIColor {
        isNightMode() ? .white : .black
    }
    
    private var isSmallSize: Bool {
        widgetSizeStyle == .small
    }
    
    convenience init(customId: String?, appMode: OAApplicationMode, widgetParams: ([String: Any])? = nil) {
        self.init(frame: .zero)
        self.customId = customId
        widgetState = RouteInfoWidgetState(customId: customId, widgetParams: widgetParams)
        defaultViewPref = widgetState.defaultViewPref
        displayPriorityPref = widgetState.displayPriorityPref
        configurePrefs(withId: customId, appMode: appMode, widgetParams: widgetParams)
        updateVisibility(false)
    }
    
    override init(frame: CGRect) {
        let widgetState = RouteInfoWidgetState(customId: "", widgetParams: nil)
        self.widgetState = widgetState
        defaultViewPref = widgetState.defaultViewPref
        displayPriorityPref = widgetState.displayPriorityPref
        isForceUpdate = true
        calculator = RouteInfoCalculator()
        hasSecondaryData = false
        super.init(frame: frame)
        widgetType = .routeInfo
        layoutWidget()
        showButton.menu = configureContextWidgetMenu()
        updateHeightConstraint(widgetHeightConstraint)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let leftViewButtonVerticalSpace = leftViewButtonVerticalSpace
        leftViewButtonWidthConstraint.constant = leftViewButtonWidth
        leftViewButtonTopConstraint.constant = leftViewButtonVerticalSpace
        leftViewButtonBottomConstraint.constant = leftViewButtonVerticalSpace
        trailingConstraint.constant = trailingSpace
        secondLineBottomConstraint.constant = secondLineBottomSpace
        secondaryBlockStackView.isHidden = !hasEnoughWidth || cachedRouteInfo.count < 2
        forceUpdateView()
    }
    
    override func getSettingsData(_ appMode: OAApplicationMode,
                                  widgetConfigurationParams: [String: Any]?,
                                  isCreate: Bool) -> OATableDataModel? {
        let data = OATableDataModel()
        let section = data.createNewSection()
        section.headerText = localizedString("shared_string_settings")
        let defaultViewState = widgetState.getDefaultView(with: appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
        let defaultViewRow = section.createNewRow()
        defaultViewRow.cellType = OAValueTableViewCell.getIdentifier()
        defaultViewRow.key = "value_pref"
        defaultViewRow.title = localizedString("shared_string_default_view")
        defaultViewRow.iconName = defaultViewState.iconName
        defaultViewRow.setObj(defaultViewPref, forKey: "pref")
        defaultViewRow.setObj(defaultViewState.title, forKey: "value")
        defaultViewRow.setObj(getPossibleDefaultPrefValues(with: appMode), forKey: "possible_values")
        
        let displayPrioriyState = widgetState.getDisplayPriority(with: appMode, widgetConfigurationParams: widgetConfigurationParams, isCreate: isCreate)
        let displayPriorityRow = section.createNewRow()
        displayPriorityRow.cellType = OAButtonTableViewCell.getIdentifier()
        displayPriorityRow.title = localizedString("display_priority")
        displayPriorityRow.iconName = displayPrioriyState.iconName
        displayPriorityRow.setObj(displayPriorityPref, forKey: "pref")
        displayPriorityRow.setObj(displayPrioriyState.key, forKey: "value")
        return data
    }
    
    override func getWidgetState() -> OAWidgetState? {
        widgetState
    }
    
    override func updateInfo() -> Bool {
        updateRouteInformation()
        return true
    }
    
    override func updateColors(_ textState: OATextState) {
        super.updateColors(textState)
        updateTextWitState(textState)
        let valueTextColor = valueTextColor
        firstLineRightLabel.textColor = valueTextColor
        secondLineRightLabel.textColor = valueTextColor
        secondaryDividerView.backgroundColor = isNightMode() ? .widgetSeparator.dark : .widgetSeparator.light
        buttonArrowImageView.image?.withRenderingMode(.alwaysTemplate)
        buttonArrowImageView.tintColor = isNightMode() ? .iconColorActive.dark : .iconColorActive.light
        navigationButtonView.backgroundColor = isNightMode() ? .buttonBgColorTertiary.dark : .buttonBgColorTertiary.light
        forceUpdateView()
    }
    
    private func layoutWidget() {
        widgetView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(widgetView)
        
        NSLayoutConstraint.activate([
            widgetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            widgetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            widgetView.topAnchor.constraint(equalTo: topAnchor),
            widgetView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func updateRouteInformation() {
        guard let appMode = settings.applicationMode.get() else { return }
        
        let priority = widgetState.getDisplayPriority(with: appMode)
        let routeInfo = calculator.calculateRouteInformationWith(priority)
        if routeInfo.isEmpty {
            updateVisibility(false)
            return
        }
        let visibilityChanged = updateVisibility(true)
        
        if !isForceUpdate && !visibilityChanged && !isUpdateNeeded(for: routeInfo) {
            return
        }
        
        if cachedRouteInfo.count != routeInfo.count {
            cachedRouteInfo = routeInfo
        } else {
            for i in 0..<routeInfo.count {
                let updateIntervalPassed = abs(routeInfo[i].timeToGo - cachedRouteInfo[i].timeToGo) > updateIntervalSeconds
                if updateIntervalPassed {
                    cachedRouteInfo[i].timeToGo = routeInfo[i].timeToGo
                    cachedRouteInfo[i].arrivalTime = routeInfo[i].arrivalTime
                }
                
                cachedRouteInfo[i].distance = routeInfo[i].distance
            }
        }
        
        let hasSecondaryData = hasSecondaryDataValue
        if self.hasSecondaryData != hasSecondaryData {
            self.hasSecondaryData = hasSecondaryData
            forceUpdateView()
            return
        }
        
        let defaultView = widgetState.getDefaultView(with: appMode)
        let orderedDisplayValues = RouteInfoDisplayValue.getValues(with: defaultView)
        
        applySuitableTextFont()
        
        updateHeightConstraint(with: .equal, constant: WidgetSizeStyleObjWrapper.getMaxWidgetHeightFor(type: widgetSizeStyle), priority: .defaultHigh)
        updatePrimaryBlockWith(destinationInfo: cachedRouteInfo.first, displayValues: orderedDisplayValues)
        updateSecondaryBlockWith(destinationInfo: cachedRouteInfo.count > 1 ? cachedRouteInfo[1] : nil, displayValues: orderedDisplayValues)
        isForceUpdate = false
        updateVisibility(true)
        refreshLayout()
    }
    
    private func forceUpdateView() {
        isForceUpdate = true
        updateRouteInformation()
    }
    
    private func updatePrimaryBlockWith(destinationInfo: DestinationInfo?, displayValues: [RouteInfoDisplayValue]) {
        guard let destinationInfo, displayValues.count > 2 else { return }
        let size = widgetSizeStyle
        let data = prepareDisplayData(info: destinationInfo)
        let textColorSecondary: UIColor = isNightMode() ? .textColorSecondary.dark : .textColorSecondary.light
        let hasEnoughWidth = hasEnoughWidth
        let valueTextColor = valueTextColor
        let isSmallSize = isSmallSize
        let firstAttributes: [NSAttributedString.Key: Any] = [
            .font: firstLineLeftLabel.font as Any,
            .foregroundColor: valueTextColor
        ]
        let secondAttributes: [NSAttributedString.Key: Any] = [
            .font: (hasEnoughWidth || isSmallSize ? firstLineLeftLabel.font : secondLineLeftLabel.font) as Any,
            .foregroundColor: valueTextColor
        ]
        let thirdAttributes: [NSAttributedString.Key: Any] = [
            .font: (hasEnoughWidth && !hasSecondaryData || isSmallSize ? firstLineLeftLabel.font : secondLineLeftLabel.font) as Any,
            .foregroundColor: textColorSecondary
        ]
        let bulletAttributes: [NSAttributedString.Key: Any] = [
            .font: (hasEnoughWidth || isSmallSize ? firstLineLeftLabel.font : secondLineLeftLabel.font) as Any,
            .foregroundColor: textColorSecondary
        ]
        
        let value1 = NSAttributedString(string: data[displayValues[0]] ?? "", attributes: firstAttributes)
        let value2 = NSAttributedString(string: data[displayValues[1]] ?? "", attributes: secondAttributes)
        let value3 = NSAttributedString(string: data[displayValues[2]] ?? "", attributes: thirdAttributes)
        let bullet = NSAttributedString(string: " • ", attributes: bulletAttributes)
        let firstLineLeftString = NSMutableAttributedString()
        let secondLineLeftString = NSMutableAttributedString()
        
        var firstLineText: [NSAttributedString] = []
        var secondLineText: [NSAttributedString] = []
        firstLineText.append(value1)
        if !hasEnoughWidth {
            if size == .small {
                firstLineText.append(value2)
                firstLineText.append(value3)
            } else {
                secondLineText.append(value2)
                secondLineText.append(value3)
            }
        } else if hasSecondaryData {
            firstLineText.append(value2)
            if size == .small {
                firstLineText.append(value3)
            } else {
                secondLineText.append(value3)
            }
        } else {
            firstLineText.append(value2)
            firstLineText.append(value3)
        }
        
        for (index, value) in firstLineText.enumerated() {
            firstLineLeftString.append(value)
            if index < firstLineText.count - 1 {
                firstLineLeftString.append(bullet)
            }
        }
        
        for (index, value) in secondLineText.enumerated() {
            secondLineLeftString.append(value)
            if index < secondLineText.count - 1 {
                secondLineLeftString.append(bullet)
            }
        }
        
        firstLineLeftLabel.attributedText = firstLineLeftString
        if !secondLineLeftLabel.isHidden {
            secondLineLeftLabel.attributedText = secondLineLeftString
        }
        
        applyOutlineIfNeeded(to: firstLineLeftLabel, apply: true)
        applyOutlineIfNeeded(to: secondLineLeftLabel, apply: true)
    }
    
    private func updateSecondaryBlockWith(destinationInfo: DestinationInfo?, displayValues: [RouteInfoDisplayValue]) {
        guard displayValues.count >= 1 else { return }
        let data = destinationInfo.flatMap { prepareDisplayData(info: $0) }
        firstLineRightLabel.text = data?[displayValues[0]] ?? ""
        secondLineRightLabel.text = data?[displayValues[1]] ?? ""
        applyOutlineIfNeeded(to: firstLineRightLabel, apply: true)
        applyOutlineIfNeeded(to: secondLineRightLabel, apply: true)
    }
    
    private func isUpdateNeeded(for routeInfo: [DestinationInfo]) -> Bool {
        let metricSystem = OAAppSettings.sharedManager()?.metricSystem.get().rawValue
        let metricSystemChanged = cachedMetricSystem == nil || cachedMetricSystem != metricSystem
        cachedMetricSystem = metricSystem
        if metricSystemChanged {
            return true
        }
    
        let defaultView = widgetState.getDefaultView()
        if cachedDefaultView != defaultView {
            cachedDefaultView = defaultView
            return true
        }
        let displayPriority = widgetState.getDisplayPriority()
        if cachedDisplayPriority != displayPriority {
            cachedDisplayPriority = displayPriority
            return true
        }
        if cachedRouteInfo.isEmpty || cachedRouteInfo.count != routeInfo.count {
            return true
        }
        for i in 0..<routeInfo.count where isDataChanged(for: cachedRouteInfo[i], and: routeInfo[i]) {
            return true
        }
        return false
    }
    
    private func isDataChanged(for i1: DestinationInfo, and i2: DestinationInfo) -> Bool {
        let distanceDiff = abs(i1.distance - i2.distance)
        let timeToGoDiff = abs(i1.timeToGo - i2.timeToGo)
        return distanceDiff > 10 || timeToGoDiff > updateIntervalSeconds
    }
    
    private func applySuitableTextFont() {
        let typefaceStyle: UIFont.Weight = .semibold
        let hasEnoughWidth = hasEnoughWidth
        let minValueFontSize = minValueFontSize
        let isSmallSize = isSmallSize
        let secondLineMinValueFontSize = secondLineMinValueFontSize
        let hasEnoughWidthAndNoSecondaryData = hasEnoughWidth && !hasSecondaryData
        firstLineLeftLabel.font = .scaledMonospacedDigitSystemFont(ofSize: hasEnoughWidthAndNoSecondaryData ? WidgetSizeStyleObjWrapper.getValueFontSizeFor(type: widgetSizeStyle) : firstLineValueFontSize, weight: typefaceStyle)
        firstLineLeftLabel.adjustsFontSizeToFitWidth = true
        firstLineLeftLabel.minimumScaleFactor = minValueFontSize / firstLineLeftLabel.font.pointSize
        
        secondLineLeftLabel.font = .scaledMonospacedDigitSystemFont(ofSize: secondLineValueFontSize, weight: typefaceStyle)
        secondLineLeftLabel.adjustsFontSizeToFitWidth = true
        secondLineLeftLabel.minimumScaleFactor = secondLineMinValueFontSize / secondLineLeftLabel.font.pointSize
        secondLineLeftLabel.isHidden = isSmallSize || hasEnoughWidthAndNoSecondaryData
        
        firstLineRightLabel.font = isSmallSize ? .scaledMonospacedDigitSystemFont(ofSize: minValueFontSize, weight: typefaceStyle) : firstLineLeftLabel.font
        firstLineRightLabel.adjustsFontSizeToFitWidth = firstLineLeftLabel.adjustsFontSizeToFitWidth
        firstLineRightLabel.minimumScaleFactor = minValueFontSize / firstLineRightLabel.font.pointSize
        
        secondLineRightLabel.font = isSmallSize ? .scaledMonospacedDigitSystemFont(ofSize: minValueFontSize, weight: typefaceStyle) : secondLineLeftLabel.font
        secondLineRightLabel.adjustsFontSizeToFitWidth = secondLineLeftLabel.adjustsFontSizeToFitWidth
        secondLineRightLabel.minimumScaleFactor = (isSmallSize ? minValueFontSize : secondLineMinValueFontSize) / secondLineRightLabel.font.pointSize
    }
    
    private func getPossibleDefaultPrefValues(with appMode: OAApplicationMode) -> [OATableRowData] {
        var rows = [OATableRowData]()
        for mode in RouteInfoDisplayValue.allCases {
            let row = OATableRowData()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.setObj(mode.key, forKey: "value")
            row.title = mode.title
            row.descr = getDescriptionWith(displayValue: mode)
            rows.append(row)
        }
        return rows
    }
    
    private func getDescriptionWith(displayValue: RouteInfoDisplayValue) -> String {
        var previewData: [RouteInfoDisplayValue: String] = [:]
        previewData[.arrivalTime] = getFormattedPreviewArrivalTime()
        previewData[.timeToGo] = formatDuration(timeLeft: Self.hourInSeconds)
        previewData[.distance] = formatDistanceWith(meters: Self.oneHundredKmInMeters)
        return getDefaultViewSummary(defaultView: displayValue, previewData: previewData)
    }
    
    private func prepareDisplayData(info: DestinationInfo) -> [RouteInfoDisplayValue: String] {
        var displayData: [RouteInfoDisplayValue: String] = [:]
        displayData[.arrivalTime] = formatArrivalTime(time: info.arrivalTime)
        displayData[.timeToGo] = formatDuration(timeLeft: info.timeToGo)
        displayData[.distance] = formatDistanceWith(meters: info.distance)
        return displayData
    }
    
    private func getDefaultViewSummary(defaultView: RouteInfoDisplayValue, previewData: [RouteInfoDisplayValue: String]) -> String {
        RouteInfoDisplayValue.getValues(with: defaultView)
            .compactMap { previewData[$0] }
            .joined(separator: " • ")
    }
    
    private func getFormattedPreviewArrivalTime() -> String {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 13
        components.minute = 0
        components.second = 0
        let date = calendar.date(from: components)
        return date.flatMap { formatArrivalTime(time: $0.timeIntervalSince1970) } ?? ""
    }
    
    private func formatArrivalTime(time: TimeInterval) -> String {
        let date = Date(timeIntervalSince1970: time)
        return DateFormatter.shortTimeFormatter.string(from: date)
    }
    
    private func formatDuration(timeLeft: TimeInterval) -> String {
        OAOsmAndFormatter.getFormattedDuration(timeLeft)
    }
    
    private func formatDistanceWith(meters: Int32) -> String {
        OAOsmAndFormatter.getFormattedDistance(Float(meters), with: .useLowerBounds)
    }

    override func isEnabledShowIconSwitch(with widgetsPanel: WidgetsPanel, widgetConfigurationParams: [String: Any]?) -> Bool {
        false
    }
    
    override func isEnabledTextInfoComponents() -> Bool {
        false
    }
    
    @IBAction private func onNavigationButtonClicked(_ sender: Any) {
        OARootViewController.instance().mapPanel.onNavigationClick(false)
    }
}

extension RouteInfoWidget {
    private var firstLineValueFontSize: CGFloat {
        switch widgetSizeStyle {
        case .small: 22
        case .medium: 31
        case .large: 36
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var secondLineValueFontSize: CGFloat {
        switch widgetSizeStyle {
        case .small: 16
        case .medium: 18
        case .large: 24
        default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var secondLineMinValueFontSize: CGFloat {
        switch widgetSizeStyle {
        case .small, .medium: 14
        case .large: 16
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var leftViewButtonWidth: CGFloat {
        switch widgetSizeStyle {
        case .small: 30
        case .medium, .large: 36
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var leftViewButtonVerticalSpace: CGFloat {
        switch widgetSizeStyle {
        case .small: 9
        case .medium: 12
        case .large: 16
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
    
    private var secondLineBottomSpace: CGFloat {
        switch widgetSizeStyle {
        case .small: 6
        case .medium: 9
        case .large: 12
        @unknown default: fatalError("Unknown EOAWidgetSizeStyle enum value")
        }
    }
}
