//
//  MapSettingsMapModeParametersViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 18.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

final class MapSettingsMapModeParametersViewController: OABaseScrollableHudViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet private weak var cancelButtonContainerView: UIView!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var cancelButtonLeadingConstraint: NSLayoutConstraint!

    @IBOutlet private weak var resetButtonContainerView: UIView!
    @IBOutlet private weak var resetButton: UIButton!
    @IBOutlet private weak var resetButtonTrailingConstraint: NSLayoutConstraint!

    private let mapPanel: OAMapPanelViewController = OARootViewController.instance().mapPanel
    private let settings: OAAppSettings = OAAppSettings.sharedManager()

    override var initialMenuHeight: CGFloat {
        OAUtilities.calculateScreenHeight() / 2 + OAUtilities.getBottomMargin()
    }

    override var supportsFullScreen: Bool {
        false
    }

    override var useGestureRecognizer: Bool {
        false
    }

    private var applyButton = UIButton(type: .system)
    private var tableData = OATableDataModel()
    private var baseMode = DayNightMode(rawValue: OAAppSettings.sharedManager().appearanceMode.get())
    private var currentMode = DayNightMode(rawValue: OAAppSettings.sharedManager().appearanceMode.get())
    private var nameIndexPath: IndexPath?
    private var descIndexPath: IndexPath?

    init() {
        super.init(nibName: "MapSettingsMapModeParametersViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        applyLocalization()
        registerCells()
        generateData()

        resetButton.setImage(UIImage.icCustomReset, for: .normal)
        resetButton.addBlurEffect(ThemeManager.shared.isLightTheme(),
                                  cornerRadius: 12,
                                  padding: 0)
        cancelButton.addBlurEffect(ThemeManager.shared.isLightTheme(),
                                   cornerRadius: 12,
                                   padding: 0)

        tableView.delegate = self
        tableView.dataSource = self

        setupBottomButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let statusBarStyle = settings.nightMode
            ? UIStatusBarStyle.lightContent
            : UIStatusBarStyle.default
        mapPanel.targetUpdateControlsLayout(true,
                                            customStatusBarStyle: statusBarStyle)
    }

    override func hide() {
        OADayNightHelper.instance().resetTempMode()

        hide(true, duration: 0.2) { [weak self] in
            guard let self else { return }

            mapPanel.mapSettingsButtonClick("")
        }
    }

    override func hide(_ animated: Bool, duration: TimeInterval, onComplete: (() -> Void)!) {
        super.hide(animated, duration: duration) { [weak self] in
            guard let self else { return }

            mapPanel.hideScrollableHudViewController()
            onComplete()
        }
    }

    override func doAdditionalLayout() {
        let isRTL = cancelButtonContainerView.isDirectionRTL()
        let landscapeWidthAdjusted = getLandscapeViewWidth() - OAUtilities.getLeftMargin() + 10
        let commonMargin = OAUtilities.getLeftMargin() + 10
        let defaultPadding = 13.0
        cancelButtonLeadingConstraint.constant = isLandscape() ? (isRTL ? defaultPadding : landscapeWidthAdjusted) : commonMargin
        resetButtonTrailingConstraint.constant = isLandscape() ? (isRTL ? landscapeWidthAdjusted : defaultPadding) : commonMargin
    }

    override func getToolbarHeight() -> CGFloat {
        50
    }

    @IBAction private func cancelButtonPressed() {
        hide()
    }

    @IBAction private func resetButtonPressed() {
        currentMode = baseMode
        updateModeUI()
        if let baseMode {
            OADayNightHelper.instance().setTempMode(Int(baseMode.rawValue))
        }
        generateData()
        tableView.reloadData()
    }

    private func applyLocalization() {
        cancelButton.setTitle(localizedString("shared_string_cancel"),
                              for: .normal)
    }

    private func registerCells() {
        tableView.register(UINib(nibName: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier,
                                 bundle: nil),
                           forCellReuseIdentifier: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier,
                                 bundle: nil),
                           forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
    }

    private func setupBottomButton() {
        applyButton.setTitle(localizedString("shared_string_apply"),
                             for: .normal)
        applyButton.titleLabel?.font = UIFont.systemFont(ofSize: 15.0,
                                                         weight: .semibold)
        applyButton.layer.cornerRadius = 10
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.addTarget(self,
                              action: #selector(onApplyButtonPressed),
                              for: .touchUpInside)
        updateModeUI()
        toolBarView.addSubview(applyButton)

        NSLayoutConstraint.activate([
            applyButton.centerXAnchor.constraint(equalTo: toolBarView.centerXAnchor),
            applyButton.topAnchor.constraint(equalTo: toolBarView.topAnchor),
            applyButton.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: 20),
            applyButton.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -20),
            applyButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func updateModeUI() {
        let isValueChanged = baseMode != currentMode
        applyButton.backgroundColor = isValueChanged
            ? UIColor.buttonBgColorPrimary
            : UIColor.buttonBgColorSecondary
        applyButton.setTitleColor(isValueChanged ? UIColor.buttonTextColorPrimary : UIColor.lightGray,
                                  for: .normal)
        applyButton.isUserInteractionEnabled = isValueChanged
        resetButton.isEnabled = isValueChanged

        if let descIndexPath, let nameIndexPath {
            tableView.reloadRows(at: [nameIndexPath, descIndexPath], with: .none)
        }
    }

    private func generateData() {
        tableData.clearAllData()

        let section = tableData.createNewSection()
        section.headerText = localizedString("map_mode")

        section.addRow(from: [
            kCellKeyKey: "name",
            kCellTypeKey: OASimpleTableViewCell.reuseIdentifier
        ])
        nameIndexPath = IndexPath(row: Int(section.rowCount()) - 1,
                                  section: Int(tableData.sectionCount()) - 1)

        section.addRow(from: [
            kCellKeyKey: "modes",
            kCellTypeKey: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier
        ])

        section.addRow(from: [
            kCellKeyKey: "desc",
            kCellTypeKey: OASimpleTableViewCell.reuseIdentifier
        ])
        descIndexPath = IndexPath(row: Int(section.rowCount()) - 1,
                                  section: Int(tableData.sectionCount()) - 1)
    }

    @objc private func onApplyButtonPressed() {
        if let currentMode {
            settings.appearanceMode.set(currentMode.rawValue)
        }
        hide()
    }
}

extension MapSettingsMapModeParametersViewController {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(tableData.rowCount(UInt(section)))
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        Int(tableData.sectionCount())
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        tableData.sectionData(for: UInt(section)).headerText
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)

        if item.cellType == SegmentImagesWithRightLabelTableViewCell.reuseIdentifier {
            var selectedMode = currentMode?.rawValue ?? 0
            if currentMode == .appTheme {
                selectedMode -= 1
            }
            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier) as! SegmentImagesWithRightLabelTableViewCell
            cell.selectionStyle = .none
            cell.configureTitle(title: nil)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)

            let modes = DayNightMode.allCases
            cell.configureSegmentedControl(icons: modes.map({ $0.iconName }),
                                           selectedSegmentIndex: Int(selectedMode),
                                           selectedIcons: modes.map({ $0.selectedIconName })
)

            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self else { return }

                currentMode = DayNightMode(rawValue: Int32(index))
                if currentMode == nil && index == 3 {
                    currentMode = .appTheme
                }
                updateModeUI()
                if let currentMode {
                    OADayNightHelper.instance().setTempMode(Int(currentMode.rawValue))
                }
            }
            return cell
        } else if item.cellType == OASimpleTableViewCell.getIdentifier() {
            let isName = item.key == "name"
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.selectionStyle = .none
            cell.setCustomLeftSeparatorInset(true)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.titleLabel.font = UIFont.preferredFont(forTextStyle: isName ? .body : .subheadline)
            cell.titleLabel.textColor = isName ? UIColor.textColorPrimary : UIColor(rgb: color_extra_text_gray)
            cell.titleLabel.text = isName ? currentMode?.title : currentMode?.desc
            cell.titleLabel.accessibilityLabel = cell.titleLabel.text
            return cell
        }
        return UITableViewCell()
    }
}
