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
    private static let customSplitIntervalRowKey = "customSplitIntervalRowKey"
    private static let widthDescrRow = "widthDescrRow"
    private static let splitIntervalRow = "splitIntervalRow"
    private static let splitIntervalDescrRow = "splitIntervalDescrRow"
    private static let splitIntervalNoneDescrRow = "splitIntervalNoneDescrRow"
    private static let customStringValue = "customStringValue"
    private static let widthArrayValue = "widthArrayValue"
    private static let hasTopLabels = "hasTopLabels"
    private static let hasBottomLabels = "hasBottomLabels"
    
    private var tracks: Set<TrackItem>
    private var initialData: AppearanceData
    private var data: AppearanceData
    private var appearanceCollection: OAGPXAppearanceCollection?
    private var selectedShowArrows: Bool?
    private var selectedShowStartFinish: Bool?
    private var selectedWidth: OAGPXTrackWidth?
    private var customWidthValues: [String] = []
    private var selectedWidthIndex: Int = 0
    private var selectedSplit: OAGPXTrackSplitInterval?
    private var selectedSplitIntervalIndex: Int = 0
    private var isWidthSelected = false
    private var isCustomWidthSelected = false
    private var isSplitIntervalSelected = false
    private var isSplitIntervalNoneSelected = false
    
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
        selectedShowArrows = preselectParameter(in: tracks) { $0.showArrows }
        selectedShowStartFinish = preselectParameter(in: tracks) { $0.showStartFinish }
        configureWidth()
        configureSplitInterval()
        updateData()
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OAButtonTableViewCell.reuseIdentifier)
        addCell(GradientChartCell.reuseIdentifier)
        addCell(SegmentImagesWithRightLabelTableViewCell.reuseIdentifier)
        addCell(SegmentTextWithRightLabelTableViewCell.reuseIdentifier)
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
                customWidthModesRow.setObj(selectedWidth?.customValue as Any, forKey: Self.customStringValue)
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
        if isSplitIntervalSelected {
            let splitModesRow = splitIntervalSection.createNewRow()
            splitModesRow.cellType = SegmentTextWithRightLabelTableViewCell.reuseIdentifier
            splitModesRow.key = Self.splitModesRowKey
            if isSplitIntervalNoneSelected {
                let splitIntervalNoneDescrRow = splitIntervalSection.createNewRow()
                splitIntervalNoneDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
                splitIntervalNoneDescrRow.key = Self.splitIntervalNoneDescrRow
                splitIntervalNoneDescrRow.title = localizedString("gpx_split_interval_none_descr")
            } else {
                let customSplitIntervalRow = splitIntervalSection.createNewRow()
                customSplitIntervalRow.cellType = OASegmentSliderTableViewCell.reuseIdentifier
                customSplitIntervalRow.key = Self.customSplitIntervalRowKey
                customSplitIntervalRow.title = localizedString("shared_string_interval")
                customSplitIntervalRow.setObj(selectedSplit?.customValue as Any, forKey: Self.customStringValue)
                customSplitIntervalRow.setObj(selectedSplit?.titles as Any, forKey: Self.widthArrayValue)
                customSplitIntervalRow.setObj(true, forKey: Self.hasTopLabels)
                customSplitIntervalRow.setObj(true, forKey: Self.hasBottomLabels)
            }
        } else {
            let splitIntervalDescrRow = splitIntervalSection.createNewRow()
            splitIntervalDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
            splitIntervalDescrRow.key = Self.splitIntervalDescrRow
            splitIntervalDescrRow.title = localizedString("unchanged_parameter_summary")
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OAButtonTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            if (item.key == Self.widthRowKey && isWidthSelected) || (item.key == Self.splitIntervalRow && isSplitIntervalSelected) {
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            } else {
                cell.setCustomLeftSeparatorInset(false)
            }
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
            cell.backgroundColor = .groupBg
            cell.configureTitle(title: nil)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.configureSegmentedControl(icons: [.icCustomTrackLineThin, .icCustomTrackLineMedium, .icCustomTrackLineBold, .icCustomParameters], selectedSegmentIndex: selectedWidthIndex)
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self else { return }
                self.handleWidthSelection(index: index)
            }
            return cell
        } else if item.cellType == SegmentTextWithRightLabelTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentTextWithRightLabelTableViewCell.reuseIdentifier) as! SegmentTextWithRightLabelTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            cell.configureTitle(title: nil)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.configureSegmentedControl(titles: [localizedString("shared_string_none"), localizedString("shared_string_time"), localizedString("shared_string_distance")], selectedSegmentIndex: selectedSplitIntervalIndex)
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self else { return }
                self.handleSplitIntervalSelection(index: index)
            }
            return cell
        } else if item.cellType == OASegmentSliderTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASegmentSliderTableViewCell.reuseIdentifier) as! OASegmentSliderTableViewCell
            let arrayValue = item.obj(forKey: Self.widthArrayValue) as? [String] ?? []
            cell.topLeftLabel.text = item.title
            cell.topRightLabel.text = (item.key == Self.customSplitIntervalRowKey) ? (item.obj(forKey: Self.customStringValue) as? String ?? "") : ""
            cell.topRightLabel.textColor = .textColorSecondary
            cell.topRightLabel.font = UIFont.scaledSystemFont(ofSize: 17, weight: .medium)
            cell.bottomLeftLabel.text = arrayValue.first
            cell.bottomRightLabel.text = arrayValue.last
            cell.sliderView.setNumberOfMarks(arrayValue.count)
            if let customString = item.obj(forKey: Self.customStringValue) as? String, let index = arrayValue.firstIndex(of: customString) {
                cell.sliderView.selectedMark = index
            }
            cell.sliderView.tag = (indexPath.section << 10) | indexPath.row
            cell.sliderView.removeTarget(self, action: nil, for: [.touchUpInside, .touchUpOutside])
            cell.sliderView.addTarget(self, action: #selector(sliderChanged(sender:)), for: [.touchUpInside, .touchUpOutside])
            return cell
        }
        
        return nil
    }
    
    override func onLeftNavbarButtonPressed() {
        if data != initialData {
            let alertController = UIAlertController(title: localizedString("unsaved_changes"), message: localizedString("unsaved_changes_will_be_lost"), preferredStyle: .actionSheet)
            let discardAction = UIAlertAction(title: "Discard", style: .destructive) { [weak self] _ in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: nil)
            }
            let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.onRightNavbarButtonPressed()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(discardAction)
            alertController.addAction(applyAction)
            alertController.addAction(cancelAction)
            let popPresenter = alertController.popoverPresentationController
            popPresenter?.barButtonItem = navigationItem.leftBarButtonItem
            popPresenter?.permittedArrowDirections = UIPopoverArrowDirection.any
            present(alertController, animated: true, completion: nil)
        } else {
            super.onLeftNavbarButtonPressed()
        }
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
    
    private func configureWidth() {
        selectedWidth = preselectParameter(in: tracks) { appearanceCollection?.getWidthForValue($0.width) }
        let minValue = OAGPXTrackWidth.getCustomTrackWidthMin()
        let maxValue = OAGPXTrackWidth.getCustomTrackWidthMax()
        customWidthValues = (minValue...maxValue).map { "\($0)" }
        if let width = selectedWidth {
            switch width.key {
            case "thin":
                isWidthSelected = true
                isCustomWidthSelected = false
                selectedWidthIndex = 0
            case "medium":
                isWidthSelected = true
                isCustomWidthSelected = false
                selectedWidthIndex = 1
            case "bold":
                isWidthSelected = true
                isCustomWidthSelected = false
                selectedWidthIndex = 2
            default:
                isWidthSelected = true
                isCustomWidthSelected = true
                selectedWidthIndex = 3
            }
        }
    }
    
    private func configureSplitInterval() {
        selectedSplit = preselectParameter(in: tracks) { appearanceCollection?.getSplitInterval(for: $0.splitType) }
        if tracks.first?.splitInterval ?? 0 > 0 && tracks.first?.splitType != EOAGpxSplitType.none {
            selectedSplit?.customValue = selectedSplit?.titles[(selectedSplit?.values.firstIndex { ($0).doubleValue == Double(tracks.first?.splitInterval ?? 0) }) ?? 0]
        }
        
        if let split = selectedSplit {
            switch split.type {
            case .none:
                isSplitIntervalSelected = true
                isSplitIntervalNoneSelected = true
                selectedSplitIntervalIndex = 0
            case .time:
                isSplitIntervalSelected = true
                isSplitIntervalNoneSelected = false
                selectedSplitIntervalIndex = 1
            case .distance:
                isSplitIntervalSelected = true
                isSplitIntervalNoneSelected = false
                selectedSplitIntervalIndex = 2
            default:
                break
            }
        }
    }
    
    private func preselectParameter<T: Equatable>(in tracks: Set<TrackItem>, extractor: (TrackItem) -> T?) -> T? {
        var result: T?
        for track in tracks {
            let value = extractor(track)
            if result == nil {
                result = value
            } else if result != value {
                return nil
            }
        }
        
        return result
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
    
    private func updateData() {
        generateData()
        tableView.reloadData()
    }
    
    private func handleWidthSelection(index: Int) {
        guard let widths = appearanceCollection?.getAvailableWidth(), index >= 0, index < widths.count else { return }
        let width = widths[index]
        selectedWidth = width
        let widthString = width.isCustom() ? width.customValue : width.key
        data.setParameter(.width, value: widthString)
        isWidthSelected = true
        isCustomWidthSelected = width.isCustom()
        selectedWidthIndex = index
        updateData()
    }
    
    private func handleSplitIntervalSelection(index: Int) {
        guard let availableSplits = appearanceCollection?.getAvailableSplitIntervals(), index >= 0, index < availableSplits.count else { return }
        let split = availableSplits[index]
        selectedSplit = split
        data.setParameter(.splitType, value: Int32(split.type.rawValue))
        if split.isCustom(), let customValue = split.customValue, let customIndex = split.titles.firstIndex(of: customValue) {
            data.setParameter(.splitInterval, value: split.values[customIndex].doubleValue)
        } else {
            data.setParameter(.splitInterval, value: 0)
        }
        
        isSplitIntervalSelected = true
        isSplitIntervalNoneSelected = (split.key == "no_split")
        selectedSplitIntervalIndex = index
        updateData()
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        guard let tableData = tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.cellForRow(at: indexPath) as? OASegmentSliderTableViewCell else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        if item.key == Self.customWidthModesRowKey {
            guard let customWidthValues = item.obj(forKey: Self.widthArrayValue) as? [String], selectedIndex >= 0, selectedIndex < customWidthValues.count else { return }
            let selectedValue = customWidthValues[selectedIndex]
            if let w = selectedWidth, w.isCustom() {
                w.customValue = selectedValue
            }
            data.setParameter(.width, value: selectedValue)
        } else if item.key == Self.customSplitIntervalRowKey {
            guard let splitTitles = item.obj(forKey: Self.widthArrayValue) as? [String], selectedIndex >= 0, selectedIndex < splitTitles.count else { return }
            let selectedValue = splitTitles[selectedIndex]
            if let split = selectedSplit, split.isCustom() {
                split.customValue = selectedValue
                if let customIndex = split.titles.firstIndex(of: selectedValue) {
                    data.setParameter(.splitInterval, value: split.values[customIndex].doubleValue)
                }
            }
        }
        
        generateData()
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

extension TracksChangeAppearanceViewController {
    private func createArrowsMenu() -> UIMenu {
        let paramValue: Bool? = selectedShowArrows
        let isReset = data.shouldResetParameter(.showArrows)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && paramValue == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showArrows, value: nil)
            self.selectedShowArrows = nil
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.showArrows)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: !isReset && paramValue == true ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showArrows, value: true)
            self.selectedShowArrows = true
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: !isReset && paramValue == false ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showArrows, value: false)
            self.selectedShowArrows = false
        }
        let onOffMenu = inlineMenu(withActions: [onAction, offAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func createStartFinishMenu() -> UIMenu {
        let paramValue: Bool? = selectedShowStartFinish
        let isReset = data.shouldResetParameter(.showStartFinish)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && paramValue == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showStartFinish, value: nil)
            self.selectedShowStartFinish = nil
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.showStartFinish)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: !isReset && paramValue == true ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showStartFinish, value: true)
            self.selectedShowStartFinish = true
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: !isReset && paramValue == false ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.showStartFinish, value: false)
            self.selectedShowStartFinish = false
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
        let paramValue: String? = selectedWidth?.isCustom() == true ? selectedWidth?.customValue : selectedWidth?.key
        let isReset = data.shouldResetParameter(.width)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && paramValue == nil ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.width, value: nil)
            self.selectedWidth = nil
            if self.isWidthSelected {
                self.isWidthSelected = false
                self.isCustomWidthSelected = false
                self.updateData()
            }
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.resetParameter(.width)
            if self.isWidthSelected {
                self.isWidthSelected = false
                self.isCustomWidthSelected = false
                self.updateData()
            }
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let thinAction = UIAction(title: localizedString("rendering_value_thin_name"), state: !isReset && paramValue == "thin" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.handleWidthSelection(index: 0)
        }
        let mediumAction = UIAction(title: localizedString("rendering_value_medium_w_name"), state: !isReset && paramValue == "medium" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.handleWidthSelection(index: 1)
        }
        let boldAction = UIAction(title: localizedString("rendering_value_bold_name"), state: !isReset && paramValue == "bold" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.handleWidthSelection(index: 2)
        }
        let widthMenu = inlineMenu(withActions: [thinAction, mediumAction, boldAction])
        
        let customAction = UIAction(title: localizedString("shared_string_custom"), state: !isReset && paramValue == selectedWidth?.customValue ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.handleWidthSelection(index: 2)
        }
        let customWidthMenu = inlineMenu(withActions: [customAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, widthMenu, customWidthMenu])
    }
    
    private func createSplitIntervalMenu() -> UIMenu {
        let paramSplitType: Int32? = selectedSplit.map { Int32($0.type.rawValue) } ?? data.getParameter(for: .splitType)
        let isResetSplitType = data.shouldResetParameter(.splitType)
        let isResetSplitInterval = data.shouldResetParameter(.splitInterval)
        let isUnchanged = paramSplitType == nil && !isResetSplitType && !isResetSplitInterval
        let isOriginalSelected = isResetSplitType && isResetSplitInterval
        let isNoSplit = paramSplitType != nil && paramSplitType ?? 0 == GpxSplitType.noSplit.type
        let isTime = paramSplitType ?? 0 == GpxSplitType.time.type
        let isDistance = paramSplitType ?? 0 == GpxSplitType.distance.type
        
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: isUnchanged ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.splitType, value: nil)
            self.data.setParameter(.splitInterval, value: nil)
            self.selectedSplit = nil
            if self.isSplitIntervalSelected {
                self.isSplitIntervalSelected = false
                self.isSplitIntervalNoneSelected = false
                self.updateData()
            }
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isOriginalSelected ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.resetParameter(.splitType)
            self.data.resetParameter(.splitInterval)
            if self.isSplitIntervalSelected {
                self.isSplitIntervalSelected = false
                self.isSplitIntervalNoneSelected = false
                self.updateData()
            }
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let noSplitAction = UIAction(title: localizedString("shared_string_none"), state: isNoSplit ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.handleSplitIntervalSelection(index: 0)
        }
        let timeAction = UIAction(title: localizedString("shared_string_time"), state: isTime ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.handleSplitIntervalSelection(index: 1)
        }
        let distanceAction = UIAction(title: localizedString("shared_string_distance"), state: isDistance ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.handleSplitIntervalSelection(index: 2)
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
