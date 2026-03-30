//
//  MapSettingsBuildings3DParametersViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 27.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objc protocol Buildings3DParametersDelegate: AnyObject {
    func onBackBuildings3DParameters()
}

@objc enum Buildings3DSettingsType: Int {
    case color
    case visibility
}

private enum RowKey: String {
    case visibilitySlider
    case buildings3DColorType
    case buildings3DMapStyleDescription
    case colorDayNight
    case buildings3DGridColors
    case allColors
    case buildings3DColorPurchaseBanner
    case buildings3DColorChooseColor
}

private enum ItemKey: String {
    case tintTitle
    case hideSeparator
}

@objcMembers
final class MapSettingsBuildings3DParametersViewController: OABaseScrollableHudViewController {
    @IBOutlet private weak var backButtonContainerView: UIView!
    @IBOutlet private weak var backButton: UIButton!
    @IBOutlet private weak var doneButtonContainerView: UIView!
    @IBOutlet private weak var resetButton: UIButton!
    @IBOutlet private var backButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private var resetButtonTrailingConstraint: NSLayoutConstraint!
    
    private let settingsType: Buildings3DSettingsType
    private let plugin: OASRTMPlugin? = OAPluginsHelper.getPlugin(OASRTMPlugin.self) as? OASRTMPlugin
    private let settings: OAAppSettings = OAAppSettings.sharedManager()
    private let mapPanel: OAMapPanelViewController = OARootViewController.instance().mapPanel
    private let appearanceCollection: OAGPXAppearanceCollection = OAGPXAppearanceCollection.sharedInstance()
    
    private var data = OATableDataModel()
    private var applyButton = UIButton(type: .system)
    private var sortedColorItems: [ColorItem] = []
    private var baseDayColorItem: ColorItem?
    private var currentDayColorItem: ColorItem?
    private var baseNightColorItem: ColorItem?
    private var currentNightColorItem: ColorItem?
    private var colorsCollectionIndexPath: IndexPath?
    private var baseAlpha = 0.0
    private var currentAlpha = 0.0
    private var baseBuildings3DColorStyle = 0
    private var currentBuildings3DColorStyle = 0
    private var isNightColorMode = false
    private var isValueChange = false
    
    weak var delegate: Buildings3DParametersDelegate?
    
    override var initialMenuHeight: CGFloat {
        let divider: CGFloat = settingsType == .visibility ? 3.0 : 2.0
        return (OAUtilities.calculateScreenHeight() / divider) + OAUtilities.getBottomMargin()
    }
    
    override var supportsFullScreen: Bool {
        false
    }
    
    override var useGestureRecognizer: Bool {
        false
    }
    
    init(settingsType: Buildings3DSettingsType) {
        self.settingsType = settingsType
        super.init(nibName: "MapSettingsBuildings3DParametersViewController", bundle: nil)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyLocalization()
        registerCells()
        generateData()
        resetButton.setImage(UIImage.templateImageNamed("ic_navbar_reset"), for: .normal)
        updateButtonsBlur()
        tableView.delegate = self
        tableView.dataSource = self
        setupBottomButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshColorsCollection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let statusBarStyle: UIStatusBarStyle = settings.nightMode ? .lightContent : .default
        mapPanel.targetUpdateControlsLayout(true, customStatusBarStyle: statusBarStyle)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self, !self.isLandscape() else { return }
            self.goMinimized(false)
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard let previousTraitCollection, traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        updateButtonsBlur()
    }
    
    override func getToolbarHeight() -> CGFloat {
        50.0
    }
    
    override func doAdditionalLayout() {
        let isRTL = backButtonContainerView.isDirectionRTL()
        let landscapeWidthAdjusted = getLandscapeViewWidth() - OAUtilities.getLeftMargin() + 10.0
        let commonMargin = OAUtilities.getLeftMargin() + 10.0
        let defaultPadding = 13.0
        backButtonLeadingConstraint.constant = isLandscape() ? (isRTL ? defaultPadding : landscapeWidthAdjusted) : commonMargin
        resetButtonTrailingConstraint.constant = isLandscape() ? (isRTL ? landscapeWidthAdjusted : defaultPadding) : commonMargin
    }
    
