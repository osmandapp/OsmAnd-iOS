//
//  InclinometerCalibrationViewController.swift
//  OsmAnd Maps
//
//  Created by Eugene Zmeuk on 02.11.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

/// Calibration screen of the inclinometer widgets: a live bubble level, the stored offset and
/// the Calibrate / Reset buttons. The calibration is shared by all inclinometer widgets.
@objc(OAInclinometerCalibrationViewController)
@objcMembers
final class InclinometerCalibrationViewController: OABaseButtonsViewController, InclinometerListener {

    private static let levelRowKey = "level"
    private static let pitchRowKey = "pitch"
    private static let rollRowKey = "roll"
    private static let statusRowKey = "status"

    private let sensor = InclinometerSensor.shared
    private var levelIndexPath: IndexPath?
    private var pitchIndexPath: IndexPath?
    private var rollIndexPath: IndexPath?

    // Called when the calibration is changed on this screen
    var onCalibrationChanged: (() -> Void)?

    // MARK: - Life cycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if sensor.isSensorAvailable {
            sensor.requestUpdates(self)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        sensor.removeListener(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            updateBottomButtons()
            tableView.reloadData()
        }
    }

    // iPhone in landscape: a smaller level and the buttons in one row, so that the level,
    // the live values and the buttons fit on the screen together
    private var isCompactHeight: Bool {
        traitCollection.verticalSizeClass == .compact
    }

    // MARK: - Base UI

    override func getTitle() -> String {
        localizedString("inclinometer_calibration")
    }

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    override func hideFirstHeader() -> Bool {
        true
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        tableView.register(InclinometerLevelCell.self, forCellReuseIdentifier: InclinometerLevelCell.cellIdentifier)
    }

    // MARK: - Table data

    override func generateData() {
        tableData.clearAllData()

        // The level is drawn on the plain background, so it gets a section of its own
        let levelSection = tableData.createNewSection()
        let levelRow = levelSection.createNewRow()
        levelRow.cellType = InclinometerLevelCell.cellIdentifier
        levelRow.key = Self.levelRowKey
        levelIndexPath = IndexPath(row: 0, section: 0)

        let valuesSection = tableData.createNewSection()
        valuesSection.footerText = localizedString("inclinometer_calibration_desc")
        let pitchRow = valuesSection.createNewRow()
        pitchRow.cellType = OAValueTableViewCell.reuseIdentifier
        pitchRow.key = Self.pitchRowKey
        pitchRow.title = localizedString("inclinometer_pitch")
        let rollRow = valuesSection.createNewRow()
        rollRow.cellType = OAValueTableViewCell.reuseIdentifier
        rollRow.key = Self.rollRowKey
        rollRow.title = localizedString("inclinometer_roll")
        pitchIndexPath = IndexPath(row: 0, section: 1)
        rollIndexPath = IndexPath(row: 1, section: 1)

        let statusSection = tableData.createNewSection()
        statusSection.footerText = localizedString("inclinometer_calibration_applies_to_all")
        let statusRow = statusSection.createNewRow()
        statusRow.cellType = OASimpleTableViewCell.reuseIdentifier
        statusRow.key = Self.statusRowKey
        if !sensor.isSensorAvailable {
            statusRow.title = localizedString("inclinometer_sensor_unavailable")
        } else if let offset = sensor.calibrationOffset {
            statusRow.title = localizedString("inclinometer_calibrated")
            statusRow.descr = String(format: localizedString("inclinometer_calibration_offset"),
                                     InclinometerWidget.formatOffset(offset.pitch), InclinometerWidget.formatOffset(offset.roll))
        } else {
            statusRow.title = localizedString("inclinometer_not_calibrated")
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == InclinometerLevelCell.cellIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: InclinometerLevelCell.cellIdentifier, for: indexPath) as! InclinometerLevelCell
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.levelView.setInclination(pitch: currentPitch, roll: currentRoll)
            cell.setCompact(isCompactHeight)
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.valueVisibility(true)
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.key == Self.pitchRowKey ? formatTilt(.inclinometerPitch, currentPitch) : formatTilt(.inclinometerRoll, currentRoll)
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            let hasDescr = item.descr != nil && !item.descr!.isEmpty
            cell.descriptionVisibility(hasDescr)
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorPrimary
            cell.descriptionLabel.text = item.descr
            return cell
        }
        return nil
    }

    // MARK: - Bottom buttons

    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        isCompactHeight ? .horizontal : .vertical
    }

    override func getTopButtonTitle() -> String? {
        localizedString(sensor.isCalibrated ? "inclinometer_recalibrate" : "inclinometer_calibrate")
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        guard sensor.isSensorAvailable else {
            return .inactive
        }
        // buttons in a row are drawn as text buttons on a clear background
        return isCompactHeight ? .graySimple : .purple
    }

    override func getBottomButtonTitle() -> String? {
        sensor.isCalibrated ? localizedString("inclinometer_reset_calibration") : nil
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .graySimple
    }

    override func onTopButtonPressed() {
        if sensor.calibrate() {
            OAUtilities.showToast(localizedString("inclinometer_calibration_saved"), details: nil, duration: 2, in: view)
        } else {
            OAUtilities.showToast(localizedString("inclinometer_sensor_unavailable"), details: nil, duration: 2, in: view)
        }
        refreshAfterCalibrationChange()
    }

    override func onBottomButtonPressed() {
        sensor.resetCalibration()
        refreshAfterCalibrationChange()
    }

    private func refreshAfterCalibrationChange() {
        generateData()
        tableView.reloadData()
        updateBottomButtons()
        onCalibrationChanged?()
    }

    // MARK: - InclinometerListener

    func onInclinationChanged(pitch: Float, roll: Float) {
        guard isViewLoaded else {
            return
        }
        if let levelIndexPath, let cell = tableView.cellForRow(at: levelIndexPath) as? InclinometerLevelCell {
            cell.levelView.setInclination(pitch: pitch, roll: roll)
        }
        if let pitchIndexPath, let cell = tableView.cellForRow(at: pitchIndexPath) as? OAValueTableViewCell {
            cell.valueLabel.text = formatTilt(.inclinometerPitch, pitch)
        }
        if let rollIndexPath, let cell = tableView.cellForRow(at: rollIndexPath) as? OAValueTableViewCell {
            cell.valueLabel.text = formatTilt(.inclinometerRoll, roll)
        }
    }

    var isInclinometerActive: Bool {
        isViewLoaded && view.window != nil
    }

    // MARK: - Values

    private var currentPitch: Float {
        sensor.hasValue ? sensor.pitch : 0
    }

    private var currentRoll: Float {
        sensor.hasValue ? sensor.roll : 0
    }

    private func formatTilt(_ widgetType: WidgetType, _ degrees: Float) -> String {
        let value = InclinometerWidget.formatOffset(degrees.magnitude)
        if let arrow = InclinometerWidget.directionArrow(widgetType, degrees: degrees) {
            return value + " " + arrow
        }
        return value
    }
}

final class InclinometerLevelCell: UITableViewCell {

    static let cellIdentifier = "InclinometerLevelCell"
    private static let levelSize: CGFloat = 200
    private static let compactLevelSize: CGFloat = 120
    private static let padding: CGFloat = 16
    private static let compactPadding: CGFloat = 8

    let levelView = InclinometerLevelView()
    private var sizeConstraint: NSLayoutConstraint!
    private var topConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        levelView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(levelView)
        sizeConstraint = levelView.widthAnchor.constraint(equalToConstant: Self.levelSize)
        topConstraint = levelView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Self.padding)
        bottomConstraint = levelView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Self.padding)
        NSLayoutConstraint.activate([
            sizeConstraint,
            levelView.heightAnchor.constraint(equalTo: levelView.widthAnchor),
            levelView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            topConstraint,
            bottomConstraint
        ])
    }

    func setCompact(_ compact: Bool) {
        sizeConstraint.constant = compact ? Self.compactLevelSize : Self.levelSize
        topConstraint.constant = compact ? Self.compactPadding : Self.padding
        bottomConstraint.constant = -(compact ? Self.compactPadding : Self.padding)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
