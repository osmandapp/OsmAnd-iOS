//
//  MapButtonAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 16.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class MapButtonAppearanceViewController: OABaseNavbarSubviewViewController {
    private static let valueKey = "valueKey"
    private static let unitKey = "unitKey"
    private static let glassStyleKey = "glassStyleKey"
    private static let arrayValuesKey = "arrayValuesKey"
    private static let cornerRadiusRowKey = "cornerRadiusRowKey"
    private static let cornerRadiusArrayValues: [Int32] = [3, 6, 9, 12, 36]
    private static let sizeRowKey = "sizeRowKey"
    private static let sizeArrayValues: [Int32] = [40, 48, 56, 64, 72]
    private static let backgroundOpacityRowKey = "backgroundOpacityRowKey"
    
    weak var mapButtonState: MapButtonState?
    weak var delegate: OASettingsDataDelegate?
    
    private var appMode: OAApplicationMode?
    private var appearanceParams: ButtonAppearanceParams?
    private var originalAppearanceParams: ButtonAppearanceParams?
    private var iconCollectionHandler: ButtonAppearanceIconCollectionHandler?
    private var opacityType: BackgroundOpacityType = .solid
    private let previewImageHeight: CGFloat = 150
    
    private var hasAppearanceChanged: Bool {
        appearanceParams != originalAppearanceParams
    }
    
    private lazy var previewImageView: PreviewImageView? = {
        guard let mapButtonState else { return nil }
        let previewImageView: PreviewImageView = .fromNib()
        previewImageView.configure(appearanceParams: appearanceParams, buttonState: mapButtonState)
        return previewImageView
    }()
    
    override func commonInit() {
        appMode = OAAppSettings.sharedManager().applicationMode.get()
    }
    
    override func viewDidLoad() {
        setupAppearanceParams()
        if #available(iOS 26.0, *) {
            setupOpacityType()
        }
        setupIconHandler()
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateSubviewHeight(previewImageHeight)
        updateSubview(true)
    }
    
    override func getTitle() -> String {
        localizedString("shared_string_appearance")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(nil, iconName: "ic_navbar_reset", action: #selector(onRightNavbarButtonPressed), menu: nil)]
    }
    
    override func onLeftNavbarButtonPressed() {
        if hasAppearanceChanged {
            showUnsavedChangesAlert()
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }
    
    override func onRightNavbarButtonPressed() {
        showResetToDefaultActionSheet()
    }
    
    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .vertical
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        hasAppearanceChanged ? .purple : .inactive
    }
    
    override func onBottomButtonPressed() {
        guard hasAppearanceChanged, let appearanceParams else { return }
        if let iconName = appearanceParams.iconName {
            mapButtonState?.storedIconPref().set(iconName)
        }
        mapButtonState?.storedSizePref().set(appearanceParams.size)
        mapButtonState?.storedCornerRadiusPref().set(appearanceParams.cornerRadius)
        mapButtonState?.storedOpacityPref().set(Double(appearanceParams.opacity))
        mapButtonState?.storedGlassStylePref().set(appearanceParams.glassStyle)
        delegate?.onSettingsChanged()
        dismiss()
    }
    
    override func getBottomButtonTitle() -> String {
        localizedString("shared_string_apply")
    }
    
    override func registerCells() {
        addCell(SegmentButtonsSliderTableViewCell.reuseIdentifier)
        addCell(TopBottomValuesSliderTableViewCell.reuseIdentifier)
        addCell(OAIconsPaletteCell.reuseIdentifier)
    }
    
    override func generateData() {
        guard let appearanceParams else { return }
        tableData.clearAllData()
        
        let iconSection = tableData.createNewSection()
        let iconRow = iconSection.createNewRow()
        iconRow.cellType = OAIconsPaletteCell.reuseIdentifier
        iconRow.title = localizedString("shared_string_icon")
        iconRow.descr = localizedString("shared_string_all_icons")
        
        let sizeSection = tableData.createNewSection()
        let sizeSliderRow = sizeSection.createNewRow()
        sizeSliderRow.cellType = SegmentButtonsSliderTableViewCell.reuseIdentifier
        sizeSliderRow.key = Self.sizeRowKey
        sizeSliderRow.title = localizedString("shared_string_size")
        sizeSliderRow.setObj(Self.sizeArrayValues.map { String($0) }, forKey: Self.arrayValuesKey)
        sizeSliderRow.setObj(String(appearanceParams.size), forKey: Self.valueKey)
        sizeSliderRow.setObj(localizedString("shared_string_pt"), forKey: Self.unitKey)
        
        let cornerRadiusSection = tableData.createNewSection()
        let cornerRadiusSliderRow = cornerRadiusSection.createNewRow()
        cornerRadiusSliderRow.cellType = SegmentButtonsSliderTableViewCell.reuseIdentifier
        cornerRadiusSliderRow.key = Self.cornerRadiusRowKey
        cornerRadiusSliderRow.title = localizedString("corner_radius")
        cornerRadiusSliderRow.setObj(Self.cornerRadiusArrayValues.map { String($0) }, forKey: Self.arrayValuesKey)
        cornerRadiusSliderRow.setObj(String(appearanceParams.cornerRadius), forKey: Self.valueKey)
        cornerRadiusSliderRow.setObj(localizedString("shared_string_pt"), forKey: Self.unitKey)
        
        let backgroundOpacitySection = tableData.createNewSection()
        let backgroundOpacityRow = backgroundOpacitySection.createNewRow()
        backgroundOpacityRow.key = Self.backgroundOpacityRowKey
        backgroundOpacityRow.cellType = TopBottomValuesSliderTableViewCell.reuseIdentifier
        backgroundOpacityRow.title = localizedString("shared_background")
        backgroundOpacityRow.setObj(appearanceParams.opacity as Any, forKey: Self.valueKey)
        backgroundOpacityRow.setObj(appearanceParams.glassStyle as Any, forKey: Self.glassStyleKey)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == SegmentButtonsSliderTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SegmentButtonsSliderTableViewCell.reuseIdentifier) as? SegmentButtonsSliderTableViewCell,
                  let value = item.obj(forKey: Self.valueKey) as? String,
                  let unit = item.obj(forKey: Self.unitKey) as? String else {
                return UITableViewCell()
            }
            let arrayValue = item.obj(forKey: Self.arrayValuesKey) as? [String] ?? []
            cell.delegate = self
            cell.sliderView.setNumberOfMarks(arrayValue.count)
            cell.sliderView.maximumTrackTintColor = .sliderLineBg
            if let index = arrayValue.firstIndex(of: value) {
                cell.sliderView.selectedMark = index
                cell.setupButtonsEnabling()
            }
            cell.sliderView.tag = (indexPath.section << 10) | indexPath.row
            cell.topLeftLabel.text = item.title
            cell.topLeftLabel.accessibilityLabel = cell.topLeftLabel.text
            cell.topRightLabel.text = String(format: localizedString("ltr_or_rtl_combine_via_space"), value, unit)
            cell.topRightLabel.accessibilityLabel = cell.topRightLabel.text
            return cell
        } else if item.cellType == TopBottomValuesSliderTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: TopBottomValuesSliderTableViewCell.reuseIdentifier) as? TopBottomValuesSliderTableViewCell, let value = item.obj(forKey: Self.valueKey) as? Float else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.slider.value = value
            cell.slider.tag = (indexPath.section << 10) | indexPath.row
            cell.slider.removeTarget(self, action: nil, for: .valueChanged)
            cell.slider.addTarget(self, action: #selector(sliderChanged(sender:)), for: .valueChanged)
            cell.slider.tintColor = .menuButton
            cell.slider.maximumTrackTintColor = .sliderLineBg
            cell.topLeftLabel.text = item.title
            
            if #available(iOS 26, *) {
                cell.topRightButton.showsMenuAsPrimaryAction = true
                cell.topRightButton.menu = createOpacityModeMenu()
                let config = UIImage.SymbolConfiguration(pointSize: 17)
                if var iconImage = UIImage(systemName: "chevron.up.chevron.down", withConfiguration: config) {
                    iconImage = iconImage.withRenderingMode(.alwaysTemplate)
                    let attachment = NSTextAttachment()
                    attachment.image = iconImage
                    let imageString = NSAttributedString(attachment: attachment)
                    
                    let attributedString = NSMutableAttributedString(string: opacityType.title + " ")
                    attributedString.append(imageString)
                    cell.topRightButton.setAttributedTitle(attributedString, for: .normal)
                }
                cell.topRightLabelVisibility(false)
                cell.topRightButtonVisibility(true)
                cell.sliderValuesVisibility(opacityType == .solid)
                cell.segmentValuesVisibility(opacityType == .liquidGlass)
                cell.segmentedControl.setTitle(localizedString("background_liquid_glass_clear_ios"), forSegmentAt: 0)
                cell.segmentedControl.setTitle(localizedString("shared_string_tinted"), forSegmentAt: 1)
                cell.segmentedControl.removeTarget(self, action: nil, for: .valueChanged)
                cell.segmentedControl.addTarget(self, action: #selector(segmentChanged(sender:)), for: .valueChanged)
                if let glassStyle = item.obj(forKey: Self.glassStyleKey) as? Int32 {
                    cell.segmentedControl.selectedSegmentIndex = glassStyle == UIGlassEffect.Style.regular.rawValue ? 1 : 0
                }
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineHeightMultiple = 1.12
                cell.descriptionLabel.attributedText = NSAttributedString(string: localizedString("background_opacity_description"), attributes: [.paragraphStyle: paragraphStyle])
            } else {
                cell.topRightLabel.text = NumberFormatter.percentFormatter.string(from: value as NSNumber)
                cell.topRightLabel.textColor = .textColorSecondary
                cell.topRightLabelVisibility(true)
                cell.topRightButtonVisibility(false)
                cell.sliderValuesVisibility(true)
                cell.segmentValuesVisibility(false)
            }
            
            cell.bottomLeftLabel.text = NumberFormatter.percentFormatter.string(from: cell.slider.minimumValue as NSNumber)
            cell.bottomLeftLabel.textColor = .textColorSecondary
            cell.bottomRightLabel.text = NumberFormatter.percentFormatter.string(from: cell.slider.maximumValue as NSNumber)
            cell.bottomRightLabel.textColor = .textColorSecondary
            return cell
        } else if item.cellType == OAIconsPaletteCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OAIconsPaletteCell.reuseIdentifier) as? OAIconsPaletteCell else {
                return UITableViewCell()
            }
            cell.useMultyLines = false
            cell.forceScrollOnStart = true
            cell.disableAnimationsOnStart = true
            cell.topLabel.font = .preferredFont(forTextStyle: .body)
            cell.topLabel.textColor = .textColorPrimary
            cell.hostVC = self
            cell.descriptionLabel.text = localizedString("dynamic_icon_type_summary")
            iconCollectionHandler?.setCollectionView(cell.collectionView)
            cell.setCollectionHandler(iconCollectionHandler)
            iconCollectionHandler?.updateHostCellIfNeeded()
            cell.topLabel.text = item.title
            cell.topButtonVisibility(true)
            cell.bottomButton.setTitle(item.descr, for: .normal)
            cell.collectionView.reloadData()
            return cell
        }
        return nil
    }
    
    override func createSubview() -> UIView? {
        previewImageView
    }
    
    override func subviewMargin() -> UIEdgeInsets {
        .zero
    }
    
    private func setupAppearanceParams() {
        guard let mapButtonState else { return }
        let savedIconName = mapButtonState.savedIconName()
        appearanceParams = mapButtonState.createAppearanceParams()
        originalAppearanceParams = mapButtonState.createAppearanceParams()
        appearanceParams?.iconName = savedIconName
        originalAppearanceParams?.iconName = savedIconName
    }
    
    private func setupOpacityType() {
        guard let appearanceParams else { return }
        opacityType = appearanceParams.glassStyle == MapButtonState.defaultGlassStyle ? .solid : .liquidGlass
    }
    
    private func createOpacityModeMenu() -> UIMenu {
        let solidAction = UIAction(title: BackgroundOpacityType.solid.title, state: opacityType == .solid ? .on : .off) { [weak self] _ in
            self?.switchOpacityType(to: .solid)
        }
        let liquidGlassAction = UIAction(title: BackgroundOpacityType.liquidGlass.title, state: opacityType == .liquidGlass ? .on : .off) { [weak self] _ in
            self?.switchOpacityType(to: .liquidGlass)
        }
        return UIMenu.composedMenu(from: [[solidAction], [liquidGlassAction]])
    }
    
    private func switchOpacityType(to opacityType: BackgroundOpacityType) {
        self.opacityType = opacityType
        appearanceParams?.glassStyle = opacityType == .liquidGlass ? 1 : MapButtonState.defaultGlassStyle
        updateData()
    }
    
    private func setupIconHandler() {
        guard let iconName = appearanceParams?.iconName else { return }
        
        let iconKeys: [String] = {
            if let quickActionState = mapButtonState as? QuickActionButtonState, !quickActionState.isSingleAction() {
                return [quickActionState.defaultPreviewIconName()] + quickActionState.quickActions.compactMap { $0.getIconResName() }
            }
            if let defaultIcon = mapButtonState?.defaultPreviewIconName() {
                return [defaultIcon]
            }
            return []
        }()
            
        guard !iconKeys.isEmpty else { return }
        iconCollectionHandler = ButtonAppearanceIconCollectionHandler(customIconKeys: iconKeys)
        iconCollectionHandler?.delegate = self
        iconCollectionHandler?.handlerDelegate = self
        iconCollectionHandler?.hostVC = self
        iconCollectionHandler?.regularIconColor = .iconColorSecondary
        iconCollectionHandler?.selectedIconColor = UIColor(rgb: OAAppSettings.sharedManager().profileIconColor.get())
        iconCollectionHandler?.setItemSize(size: 48)
        iconCollectionHandler?.setIconBackgroundSize(size: 36)
        iconCollectionHandler?.setIconSize(size: 24)
        iconCollectionHandler?.setSpacing(spacing: 9)
        iconCollectionHandler?.setIconName(iconName)
    }
    
    private func updatePreview() {
        guard let mapButtonState else { return }
        previewImageView?.configure(appearanceParams: appearanceParams, buttonState: mapButtonState)
    }
    
    private func showUnsavedChangesAlert() {
        let alert: UIAlertController = UIAlertController(title: localizedString("unsaved_changes"),
                                                         message: localizedString("unsaved_changes_will_be_lost_discard"),
                                                         preferredStyle: .alert)
        let discardAction = UIAlertAction(title: localizedString("shared_string_discard"), style: .default) { _ in
            self.dismiss()
        }

        let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .default, handler: nil)

        alert.addAction(cancelAction)
        alert.addAction(discardAction)
        alert.preferredAction = discardAction

        present(alert, animated: true)
    }
    
    private func showResetToDefaultActionSheet() {
        let actionSheet = UIAlertController(title: localizedString("reset_to_default"),
                                            message: localizedString("reset_all_settings_desc"),
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { [weak self] _ in
            self?.resetAppearanceToDefault()
        })
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(actionSheet, animated: true)
    }
    
    private func resetAppearanceToDefault() {
        guard let mapButtonState else { return }
        let defaultParams = mapButtonState.createDefaultAppearanceParams()
        appearanceParams?.iconName = ""
        iconCollectionHandler?.setIconName("")
        iconCollectionHandler?.selectCategory(ButtonAppearanceIconCollectionHandler.dynamicKey)
        appearanceParams?.size = defaultParams.size
        appearanceParams?.cornerRadius = defaultParams.cornerRadius
        appearanceParams?.opacity = defaultParams.opacity
        appearanceParams?.glassStyle = defaultParams.glassStyle
        opacityType = .solid
        updateData()
    }
    
    private func setAppearanceParameter(_ selectedIndex: Int, sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.cellForRow(at: indexPath) as? SegmentButtonsSliderTableViewCell else {
            return
        }
        var value: Int32?
        if item.key == Self.cornerRadiusRowKey {
            appearanceParams?.cornerRadius = Self.cornerRadiusArrayValues[selectedIndex]
            value = appearanceParams?.cornerRadius
        } else if item.key == Self.sizeRowKey {
            appearanceParams?.size = Self.sizeArrayValues[selectedIndex]
            value = appearanceParams?.size
        }
        if let value {
            cell.topRightLabel.text = String(format: localizedString("ltr_or_rtl_combine_via_space"), String(value), localizedString("shared_string_pt"))
            cell.topRightLabel.accessibilityLabel = cell.topRightLabel.text
        }
        cell.setupButtonsEnabling()
        updateBottomButtons()
        updatePreview()
    }
    
    private func updateData() {
        reloadDataWith(animated: true, completion: nil)
        updateBottomButtons()
        updatePreview()
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        if item.key == Self.backgroundOpacityRowKey {
            appearanceParams?.opacity = Double(sender.value)
            updateData()
        }
    }
    
    @available(iOS 26.0, *)
    @objc private func segmentChanged(sender: UISegmentedControl) {
        appearanceParams?.glassStyle = Int32(sender.selectedSegmentIndex == 0 ? UIGlassEffect.Style.clear.rawValue : UIGlassEffect.Style.regular.rawValue)
        updateData()
    }
}