    override func hide() {
        switch settingsType {
        case .visibility where baseAlpha != currentAlpha:
            plugin?.apply3DBuildingsAlpha(baseAlpha)
        case .visibility:
            break
        case .color:
            setBuildings3DBaseColorItem()
        }
        
        hide(true, duration: 0.2) { [weak self] in
            self?.delegate?.onBackBuildings3DParameters()
        }
    }
    
    override func hide(_ animated: Bool, duration: TimeInterval, onComplete: (() -> Void)?) {
        super.hide(animated, duration: duration) { [weak self] in
            guard let self else { return }
            if settingsType == .color {
                OADayNightHelper.instance().resetTempMode()
                let colorStyle = plugin?.get3DBuildingsColorStyle() ?? Buildings3DColorType.mapStyle.rawValue
                plugin?.apply3DBuildingsColorStyle(colorStyle)
            }
            
            mapPanel.hideScrollableHudViewController()
            onComplete?()
        }
    }
    
    @IBAction private func backButtonPressed(_: UIButton) {
        hide()
    }
    
    @IBAction private func resetButtonPressed(_: UIButton) {
        let wasReset: Bool
        switch settingsType {
        case .visibility:
            wasReset = resetVisibilityValues()
        case .color:
            wasReset = resetBuildings3DColor()
        }
        
        if wasReset {
            generateData()
            tableView.reloadData()
        }
    }
    
