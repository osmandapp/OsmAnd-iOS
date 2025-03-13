//
//  TracksChangeAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

private struct WidthKeys {
    static let thin = "thin"
    static let medium = "medium"
    static let bold = "bold"
}

final class TracksChangeAppearanceViewController: OABaseNavbarViewController {
    private static let directionArrowsRowKey = "directionArrowsRowKey"
    private static let startFinishIconsRowKey = "startFinishIconsRowKey"
    private static let coloringRowKey = "coloringRowKey"
    private static let coloringDescRowKey = "coloringDescRowKey"
    private static let coloringGridRowKey = "coloringGridRowKey"
    private static let gradientLegendRowKey = "gradientLegendRowKey"
    private static let allColorsRowKey = "allColorsRowKey"
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
    private static let routeStatisticsAttributesStrings: [String] = ["routeInfo_roadClass", "routeInfo_surface", "routeInfo_smoothness", "routeInfo_winter_ice_road", "routeInfo_tracktype", "routeInfo_horse_scale"]
    
    private var tracks: Set<TrackItem>
    private var initialData: AppearanceData
    private var data: AppearanceData
    private var appearanceCollection: OAGPXAppearanceCollection?
    private var gradientColorsCollection: GradientColorsCollection?
    private var sortedColorItems: [ColorItem] = []
    private var sortedPaletteColorItems = OAConcurrentArray<PaletteColor>()
    private var selectedShowArrows: Bool?
    private var selectedShowStartFinish: Bool?
    private var selectedColorType: ColoringType?
    private var selectedRouteAttributesString: String?
    private var selectedColorItem: ColorItem?
    private var selectedPaletteColorItem: PaletteColor?
    private var selectedWidth: OAGPXTrackWidth?
    private var customWidthValues: [String] = []
    private var selectedWidthIndex: Int = 0
    private var selectedSplit: OAGPXTrackSplitInterval?
    private var selectedSplitIntervalIndex: Int = 0
    private var colorsCollectionIndexPath: IndexPath?
    private var isColorSelected = false
    private var isSolidColorSelected = false
    private var isGradientColorSelected = false
    private var isRouteAttributeTypeSelected = false
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
        configureColorType()
        configureWidth()
        configureSplitInterval()
        updateData()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        tableView.reloadData()
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(OAButtonTableViewCell.reuseIdentifier)
        addCell(GradientChartCell.reuseIdentifier)
        addCell(OACollectionSingleLineTableViewCell.reuseIdentifier)
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
        colorsCollectionIndexPath = nil
        
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
        if isColorSelected {
            if isSolidColorSelected {
                let coloringGridRow = coloringSection.createNewRow()
                coloringGridRow.cellType = OACollectionSingleLineTableViewCell.reuseIdentifier
                coloringGridRow.key = Self.coloringGridRowKey
                colorsCollectionIndexPath = IndexPath(row: Int(tableData.rowCount(tableData.sectionCount() - 1)) - 1, section: Int(tableData.sectionCount()) - 1)
            } else if isGradientColorSelected {
                let gradientLegendRow = coloringSection.createNewRow()
                gradientLegendRow.cellType = GradientChartCell.reuseIdentifier
                gradientLegendRow.key = Self.gradientLegendRowKey
                let coloringGridRow = coloringSection.createNewRow()
                coloringGridRow.cellType = OACollectionSingleLineTableViewCell.reuseIdentifier
                coloringGridRow.key = Self.coloringGridRowKey
                colorsCollectionIndexPath = IndexPath(row: Int(tableData.rowCount(tableData.sectionCount() - 1)) - 1, section: Int(tableData.sectionCount()) - 1)
            }
            let allColorsRow = coloringSection.createNewRow()
            allColorsRow.cellType = OAValueTableViewCell.reuseIdentifier
            allColorsRow.key = Self.allColorsRowKey
            allColorsRow.title = localizedString("shared_string_all_colors")
            allColorsRow.iconTintColor = .iconColorActive
        } else {
            let coloringDescrRow = coloringSection.createNewRow()
            coloringDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
            coloringDescrRow.key = Self.coloringDescRowKey
            coloringDescrRow.title = localizedString(isRouteAttributeTypeSelected ? "white_color_undefined" : "each_favourite_point_own_icon")
        }
        
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
            cell.setCustomLeftSeparatorInset(false)
            if (item.key == Self.widthRowKey && isWidthSelected) || (item.key == Self.splitIntervalRow && isSplitIntervalSelected) || (item.key == Self.coloringRowKey && isColorSelected) {
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
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
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier) as! OAValueTableViewCell
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.valueVisibility(false)
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = item.iconTintColor
            return cell
        } else if item.cellType == GradientChartCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: GradientChartCell.reuseIdentifier) as! GradientChartCell
            cell.selectionStyle = .none
            cell.heightConstraint.constant = 60
            cell.chartView.extraBottomOffset = 24
            GpxUIHelper.setupGradientChart(chart: cell.chartView, useGesturesAndScale: false, xAxisGridColor: .chartAxisGridLine, labelsColor: .textColorSecondary)
            var colorPalette: ColorPalette?
            if let paletteColor = selectedPaletteColorItem as? PaletteGradientColor {
                colorPalette = paletteColor.colorPalette
            }
            if let colorPalette {
                cell.chartView.data = GpxUIHelper.buildGradientChart(chart: cell.chartView, colorPalette: colorPalette, valueFormatter: GradientUiHelper.getGradientTypeFormatter(gradientColorsCollection?.gradientType as Any, analysis: tracks.first?.dataItem?.getAnalysis()))
                cell.chartView.notifyDataSetChanged()
                cell.chartView.setNeedsDisplay()
            }
            return cell
        } else if item.cellType == OACollectionSingleLineTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier) as! OACollectionSingleLineTableViewCell
            cell.rightActionButtonVisibility(isSolidColorSelected)
            cell.rightActionButton.setImage(isSolidColorSelected ? UIImage.templateImageNamed("ic_custom_add") : nil, for: .normal)
            cell.rightActionButton.tag = isSolidColorSelected ? (indexPath.section << 10 | indexPath.row) : 0
            cell.rightActionButton.removeTarget(nil, action: nil, for: .allEvents)
            if isSolidColorSelected {
                cell.rightActionButton.addTarget(self, action: #selector(onCellButtonPressed(_:)), for: .touchUpInside)
                let colorHandler = OAColorCollectionHandler(data: [sortedColorItems], collectionView: cell.collectionView)
                colorHandler?.delegate = self
                let selectedIndex = sortedColorItems.firstIndex(where: { $0 == selectedColorItem }) ?? sortedColorItems.firstIndex(where: { $0 == appearanceCollection?.getDefaultLineColorItem() }) ?? 0
                colorHandler?.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
                cell.setCollectionHandler(colorHandler)
            } else if isGradientColorSelected {
                let paletteHandler = PaletteCollectionHandler(data: [sortedPaletteColorItems.asArray()], collectionView: cell.collectionView)
                paletteHandler?.delegate = self
                var selectedIndex = sortedPaletteColorItems.index(ofObjectSync: selectedPaletteColorItem)
                selectedIndex = (selectedIndex != NSNotFound) ? selectedIndex : sortedPaletteColorItems.index(ofObjectSync: gradientColorsCollection?.getDefaultGradientPalette())
                selectedIndex = (selectedIndex != NSNotFound) ? selectedIndex : 0
                let selectedIndexPath = IndexPath(row: Int(selectedIndex), section: 0)
                paletteHandler?.setSelectedIndexPath(selectedIndexPath)
                cell.setCollectionHandler(paletteHandler)
                cell.collectionView.contentInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
                cell.configureTopOffset(12)
                cell.configureBottomOffset(12)
            }
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
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.key == Self.allColorsRowKey {
            if isSolidColorSelected {
                if let items = appearanceCollection?.getAvailableColorsSortingByKey(), let colorItem = selectedColorItem {
                    let colorCollectionVC = ItemsCollectionViewController(collectionType: .colorItems, items: items, selectedItem: colorItem)
                    colorCollectionVC.delegate = self
                    navigationController?.pushViewController(colorCollectionVC, animated: true)
                }
            } else if isGradientColorSelected {
                if let gradientColors = gradientColorsCollection, let paletteColorItem = selectedPaletteColorItem {
                    let colorCollectionVC = ItemsCollectionViewController(collectionType: .colorizationPaletteItems, items: gradientColors, selectedItem: paletteColorItem)
                    colorCollectionVC.delegate = self
                    navigationController?.pushViewController(colorCollectionVC, animated: true)
                }
            }
        }
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
    
    private func configureColorType() {
        let selectedColorTypeString = preselectParameter(in: tracks) { $0.coloringType }
        if let typeStr = selectedColorTypeString {
            if TracksChangeAppearanceViewController.routeStatisticsAttributesStrings.contains(typeStr) {
                let modifiedTypeStr = typeStr.replacingOccurrences(of: "routeInfo", with: "route_info")
                selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: modifiedTypeStr, defaultValue: .trackSolid)
            } else {
                selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: typeStr, defaultValue: .trackSolid)
            }
        }
        
        if let type = selectedColorType {
            switch type {
            case .trackSolid:
                configureLineColors()
                isColorSelected = true
                isSolidColorSelected = true
                isGradientColorSelected = false
                isRouteAttributeTypeSelected = false
            case .speed, .altitude, .slope:
                configureGradientColors()
                isColorSelected = true
                isSolidColorSelected = false
                isGradientColorSelected = true
                isRouteAttributeTypeSelected = false
            case .attribute:
                selectedRouteAttributesString = type.isRouteInfoAttribute() ? type.getName(routeInfoAttribute: selectedColorTypeString) : nil
                isRouteAttributeTypeSelected = true
                isColorSelected = false
                isSolidColorSelected = false
                isGradientColorSelected = false
            default:
                break
            }
        }
    }
    
    private func configureLineColors() {
        sortedColorItems = Array(appearanceCollection?.getAvailableColorsSortingByLastUsed() ?? [])
        if let trackColor = tracks.first?.color {
            selectedColorItem = appearanceCollection?.getColorItem(withValue: Int32(trackColor))
        } else {
            selectedColorItem = appearanceCollection?.getDefaultLineColorItem()
        }
    }
    
    private func configureGradientColors() {
        if let type = selectedColorType, let rawValue = type.toColorizationType()?.ordinal, let colorizationTypeEnum = ColorizationType(rawValue: Int(rawValue)) {
            gradientColorsCollection = GradientColorsCollection(colorizationType: colorizationTypeEnum)
        }
        
        sortedPaletteColorItems.replaceAll(withObjectsSync: gradientColorsCollection?.getPaletteColors())
        if let paletteName = tracks.first?.gradientPaletteName,
           let palette = gradientColorsCollection?.getPaletteColor(byName: paletteName) {
            selectedPaletteColorItem = palette
        } else {
            selectedPaletteColorItem = gradientColorsCollection?.getDefaultGradientPalette()
        }
    }
    
    private func configureWidth() {
        selectedWidth = preselectParameter(in: tracks) { appearanceCollection?.getWidthForValue($0.width) }
        let minValue = OAGPXTrackWidth.getCustomTrackWidthMin()
        let maxValue = OAGPXTrackWidth.getCustomTrackWidthMax()
        customWidthValues = (minValue...maxValue).map { "\($0)" }
        if let width = selectedWidth {
            switch width.key {
            case WidthKeys.thin:
                isWidthSelected = true
                isCustomWidthSelected = false
                selectedWidthIndex = 0
            case WidthKeys.medium:
                isWidthSelected = true
                isCustomWidthSelected = false
                selectedWidthIndex = 1
            case WidthKeys.bold:
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
    
    @objc private func onCellButtonPressed(_ sender: UIButton) {
        guard let tableData = tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        if item.key == Self.coloringGridRowKey {
            guard let colorItem = selectedColorItem else { return }
            let colorPickerVC = UIColorPickerViewController()
            colorPickerVC.delegate = self
            colorPickerVC.selectedColor = colorItem.getColor()
            self.navigationController?.present(colorPickerVC, animated: true, completion: nil)
        }
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
        let paramValue = selectedColorType
        let isReset = data.shouldResetParameter(.coloringType)
        let isRouteInfoAttribute = selectedColorType?.isRouteInfoAttribute()
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && paramValue == nil ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.coloringType, value: nil)
            self.selectedColorType = nil
            self.isRouteAttributeTypeSelected = false
            if self.isColorSelected {
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.updateData()
            }
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.resetParameter(.coloringType)
            self.data.resetParameter(.color)
            self.isRouteAttributeTypeSelected = false
            if self.isColorSelected {
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.updateData()
            }
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let solidColorAction = UIAction(title: localizedString("track_coloring_solid"), state: !isReset && paramValue == .trackSolid ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.trackSolid.id)
            self.selectedColorType = .trackSolid
            self.configureLineColors()
            self.isColorSelected = true
            self.isSolidColorSelected = true
            self.isGradientColorSelected = false
            self.isRouteAttributeTypeSelected = false
            self.updateData()
        }
        let solidColorMenu = inlineMenu(withActions: [solidColorAction])
        
        let altitudeAction = UIAction(title: localizedString("altitude"), state: !isReset && paramValue == .altitude ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.altitude.id)
            self.selectedColorType = .altitude
            self.configureGradientColors()
            self.isColorSelected = true
            self.isSolidColorSelected = false
            self.isGradientColorSelected = true
            self.isRouteAttributeTypeSelected = false
            self.updateData()
        }
        let speedAction = UIAction(title: localizedString("shared_string_speed"), state: !isReset && paramValue == .speed ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.speed.id)
            self.selectedColorType = .speed
            self.configureGradientColors()
            self.isColorSelected = true
            self.isSolidColorSelected = false
            self.isGradientColorSelected = true
            self.isRouteAttributeTypeSelected = false
            self.updateData()
        }
        let slopeAction = UIAction(title: localizedString("shared_string_slope"), state: !isReset && paramValue == .slope ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.slope.id)
            self.selectedColorType = .slope
            self.configureGradientColors()
            self.isColorSelected = true
            self.isSolidColorSelected = false
            self.isGradientColorSelected = true
            self.isRouteAttributeTypeSelected = false
            self.updateData()
        }
        let gradientColorMenu = inlineMenu(withActions: [altitudeAction, speedAction, slopeAction])
        
        let roadTypeAction = UIAction(title: localizedString("routeInfo_roadClass_name"), image: UIImage.icCustomProLogoOutlined, state: isRouteInfoAttribute ?? false && selectedRouteAttributesString == "routeInfo_roadClass" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            if OAIAPHelper.isOsmAndProAvailable() {
                self.data.setParameter(.coloringType, value: "routeInfo_roadClass")
                self.selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: "routeInfo_roadClass".replacingOccurrences(of: "routeInfo", with: "route_info"))
                self.selectedRouteAttributesString = "routeInfo_roadClass"
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.isRouteAttributeTypeSelected = true
                self.updateData()
            }
        }
        let surfaceAction = UIAction(title: localizedString("routeInfo_surface_name"), image: UIImage.icCustomProLogoOutlined, state: isRouteInfoAttribute ?? false && selectedRouteAttributesString == "routeInfo_surface" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            if OAIAPHelper.isOsmAndProAvailable() {
                self.data.setParameter(.coloringType, value: "routeInfo_surface")
                self.selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: "routeInfo_surface".replacingOccurrences(of: "routeInfo", with: "route_info"))
                self.selectedRouteAttributesString = "routeInfo_surface"
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.isRouteAttributeTypeSelected = true
                self.updateData()
            }
        }
        let smoothhnessAction = UIAction(title: localizedString("routeInfo_smoothness_name"), image: UIImage.icCustomProLogoOutlined, state: isRouteInfoAttribute ?? false && selectedRouteAttributesString == "routeInfo_smoothness" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            if OAIAPHelper.isOsmAndProAvailable() {
                self.data.setParameter(.coloringType, value: "routeInfo_smoothness")
                self.selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: "routeInfo_smoothness".replacingOccurrences(of: "routeInfo", with: "route_info"))
                self.selectedRouteAttributesString = "routeInfo_smoothness"
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.isRouteAttributeTypeSelected = true
                self.updateData()
            }
        }
        let winterRoadsAction = UIAction(title: localizedString("routeInfo_winter_ice_road_name"), image: UIImage.icCustomProLogoOutlined, state: isRouteInfoAttribute ?? false && selectedRouteAttributesString == "routeInfo_winter_ice_road" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            if OAIAPHelper.isOsmAndProAvailable() {
                self.data.setParameter(.coloringType, value: "routeInfo_winter_ice_road")
                self.selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: "routeInfo_winter_ice_road".replacingOccurrences(of: "routeInfo", with: "route_info"))
                self.selectedRouteAttributesString = "routeInfo_winter_ice_road"
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.isRouteAttributeTypeSelected = true
                self.updateData()
            }
        }
        let thicknessRoadsAction = UIAction(title: localizedString("routeInfo_tracktype_name"), image: UIImage.icCustomProLogoOutlined, state: isRouteInfoAttribute ?? false && selectedRouteAttributesString == "routeInfo_tracktype" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            if OAIAPHelper.isOsmAndProAvailable() {
                self.data.setParameter(.coloringType, value: "routeInfo_tracktype")
                self.selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: "routeInfo_tracktype".replacingOccurrences(of: "routeInfo", with: "route_info"))
                self.selectedRouteAttributesString = "routeInfo_tracktype"
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.isRouteAttributeTypeSelected = true
                self.updateData()
            }
        }
        let horseRoadsAction = UIAction(title: localizedString("routeInfo_horse_scale_name"), image: UIImage.icCustomProLogoOutlined, state: isRouteInfoAttribute ?? false && selectedRouteAttributesString == "routeInfo_horse_scale" ? .on : .off) { [weak self] _ in
            guard let self = self else { return }
            if OAIAPHelper.isOsmAndProAvailable() {
                self.data.setParameter(.coloringType, value: "routeInfo_horse_scale")
                self.selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: "routeInfo_horse_scale".replacingOccurrences(of: "routeInfo", with: "route_info"))
                self.selectedRouteAttributesString = "routeInfo_horse_scale"
                self.isColorSelected = false
                self.isSolidColorSelected = false
                self.isGradientColorSelected = false
                self.isRouteAttributeTypeSelected = true
                self.updateData()
            }
        }
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
            self.handleWidthSelection(index: 3)
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

