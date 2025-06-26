//
//  TracksChangeAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

private enum WidthKeys: String {
    case thin, medium, bold
}

private enum RowKey: String {
    case directionArrowsRowKey
    case startFinishIconsRowKey
    case coloringRowKey
    case coloringDescRowKey
    case coloringGridRowKey
    case gradientLegendRowKey
    case allColorsRowKey
    case widthRowKey
    case widthModesRowKey
    case splitModesRowKey
    case customWidthModesRowKey
    case customSplitIntervalRowKey
    case widthDescrRowKey
    case splitIntervalRowKey
    case splitIntervalDescrRowKey
    case splitIntervalNoneDescrRowKey
}

final class TracksChangeAppearanceViewController: OABaseNavbarViewController {
    private static let customStringValue = "customStringValue"
    private static let widthArrayValue = "widthArrayValue"
    private static let hasTopLabels = "hasTopLabels"
    private static let hasBottomLabels = "hasBottomLabels"
    
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
        appearanceCollection = OAGPXAppearanceCollection.sharedInstance()
        configureShowArrows()
        configureShowStartFinish()
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
        addCell(SegmentImagesTableViewCell.reuseIdentifier)
        addCell(SegmentTextTableViewCell.reuseIdentifier)
        addCell(OASegmentSliderTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString("change_appearance")
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(localizedString("shared_string_done"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil)]
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
        directionArrowsRow.key = RowKey.directionArrowsRowKey.rawValue
        directionArrowsRow.title = localizedString("gpx_direction_arrows")
        let startFinishIconsRow = directionSection.createNewRow()
        startFinishIconsRow.cellType = OAButtonTableViewCell.reuseIdentifier
        startFinishIconsRow.key = RowKey.startFinishIconsRowKey.rawValue
        startFinishIconsRow.title = localizedString("track_show_start_finish_icons")
        
        let coloringSection = tableData.createNewSection()
        let coloringRow = coloringSection.createNewRow()
        coloringRow.cellType = OAButtonTableViewCell.reuseIdentifier
        coloringRow.key = RowKey.coloringRowKey.rawValue
        coloringRow.title = localizedString("shared_string_coloring")
        if isColorSelected {
            if isSolidColorSelected {
                let coloringGridRow = coloringSection.createNewRow()
                coloringGridRow.cellType = OACollectionSingleLineTableViewCell.reuseIdentifier
                coloringGridRow.key = RowKey.coloringGridRowKey.rawValue
                colorsCollectionIndexPath = IndexPath(row: Int(tableData.rowCount(tableData.sectionCount() - 1)) - 1, section: Int(tableData.sectionCount()) - 1)
            } else if isGradientColorSelected {
                let gradientLegendRow = coloringSection.createNewRow()
                gradientLegendRow.cellType = GradientChartCell.reuseIdentifier
                gradientLegendRow.key = RowKey.gradientLegendRowKey.rawValue
                let coloringGridRow = coloringSection.createNewRow()
                coloringGridRow.cellType = OACollectionSingleLineTableViewCell.reuseIdentifier
                coloringGridRow.key = RowKey.coloringGridRowKey.rawValue
                colorsCollectionIndexPath = IndexPath(row: Int(tableData.rowCount(tableData.sectionCount() - 1)) - 1, section: Int(tableData.sectionCount()) - 1)
            }
            let allColorsRow = coloringSection.createNewRow()
            allColorsRow.cellType = OAValueTableViewCell.reuseIdentifier
            allColorsRow.key = RowKey.allColorsRowKey.rawValue
            allColorsRow.title = localizedString("shared_string_all_colors")
            allColorsRow.iconTintColor = .iconColorActive
        } else {
            let coloringDescrRow = coloringSection.createNewRow()
            coloringDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
            coloringDescrRow.key = RowKey.coloringDescRowKey.rawValue
            coloringDescrRow.title = localizedString(isRouteAttributeTypeSelected ? "white_color_undefined" : "unchanged_parameter_summary")
        }
        
        let widthSection = tableData.createNewSection()
        let widthRow = widthSection.createNewRow()
        widthRow.cellType = OAButtonTableViewCell.reuseIdentifier
        widthRow.key = RowKey.widthRowKey.rawValue
        widthRow.title = localizedString("routing_attr_width_name")
        if isWidthSelected {
            let widthModesRow = widthSection.createNewRow()
            widthModesRow.cellType = SegmentImagesTableViewCell.reuseIdentifier
            widthModesRow.key = RowKey.widthModesRowKey.rawValue
            if isCustomWidthSelected {
                let customWidthModesRow = widthSection.createNewRow()
                customWidthModesRow.cellType = OASegmentSliderTableViewCell.reuseIdentifier
                customWidthModesRow.key = RowKey.customWidthModesRowKey.rawValue
                customWidthModesRow.setObj(selectedWidth?.customValue as Any, forKey: Self.customStringValue)
                customWidthModesRow.setObj(customWidthValues, forKey: Self.widthArrayValue)
                customWidthModesRow.setObj(false, forKey: Self.hasTopLabels)
                customWidthModesRow.setObj(true, forKey: Self.hasBottomLabels)
            }
        } else {
            let widthDescrRow = widthSection.createNewRow()
            widthDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
            widthDescrRow.key = RowKey.widthDescrRowKey.rawValue
            widthDescrRow.title = localizedString("unchanged_parameter_summary")
        }
        
        let splitIntervalSection = tableData.createNewSection()
        let splitIntervalRow = splitIntervalSection.createNewRow()
        splitIntervalRow.cellType = OAButtonTableViewCell.reuseIdentifier
        splitIntervalRow.key = RowKey.splitIntervalRowKey.rawValue
        splitIntervalRow.title = localizedString("gpx_split_interval")
        if isSplitIntervalSelected {
            let splitModesRow = splitIntervalSection.createNewRow()
            splitModesRow.cellType = SegmentTextTableViewCell.reuseIdentifier
            splitModesRow.key = RowKey.splitModesRowKey.rawValue
            if isSplitIntervalNoneSelected {
                let splitIntervalNoneDescrRow = splitIntervalSection.createNewRow()
                splitIntervalNoneDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
                splitIntervalNoneDescrRow.key = RowKey.splitIntervalNoneDescrRowKey.rawValue
                splitIntervalNoneDescrRow.title = localizedString("gpx_split_interval_none_descr")
            } else {
                let customSplitIntervalRow = splitIntervalSection.createNewRow()
                customSplitIntervalRow.cellType = OASegmentSliderTableViewCell.reuseIdentifier
                customSplitIntervalRow.key = RowKey.customSplitIntervalRowKey.rawValue
                customSplitIntervalRow.title = localizedString("shared_string_interval")
                customSplitIntervalRow.setObj(selectedSplit?.customValue as Any, forKey: Self.customStringValue)
                customSplitIntervalRow.setObj(selectedSplit?.titles as Any, forKey: Self.widthArrayValue)
                customSplitIntervalRow.setObj(true, forKey: Self.hasTopLabels)
                customSplitIntervalRow.setObj(true, forKey: Self.hasBottomLabels)
            }
        } else {
            let splitIntervalDescrRow = splitIntervalSection.createNewRow()
            splitIntervalDescrRow.cellType = OASimpleTableViewCell.reuseIdentifier
            splitIntervalDescrRow.key = RowKey.splitIntervalDescrRowKey.rawValue
            splitIntervalDescrRow.title = localizedString("unchanged_parameter_summary")
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == OAButtonTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
            if cell.contentHeightConstraint == nil {
                let constraint = cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
                constraint.isActive = true
                cell.contentHeightConstraint = constraint
            }
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.setCustomLeftSeparatorInset(false)
            let selectedKeys = [
                (key: RowKey.widthRowKey.rawValue, isSelected: isWidthSelected),
                (key: RowKey.splitIntervalRowKey.rawValue, isSelected: isSplitIntervalSelected),
                (key: RowKey.coloringRowKey.rawValue, isSelected: isColorSelected)
            ]
            if selectedKeys.contains(where: { $0.key == item.key && $0.isSelected }) {
                cell.setCustomLeftSeparatorInset(true)
                cell.separatorInset = UIEdgeInsets(top: 0, left: tableView.bounds.width, bottom: 0, right: 0)
            }
            cell.titleLabel.text = item.title
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = .textColorActive
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 0)
            cell.button.configuration = config
            if let key = item.key {
                cell.button.menu = createStateSelectionMenu(for: key)
            }
            cell.button.showsMenuAsPrimaryAction = true
            cell.button.changesSelectionAsPrimaryAction = true
            cell.button.contentHorizontalAlignment = .right
            cell.button.setContentHuggingPriority(.required, for: .horizontal)
            cell.button.setContentCompressionResistancePriority(.required, for: .horizontal)
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
            cell.disableAnimationsOnStart = true
            if isSolidColorSelected {
                cell.rightActionButton.addTarget(self, action: #selector(onCellButtonPressed(_:)), for: .touchUpInside)
                let colorHandler = OAColorCollectionHandler(data: [sortedColorItems], collectionView: cell.collectionView)
                colorHandler?.delegate = self
                colorHandler?.hostVC = self
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
        } else if item.cellType == SegmentImagesTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentImagesTableViewCell.reuseIdentifier) as! SegmentImagesTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.setSegmentedControlBottomSpacing(isCustomWidthSelected ? 8 : 20)
            cell.configureSegmentedControl(icons: [.icCustomTrackLineThin, .icCustomTrackLineMedium, .icCustomTrackLineBold, .icCustomParameters], selectedSegmentIndex: selectedWidthIndex)
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self else { return }
                self.handleWidthSelection(index: index)
            }
            return cell
        } else if item.cellType == SegmentTextTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentTextTableViewCell.reuseIdentifier) as! SegmentTextTableViewCell
            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFLOAT_MAX, bottom: 0, right: 0)
            cell.setSegmentedControlBottomSpacing(8)
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
            cell.topRightLabel.text = (item.key == RowKey.customSplitIntervalRowKey.rawValue) ? (item.obj(forKey: Self.customStringValue) as? String ?? "") : ""
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
        if item.key == RowKey.allColorsRowKey.rawValue {
            if isSolidColorSelected {
                if let items = appearanceCollection?.getAvailableColorsSortingByLastUsed(), let colorItem = selectedColorItem {
                    let colorCollectionVC = ItemsCollectionViewController(collectionType: .colorItems, items: items, selectedItem: colorItem)
                    colorCollectionVC.delegate = self
    
                    if let colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                        colorCollectionVC.hostColorHandler = colorHandler
                    }
                    
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
                guard let self else { return }
                self.dismiss(animated: true, completion: nil)
            }
            let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self] _ in
                guard let self else { return }
                self.onRightNavbarButtonPressed()
            }
            let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel, handler: nil)
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
        let task = ChangeTracksAppearanceTask(data: data, items: tracks) { [weak self] in
            guard let self else { return }
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
    
    private func configureShowArrows() {
        selectedShowArrows = preselectParameter(in: tracks) { $0.showArrows }
        initialData.setParameter(.showArrows, value: selectedShowArrows)
        data.setParameter(.showArrows, value: selectedShowArrows)
    }
    
    private func configureShowStartFinish() {
        selectedShowStartFinish = preselectParameter(in: tracks) { $0.showStartFinish }
        initialData.setParameter(.showStartFinish, value: selectedShowStartFinish)
        data.setParameter(.showStartFinish, value: selectedShowStartFinish)
    }
    
    private func configureColorType() {
        guard let typeStr = preselectParameter(in: tracks, extractor: { $0.coloringType }) else { return }
        let normalizedTypeStr = kRouteStatisticsAttributesStrings.contains(typeStr) ? typeStr.replacingOccurrences(of: "routeInfo", with: "route_info") : typeStr
        selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: normalizedTypeStr, defaultValue: .trackSolid)
        initialData.setParameter(.coloringType, value: selectedColorType?.id)
        data.setParameter(.coloringType, value: selectedColorType?.id)
        guard let type = selectedColorType else { return }
        switch type {
        case .trackSolid:
            if preselectParameter(in: tracks, extractor: { $0.color }) != nil {
                configureLineColors()
                isColorSelected = true
                isSolidColorSelected = true
            } else {
                selectedColorType = nil
                initialData.setParameter(.coloringType, value: nil)
                data.setParameter(.coloringType, value: nil)
                isColorSelected = false
                isSolidColorSelected = false
            }
            isGradientColorSelected = false
            isRouteAttributeTypeSelected = false
        case .speed, .altitude, .slope:
            if preselectParameter(in: tracks, extractor: { $0.gradientPaletteName }) != nil {
                configureGradientColors()
                isColorSelected = true
                isGradientColorSelected = true
            } else {
                selectedColorType = nil
                initialData.setParameter(.coloringType, value: nil)
                data.setParameter(.coloringType, value: nil)
                isColorSelected = false
                isGradientColorSelected = false
            }
            isSolidColorSelected = false
            isRouteAttributeTypeSelected = false
        case .attribute:
            selectedRouteAttributesString = type.isRouteInfoAttribute() ? type.getName(routeInfoAttribute: typeStr) : nil
            isRouteAttributeTypeSelected = true
            isColorSelected = false
            isSolidColorSelected = false
            isGradientColorSelected = false
        default:
            break
        }
    }
    
    private func configureLineColors() {
        sortedColorItems = Array(appearanceCollection?.getAvailableColorsSortingByLastUsed() ?? [])
        if let trackColor = tracks.first?.color {
            selectedColorItem = appearanceCollection?.getColorItem(withValue: Int32(trackColor))
        } else {
            selectedColorItem = appearanceCollection?.getDefaultLineColorItem()
        }
        
        initialData.setParameter(.color, value: KotlinInt(integerLiteral: selectedColorItem?.value ?? 0))
        data.setParameter(.color, value: KotlinInt(integerLiteral: selectedColorItem?.value ?? 0))
    }
    
    private func configureGradientColors() {
        guard let type = selectedColorType, let ordinal = type.toColorizationType()?.ordinal, let colorizationTypeEnum = ColorizationType(rawValue: Int(ordinal)) else { return }
        gradientColorsCollection = GradientColorsCollection(colorizationType: colorizationTypeEnum)
        if let paletteColors = gradientColorsCollection?.getColors(.original) {
            sortedPaletteColorItems.replaceAll(withObjectsSync: paletteColors)
        }
        
        if let paletteName = tracks.first?.gradientPaletteName, let palette = gradientColorsCollection?.getPaletteColor(byName: paletteName) {
            selectedPaletteColorItem = palette
        } else {
            selectedPaletteColorItem = gradientColorsCollection?.getDefaultGradientPalette()
        }
        
        if let paletteGradient = selectedPaletteColorItem as? PaletteGradientColor {
            initialData.setParameter(.colorPalette, value: paletteGradient.paletteName)
            data.setParameter(.colorPalette, value: paletteGradient.paletteName)
        }
    }
    
    private func configureWidth() {
        selectedWidth = preselectParameter(in: tracks) { appearanceCollection?.getWidthForValue($0.width) }
        let minValue = OAGPXTrackWidth.getCustomTrackWidthMin()
        let maxValue = OAGPXTrackWidth.getCustomTrackWidthMax()
        customWidthValues = (minValue...maxValue).map { "\($0)" }
        guard let width = selectedWidth else { return }
        isWidthSelected = true
        isCustomWidthSelected = false
        let widthString = width.isCustom() ? width.customValue : width.key
        initialData.setParameter(.width, value: widthString)
        data.setParameter(.width, value: widthString)
        switch width.key {
        case WidthKeys.thin.rawValue:
            selectedWidthIndex = 0
        case WidthKeys.medium.rawValue:
            selectedWidthIndex = 1
        case WidthKeys.bold.rawValue:
            selectedWidthIndex = 2
        default:
            isCustomWidthSelected = true
            selectedWidthIndex = 3
        }
    }
    
    private func configureSplitInterval() {
        selectedSplit = preselectParameter(in: tracks) { appearanceCollection?.getSplitInterval(for: $0.splitType) }
        if let firstTrack = tracks.first {
            if firstTrack.splitInterval > 0 && firstTrack.splitType != EOAGpxSplitType.none {
                selectedSplit?.customValue = selectedSplit?.titles[(selectedSplit?.values.firstIndex { ($0).doubleValue == Double(firstTrack.splitInterval) }) ?? 0]
            }
        }
        
        if let selectedSplit {
            isSplitIntervalSelected = true
            switch selectedSplit.type {
            case .none:
                isSplitIntervalNoneSelected = true
                selectedSplitIntervalIndex = 0
            case .time:
                isSplitIntervalNoneSelected = false
                selectedSplitIntervalIndex = 1
            case .distance:
                isSplitIntervalNoneSelected = false
                selectedSplitIntervalIndex = 2
            default:
                break
            }
            
            let splitTypeValue = Int32(selectedSplit.type.rawValue)
            initialData.setParameter(.splitType, value: splitTypeValue)
            data.setParameter(.splitType, value: splitTypeValue)
            if selectedSplit.isCustom(), let customValue = selectedSplit.customValue, let customIndex = selectedSplit.titles.firstIndex(of: customValue) {
                let intervalValue = selectedSplit.values[customIndex].doubleValue
                initialData.setParameter(.splitInterval, value: intervalValue)
                data.setParameter(.splitInterval, value: intervalValue)
            } else {
                initialData.setParameter(.splitInterval, value: 0)
                data.setParameter(.splitInterval, value: 0)
            }
        }
    }
    
    private func preselectParameter<T: Equatable>(in tracks: Set<TrackItem>, extractor: (TrackItem) -> T?) -> T? {
        guard let firstTrack = tracks.first, let firstValue = extractor(firstTrack) else { return nil }
        return tracks.allSatisfy { extractor($0) == firstValue } ? firstValue : nil
    }
    
    private func createStateSelectionMenu(for key: String) -> UIMenu {
        switch key {
        case RowKey.directionArrowsRowKey.rawValue:
            return createArrowsMenu()
        case RowKey.startFinishIconsRowKey.rawValue:
            return createStartFinishMenu()
        case RowKey.coloringRowKey.rawValue:
            return createColoringMenu()
        case RowKey.widthRowKey.rawValue:
            return createWidthMenu()
        case RowKey.splitIntervalRowKey.rawValue:
            return createSplitIntervalMenu()
        default:
            return UIMenu()
        }
    }
    
    private func updateData() {
        generateData()
        tableView.reloadData()
    }
    
    private func updateSection(containingRowKey key: RowKey) {
        generateData()
        guard let matchingSection = (0..<tableData.sectionCount()).first(where: {
            let sectionData = tableData.sectionData(for: $0)
            return (0..<sectionData.rowCount()).contains { sectionData.getRow($0).key == key.rawValue }
        }) else { return }
        tableView.reloadSections(IndexSet(integer: Int(matchingSection)), with: .automatic)
    }
    
    private func handleWidthSelection(index: Int) {
        guard let widths = appearanceCollection?.getAvailableWidth(), index >= 0, index < widths.count else { return }
        let width = widths[index]
        selectedWidth = width
        let isCustom = width.isCustom()
        let widthString = isCustom ? width.customValue : width.key
        data.setParameter(.width, value: widthString)
        isWidthSelected = true
        isCustomWidthSelected = isCustom
        selectedWidthIndex = index
        updateSection(containingRowKey: .widthRowKey)
    }
    
    private func handleSplitIntervalSelection(index: Int) {
        guard let availableSplits = appearanceCollection?.getAvailableSplitIntervals(), index >= 0, index < availableSplits.count else { return }
        let split = availableSplits[index]
        selectedSplit = split
        data.setParameter(.splitType, value: Int32(split.type.rawValue))
        let isCustom = split.isCustom()
        if isCustom, let customValue = split.customValue, let customIndex = split.titles.firstIndex(of: customValue) {
            data.setParameter(.splitInterval, value: split.values[customIndex].doubleValue)
        } else {
            data.setParameter(.splitInterval, value: 0)
        }
        
        isSplitIntervalSelected = true
        isSplitIntervalNoneSelected = split.key == "no_split"
        selectedSplitIntervalIndex = index
        updateSection(containingRowKey: .splitIntervalRowKey)
    }
    
    @objc private func onCellButtonPressed(_ sender: UIButton) {
        guard let tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        if item.key == RowKey.coloringGridRowKey.rawValue {
            guard let colorItem = selectedColorItem else { return }
            let colorPickerVC = UIColorPickerViewController()
            colorPickerVC.delegate = self
            colorPickerVC.selectedColor = colorItem.getColor()
            self.navigationController?.present(colorPickerVC, animated: true, completion: nil)
        }
    }
    
    @objc private func sliderChanged(sender: UISlider) {
        guard let tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.cellForRow(at: indexPath) as? OASegmentSliderTableViewCell else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        if item.key == RowKey.customWidthModesRowKey.rawValue {
            guard let customWidthValues = item.obj(forKey: Self.widthArrayValue) as? [String], selectedIndex >= 0, selectedIndex < customWidthValues.count else { return }
            let selectedValue = customWidthValues[selectedIndex]
            if let w = selectedWidth, w.isCustom() {
                w.customValue = selectedValue
            }
            data.setParameter(.width, value: selectedValue)
        } else if item.key == RowKey.customSplitIntervalRowKey.rawValue {
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
    
    private func getColorHandler() -> OAColorCollectionHandler? {
        guard let colorsCollectionIndexPath,
              let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell,
              let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler else { return nil }
        
        return colorHandler
    }
}

extension TracksChangeAppearanceViewController {
    private func createArrowsMenu() -> UIMenu {
        return createBooleanSelectionMenu(currentValue: selectedShowArrows, parameter: .showArrows) { [weak self] newValue in
            self?.selectedShowArrows = newValue
        }
    }
    
    private func createStartFinishMenu() -> UIMenu {
        return createBooleanSelectionMenu(currentValue: selectedShowStartFinish, parameter: .showStartFinish) { [weak self] newValue in
            self?.selectedShowStartFinish = newValue
        }
    }
    
    private func createBooleanSelectionMenu(currentValue: Bool?, parameter: GpxParameter, update: @escaping (Bool?) -> Void) -> UIMenu {
        let isReset = data.shouldResetParameter(parameter)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && currentValue == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(parameter, value: nil)
            update(nil)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(parameter)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: !isReset && currentValue == true ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(parameter, value: true)
            update(true)
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: !isReset && currentValue == false ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(parameter, value: false)
            update(false)
        }
        let onOffMenu = inlineMenu(withActions: [onAction, offAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func createColoringMenu() -> UIMenu {
        let isReset = data.shouldResetParameter(.coloringType)
        let isRouteInfoAttribute = selectedColorType?.isRouteInfoAttribute() ?? false
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && selectedColorType == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: nil)
            self.selectedColorType = nil
            self.isRouteAttributeTypeSelected = false
            self.resetColorSelectionFlags()
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.coloringType)
            self.data.resetParameter(.color)
            self.selectedColorType = nil
            self.isRouteAttributeTypeSelected = false
            self.resetColorSelectionFlags()
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let solidColorAction = UIAction(title: localizedString("track_coloring_solid"), state: !isReset && selectedColorType == .trackSolid ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.trackSolid.id)
            self.selectedColorType = .trackSolid
            self.configureLineColors()
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: true)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let solidColorMenu = inlineMenu(withActions: [solidColorAction])
        
        let altitudeAction = UIAction(title: localizedString("altitude"), state: !isReset && selectedColorType == .altitude ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.altitude.id)
            self.selectedColorType = .altitude
            self.configureGradientColors()
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: false)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let speedAction = UIAction(title: localizedString("shared_string_speed"), state: !isReset && selectedColorType == .speed ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.speed.id)
            self.selectedColorType = .speed
            self.configureGradientColors()
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: false)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let slopeAction = UIAction(title: localizedString("shared_string_slope"), state: !isReset && selectedColorType == .slope ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.slope.id)
            self.selectedColorType = .slope
            self.configureGradientColors()
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: false)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let gradientColorMenu = inlineMenu(withActions: [altitudeAction, speedAction, slopeAction])
        
        let proColorActions = (kRouteStatisticsAttributesStrings as? [String])?.map { attribute in
            return createProColorAction(titleKey: attribute + "_name", parameterValue: attribute, selectedString: attribute, isRouteInfoAttribute: isRouteInfoAttribute)
        } ?? []
        let proColorMenu = inlineMenu(withActions: proColorActions)
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, solidColorMenu, gradientColorMenu, proColorMenu])
    }
    
    private func createProColorAction(titleKey: String, parameterValue: String, selectedString: String, isRouteInfoAttribute: Bool) -> UIAction {
        return UIAction(title: localizedString(titleKey), image: OAIAPHelper.isOsmAndProAvailable() ? nil : .icCustomProLogoOutlined, state: isRouteInfoAttribute && (selectedRouteAttributesString == selectedString) ? .on : .off) { [weak self] _ in
            guard let self else { return }
            if OAIAPHelper.isOsmAndProAvailable() {
                self.data.setParameter(.coloringType, value: parameterValue)
                self.selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: parameterValue.replacingOccurrences(of: "routeInfo", with: "route_info"))
                self.selectedRouteAttributesString = selectedString
                self.resetColorSelectionFlags()
                self.isRouteAttributeTypeSelected = true
            } else {
                if let navigationController {
                    OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
                }
            }
            
            self.updateSection(containingRowKey: .coloringRowKey)
        }
    }
    
    private func resetColorSelectionFlags() {
        isColorSelected = false
        isSolidColorSelected = false
        isGradientColorSelected = false
    }
    
    private func isColorSelectionEnabled(_ enabled: Bool, solid: Bool) {
        isColorSelected = enabled
        isSolidColorSelected = solid
        isGradientColorSelected = !solid
    }
    
    private func createWidthMenu() -> UIMenu {
        let paramValue: String? = selectedWidth?.isCustom() == true ? selectedWidth?.customValue : selectedWidth?.key
        let isReset = data.shouldResetParameter(.width)
        let fixedWidths: [(titleKey: String, widthKey: String, index: Int)] = [("rendering_value_thin_name", "thin", 0), ("rendering_value_medium_w_name", "medium", 1), ("rendering_value_bold_name", "bold", 2)]
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: (!isReset && paramValue == nil) ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.width, value: nil)
            self.selectedWidth = nil
            self.isWidthSelected = false
            self.isCustomWidthSelected = false
            self.updateSection(containingRowKey: .widthRowKey)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isReset ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.width)
            self.isWidthSelected = false
            self.isCustomWidthSelected = false
            self.updateSection(containingRowKey: .widthRowKey)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let fixedWidthActions = fixedWidths.map { item in
            return UIAction(title: localizedString(item.titleKey), state: (!isReset && paramValue == item.widthKey) ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.handleWidthSelection(index: item.index)
            }
        }
        let widthMenu = inlineMenu(withActions: fixedWidthActions)
        
        let customAction = UIAction(title: localizedString("shared_string_custom"), state: (!isReset && paramValue == selectedWidth?.customValue) ? .on : .off) { [weak self] _ in
            guard let self else { return }
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
        let currentType = paramSplitType ?? 0
        let isNoSplit = paramSplitType != nil && currentType == GpxSplitType.noSplit.type
        let isTime = currentType == GpxSplitType.time.type
        let isDistance = currentType == GpxSplitType.distance.type
        
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: isUnchanged ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.splitType, value: nil)
            self.data.setParameter(.splitInterval, value: nil)
            self.selectedSplit = nil
            self.isSplitIntervalSelected = false
            self.isSplitIntervalNoneSelected = false
            self.updateSection(containingRowKey: .splitIntervalRowKey)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isOriginalSelected ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.splitType)
            self.data.resetParameter(.splitInterval)
            self.isSplitIntervalSelected = false
            self.isSplitIntervalNoneSelected = false
            self.updateSection(containingRowKey: .splitIntervalRowKey)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: [unchangedAction, originalAction])
        
        let noSplitAction = UIAction(title: localizedString("shared_string_none"), state: isNoSplit ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.handleSplitIntervalSelection(index: 0)
        }
        let timeAction = UIAction(title: localizedString("shared_string_time"), state: isTime ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.handleSplitIntervalSelection(index: 1)
        }
        let distanceAction = UIAction(title: localizedString("shared_string_distance"), state: isDistance ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.handleSplitIntervalSelection(index: 2)
        }
        let onOffMenu = inlineMenu(withActions: [noSplitAction, timeAction, distanceAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func inlineMenu(withActions actions: [UIAction]) -> UIMenu {
        UIMenu(title: "", options: .displayInline, children: actions)
    }
}

extension TracksChangeAppearanceViewController: OACollectionCellDelegate {
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem: Any?, collectionView: UICollectionView?, shouldDismiss: Bool) {
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
        guard let appearanceCollection else { return }
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
        var selectedItem: ColorItem?
        if let colorHandler = getColorHandler(), let selectedColor = colorHandler.getSelectedItem() {
            selectedItem = selectedColor
        }
        if selectedItem == nil {
            if let trackColor = tracks.first?.color {
                selectedItem = appearanceCollection.getColorItem(withValue: Int32(trackColor))
            } else {
                selectedItem = appearanceCollection.getDefaultLineColorItem()
            }
        }
        selectedColorItem = selectedItem
    }
}