    private func commonInit() {
        switch settingsType {
        case .visibility:
            guard let plugin else { return }
            baseAlpha = plugin.buildings3dAlphaPref.get()
            currentAlpha = baseAlpha
        case .color:
            guard let plugin else { return }
            sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
            isNightColorMode = settings.nightMode
            baseBuildings3DColorStyle = plugin.get3DBuildingsColorStyle()
            currentBuildings3DColorStyle = baseBuildings3DColorStyle
            let defaultColorItem = appearanceCollection.getDefaultLineColorItem()
            baseDayColorItem = appearanceCollection.getColorItem(withValue: plugin.buildings3dCustomDayColorPref.get()) ?? defaultColorItem
            currentDayColorItem = baseDayColorItem
            baseNightColorItem = appearanceCollection.getColorItem(withValue: plugin.buildings3dCustomNightColorPref.get()) ?? defaultColorItem
            currentNightColorItem = baseNightColorItem
            NotificationCenter.default.addObserver(self, selector: #selector(productPurchased(_:)), name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(productsRestored(_:)), name: Notification.Name(NSNotification.Name.OAIAPProductsRestored.rawValue), object: nil)
        }
    }
    
    private func applyLocalization() {
        backButton.setTitle(localizedString("shared_string_cancel"), for: .normal)
    }
    
    private func registerCells() {
        tableView.register(UINib(nibName: OATitleSliderTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OATitleSliderTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OAButtonTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OAButtonTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OATitleDescriptionBigIconCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OATitleDescriptionBigIconCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OACollectionSingleLineTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: SegmentTextTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SegmentTextTableViewCell.reuseIdentifier)
    }
    
    private func generateData() {
        data.clearAllData()
        colorsCollectionIndexPath = nil
        
        let topSection = data.createNewSection()
        topSection.headerText = localizedString("enable_3d_objects")
        if settingsType == .visibility {
            topSection.footerText = localizedString("buildings_3d_visibility_description")
        }
        
        switch settingsType {
        case .visibility:
            let visibilityRow = topSection.createNewRow()
            visibilityRow.key = RowKey.visibilitySlider.rawValue
            visibilityRow.cellType = OATitleSliderTableViewCell.reuseIdentifier
            visibilityRow.title = localizedString("visibility")
        case .color:
            let colorTypeRow = topSection.createNewRow()
            colorTypeRow.key = RowKey.buildings3DColorType.rawValue
            colorTypeRow.cellType = OAButtonTableViewCell.reuseIdentifier
            colorTypeRow.title = localizedString("shared_string_color")
            colorTypeRow.setObj(UIColor.textColorPrimary, forKey: ItemKey.tintTitle.rawValue)
            let isPurchased = isBuildings3DColorPurchased()
            let shouldHideSeparator = currentBuildings3DColorStyle == Buildings3DColorType.custom.rawValue && isPurchased
            colorTypeRow.setObj(shouldHideSeparator, forKey: ItemKey.hideSeparator.rawValue)
            if currentBuildings3DColorStyle == Buildings3DColorType.mapStyle.rawValue {
                let mapStyleDescriptionRow = topSection.createNewRow()
                mapStyleDescriptionRow.key = RowKey.buildings3DMapStyleDescription.rawValue
                mapStyleDescriptionRow.cellType = OASimpleTableViewCell.reuseIdentifier
                let rendererName = settings.renderer.get()
                mapStyleDescriptionRow.title = String(format: localizedString("route_line_use_map_style_color"), rendererName)
            } else if isPurchased {
                let colorDayNightRow = topSection.createNewRow()
                colorDayNightRow.key = RowKey.colorDayNight.rawValue
                colorDayNightRow.cellType = SegmentTextTableViewCell.reuseIdentifier
                let buildings3DGridColorsRow = topSection.createNewRow()
                buildings3DGridColorsRow.key = RowKey.buildings3DGridColors.rawValue
                buildings3DGridColorsRow.cellType = OACollectionSingleLineTableViewCell.reuseIdentifier
                let sectionIndex = Int(data.sectionCount()) - 1
                let rowIndex = Int(data.rowCount(UInt(sectionIndex))) - 1
                colorsCollectionIndexPath = IndexPath(row: rowIndex, section: sectionIndex)
                let allColorsRow = topSection.createNewRow()
                allColorsRow.key = RowKey.allColors.rawValue
                allColorsRow.cellType = OASimpleTableViewCell.reuseIdentifier
                allColorsRow.title = localizedString("shared_string_all_colors")
                allColorsRow.setObj(UIColor.textColorActive, forKey: ItemKey.tintTitle.rawValue)
            } else {
                let purchaseBannerRow = topSection.createNewRow()
                purchaseBannerRow.key = RowKey.buildings3DColorPurchaseBanner.rawValue
                purchaseBannerRow.cellType = OATitleDescriptionBigIconCell.reuseIdentifier
                purchaseBannerRow.title = localizedString("custom_color")
                purchaseBannerRow.descr = localizedString("free_custom_color_description")
                purchaseBannerRow.icon = UIImage.templateImageNamed("ic_custom_3d_building_colored")
                let chooseColorRow = topSection.createNewRow()
                chooseColorRow.key = RowKey.buildings3DColorChooseColor.rawValue
                chooseColorRow.cellType = OAButtonTableViewCell.reuseIdentifier
                chooseColorRow.title = localizedString("choose_color")
                chooseColorRow.secondaryIconName = "ic_payment_label_maps_plus"
                chooseColorRow.setObj(UIColor.textColorActive, forKey: ItemKey.tintTitle.rawValue)
            }
        }
    }
    
    private func setupBottomButton() {
        applyButton.setTitle(localizedString("shared_string_apply"), for: .normal)
        applyButton.titleLabel?.font = .systemFont(ofSize: 15.0, weight: .semibold)
        applyButton.layer.cornerRadius = 10.0
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        applyButton.addTarget(self, action: #selector(onApplyButtonPressed), for: .touchUpInside)
        updateApplyButton()
        toolBarView.addSubview(applyButton)
        NSLayoutConstraint.activate([
            applyButton.centerXAnchor.constraint(equalTo: toolBarView.centerXAnchor),
            applyButton.topAnchor.constraint(equalTo: toolBarView.topAnchor),
            applyButton.leadingAnchor.constraint(equalTo: toolBarView.leadingAnchor, constant: 20.0),
            applyButton.trailingAnchor.constraint(equalTo: toolBarView.trailingAnchor, constant: -20.0),
            applyButton.heightAnchor.constraint(equalToConstant: 44.0)
        ])
    }
    
    private func updateApplyButton() {
        applyButton.backgroundColor = isValueChange ? .buttonBgColorPrimary : .buttonBgColorSecondary
        applyButton.setTitleColor(isValueChange ? .buttonTextColorPrimary : .lightGray, for: .normal)
        applyButton.isUserInteractionEnabled = isValueChange
    }
    
    private func updateButtonsBlur() {
        let isLightTheme = ThemeManager.shared.isLightTheme()
        backButton.addBlurEffect(isLightTheme, cornerRadius: 12.0, padding: 0.0)
        resetButton.addBlurEffect(isLightTheme, cornerRadius: 12.0, padding: 0.0)
    }
    
    private func resetVisibilityValues() -> Bool {
        guard let plugin else { return false }
        let defaultAlpha = plugin.buildings3dAlphaPref.defValue
        if currentAlpha != defaultAlpha {
            currentAlpha = defaultAlpha
            plugin.apply3DBuildingsAlpha(currentAlpha)
            isValueChange = baseAlpha != currentAlpha
            updateApplyButton()
            return true
        }
        
        return false
    }
    
    private func resetBuildings3DColor() -> Bool {
        guard let plugin else { return false }
        let defaultColorStyle = Buildings3DColorType.mapStyle.rawValue
        let defaultDayColor = Int(plugin.buildings3dCustomDayColorPref.defValue)
        let defaultNightColor = Int(plugin.buildings3dCustomNightColorPref.defValue)
        if currentDayColorItem?.value == defaultDayColor, currentNightColorItem?.value == defaultNightColor, currentBuildings3DColorStyle == defaultColorStyle {
            return false
        }
        
        currentBuildings3DColorStyle = defaultColorStyle
        currentDayColorItem = appearanceCollection.getColorItem(withValue: Int32(defaultDayColor)) ?? appearanceCollection.getDefaultLineColorItem()
        currentNightColorItem = appearanceCollection.getColorItem(withValue: Int32(defaultNightColor)) ?? appearanceCollection.getDefaultLineColorItem()
        previewBuildings3DColor()
        if let colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler, let currentColorItem = isNightColorMode ? currentNightColorItem : currentDayColorItem, let row = sortedColorItems.firstIndex(where: { $0 == currentColorItem }) {
            let indexPath = IndexPath(row: row, section: 0)
            colorHandler.onItemSelected(indexPath, collectionView: colorCell.collectionView)
        }
        
        isValueChange = baseDayColorItem != currentDayColorItem || baseNightColorItem != currentNightColorItem || baseBuildings3DColorStyle != currentBuildings3DColorStyle
        updateApplyButton()
        return true
    }
    
    private func refreshColorsCollection() {
        guard settingsType == .color else { return }
        if let colorsCollectionIndexPath, colorsCollectionIndexPath.section < tableView.numberOfSections, colorsCollectionIndexPath.row < tableView.numberOfRows(inSection: colorsCollectionIndexPath.section) {
            tableView.reloadRows(at: [colorsCollectionIndexPath], with: .none)
            if let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let selectedIndexPath = colorCell.getCollectionHandler()?.getSelectedIndexPath(), selectedIndexPath.row != NSNotFound, !colorCell.collectionView.indexPathsForVisibleItems.contains(selectedIndexPath) {
                colorCell.collectionView.scrollToItem(at: selectedIndexPath, at: .centeredHorizontally, animated: false)
            }
        }
    }
    
    private func applyCurrentVisibility() {
        guard let plugin else { return }
        plugin.buildings3dAlphaPref.set(currentAlpha)
        plugin.apply3DBuildingsAlpha(currentAlpha)
    }
    
    private func isBuildings3DColorPurchased() -> Bool {
        OAIAPHelper.isMapsPlusAvailable() || OAIAPHelper.isOsmAndProAvailable()
    }
    
    private func applyBuildings3DColor() {
        guard let plugin else { return }
        if currentBuildings3DColorStyle == Buildings3DColorType.custom.rawValue && !isBuildings3DColorPurchased() {
            setBuildings3DBaseColorItem()
            return
        }
        
        guard let currentDayColorItem, let currentNightColorItem else { return }
        plugin.buildings3dCustomDayColorPref.set(Int32(currentDayColorItem.value))
        plugin.buildings3dCustomNightColorPref.set(Int32(currentNightColorItem.value))
        plugin.apply3DBuildingsColorStyle(currentBuildings3DColorStyle)
    }
    
    private func previewBuildings3DColor() {
        guard let plugin else { return }
        if currentBuildings3DColorStyle == Buildings3DColorType.custom.rawValue && !isBuildings3DColorPurchased() {
            guard let baseDayColorItem, let baseNightColorItem else { return }
            plugin.buildings3dCustomDayColorPref.set(Int32(baseDayColorItem.value))
            plugin.buildings3dCustomNightColorPref.set(Int32(baseNightColorItem.value))
            plugin.buildings3dColorStylePref.set(Int32(baseBuildings3DColorStyle))
            plugin.apply3DBuildingsColorStyle(baseBuildings3DColorStyle)
            return
        }
        
        if currentBuildings3DColorStyle == Buildings3DColorType.mapStyle.rawValue {
            plugin.apply3DBuildingsColorStyle(Buildings3DColorType.mapStyle.rawValue)
            return
        }
        
        guard let currentDayColorItem, let currentNightColorItem else { return }
        plugin.buildings3dCustomDayColorPref.set(Int32(currentDayColorItem.value))
        plugin.buildings3dCustomNightColorPref.set(Int32(currentNightColorItem.value))
        if plugin.get3DBuildingsColorStyle() != Buildings3DColorType.custom.rawValue {
            plugin.apply3DBuildingsColorStyle(Buildings3DColorType.custom.rawValue)
        }
        
        let color = isNightColorMode ? currentNightColorItem.value : currentDayColorItem.value
        plugin.apply3DBuildingsColor(Int32(color))
    }
    
    private func setBuildings3DBaseColorItem() {
        guard let plugin, let baseDayColorItem, let baseNightColorItem else { return }
        plugin.buildings3dCustomDayColorPref.set(Int32(baseDayColorItem.value))
        plugin.buildings3dCustomNightColorPref.set(Int32(baseNightColorItem.value))
        plugin.buildings3dColorStylePref.set(Int32(baseBuildings3DColorStyle))
        currentBuildings3DColorStyle = baseBuildings3DColorStyle
    }
    
    private func segmentChanged(_ index: Int) {
        isNightColorMode = index == 1
        OADayNightHelper.instance().setTempMode(Int((isNightColorMode ? DayNightMode.night : DayNightMode.day).rawValue))
        previewBuildings3DColor()
        refreshColorsCollection()
    }
    
    private func createBuildings3DColorTypeMenu() -> UIMenu {
        let mapStyleAction = createBuildings3DColorTypeAction(title: localizedString("quick_action_map_style"), style: Buildings3DColorType.mapStyle.rawValue)
        let customAction = createBuildings3DColorTypeAction(title: localizedString("shared_string_custom"), style: Buildings3DColorType.custom.rawValue)
        return UIMenu(children: [mapStyleAction, customAction])
    }
    
    private func createBuildings3DColorTypeAction(title: String, style: Int) -> UIAction {
        let action = UIAction(title: title) { [weak self] _ in
            guard let self else { return }
            self.currentBuildings3DColorStyle = style
            self.previewBuildings3DColor()
            self.isValueChange = self.baseDayColorItem != self.currentDayColorItem || self.baseNightColorItem != self.currentNightColorItem || self.baseBuildings3DColorStyle != self.currentBuildings3DColorStyle
            self.updateApplyButton()
            self.generateData()
            self.tableView.reloadData()
        }
        
        action.state = currentBuildings3DColorStyle == style ? .on : .off
        return action
    }
    
    @objc private func onApplyButtonPressed() {
        switch settingsType {
        case .visibility:
            guard let plugin else { break }
            if currentAlpha != plugin.buildings3dAlphaPref.get() {
                applyCurrentVisibility()
            }
        case .color:
            applyBuildings3DColor()
        }
        
        hide(true, duration: 0.2) { [weak self] in
            self?.delegate?.onBackBuildings3DParameters()
        }
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        currentAlpha = Double(slider.value)
        plugin?.apply3DBuildingsAlpha(currentAlpha)
        isValueChange = baseAlpha != currentAlpha
        updateApplyButton()
    }
    
    @objc private func onCellButtonPressed(_: UIButton) {
        let colorViewController = UIColorPickerViewController()
        colorViewController.delegate = self
        let activeItem = isNightColorMode ? currentNightColorItem : currentDayColorItem
        colorViewController.selectedColor = activeItem?.getColor() ?? .clear
        navigationController?.present(colorViewController, animated: true)
    }
    
    @objc private func showChoosePlanScreen() {
        guard let navigationController = OARootViewController.instance().navigationController else { return }
        OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.terrain(), navController: navigationController)
    }
    
    @objc private func productPurchased(_: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.settingsType == .color else { return }
            self.generateData()
            self.tableView.reloadData()
        }
    }
    
    @objc private func productsRestored(_: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.settingsType == .color else { return }
            self.generateData()
            self.tableView.reloadData()
        }
    }
}

