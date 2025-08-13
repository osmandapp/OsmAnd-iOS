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

        resetButton.setImage(.icCustomReset, for: .normal)
        let isLightTheme = ThemeManager.shared.isLightTheme()
        resetButton.addBlurEffect(isLightTheme,
                                  cornerRadius: 12,
                                  padding: 0)
        cancelButton.addBlurEffect(isLightTheme,
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
        applyButton.backgroundColor = isValueChanged ? .buttonBgColorPrimary : .buttonBgColorSecondary
        applyButton.setTitleColor(isValueChanged ? .buttonTextColorPrimary : .lightGray,
                                  for: .normal)
        applyButton.isUserInteractionEnabled = isValueChanged
        resetButton.isEnabled = isValueChanged

        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }

    private func generateData() {
        tableData.clearAllData()

        let section = tableData.createNewSection()
        section.headerText = localizedString("map_mode")

        section.addRow(from: [
            kCellKeyKey: "name",
            kCellTypeKey: OASimpleTableViewCell.reuseIdentifier
        ])

        section.addRow(from: [
            kCellKeyKey: "modes",
            kCellTypeKey: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier,
            "icons": getImagesFromModes(false),
            "selectedIcons": getImagesFromModes(true)
        ])

        section.addRow(from: [
            kCellKeyKey: "desc",
            kCellTypeKey: OASimpleTableViewCell.reuseIdentifier
        ])
    }

    private func getImagesFromModes(_ selected: Bool) -> [UIImage] {
        DayNightMode.allCases.map({
            if let image = UIImage(named: selected ? $0.selectedIconName : $0.iconName) {
                return OAUtilities.resize(image, newSize: CGSize(width: 20, height: 20))
            }
            return UIImage()
        })
    }

    @objc private func onApplyButtonPressed() {
        if let currentMode {
            settings.appearanceMode.set(currentMode.rawValue)
        }
        hide()
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

            cell.configureSegmentedControl(icons: item.obj(forKey: "icons") as? [UIImage] ?? [],
                                           selectedSegmentIndex: Int(selectedMode),
                                           selectedIcons: item.obj(forKey: "selectedIcons") as? [UIImage] ?? [])

            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self else { return }

                currentMode = DayNightMode(rawValue: Int32(index))
                if currentMode == nil && index == 3 { // todo: compatibility with Android, 3 - light sensor
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
            cell.titleLabel.textColor = isName ? .textColorPrimary : UIColor(rgb: color_extra_text_gray)
            cell.titleLabel.text = isName ? currentMode?.title : currentMode?.desc
            cell.titleLabel.accessibilityLabel = cell.titleLabel.text
            return cell
        }
        return UITableViewCell()
    }
}