extension TracksChangeAppearanceViewController: OACollectionCellDelegate {
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem: Any?, collectionView: UICollectionView?) {
        if isSolidColorSelected {
            selectedColorItem = sortedColorItems[indexPath.row]
            if let colorValue = selectedColorItem?.value {
                data.setParameter(.color, value: KotlinInt(integerLiteral: colorValue))
            }
        } else if isGradientColorSelected {
            selectedPaletteColorItem = sortedPaletteColorItems.object(atIndexSync: UInt(indexPath.row)) as? PaletteColor
            if let paletteColor = selectedPaletteColorItem as? PaletteGradientColor {
                data.setParameter(.colorPalette, value: paletteColor.paletteName)
            }
        }
    }
    
    func reloadCollectionData() {
    }
}

extension TracksChangeAppearanceViewController: ColorCollectionViewControllerDelegate {
    func selectColorItem(_ colorItem: ColorItem) {
        if let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            onCollectionItemSelected(IndexPath(row: row, section: 0), selectedItem: nil, collectionView: nil)
        }
    }
    
    func selectPaletteItem(_ paletteItem: PaletteColor) {
        let index = sortedPaletteColorItems.index(ofObjectSync: paletteItem)
        if index != NSNotFound {
            onCollectionItemSelected(IndexPath(row: Int(index), section: 0), selectedItem: nil, collectionView: nil)
        }
    }
    
    func addAndGetNewColorItem(_ color: UIColor) -> ColorItem {
        guard let newColorItem = appearanceCollection?.addNewSelectedColor(color) else { return ColorItem(hexColor: color.toHexString()) }
        if let colorsIndexPath = colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
            sortedColorItems.insert(newColorItem, at: 0)
            colorHandler.addAndSelectColor(IndexPath(row: 0, section: 0), newItem: newColorItem)
        }
        
        return newColorItem
    }
    
    func changeColorItem(_ colorItem: ColorItem, withColor color: UIColor) {
        if let colorsIndexPath = colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler, let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            appearanceCollection?.changeColor(colorItem, newColor: color)
            let indexPath = IndexPath(row: row, section: 0)
            colorHandler.replaceOldColor(indexPath)
        }
    }
    
    func duplicateColorItem(_ colorItem: ColorItem) -> ColorItem {
        guard let duplicatedColorItem = appearanceCollection?.duplicateColor(colorItem) else { return colorItem }
        if let colorsIndexPath = colorsCollectionIndexPath, let index = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            sortedColorItems.insert(duplicatedColorItem, at: index + 1)
            if let colorCell = tableView.cellForRow(at: colorsIndexPath) as? OACollectionSingleLineTableViewCell,
               let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                let newIndexPath = IndexPath(row: index + 1, section: 0)
                colorHandler.addColor(newIndexPath, newItem: duplicatedColorItem)
            }
        }
        
        return duplicatedColorItem
    }
    
    func deleteColorItem(_ colorItem: ColorItem) {
        if let colorsIndexPath = colorsCollectionIndexPath, let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            let indexPathForColor = IndexPath(row: row, section: 0)
            appearanceCollection?.deleteColor(colorItem)
            sortedColorItems.remove(at: row)
            if let colorCell = tableView.cellForRow(at: colorsIndexPath) as? OACollectionSingleLineTableViewCell,
               let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                colorHandler.removeColor(indexPathForColor)
            }
        }
    }
}

extension TracksChangeAppearanceViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        _ = addAndGetNewColorItem(viewController.selectedColor)
    }
}