extension MapSettingsBuildings3DParametersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        data.sectionData(for: UInt(section)).headerText
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        data.sectionData(for: UInt(section)).footerText
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        Int(data.sectionCount())
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Int(data.rowCount(UInt(section)))
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = data.item(for: indexPath)
        if item.cellType == OATitleSliderTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OATitleSliderTableViewCell.reuseIdentifier, for: indexPath) as? OATitleSliderTableViewCell {
            cell.selectionStyle = .none
            cell.sliderView?.minimumTrackTintColor = .iconColorActive
            cell.titleLabel?.text = item.title
            cell.updateValueCallback = nil
            cell.sliderView?.minimumValue = 0.1
            cell.sliderView?.maximumValue = 1.0
            let sliderValue = Float(currentAlpha)
            cell.sliderView?.value = sliderValue
            cell.valueLabel?.text = NumberFormatter.percentFormatter.string(from: sliderValue as NSNumber)
            cell.sliderView?.removeTarget(self, action: nil, for: .allEvents)
            cell.sliderView?.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
            return cell
        }
        if item.cellType == OASimpleTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as? OASimpleTableViewCell {
            let isMapStyleDescriptionRow = item.key == RowKey.buildings3DMapStyleDescription.rawValue
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(isMapStyleDescriptionRow)
            cell.titleVisibility(!isMapStyleDescriptionRow)
            cell.textStackView.isHidden = cell.titleLabel.isHidden && cell.descriptionLabel.isHidden
            cell.setCustomLeftSeparatorInset(false)
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: .greatestFiniteMagnitude, bottom: 0.0, right: 0.0)
            cell.selectionStyle = isMapStyleDescriptionRow ? .none : .default
            cell.titleLabel.text = isMapStyleDescriptionRow ? nil : item.title
            cell.titleLabel.textColor = item.obj(forKey: ItemKey.tintTitle.rawValue) as? UIColor ?? .textColorSecondary
            cell.titleLabel.font = .preferredFont(forTextStyle: .body)
            cell.descriptionLabel.text = isMapStyleDescriptionRow ? item.title : nil
            return cell
        }
        if item.cellType == OAButtonTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier, for: indexPath) as? OAButtonTableViewCell {
            cell.titleVisibility(true)
            cell.descriptionVisibility(false)
            cell.textStackView.isHidden = cell.titleLabel.isHidden && cell.descriptionLabel.isHidden
            cell.selectionStyle = .none
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = item.obj(forKey: ItemKey.tintTitle.rawValue) as? UIColor
            cell.button.removeTarget(nil, action: nil, for: .allEvents)
            if item.key == RowKey.buildings3DColorChooseColor.rawValue {
                cell.setCustomLeftSeparatorInset(false)
                cell.separatorInset = .zero
                cell.leftIconVisibility(false)
                cell.leftIconView.image = nil
                cell.leftIconView.tintColor = nil
                cell.button.setTitle(nil, for: .normal)
                cell.button.setImage(nil, for: .normal)
                cell.button.contentHorizontalAlignment = .center
                if let secondaryIconName = item.secondaryIconName {
                    cell.button.configuration = ButtonConfigurationHelper.proBannerButtonConfiguration(imageName: secondaryIconName)
                }
                cell.button.setTitleColor(nil, for: .highlighted)
                cell.button.tintColor = nil
                cell.button.menu = nil
                cell.button.showsMenuAsPrimaryAction = false
                cell.button.changesSelectionAsPrimaryAction = false
                cell.button.addTarget(self, action: #selector(showChoosePlanScreen), for: .touchUpInside)
            } else {
                cell.leftIconVisibility(false)
                cell.button.setImage(nil, for: .normal)
                var config = UIButton.Configuration.plain()
                config.baseForegroundColor = .textColorActive
                config.contentInsets = NSDirectionalEdgeInsets(top: 3.1, leading: 16.0, bottom: 3.1, trailing: 0.0)
                config.title = localizedString(currentBuildings3DColorStyle == Buildings3DColorType.mapStyle.rawValue ? "quick_action_map_style" : "shared_string_custom")
                cell.button.configuration = config
                cell.button.setTitleColor(.textColorActive, for: .highlighted)
                cell.button.tintColor = .textColorActive
                cell.button.menu = createBuildings3DColorTypeMenu()
                cell.button.showsMenuAsPrimaryAction = true
                cell.button.changesSelectionAsPrimaryAction = true
                cell.button.contentHorizontalAlignment = .right
                cell.button.setContentHuggingPriority(.required, for: .horizontal)
                cell.button.setContentCompressionResistancePriority(.required, for: .horizontal)
                cell.layoutIfNeeded()
                if item.bool(forKey: ItemKey.hideSeparator.rawValue) {
                    cell.setCustomLeftSeparatorInset(true)
                    cell.separatorInset = UIEdgeInsets(top: 0.0, left: .greatestFiniteMagnitude, bottom: 0.0, right: 0.0)
                } else {
                    cell.setCustomLeftSeparatorInset(false)
                    cell.updateSeparatorInset()
                }
            }
            return cell
        }
        if item.cellType == OATitleDescriptionBigIconCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OATitleDescriptionBigIconCell.reuseIdentifier, for: indexPath) as? OATitleDescriptionBigIconCell {
            cell.showLeftIcon(false)
            cell.selectionStyle = .none
            cell.titleView.text = item.title
            cell.descriptionView.text = item.descr
            cell.rightIconView.image = item.icon
            cell.titleView.font = .preferredFont(forTextStyle: .body)
            cell.descriptionView.font = .preferredFont(forTextStyle: .footnote)
            return cell
        }
        if item.cellType == OACollectionSingleLineTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier, for: indexPath) as? OACollectionSingleLineTableViewCell {
            cell.rightActionButtonVisibility(true)
            cell.rightActionButton.setImage(UIImage.templateImageNamed("ic_custom_add"), for: .normal)
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row
            cell.rightActionButton.accessibilityLabel = localizedString("shared_string_add_color")
            cell.rightActionButton.removeTarget(nil, action: nil, for: .allEvents)
            let colorHandler = OAColorCollectionHandler(data: [sortedColorItems], collectionView: cell.collectionView)
            colorHandler?.delegate = self
            let activeItem = isNightColorMode ? currentNightColorItem : currentDayColorItem
            let selectedIndex = sortedColorItems.firstIndex(where: { $0 == activeItem }) ?? sortedColorItems.firstIndex(where: { $0 == appearanceCollection.getDefaultLineColorItem() }) ?? 0
            colorHandler?.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
            cell.setCollectionHandler(colorHandler)
            cell.rightActionButton.addTarget(self, action: #selector(onCellButtonPressed(_:)), for: .touchUpInside)
            return cell
        }
        if item.cellType == SegmentTextTableViewCell.reuseIdentifier, let cell = tableView.dequeueReusableCell(withIdentifier: SegmentTextTableViewCell.reuseIdentifier, for: indexPath) as? SegmentTextTableViewCell {
            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            cell.separatorInset = UIEdgeInsets(top: 0.0, left: .greatestFiniteMagnitude, bottom: 0.0, right: 0.0)
            cell.setSegmentedControlBottomSpacing(8.0)
            cell.configureSegmentedControl(titles: [localizedString("day"), localizedString("daynight_mode_night")], selectedSegmentIndex: isNightColorMode ? 1 : 0)
            cell.didSelectSegmentIndex = { [weak self] idx in
                self?.segmentChanged(idx)
            }
            return cell
        }
        
        return UITableViewCell()
    }
}

