//
//  MapSettingsMapModeParametersViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 18.09.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

final class MapSettingsMapModeParametersViewController: BaseSettingsParametersViewController {

    private let newImageSize: CGFloat = 20
    
    private lazy var baseAppearanceMode = DayNightMode(rawValue: settings.appearanceMode.get())
    private lazy var currentAppearanceMode = DayNightMode(rawValue: settings.appearanceMode.get())

    override func updateModeUI() {
        updateModeUI(isValueChanged: baseAppearanceMode != currentAppearanceMode, animated: true)
    }
    
    override func registerCells() {
        tableView.register(UINib(nibName: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier,
                                 bundle: nil),
                           forCellReuseIdentifier: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier)
        tableView.register(UINib(nibName: OASimpleTableViewCell.reuseIdentifier, bundle: nil),
                           forCellReuseIdentifier: OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        super.generateData()

        let section = createSectionWithName()
        
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
    
    override func headerName() -> String {
        localizedString("map_mode")
    }
    
    override func hide() {
        OADayNightHelper.instance().resetTempMode()

        hide(true, duration: hideDuration) { [weak self] in
            guard let self else { return }

            mapPanel.mapSettingsButtonClick("")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = tableData.item(for: indexPath)

        if item.cellType == SegmentImagesWithRightLabelTableViewCell.reuseIdentifier {
            var selectedMode = currentAppearanceMode?.rawValue ?? 0
            if currentAppearanceMode == .appTheme {
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

                currentAppearanceMode = DayNightMode(rawValue: Int32(index))
                if currentAppearanceMode == nil && index == 3 { // todo: compatibility with Android, 3 - light sensor
                    currentAppearanceMode = .appTheme
                }
                updateModeUI()
                if let currentAppearanceMode {
                    OADayNightHelper.instance().setTempMode(Int(currentAppearanceMode.rawValue))
                }
            }
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let isName = item.key == "name"
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.selectionStyle = .none
            cell.setCustomLeftSeparatorInset(true)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.titleLabel.font = .preferredFont(forTextStyle: isName ? .body : .subheadline)
            cell.titleLabel.textColor = isName ? .textColorPrimary : UIColor(rgb: color_extra_text_gray)
            cell.titleLabel.text = isName ? currentAppearanceMode?.title : currentAppearanceMode?.desc
            cell.titleLabel.accessibilityLabel = cell.titleLabel.text
            return cell
        }
        return UITableViewCell()
    }
    
    private func getImagesFromModes(_ selected: Bool) -> [UIImage] {
        DayNightMode.allCases.compactMap({
            if let image = UIImage(named: selected ? $0.selectedIconName : $0.iconName) {
                return OAUtilities.resize(image, newSize: CGSize(width: newImageSize, height: newImageSize))
            }
            return UIImage()
        })
    }

    override func onApplyButtonPressed() {
        if let currentAppearanceMode {
            settings.appearanceMode.set(currentAppearanceMode.rawValue)
        }
        super.onApplyButtonPressed()
    }

    override func resetButtonPressed() {
        currentAppearanceMode = baseAppearanceMode
        updateModeUI()
        if let baseAppearanceMode {
            OADayNightHelper.instance().setTempMode(Int(baseAppearanceMode.rawValue))
        }
        super.resetButtonPressed()
    }
}
