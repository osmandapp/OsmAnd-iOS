//
//  TracksChangeAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class TracksChangeAppearanceViewController: OABaseNavbarViewController, AppearanceChangedDelegate {
    private static let directionArrowsRowKey = "directionArrowsRowKey"
    private static let startFinishIconsRowKey = "startFinishIconsRowKey"
    private static let coloringRowKey = "coloringRowKey"
    private static let coloringDescRowKey = "coloringDescRowKey"
    private static let widthRowKey = "widthRowKey"
    private static let widthDescrRow = "widthDescrRow"
    private static let splitIntervalRow = "splitIntervalRow"
    private static let splitIntervalDescrRow = "splitIntervalDescrRow"
    
    private var tracks: Set<TrackItem>
    private var initialData: AppearanceData
    private var data: AppearanceData
    
    init(tracks: Set<TrackItem>) {
        self.tracks = tracks
        self.initialData = Self.buildAppearanceData()
        self.data = AppearanceData(data: self.initialData)
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OAButtonTableViewCell.reuseIdentifier)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.data.delegate = self
    }
    
    override func getTitle() -> String? {
        localizedString("change_appearance")
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        return [createRightNavbarButton(localizedString("shared_string_done"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)]
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        let directionSection = tableData.createNewSection()
        let directionArrowsRow = directionSection.createNewRow()
        directionArrowsRow.cellType = OAButtonTableViewCell.reuseIdentifier
        directionArrowsRow.key = Self.directionArrowsRowKey
        directionArrowsRow.title = localizedString("gpx_direction_arrows")
        let startFinishIconsRow = directionSection.createNewRow()
        startFinishIconsRow.cellType = OAButtonTableViewCell.reuseIdentifier
        startFinishIconsRow.key = Self.startFinishIconsRowKey
        startFinishIconsRow.title = localizedString("track_show_start_finish_icons")
        
        let coloringSection = tableData.createNewSection()
        let coloringRow = coloringSection.createNewRow()
        coloringRow.cellType = OAButtonTableViewCell.reuseIdentifier
        coloringRow.key = Self.coloringRowKey
        coloringRow.title = localizedString("shared_string_coloring")
        let coloringDescrRow = coloringSection.createNewRow()
        coloringDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
        coloringDescrRow.key = Self.coloringDescRowKey
        coloringDescrRow.title = localizedString("each_favourite_point_own_icon")
        
        let widthSection = tableData.createNewSection()
        let widthRow = widthSection.createNewRow()
        widthRow.cellType = OAButtonTableViewCell.reuseIdentifier
        widthRow.key = Self.widthRowKey
        widthRow.title = localizedString("routing_attr_width_name")
        let widthDescrRow = widthSection.createNewRow()
        widthDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
        widthDescrRow.key = Self.widthDescrRow
        widthDescrRow.title = localizedString("unchanged_parameter_summary")
        
        let splitIntervalSection = tableData.createNewSection()
        let splitIntervalRow = splitIntervalSection.createNewRow()
        splitIntervalRow.cellType = OAButtonTableViewCell.reuseIdentifier
        splitIntervalRow.key = Self.splitIntervalRow
        splitIntervalRow.title = localizedString("gpx_split_interval")
        let splitIntervalDescrRow = splitIntervalSection.createNewRow()
        splitIntervalDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
        splitIntervalDescrRow.key = Self.splitIntervalDescrRow
        splitIntervalDescrRow.title = localizedString("unchanged_parameter_summary")
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OAButtonTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            let config = UIButton.Configuration.plain()
            cell.button.configuration = config
            if let key = item.key {
                cell.button.menu = createStateSelectionMenu(for: key)
            }
            cell.button.showsMenuAsPrimaryAction = true
            cell.button.changesSelectionAsPrimaryAction = true
            cell.button.contentHorizontalAlignment = .right
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier) as! OASimpleTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.titleVisibility(false)
            cell.descriptionLabel.text = item.title
            return cell
        }
        
        return nil
    }
    
    override func onRightNavbarButtonPressed() {
        let task = ChangeTracksAppearanceTask(data: self.data, items: self.tracks) { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true) {
                OsmAndApp.swiftInstance().updateGpxTracksOnMapObservable.notifyEvent()
            }
        }
        
        task.execute()
    }
    
    private static func buildAppearanceData() -> AppearanceData {
        let data = AppearanceData()
        for parameter in GpxParameter.companion.getAppearanceParameters() {
            data.setParameter(parameter, value: nil)
        }
        
        return data
    }
    
    private func createStateSelectionMenu(for key: String) -> UIMenu {
        if key == Self.directionArrowsRowKey {
            return createArrowsMenu()
        } else if key == Self.startFinishIconsRowKey {
            return createStartFinishMenu()
        } else if key == Self.coloringRowKey {
            return createColoringMenu()
        } else if key == Self.widthRowKey {
            return createWidthMenu()
        } else if key == Self.splitIntervalRow {
            return createStartFinishMenu()
        } else {
            return UIMenu()
        }
    }
    
    private func createArrowsMenu() -> UIMenu {
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: .on) { _ in }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(GpxParameter.showArrows)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(GpxParameter.showArrows, value: true)
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(GpxParameter.showArrows, value: false)
        }
        let onOffMenu = inlineMenu(withActions: [onAction, offAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func createStartFinishMenu() -> UIMenu {
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: .on) { _ in }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(GpxParameter.showStartFinish)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(GpxParameter.showStartFinish, value: true)
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(GpxParameter.showStartFinish, value: false)
        }
        let onOffMenu = inlineMenu(withActions: [onAction, offAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func createColoringMenu() -> UIMenu {
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: .on) { _ in }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: .off) { _ in }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let solidColorAction = UIAction(title: localizedString("track_coloring_solid"), state: .off) { _ in }
        let solidColorMenu = inlineMenu(withActions: [solidColorAction])
        
        let altitudeAction = UIAction(title: localizedString("altitude"), state: .off) { _ in }
        let speedAction = UIAction(title: localizedString("shared_string_speed"), state: .off) { _ in }
        let slopeAction = UIAction(title: localizedString("shared_string_slope"), state: .off) { _ in }
        let gradientColorMenu = inlineMenu(withActions: [altitudeAction, speedAction, slopeAction])
        
        let roadTypeAction = UIAction(title: localizedString("routeInfo_roadClass_name"), image: UIImage(named: "ic_payment_label_pro"), state: .off) { _ in }
        let surfaceAction = UIAction(title: localizedString("routeInfo_surface_name"), image: UIImage(named: "ic_payment_label_pro"), state: .off) { _ in }
        let smoothhnessAction = UIAction(title: localizedString("routeInfo_smoothness_name"), image: UIImage(named: "ic_payment_label_pro"), state: .off) { _ in }
        let winterRoadsAction = UIAction(title: localizedString("routeInfo_winter_ice_road_name"), image: UIImage(named: "ic_payment_label_pro"), state: .off) { _ in }
        let thicknessRoadsAction = UIAction(title: localizedString("routeInfo_tracktype_name"), image: UIImage(named: "ic_payment_label_pro"), state: .off) { _ in }
        let horseRoadsAction = UIAction(title: localizedString("routeInfo_horse_scale_name"), image: UIImage(named: "ic_payment_label_pro"), state: .off) { _ in }
        let proColorMenu = inlineMenu(withActions: [roadTypeAction, surfaceAction, smoothhnessAction, winterRoadsAction, thicknessRoadsAction, horseRoadsAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, solidColorMenu, gradientColorMenu, proColorMenu])
    }
    
    private func createWidthMenu() -> UIMenu {
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: .on) { _ in }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: .off) { _ in }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let thinAction = UIAction(title: localizedString("rendering_value_thin_name"), state: .off) { _ in }
        let mediumAction = UIAction(title: localizedString("rendering_value_medium_w_name"), state: .off) { _ in }
        let boldAction = UIAction(title: localizedString("rendering_value_bold_name"), state: .off) { _ in }
        let widthMenu = inlineMenu(withActions: [thinAction, mediumAction, boldAction])
        
        let customAction = UIAction(title: localizedString("shared_string_custom"), state: .off) { _ in }
        let customWidthMenu = inlineMenu(withActions: [customAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, widthMenu, customWidthMenu])
    }
    
    private func createSplitIntervalMenu() -> UIMenu {
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: .on) { _ in }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: .off) { _ in }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: .off) { _ in }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: .off) { _ in }
        let onOffMenu = inlineMenu(withActions: [onAction, offAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func inlineMenu(withActions actions: [UIAction]) -> UIMenu {
        UIMenu(title: "", options: .displayInline, children: actions)
    }
    
    func onAppearanceChanged() {
    }
}