extension MapSettingsBuildings3DParametersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = data.item(for: indexPath)
        if item.key == RowKey.allColors.rawValue {
            let allColors = appearanceCollection.getAvailableColorsSortingByLastUsed() ?? []
            let selectedItem = (isNightColorMode ? currentNightColorItem : currentDayColorItem) ?? appearanceCollection.getDefaultLineColorItem()
            guard let selectedItem else { return }
            let colorCollectionViewController = ItemsCollectionViewController(collectionType: .colorItems, items: allColors, selectedItem: selectedItem)
            colorCollectionViewController.delegate = self
            if let colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                colorCollectionViewController.hostColorHandler = colorHandler
            }
            
            navigationController?.pushViewController(colorCollectionViewController, animated: true)
        }
    }
}

extension MapSettingsBuildings3DParametersViewController: OACollectionCellDelegate {
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem _: Any?, collectionView _: UICollectionView?, shouldDismiss _: Bool) {
        guard settingsType == .color else { return }
        let picked = sortedColorItems[indexPath.row]
        if isNightColorMode {
            currentNightColorItem = picked
        } else {
            currentDayColorItem = picked
        }
        
        if let colorsCollectionIndexPath, let cell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let handler = cell.getCollectionHandler() as? OAColorCollectionHandler {
            handler.setSelectedIndexPath(indexPath)
        }
        
        previewBuildings3DColor()
        isValueChange = currentDayColorItem != baseDayColorItem || currentNightColorItem != baseNightColorItem || currentBuildings3DColorStyle != baseBuildings3DColorStyle
        updateApplyButton()
    }
    
    func reloadCollectionData() {
        guard settingsType == .color, let plugin else { return }
        currentDayColorItem = appearanceCollection.getColorItem(withValue: plugin.buildings3dCustomDayColorPref.get()) ?? appearanceCollection.getDefaultLineColorItem()
        currentNightColorItem = appearanceCollection.getColorItem(withValue: plugin.buildings3dCustomNightColorPref.get()) ?? appearanceCollection.getDefaultLineColorItem()
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
    }
}

