//
//  DefaultMapButtonViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 08.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class DefaultMapButtonViewController: OABaseNavbarViewController {
    private static let descriptionFontSize: CGFloat = 15
    private static let selectedKey = "selected"
    private static let visibilityRowKey = "visibilityRowKey"
    private static let appearanceRowKey = "appearanceRowKey"
    
    weak var mapButtonState: MapButtonState?
    weak var delegate: OASettingsDataDelegate?
    
    private var appMode: OAApplicationMode?
    
    override func commonInit() {
        appMode = OAAppSettings.sharedManager().applicationMode.get()
    }
    
    override func getTitle() -> String {
        mapButtonState?.getName() ?? ""
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(PreviewImageViewTableViewCell.reuseIdentifier)
        addCell(OASwitchTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        var resetAlert: UIAlertController?
        resetAlert = UIAlertController(title: title,
                                       message: localizedString("reset_all_settings_desc"),
                                       preferredStyle: .actionSheet)
        let resetAction: UIAction = UIAction(title: localizedString("reset_to_default"),
                                             image: .icCustomReset) { [weak self] _ in
            let actionSheet = UIAlertController(title: self?.title,
                                                message: localizedString("reset_all_settings_desc"),
                                                preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { _ in
                guard let self, let appMode = self.appMode else { return }
                self.mapButtonState?.resetForMode(appMode)
                self.updateData()
            })
            actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
            if let popoverController = actionSheet.popoverPresentationController {
                popoverController.barButtonItem = self?.navigationItem.rightBarButtonItem
            }
            self?.present(actionSheet, animated: true)
        }
        let copyAction: UIAction = UIAction(title: localizedString("copy_from_other_profile"),
                                            image: .icCustomCopy) { [weak self] _ in
            guard let self, let appMode = self.appMode else { return }
            
            let bottomSheet: OACopyProfileBottomSheetViewControler = OACopyProfileBottomSheetViewControler(mode: appMode)
            bottomSheet.delegate = self
            bottomSheet.present(in: self)
        }
        let menuElements = [resetAction, copyAction]
        let menu = UIMenu(children: menuElements)
        let button = createRightNavbarButton(nil,
                                             iconName: "ic_navbar_overflow_menu_stroke",
                                             action: #selector(onRightNavbarButtonPressed),
                                             menu: menu)
        button?.accessibilityLabel = localizedString("shared_string_options")
        let popover = resetAlert?.popoverPresentationController
        popover?.barButtonItem = button
        var buttons = [UIBarButtonItem]()
        if let button {
            buttons.append(button)
        }
        return buttons
    }
    
    override func generateData() {
        guard let appMode else { return }
        tableData.clearAllData()
        let visibilitySection = tableData.createNewSection()
        let imageHeaderRow = visibilitySection.createNewRow()
        imageHeaderRow.cellType = PreviewImageViewTableViewCell.reuseIdentifier
        
        let descriptionRow = visibilitySection.createNewRow()
        descriptionRow.title = mapButtonState?.buttonDescription()
        descriptionRow.cellType = OASimpleTableViewCell.reuseIdentifier
        
        let visibilityRow = visibilitySection.createNewRow()
        visibilityRow.title = localizedString("visibility")
        visibilityRow.accessibilityLabel = visibilityRow.title
        visibilityRow.iconTintColor = appMode.getProfileColor()
        if let boolPref = mapButtonState?.storedVisibilityPref() as? OACommonBoolean {
            visibilityRow.setObj(NSNumber(value: boolPref.get(appMode)), forKey: Self.selectedKey)
            visibilityRow.cellType = OASwitchTableViewCell.reuseIdentifier
        } else if let intPref = mapButtonState?.storedVisibilityPref() as? OACommonInteger {
            if mapButtonState is CompassButtonState, let visibility = CompassVisibility(rawValue: intPref.get(appMode)) {
                visibilityRow.iconName = visibility.iconName
                visibilityRow.descr = visibility.title
                visibilityRow.setObj(NSNumber(value: visibility != .alwaysHidden), forKey: Self.selectedKey)
            } else if mapButtonState is Map3DButtonState, let visibility = Map3DModeVisibility(rawValue: intPref.get(appMode)) {
                visibilityRow.iconName = visibility.iconName
                visibilityRow.descr = visibility.title
                visibilityRow.setObj(NSNumber(value: visibility != .hidden), forKey: Self.selectedKey)
            }
            visibilityRow.key = Self.visibilityRowKey
            visibilityRow.cellType = OAValueTableViewCell.reuseIdentifier
        }
        
        let appearanceSection = tableData.createNewSection()
        let appearanceRow = appearanceSection.createNewRow()
        appearanceRow.title = localizedString("shared_string_appearance")
        appearanceRow.accessibilityLabel = appearanceRow.title
        appearanceRow.descr = localizedString("rendering_value_default_name") // TODO
        appearanceRow.key = Self.appearanceRowKey
        appearanceRow.cellType = OAValueTableViewCell.reuseIdentifier
        appearanceRow.iconName = "ic_custom_appearance"
        appearanceRow.iconTintColor = .iconColorDefault
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        guard let mapButtonState else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == PreviewImageViewTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: PreviewImageViewTableViewCell.reuseIdentifier) as! PreviewImageViewTableViewCell
            cell.configure(appearanceParams: nil, buttonState: mapButtonState)
            if mapButtonState is CompassButtonState {
                cell.rotateImage(-CGFloat(OARootViewController.instance().mapPanel.mapViewController.azimuth()) / 180.0 * CGFloat.pi)
            }
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.selectionStyle = .none
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = .textColorSecondary
            cell.titleLabel.font = .systemFont(ofSize: Self.descriptionFontSize)
            cell.setCustomLeftSeparatorInset(true)
            cell.separatorInset = .zero
            return cell
        } else if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier) as! OASwitchTableViewCell
            let selected = item.bool(forKey: Self.selectedKey)
            cell.descriptionVisibility(false)
            cell.leftIconView.image = UIImage.templateImageNamed(selected ? "ic_custom_show" : "ic_custom_hide")
            cell.leftIconView.tintColor = selected ? item.iconTintColor : .iconColorDefault
            cell.titleLabel.text = item.title
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            cell.switchView.isOn = selected
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.accessoryType = .disclosureIndicator
            if item.key == Self.visibilityRowKey {
                let selected = item.bool(forKey: Self.selectedKey)
                cell.leftIconView.tintColor = selected ? item.iconTintColor : .iconColorDefault
            } else {
                cell.leftIconView.tintColor = item.iconTintColor
            }
            cell.accessibilityLabel = item.accessibilityLabel
            cell.accessibilityValue = item.accessibilityValue
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.key == Self.appearanceRowKey {
            guard let vc = MapButtonAppearanceViewController() else { return }
            vc.mapButtonState = mapButtonState
            show(vc)
        } else {
            if mapButtonState is CompassButtonState {
                let vc = CompassVisibilityViewController()
                vc.delegate = self
                showMediumSheetViewController(vc, isLargeAvailable: false)
            } else if mapButtonState is Map3DButtonState {
                let vc = Map3dModeButtonVisibilityViewController()
                vc.delegate = self
                showMediumSheetViewController(vc, isLargeAvailable: false)
            }
        }
    }
    
    private func updateData() {
        reloadDataWith(animated: true, completion: nil)
        delegate?.onSettingsChanged()
    }
    
    @objc private func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        if let boolPref = mapButtonState?.storedVisibilityPref() as? OACommonBoolean, let appMode {
            boolPref.set(sw.isOn, mode: appMode)
        }
        updateData()
        
        return false
    }
}

// MARK: WidgetStateDelegate
extension DefaultMapButtonViewController: WidgetStateDelegate {
    func onWidgetStateChanged() {
        updateData()
    }
}

// MARK: OACopyProfileBottomSheetDelegate
extension DefaultMapButtonViewController: OACopyProfileBottomSheetDelegate {
    func onCopyProfileCompleted() {
    }
    func onCopyProfile(_ fromAppMode: OAApplicationMode) {
        guard let appMode else { return }
        mapButtonState?.copyForMode(from: fromAppMode, to: appMode)
        updateData()
    }
}
