//
//  ProfileAppearanceIconSizeViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 28.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objcMembers
final class ProfileAppearanceIconSizeViewController: BaseSettingsParametersViewController {
    var appMode: OAApplicationMode?
    var isNavigationIconSize: Bool = false
    
    private lazy var baseIconSize: Double = {
        guard let appMode else { return 0 }
        return isNavigationIconSize ? settings.locationIconSize.get(appMode) : settings.profileIconSize.get(appMode)
    }()
    
    private lazy var currentIconSize: Double = baseIconSize
    
    private let iconSizeArrayValueKey = "iconSizeArrayValueKey"
    private let iconSizeSelectedValueKey = "iconSizeSelectedValueKey"
    private let iconSizeArrayValues: [Double] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 2.5, 3.0]
    
    override func updateModeUI() {
        updateModeUI(isValueChanged: baseIconSize != currentIconSize)
    }
    
    override func registerCells() {
        tableView.register(UINib(nibName: OAValueTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OAValueTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASegmentSliderTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OASegmentSliderTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        super.generateData()

        let section = createSectionWithName()
        
        section.addRow(from: [
            kCellKeyKey: "name",
            kCellTypeKey: OAValueTableViewCell.reuseIdentifier
        ])
        
        section.addRow(from: [
            kCellKeyKey: "slider",
            kCellTypeKey: OASegmentSliderTableViewCell.reuseIdentifier,
            iconSizeSelectedValueKey: String(currentIconSize),
            iconSizeArrayValueKey: iconSizeArrayValues.map { String($0) }
        ])
    }
    
    override func headerName() -> String {
        localizedString("icon_size")
    }
    
    override func hide() {
        hide(true, duration: hideDuration) { [weak self] in
            guard let self, let settingsVC = OAMainSettingsViewController(targetAppMode: appMode, targetScreenKey: kProfileAppearanceSettings) else { return }

            OARootViewController.instance().navigationController?.pushViewController(settingsVC, animated: false)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)

        if item.cellType == OASegmentSliderTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OASegmentSliderTableViewCell.reuseIdentifier) as? OASegmentSliderTableViewCell else {
                return UITableViewCell()
            }
            let arrayValue = item.obj(forKey: iconSizeArrayValueKey) as? [String] ?? []
            cell.showAllLabels(false)
            cell.delegate = self
            cell.sliderView.setNumberOfMarks(arrayValue.count)
            if let customString = item.obj(forKey: iconSizeSelectedValueKey) as? String, let index = arrayValue.firstIndex(of: customString) {
                cell.sliderView.selectedMark = index
                cell.setupButtonsEnabling()
            }
            cell.sliderView.tag = (indexPath.section << 10) | indexPath.row
            cell.sliderView.removeTarget(self, action: nil, for: [.touchUpInside, .touchUpOutside])
            cell.sliderView.addTarget(self, action: #selector(sliderChanged(sender:)), for: [.touchUpInside, .touchUpOutside])
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as? OAValueTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.setCustomLeftSeparatorInset(true)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.titleLabel.text = localizedString("shared_string_size")
            cell.titleLabel.accessibilityLabel = cell.titleLabel.text
            cell.valueLabel.text = OAUtilities.getPercentString(currentIconSize)
            cell.valueLabel.accessibilityLabel = cell.valueLabel.text
            return cell
        }
        return UITableViewCell()
    }
    
    override func onApplyButtonPressed() {
        guard let appMode else { return }
        if isNavigationIconSize {
            settings.locationIconSize.set(currentIconSize, mode: appMode)
        } else {
            settings.profileIconSize.set(currentIconSize, mode: appMode)
        }
        super.onApplyButtonPressed()
    }
    
    override func resetButtonPressed() {
        currentIconSize = baseIconSize
        updateModeUI()
        super.resetButtonPressed()
    }
    
    private func setCurrentIconSize(_ selectedIndex: Int) {
        currentIconSize = iconSizeArrayValues[selectedIndex]
        generateData()
        updateModeUI()
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        guard let cell = tableView.cellForRow(at: indexPath) as? OASegmentSliderTableViewCell else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        guard selectedIndex >= 0, selectedIndex < iconSizeArrayValues.count else { return }
        setCurrentIconSize(selectedIndex)
    }
}

// MARK: - OASegmentSliderTableViewCellDelegate
extension ProfileAppearanceIconSizeViewController: OASegmentSliderTableViewCellDelegate {
    func onPlusTapped(_ selectedMark: Int) {
        setCurrentIconSize(selectedMark)
    }
    
    func onMinusTapped(_ selectedMark: Int) {
        setCurrentIconSize(selectedMark)
    }
}