extension MapSettingsBuildings3DParametersViewController: ColorCollectionViewControllerDelegate {
    func selectColorItem(_ colorItem: ColorItem) {
        guard settingsType == .color else { return }
        if let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            onCollectionItemSelected(IndexPath(row: row, section: 0), selectedItem: nil, collectionView: nil, shouldDismiss: true)
        }
    }
    
    func addAndGetNewColorItem(_ color: UIColor) -> ColorItem {
        guard settingsType == .color else { return ColorItem(hexColor: color.toHexString()) }
        guard let newColorItem = appearanceCollection.addNewSelectedColor(color) else { return ColorItem(hexColor: color.toHexString()) }
        if let colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
            sortedColorItems.insert(newColorItem, at: 0)
            colorHandler.addAndSelectColor(IndexPath(row: 0, section: 0), newItem: newColorItem)
        }
        
        return newColorItem
    }
    
    func changeColorItem(_ colorItem: ColorItem, withColor color: UIColor) {
        guard settingsType == .color else { return }
        if let colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler, let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            appearanceCollection.changeColor(colorItem, newColor: color)
            colorHandler.replaceOldColor(IndexPath(row: row, section: 0))
        }
    }
    
    func duplicateColorItem(_ colorItem: ColorItem) -> ColorItem {
        guard settingsType == .color else { return colorItem }
        guard let duplicatedColorItem = appearanceCollection.duplicateColor(colorItem) else { return colorItem }
        if let colorsCollectionIndexPath, let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            sortedColorItems.insert(duplicatedColorItem, at: row + 1)
            if let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                let newIndexPath = IndexPath(row: row + 1, section: 0)
                colorHandler.addColor(newIndexPath, newItem: duplicatedColorItem)
            }
        }
        
        return duplicatedColorItem
    }
    
    func deleteColorItem(_ colorItem: ColorItem) {
        guard settingsType == .color else { return }
        if let colorsCollectionIndexPath, let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            let indexPathForColor = IndexPath(row: row, section: 0)
            appearanceCollection.deleteColor(colorItem)
            sortedColorItems.remove(at: row)
            if let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                colorHandler.removeColor(indexPathForColor)
            }
        }
    }
}

extension MapSettingsBuildings3DParametersViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewController(_: UIColorPickerViewController, didSelect color: UIColor, continuously _: Bool) {
        guard settingsType == .color, OAUtilities.isiOSAppOnMac() else { return }
        _ = addAndGetNewColorItem(color)
    }
    
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        guard settingsType == .color else { return }
        _ = addAndGetNewColorItem(viewController.selectedColor)
    }
}
