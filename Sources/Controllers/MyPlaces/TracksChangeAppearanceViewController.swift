//
//  TracksChangeAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

final class TracksChangeAppearanceViewController: OABaseNavbarViewController {
    private static let directionArrowsRowKey = "directionArrowsRowKey"
    private static let startFinishIconsRowKey = "startFinishIconsRowKey"
    private static let coloringRowKey = "coloringRowKey"
    private static let coloringDescRowKey = "coloringDescRowKey"
    private static let widthRowKey = "widthRowKey"
    private static let widthModesRowKey = "widthModesRowKey"
    private static let splitModesRowKey = "splitModesRowKey"
    private static let customWidthModesRowKey = "customWidthModesRowKey"
    private static let widthDescrRow = "widthDescrRow"
    private static let splitIntervalRow = "splitIntervalRow"
    private static let splitIntervalDescrRow = "splitIntervalDescrRow"
    private static let customStringWidthValue = "customStringWidthValue"
    private static let widthArrayValue = "widthArrayValue"
    private static let hasTopLabels = "hasTopLabels"
    private static let hasBottomLabels = "hasBottomLabels"
    
    private var tracks: Set<TrackItem>
    private var initialData: AppearanceData
    private var data: AppearanceData
    private var appearanceCollection: OAGPXAppearanceCollection?
    private var selectedWidth: OAGPXTrackWidth?
    private var customWidthValues: [String] = []
    private var selectedWidthIndex: Int = 0
    private var isWidthSelected = false
    private var isCustomWidthSelected = false
    private var isSplitIntervalSelected = false
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.data.delegate = self
        appearanceCollection = OAGPXAppearanceCollection.sharedInstance()
        selectedWidth = appearanceCollection?.getWidthForValue(tracks.first?.width)
        let minValue = OAGPXTrackWidth.getCustomTrackWidthMin()
        let maxValue = OAGPXTrackWidth.getCustomTrackWidthMax()
        customWidthValues = (minValue...maxValue).map { "\($0)" }
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OAButtonTableViewCell.reuseIdentifier)
        addCell(GradientChartCell.reuseIdentifier)
        addCell(SegmentImagesWithRightLabelTableViewCell.reuseIdentifier)
        addCell(OASegmentSliderTableViewCell.reuseIdentifier)
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
        if isWidthSelected {
            let widthModesRow = widthSection.createNewRow()
            widthModesRow.cellType = SegmentImagesWithRightLabelTableViewCell.reuseIdentifier
            widthModesRow.key = Self.widthModesRowKey
            if isCustomWidthSelected {
                let customWidthModesRow = widthSection.createNewRow()
                customWidthModesRow.cellType = OASegmentSliderTableViewCell.reuseIdentifier
                customWidthModesRow.key = Self.customWidthModesRowKey
                customWidthModesRow.setObj(selectedWidth?.customValue as Any, forKey: Self.customStringWidthValue)
                customWidthModesRow.setObj(customWidthValues, forKey: Self.widthArrayValue)
                customWidthModesRow.setObj(false, forKey: Self.hasTopLabels)
                customWidthModesRow.setObj(true, forKey: Self.hasBottomLabels)
            }
        } else {
            let widthDescrRow = widthSection.createNewRow()
            widthDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
            widthDescrRow.key = Self.widthDescrRow
            widthDescrRow.title = localizedString("unchanged_parameter_summary")
        }
        
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
        } else if item.cellType == SegmentImagesWithRightLabelTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier) as! SegmentImagesWithRightLabelTableViewCell
            cell.selectionStyle = .none
            cell.configureTitle(title: nil)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.configureSegmentedControl(icons: [.icCustomTrackLineThin, .icCustomTrackLineMedium, .icCustomTrackLineBold, .icCustomParameters], selectedSegmentIndex: selectedWidthIndex)
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self else { return }
                self.handleWidthSelection(index: index)
            }
            return cell
        } else if item.cellType == OASegmentSliderTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASegmentSliderTableViewCell.reuseIdentifier) as! OASegmentSliderTableViewCell
            let hasTopLabels = item.obj(forKey: Self.hasTopLabels) as? Bool ?? false
            let hasBottomLabels = item.obj(forKey: Self.hasBottomLabels) as? Bool ?? false
            let arrayValue = item.obj(forKey: Self.widthArrayValue) as? [String] ?? []
            cell.showLabels(hasTopLabels, topRight: hasTopLabels, bottomLeft: hasBottomLabels, bottomRight: hasBottomLabels)
            cell.topLeftLabel.text = item.title
            cell.topRightLabel.text = item.obj(forKey: Self.customStringWidthValue) as? String ?? ""
            cell.topRightLabel.textColor = .textColorActive
            cell.topRightLabel.font = UIFont.scaledSystemFont(ofSize: 17, weight: .medium)
            cell.bottomLeftLabel.text = arrayValue.first
            cell.bottomRightLabel.text = arrayValue.last
            cell.sliderView.setNumberOfMarks(arrayValue.count)
            if let customString = item.obj(forKey: Self.customStringWidthValue) as? String, let index = arrayValue.firstIndex(of: customString) {
                cell.sliderView.selectedMark = index
            }
            cell.sliderView.tag = (indexPath.section << 10) | indexPath.row
            cell.sliderView.removeTarget(self, action: nil, for: [.touchUpInside, .touchUpOutside])
            cell.sliderView.addTarget(self, action: #selector(sliderChanged(sender:)), for: [.touchUpInside, .touchUpOutside])
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
            return createSplitIntervalMenu()
        } else {
            return UIMenu()
        }
    }
    
    private func updateData(withSeparatorInset selected: Bool) {
        generateData()
        tableView.reloadData()
        if let firstCell = tableView.cellForRow(at: IndexPath(row: 0, section: 2)) as? OAButtonTableViewCell {
            if selected {
                firstCell.setCustomLeftSeparatorInset(true)
                firstCell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            } else {
                firstCell.setCustomLeftSeparatorInset(false)
            }
        }
    }
    
    private func handleWidthSelection(index: Int) {
        guard let widths = appearanceCollection?.getAvailableWidth() else { return }
        guard index >= 0 && index < widths.count else { return }
        let trackWidth = widths[index]
        selectedWidth = trackWidth
        let widthString = trackWidth.isCustom() ? trackWidth.customValue : trackWidth.key
        data.setParameter(.width, value: widthString)
        isWidthSelected = true
        isCustomWidthSelected = trackWidth.isCustom()
        selectedWidthIndex = index
        updateData(withSeparatorInset: true)
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        guard let tableData = tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.cellForRow(at: indexPath) as? OASegmentSliderTableViewCell else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        guard let customWidthValues = item.obj(forKey: Self.widthArrayValue) as? [String], selectedIndex >= 0, selectedIndex < customWidthValues.count else { return }
        let selectedValue = customWidthValues[selectedIndex]
        if let w = selectedWidth, w.isCustom() {
            w.customValue = selectedValue
        }
        
        data.setParameter(.width, value: selectedValue)
        generateData()
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

extension TracksChangeAppearanceViewController {
    private func createArrowsMenu() -> UIMenu {
        let paramValue: Bool? = data.getParameter(for: .showArrows)
        let isReset = data.shouldResetParameter(.showArrows)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && paramValue == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showArrows, value: nil)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.showArrows)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: !isReset && paramValue == true ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showArrows, value: true)
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: !isReset && paramValue == false ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showArrows, value: false)
        }
        let onOffMenu = inlineMenu(withActions: [onAction, offAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func createStartFinishMenu() -> UIMenu {
        let paramValue: Bool? = data.getParameter(for: .showStartFinish)
        let isReset = data.shouldResetParameter(.showStartFinish)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && paramValue == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showStartFinish, value: nil)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.showStartFinish)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: !isReset && paramValue == true ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showStartFinish, value: true)
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: !isReset && paramValue == false ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showStartFinish, value: false)
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
        
        let roadTypeAction = UIAction(title: localizedString("routeInfo_roadClass_name"), image: UIImage.icCustomProLogoOutlined, state: .off) { _ in }
        let surfaceAction = UIAction(title: localizedString("routeInfo_surface_name"), image: UIImage.icCustomProLogoOutlined, state: .off) { _ in }
        let smoothhnessAction = UIAction(title: localizedString("routeInfo_smoothness_name"), image: UIImage.icCustomProLogoOutlined, state: .off) { _ in }
        let winterRoadsAction = UIAction(title: localizedString("routeInfo_winter_ice_road_name"), image: UIImage.icCustomProLogoOutlined, state: .off) { _ in }
        let thicknessRoadsAction = UIAction(title: localizedString("routeInfo_tracktype_name"), image: UIImage.icCustomProLogoOutlined, state: .off) { _ in }
        let horseRoadsAction = UIAction(title: localizedString("routeInfo_horse_scale_name"), image: UIImage.icCustomProLogoOutlined, state: .off) { _ in }
        let proColorMenu = inlineMenu(withActions: [roadTypeAction, surfaceAction, smoothhnessAction, winterRoadsAction, thicknessRoadsAction, horseRoadsAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, solidColorMenu, gradientColorMenu, proColorMenu])
    }
    
    private func createWidthMenu() -> UIMenu {
        let paramValue: String? = data.getParameter(for: .width)
        let isReset = data.shouldResetParameter(.width)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && paramValue == nil ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.width, value: nil)
            if self.isWidthSelected {
                self.isWidthSelected = false
                self.isCustomWidthSelected = false
                self.updateData(withSeparatorInset: false)
            }
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.resetParameter(.width)
            if self.isWidthSelected {
                self.isWidthSelected = false
                self.isCustomWidthSelected = false
                self.updateData(withSeparatorInset: false)
            }
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let thinAction = UIAction(title: localizedString("rendering_value_thin_name"), state: !isReset && paramValue == "thin" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.width, value: "thin")
            self.isWidthSelected = true
            self.isCustomWidthSelected = false
            self.selectedWidthIndex = 0
            self.updateData(withSeparatorInset: true)
        }
        let mediumAction = UIAction(title: localizedString("rendering_value_medium_w_name"), state: !isReset && paramValue == "medium" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.width, value: "medium")
            self.isWidthSelected = true
            self.isCustomWidthSelected = false
            self.selectedWidthIndex = 1
            self.updateData(withSeparatorInset: true)
        }
        let boldAction = UIAction(title: localizedString("rendering_value_bold_name"), state: !isReset && paramValue == "bold" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.width, value: "bold")
            self.isWidthSelected = true
            self.isCustomWidthSelected = false
            self.selectedWidthIndex = 2
            self.updateData(withSeparatorInset: true)
        }
        let widthMenu = inlineMenu(withActions: [thinAction, mediumAction, boldAction])
        
        let customAction = UIAction(title: localizedString("shared_string_custom"), state: !isReset && paramValue == selectedWidth?.customValue ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.width, value: selectedWidth?.customValue)
            self.isWidthSelected = true
            self.isCustomWidthSelected = true
            self.selectedWidthIndex = 3
            self.updateData(withSeparatorInset: true)
        }
        let customWidthMenu = inlineMenu(withActions: [customAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, widthMenu, customWidthMenu])
    }
    
    private func createSplitIntervalMenu() -> UIMenu {
        let paramSplitType: Int32? = data.getParameter(for: .splitType)
        let paramSplitInterval: Double? = data.getParameter(for: .splitInterval)
        let isResetSplitType = data.shouldResetParameter(.splitType)
        let isResetSplitInterval = data.shouldResetParameter(.splitInterval)
        let isUnchanged = paramSplitType == nil && paramSplitInterval == nil && !isResetSplitType && !isResetSplitInterval
        let isOriginalSelected = isResetSplitType && isResetSplitInterval
        let isNoSplit = paramSplitType != nil && paramSplitType ?? 0 == GpxSplitType.noSplit.type
        let isTime = paramSplitType ?? 0 == GpxSplitType.time.type && paramSplitInterval == 5.0 * 60.0
        let isDistance = paramSplitType ?? 0 == GpxSplitType.distance.type && paramSplitInterval == 1000.0
        
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: isUnchanged ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.splitType, value: nil)
            self.data.setParameter(.splitInterval, value: nil)
            if self.isSplitIntervalSelected {
                self.isSplitIntervalSelected = false
                self.updateData(withSeparatorInset: false)
            }
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isOriginalSelected ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.resetParameter(.splitType)
            self.data.resetParameter(.splitInterval)
            if self.isSplitIntervalSelected {
                self.isSplitIntervalSelected = false
                self.updateData(withSeparatorInset: false)
            }
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let noSplitAction = UIAction(title: localizedString("shared_string_none"), state: isNoSplit ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.splitType, value: GpxSplitType.noSplit.type)
            self.data.setParameter(.splitInterval, value: nil)
            isSplitIntervalSelected = true
            self.updateData(withSeparatorInset: true)
        }
        let timeAction = UIAction(title: localizedString("shared_string_time"), state: isTime ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.splitType, value: GpxSplitType.time.type)
            self.data.setParameter(.splitInterval, value: 5.0 * 60.0)
            isSplitIntervalSelected = true
            self.updateData(withSeparatorInset: true)
        }
        let distanceAction = UIAction(title: localizedString("shared_string_distance"), state: isDistance ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.splitType, value: GpxSplitType.distance.type)
            self.data.setParameter(.splitInterval, value: 1000.0)
            isSplitIntervalSelected = true
            self.updateData(withSeparatorInset: true)
        }
        let onOffMenu = inlineMenu(withActions: [noSplitAction, timeAction, distanceAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func inlineMenu(withActions actions: [UIAction]) -> UIMenu {
        UIMenu(title: "", options: .displayInline, children: actions)
    }
}

extension TracksChangeAppearanceViewController: AppearanceChangedDelegate {
    func onAppearanceChanged() {
    }
}