extension TracksChangeAppearanceViewController: ColorCollectionViewControllerDelegate {
    func selectColorItem(_ colorItem: ColorItem) {
        if let row = sortedColorItems.firstIndex(where: { $0 == colorItem }) {
            onCollectionItemSelected(IndexPath(row: row, section: 0), selectedItem: nil, collectionView: nil, shouldDismiss: true)
            updateSection(containingRowKey: .coloringRowKey)
        }
    }
    
    func selectPaletteItem(_ paletteItem: PaletteColor) {
        let index = sortedPaletteColorItems.index(ofObjectSync: paletteItem)
        if index != NSNotFound {
            onCollectionItemSelected(IndexPath(row: Int(index), section: 0), selectedItem: nil, collectionView: nil, shouldDismiss: true)
            updateSection(containingRowKey: .coloringRowKey)
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
    
    func reloadData() {
        // called from All Pallets screen
        
        // TODO: remove asyncAfter.
        // there is bug with deleting several color paletes from AllColor screen. Last 2 paletes not removable from host screen without this.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let paletteColors = self.gradientColorsCollection?.getColors(.original) {
                self.sortedPaletteColorItems.replaceAll(withObjectsSync: paletteColors)
            }
            self.updateData()
        }
    }
}

extension TracksChangeAppearanceViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        _ = addAndGetNewColorItem(viewController.selectedColor)
    }
}
