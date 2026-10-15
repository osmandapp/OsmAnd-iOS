//
//  SpeedLimitToleranceViewController.swift
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

@objc
final class SpeedLimitToleranceViewController: OABaseSettingsViewController {
    private let settings = OAAppSettings.sharedManager()

    private var convertedLimitFrom: Float = 0
    private var convertedLimitTo: Float = 0
    private var convertedSelectedValue: Float = 0
    private var step: Float = 0.1
    private var selectedValue: Double = 0
    private var speedFormat: EOASpeedConstant = .KILOMETERS_PER_HOUR

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 26.0, *) {
            view.backgroundColor = nil
            tableView.backgroundColor = nil
        }
    }

    override func postInit() {
        super.postInit()
        speedFormat = OAOsmAndFormatter.speedMode(forPaceMode: settings.speedSystem.get(appMode))
        let isSpeedToleranceBigRange = appMode.isSpeedToleranceBigRange()
        selectedValue = settings.speedLimitExceedKmh.get(appMode)
        let speeds = [appMode.minSpeedToleranceLimit(), appMode.maxSpeedToleranceLimit(), Float(selectedValue) / 3.6]
        let convertedValues = speeds.map { speed -> Float in
            let valueUnitArray = NSMutableArray()
            OAOsmAndFormatter.formattedSpeedTolerance(speed, speedSystem: speedFormat, hasFastSpeed: isSpeedToleranceBigRange, valueUnitArray: valueUnitArray)
            let value = (valueUnitArray.firstObject as? String ?? "").replacingOccurrences(of: " ", with: "")
            return NumberFormatter.localizedNumberFormatter.number(from: value)?.floatValue ?? 0
        }
        convertedLimitFrom = convertedValues[0]
        convertedLimitTo = convertedValues[1]
        convertedSelectedValue = convertedValues[2]
        // As on Android, clamp only the display value until the slider changes.
        convertedSelectedValue = max(convertedLimitFrom, min(convertedLimitTo, convertedSelectedValue))
        step = 0.1
        if isSpeedToleranceBigRange {
            convertedLimitFrom = integerSpeed(convertedLimitFrom)
            convertedLimitTo = integerSpeed(convertedLimitTo)
            convertedSelectedValue = integerSpeed(convertedSelectedValue)
            step = 1
        }
    }

    override func getTitle() -> String {
        localizedString("speed_limit_exceed")
    }

    override func getTableHeaderDescription() -> String {
        localizedString("speed_limit_exceed_message")
    }

    override func setupTableHeaderView() {
        super.setupTableHeaderView()
        if #available(iOS 26.0, *) {
            tableView.tableHeaderView?.backgroundColor = nil
        }
    }

    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }

    override func getBottomButtonTitle() -> String {
        localizedString("shared_string_apply")
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .purple
    }

    override func registerCells() {
        addCell(TopBottomValuesSliderTableViewCell.reuseIdentifier)
    }

    override func generateData() {
        tableData.clearAllData()
        let section = tableData.createNewSection()
        let row = section.createNewRow()
        row.cellType = TopBottomValuesSliderTableViewCell.reuseIdentifier
        row.title = localizedString("selected_value")
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TopBottomValuesSliderTableViewCell.reuseIdentifier) as? TopBottomValuesSliderTableViewCell else {
            return nil
        }
        cell.selectionStyle = .none
        cell.topRightLabelVisibility(true)
        cell.sliderValuesVisibility(true)
        cell.topLeftLabel.text = item.title
        cell.topRightLabel.text = formatValue(convertedSelectedValue)
        cell.topRightLabel.textColor = .textColorSecondary
        cell.bottomLeftLabel.text = formatValue(convertedLimitFrom)
        cell.bottomLeftLabel.textColor = .textColorSecondary
        cell.bottomRightLabel.text = formatValue(convertedLimitTo)
        cell.bottomRightLabel.textColor = .textColorSecondary

        cell.slider.minimumValue = convertedLimitFrom
        cell.slider.maximumValue = convertedLimitTo
        cell.slider.value = convertedSelectedValue
        cell.slider.tintColor = .menuButton
        cell.slider.maximumTrackTintColor = .sliderLineBg
        cell.slider.accessibilityLabel = getTitle()
        cell.slider.accessibilityValue = cell.topRightLabel.text
        cell.slider.removeTarget(self, action: nil, for: .valueChanged)
        cell.slider.addTarget(self, action: #selector(onSliderChanged(_:)), for: .valueChanged)
        return cell
    }

    override func onBottomButtonPressed() {
        settings.speedLimitExceedKmh.set(selectedValue, mode: appMode)
        delegate?.onSettingsChanged()
        dismiss()
    }

    private func integerSpeed(_ floatSpeed: Float) -> Float {
        floatSpeed.rounded(.awayFromZero)
    }

    private func formatValue(_ value: Float) -> String {
        let metersPerSecond = OAOsmAndFormatter.mpS(fromFormattedValue: value, speedSystem: speedFormat)
        return OAOsmAndFormatter.formattedSpeedTolerance(metersPerSecond, speedSystem: speedFormat, hasFastSpeed: appMode.isSpeedToleranceBigRange(), valueUnitArray: nil)
    }

    @objc private func onSliderChanged(_ slider: UISlider) {
        convertedSelectedValue = convertedLimitFrom + ((slider.value - convertedLimitFrom) / step).rounded() * step
        convertedSelectedValue = max(convertedLimitFrom, min(convertedLimitTo, convertedSelectedValue))
        let selectedSpeedInMS = OAOsmAndFormatter.mpS(fromFormattedValue: convertedSelectedValue, speedSystem: speedFormat)
        selectedValue = Double(selectedSpeedInMS * 3.6)
        slider.value = convertedSelectedValue
        slider.accessibilityValue = formatValue(convertedSelectedValue)
        if let cell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TopBottomValuesSliderTableViewCell {
            cell.topRightLabel.text = slider.accessibilityValue
        }
    }
}