// MARK: - SegmentButtonsSliderTableViewCellDelegate
extension MapButtonAppearanceViewController: SegmentButtonsSliderTableViewCellDelegate {
    func onPlusTapped(_ selectedMark: Int, sender: UISlider) {
        setAppearanceParameter(selectedMark, sender: sender)
    }
    
    func onMinusTapped(_ selectedMark: Int, sender: UISlider) {
        setAppearanceParameter(selectedMark, sender: sender)
    }
    
    func onSliderValueChanged(_ selectedMark: Int, sender: UISlider) {
        setAppearanceParameter(selectedMark, sender: sender)
    }
}

// MARK: - OACollectionCellDelegate
extension MapButtonAppearanceViewController: OACollectionCellDelegate {
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem: Any, collectionView: UICollectionView, shouldDismiss: Bool) {
        if let selectedItem = iconCollectionHandler?.getSelectedItem() as? String {
            appearanceParams?.iconName = selectedItem
        }
        updateData()
    }
}

// MARK: - OABaseCollectionHandlerDelegate
extension MapButtonAppearanceViewController: OABaseCollectionHandlerDelegate {
    func onCategorySelected(_ category: String, with cell: OACollectionSingleLineTableViewCell) {
        if category == ButtonAppearanceIconCollectionHandler.dynamicKey {
            appearanceParams?.iconName = ""
        }
        updateData()
    }
}
