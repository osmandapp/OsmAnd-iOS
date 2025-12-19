//
//  MapButtonAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Vladyslav Lysenko on 16.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@objc
final class MapButtonAppearanceViewController: OABaseNavbarViewController {
    private static let valueKey = "valueKey"
    private static let arrayValuesKey = "arrayValuesKey"
    private static let cornerRadiusRowKey = "cornerRadiusRowKey"
    private static let cornerRadiusArrayValues: [Int32] = [3, 6, 9, 12, 36]
    
    weak var mapButtonState: MapButtonState?
    
    private var appMode: OAApplicationMode?
    private var appearanceParams: ButtonAppearanceParams?
    private var originalAppearanceParams: ButtonAppearanceParams?
    
    override func commonInit() {
        appMode = OAAppSettings.sharedManager().applicationMode.get()
    }
    
    override func viewDidLoad() {
        guard let mapButtonState else { return }
        let savedIconName = mapButtonState.savedIconName()
        appearanceParams = mapButtonState.createAppearanceParams()
        originalAppearanceParams = mapButtonState.createAppearanceParams()
        appearanceParams?.iconName = savedIconName
        originalAppearanceParams?.iconName = savedIconName
        super.viewDidLoad()
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
        // TODO
        //showUnsavedChangesAlert()
        super.onLeftNavbarButtonPressed()
    }
    
    override func onRightNavbarButtonPressed() {
        showResetToDefaultActionSheet()
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func registerCells() {
        addCell(PreviewImageViewTableViewCell.reuseIdentifier)
        addCell(SegmentButtonsSliderTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        guard let appearanceParams else { return }
        tableData.clearAllData()
        let visibilitySection = tableData.createNewSection()
        let imageHeaderRow = visibilitySection.createNewRow()
        imageHeaderRow.cellType = PreviewImageViewTableViewCell.reuseIdentifier
        
        let cornerRadiusSection = tableData.createNewSection()
        let cornerRadiusValueRow = cornerRadiusSection.createNewRow()
        cornerRadiusValueRow.cellType = OAValueTableViewCell.reuseIdentifier
        cornerRadiusValueRow.title = localizedString("corner_radius")
        cornerRadiusValueRow.setObj(String(format: localizedString("ltr_or_rtl_combine_via_space"), "\(appearanceParams.cornerRadius)", localizedString("shared_string_pt")), forKey: Self.valueKey)
        
        let cornerRadiusSliderRow = cornerRadiusSection.createNewRow()
        cornerRadiusSliderRow.cellType = SegmentButtonsSliderTableViewCell.reuseIdentifier
        cornerRadiusSliderRow.key = Self.cornerRadiusRowKey
        cornerRadiusSliderRow.setObj(Self.cornerRadiusArrayValues.map { String($0) }, forKey: Self.arrayValuesKey)
        cornerRadiusSliderRow.setObj(String(appearanceParams.cornerRadius), forKey: Self.valueKey)
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        guard let mapButtonState else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == PreviewImageViewTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PreviewImageViewTableViewCell.reuseIdentifier) as? PreviewImageViewTableViewCell else {
                return UITableViewCell()
            }
            cell.configure(appearanceParams: appearanceParams, buttonState: mapButtonState)
            if mapButtonState is CompassButtonState {
                cell.rotateImage(-CGFloat(OARootViewController.instance().mapPanel.mapViewController.azimuth()) / 180.0 * CGFloat.pi)
            }
            return cell
        } else if item.cellType == SegmentButtonsSliderTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: SegmentButtonsSliderTableViewCell.reuseIdentifier) as? SegmentButtonsSliderTableViewCell else {
                return UITableViewCell()
            }
            let arrayValue = item.obj(forKey: Self.arrayValuesKey) as? [String] ?? []
            cell.delegate = self
            cell.sliderView.setNumberOfMarks(arrayValue.count)
            if let customString = item.obj(forKey: Self.valueKey) as? String, let index = arrayValue.firstIndex(of: customString) {
                cell.sliderView.selectedMark = index
                cell.setupButtonsEnabling()
            }
            cell.sliderView.tag = (indexPath.section << 10) | indexPath.row
            cell.sliderView.removeTarget(self, action: nil, for: [.touchUpInside, .touchUpOutside])
            cell.sliderView.addTarget(self, action: #selector(sliderChanged(sender:)), for: [.touchUpInside, .touchUpOutside])
            return cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as? OAValueTableViewCell, let value = item.obj(forKey: Self.valueKey) as? String else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none
            cell.setCustomLeftSeparatorInset(true)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.descriptionVisibility(false)
            cell.leftIconVisibility(false)
            cell.titleLabel.text = item.title
            cell.titleLabel.accessibilityLabel = cell.titleLabel.text
            cell.valueLabel.text = value
            cell.valueLabel.accessibilityLabel = cell.valueLabel.text
            return cell
        }
        return nil
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
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_reset"), style: .destructive) { _ in
            // TODO
        })
        actionSheet.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        present(actionSheet, animated: true)
    }
    
    private func setAppearanceParameter(_ selectedIndex: Int, sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        setAppearanceParameter(selectedIndex, key: item.key)
    }
    
    private func setAppearanceParameter(_ selectedIndex: Int, key: String?) {
        if key == Self.cornerRadiusRowKey {
            appearanceParams?.cornerRadius = Self.cornerRadiusArrayValues[selectedIndex]
        }
        reloadDataWith(animated: true, completion: nil)
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.cellForRow(at: indexPath) as? SegmentButtonsSliderTableViewCell, let arrayValues = item.obj(forKey: Self.arrayValuesKey) as? [String] else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        guard selectedIndex >= 0, selectedIndex < arrayValues.count else { return }
        setAppearanceParameter(selectedIndex, key: item.key)
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
}
