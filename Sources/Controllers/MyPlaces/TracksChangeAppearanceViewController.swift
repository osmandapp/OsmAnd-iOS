//
//  TracksChangeAppearanceViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 18.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

import UIKit

enum InitMode {
    case tracks(Set<TrackItem>)
    case folder(TrackFolder)
}

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
    case applyExistingTracksRowKey
}

final class TracksChangeAppearanceViewController: OABaseNavbarViewController {
    private static let customStringValue = "customStringValue"
    private static let widthArrayValue = "widthArrayValue"
    private static let hasTopLabels = "hasTopLabels"
    private static let hasBottomLabels = "hasBottomLabels"
    private static let isEnabledValue = "isEnabled"
    
    private let folder: TrackFolder?
    private let dirItem: GpxDirItem?
    private let appearanceCollection: OAGPXAppearanceCollection = OAGPXAppearanceCollection.sharedInstance()
    
    private var tracks: Set<TrackItem>
    private var initialData: AppearanceData
    private var data: AppearanceData
    private var sortedColorItems: [PaletteItemSolid] = []
    private var sortedPaletteColorItems = OAConcurrentArray<PaletteItemGradient>()
    private var selectedShowArrows: Bool?
    private var selectedShowStartFinish: Bool?
    private var selectedColorType: ColoringType?
    private var selectedRouteAttributesString: String?
    private var selectedColorItem: PaletteItemSolid?
    private var selectedPaletteColorItem: PaletteItemGradient?
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
    
    init(mode: InitMode) {
        switch mode {
        case .tracks(let tracks):
            self.folder = nil
            self.dirItem = nil
            self.tracks = tracks
            self.initialData = Self.buildAppearanceData()
        case .folder(let folder):
            let dirItem = folder.dirItem ?? GpxDbHelper.shared.getGpxDirItem(file: folder.getDirFile())
            folder.dirItem = dirItem
            self.folder = folder
            self.dirItem = dirItem
            self.tracks = Set(folder.getTrackItems())
            self.initialData = Self.buildAppearanceData(from: dirItem)
        }
        
        self.data = AppearanceData(data: self.initialData)
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    override func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(productPurchased(_:)), name: Notification.Name(NSNotification.Name.OAIAPProductPurchased.rawValue), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(productsRestored(_:)), name: Notification.Name(NSNotification.Name.OAIAPProductsRestored.rawValue), object: nil)
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
        addCell(OASearchMoreCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString(folder == nil ? "change_appearance" : "default_appearance")
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
    
    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func getTableHeaderDescription() -> String? {
        folder != nil ? localizedString("default_appearance_description") : nil
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
        
        if folder != nil {
            let applySection = tableData.createNewSection()
            applySection.footerText = localizedString("apply_to_existing_tracks_description")
            let applyRow = applySection.createNewRow()
            applyRow.cellType = OASearchMoreCell.reuseIdentifier
            applyRow.key = RowKey.applyExistingTracksRowKey.rawValue
            applyRow.title = applyExistingTracksTitle()
            applyRow.setObj(hasAppearanceChanges() && !tracks.isEmpty, forKey: Self.isEnabledValue)
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
            cell.backgroundColor = .groupBg
            GpxUIHelper.setupGradientChart(chart: cell.chartView, useGesturesAndScale: false, xAxisGridColor: .chartAxisGridLine, labelsColor: .textColorSecondary)
            if let paletteItem = selectedPaletteColorItem {
                let fileType = paletteItem.properties.fileType
                let colorPalette = paletteItem.isFixed() ? GradientFormatter.getAdjustedPalette(originalPalette: paletteItem.getColorPalette(), analysis: nil, fileType: fileType) : paletteItem.getColorPalette()
                cell.chartView.data = GpxUIHelper.buildGradientChart(chart: cell.chartView, colorPalette: colorPalette, valueFormatter: GradientFormatter.getAxisFormatter(fileType: fileType, analysis: nil))
                cell.chartView.notifyDataSetChanged()
                cell.chartView.setNeedsDisplay()
            }
            return cell
        } else if item.cellType == OACollectionSingleLineTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier) as! OACollectionSingleLineTableViewCell
            let isRightActionButtonVisible = isSolidColorSelected || isGradientColorSelected
            cell.rightActionButtonVisibility(isRightActionButtonVisible)
            cell.rightActionButton.setImage(isRightActionButtonVisible ? UIImage.templateImageNamed("ic_custom_add") : nil, for: .normal)
            cell.rightActionButton.tag = isRightActionButtonVisible ? (indexPath.section << 10 | indexPath.row) : 0
            cell.rightActionButton.accessibilityLabel = isRightActionButtonVisible ? localizedString(isSolidColorSelected ? "shared_string_add_color" : "add_palette") : nil
            cell.rightActionButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.disableAnimationsOnStart = true
            if isSolidColorSelected {
                cell.rightActionButton.addTarget(self, action: #selector(onColorCellButtonPressed(_:)), for: .touchUpInside)
                let colorHandler = OAColorCollectionHandler(data: [sortedColorItems], collectionView: cell.collectionView)
                colorHandler?.delegate = self
                colorHandler?.hostVC = self
                let selectedIndex = appearanceCollection.index(ofColorItem: selectedColorItem, items: sortedColorItems)
                if selectedIndex != NSNotFound {
                    colorHandler?.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
                }
                cell.setCollectionHandler(colorHandler)
            } else if isGradientColorSelected {
                cell.rightActionButton.addTarget(self, action: #selector(onPaletteCellButtonPressed(_:)), for: .touchUpInside)
                let paletteItems = sortedPaletteColorItems.asArray().compactMap { $0 as? PaletteItemGradient }
                let paletteHandler = PaletteCollectionHandler(data: [paletteItems], collectionView: cell.collectionView)
                paletteHandler?.delegate = self
                var selectedIndex = GradientPaletteHelper.shared.index(of: selectedPaletteColorItem, in: paletteItems)
                selectedIndex = selectedIndex != NSNotFound ? selectedIndex : GradientPaletteHelper.shared.index(of: GradientPaletteHelper.shared.defaultPaletteItem(gradientScaleType: selectedColorType?.toGradientScaleType()), in: paletteItems)
                selectedIndex = selectedIndex != NSNotFound ? selectedIndex : 0
                let selectedIndexPath = IndexPath(row: selectedIndex, section: 0)
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
        } else if item.cellType == OASearchMoreCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASearchMoreCell.reuseIdentifier, for: indexPath) as! OASearchMoreCell
            let isEnabled = item.bool(forKey: Self.isEnabledValue)
            cell.selectionStyle = isEnabled ? .default : .none
            cell.textView.text = item.title
            cell.textView.textAlignment = .center
            cell.textView.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textView.textColor = isEnabled ? .textColorActive : .textColorSecondary
            return cell
        }
        
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.key == RowKey.allColorsRowKey.rawValue {
            if isSolidColorSelected {
                let items = appearanceCollection.getAvailableColorsSortingByLastUsed() ?? []
                let selectedItem: Any = selectedColorItem ?? NSNull()
                let colorCollectionVC = ItemsCollectionViewController(collectionType: .colorItems, items: items, selectedItem: selectedItem)
                colorCollectionVC.delegate = self
                if let colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                    colorCollectionVC.hostColorHandler = colorHandler
                }
                navigationController?.pushViewController(colorCollectionVC, animated: true)
            } else if isGradientColorSelected {
                if let paletteColorItem = selectedPaletteColorItem {
                    let paletteItems = sortedPaletteColorItems.asArray().compactMap { $0 as? PaletteItemGradient }
                    let colorCollectionVC = ItemsCollectionViewController(collectionType: .colorizationPaletteItems, items: paletteItems, selectedItem: paletteColorItem)
                    colorCollectionVC.delegate = self
                    navigationController?.pushViewController(colorCollectionVC, animated: true)
                }
            }
        } else if item.key == RowKey.applyExistingTracksRowKey.rawValue {
            guard hasAppearanceChanges(), !tracks.isEmpty else { return }
            saveFolderDefaultAppearance(updateExisting: true, dismissOnFinish: false)
        }
    }
    
    override func onLeftNavbarButtonPressed() {
        if hasAppearanceChanges() {
            let alertController = UIAlertController(title: localizedString("unsaved_changes"), message: localizedString("unsaved_changes_will_be_lost"), preferredStyle: .actionSheet)
            let discardAction = UIAlertAction(title: localizedString("shared_string_discard_changes"), style: .destructive) { [weak self] _ in
                guard let self else { return }
                self.dismiss(animated: true, completion: nil)
            }
            alertController.addAction(discardAction)
            if folder == nil {
                let applyAction = UIAlertAction(title: localizedString("shared_string_apply"), style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.onRightNavbarButtonPressed()
                }
                alertController.addAction(applyAction)
            }
            let cancelAction = UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel, handler: nil)
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
        if folder == nil {
            markSelectedAppearanceAsUsed()
            let task = ChangeTracksAppearanceTask(data: data, items: tracks) { [weak self] in
                self?.dismissAndRefreshMap()
            }
            task.execute()
        } else {
            showFolderDefaultAppearanceConfirmation()
        }
    }
    
    private static func buildAppearanceData(from item: GpxDirItem? = nil) -> AppearanceData {
        let data = AppearanceData()
        for parameter in GpxParameter.companion.getAppearanceParameters() {
            let value: Any? = item?.getParameter(parameter: parameter)
            data.setParameter(parameter, value: value)
        }
        
        return data
    }
    
    private func markSelectedAppearanceAsUsed() {
        if isSolidColorSelected, let selectedColorItem {
            appearanceCollection.selectColor(selectedColorItem)
        } else if isGradientColorSelected, let selectedPaletteColorItem {
            GradientPaletteHelper.shared.markPaletteItemAsUsed(selectedPaletteColorItem)
        }
    }
    
    private func showFolderDefaultAppearanceConfirmation() {
        guard hasAppearanceChanges() else {
            dismissAndRefreshMap()
            return
        }
        
        let alertController = UIAlertController(title: localizedString("shared_string_save"), message: localizedString("change_default_tracks_appearance_confirmation"), preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: applyExistingTracksTitle(), style: .default) { [weak self] _ in
            self?.saveFolderDefaultAppearance(updateExisting: true)
        })
        alertController.addAction(UIAlertAction(title: localizedString("apply_only_to_new"), style: .default) { [weak self] _ in
            self?.saveFolderDefaultAppearance(updateExisting: false)
        })
        alertController.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        let popPresenter = alertController.popoverPresentationController
        popPresenter?.barButtonItem = navigationItem.rightBarButtonItems?.first
        popPresenter?.permittedArrowDirections = UIPopoverArrowDirection.any
        present(alertController, animated: true, completion: nil)
    }
    
    private func saveFolderDefaultAppearance(updateExisting: Bool, dismissOnFinish: Bool = true) {
        guard let dirItem else { return }
        markSelectedAppearanceAsUsed()
        for parameter in GpxParameter.companion.getAppearanceParameters() {
            if data.shouldResetParameter(parameter) {
                dirItem.setParameter(parameter: parameter, value: nil)
            } else {
                dirItem.setParameter(parameter: parameter, value: folderDefaultValue(for: parameter))
            }
        }
        
        GpxDbHelper.shared.updateDataItem(item: dirItem)
        if updateExisting {
            let task = ChangeTracksAppearanceTask(data: data, items: tracks) { [weak self] in
                guard let self else { return }
                if dismissOnFinish {
                    self.dismissAndRefreshMap()
                } else {
                    self.onExistingTracksAppearanceApplied()
                }
            }
            task.execute()
        } else {
            if dismissOnFinish {
                dismissAndRefreshMap()
            } else {
                onExistingTracksAppearanceApplied()
            }
        }
    }
    
    private func onExistingTracksAppearanceApplied() {
        initialData = Self.buildAppearanceData(from: dirItem)
        data = AppearanceData(data: initialData)
        updateData()
        OsmAndApp.swiftInstance().updateGpxTracksOnMapObservable.notifyEvent()
        OAUtilities.showToast(localizedString("settings_applied"), details: nil, duration: 4, verticalOffset: 50, in: view)
    }
    
    private func applyExistingTracksTitle() -> String {
        String(format: localizedString("ltr_or_rtl_combine_via_space"), localizedString("apply_to_existing"), "(\(tracks.count))")
    }
    
    private func dismissAndRefreshMap() {
        dismiss(animated: true) {
            OsmAndApp.swiftInstance().updateGpxTracksOnMapObservable.notifyEvent()
        }
    }
    
    private func configureShowArrows() {
        if folder != nil {
            selectedShowArrows = booleanNumber(for: .showArrows)?.boolValue
            return
        }

        selectedShowArrows = preselectParameter(in: tracks) { $0.showArrows }
        initialData.setParameter(.showArrows, value: selectedShowArrows)
        data.setParameter(.showArrows, value: selectedShowArrows)
    }
    
    private func configureShowStartFinish() {
        if folder != nil {
            selectedShowStartFinish = booleanNumber(for: .showStartFinish)?.boolValue
            return
        }
        
        selectedShowStartFinish = preselectParameter(in: tracks) { $0.showStartFinish }
        initialData.setParameter(.showStartFinish, value: selectedShowStartFinish)
        data.setParameter(.showStartFinish, value: selectedShowStartFinish)
    }
    
    private func configureColorType() {
        let typeStr: String?
        if folder != nil {
            typeStr = data.getParameter(for: .coloringType)
        } else {
            typeStr = preselectParameter(in: tracks, extractor: { $0.coloringType })
        }
        guard let typeStr else { return }
        let normalizedTypeStr = normalizedColoringType(typeStr)
        selectedColorType = ColoringType.companion.valueOf(purpose: .track, name: normalizedTypeStr, defaultValue: .trackSolid)
        if folder == nil {
            initialData.setParameter(.coloringType, value: selectedColorType?.id)
            data.setParameter(.coloringType, value: selectedColorType?.id)
        }
        guard let type = selectedColorType else { return }
        switch type {
        case .trackSolid:
            if folder != nil {
                let color = intValue(for: .color)
                configureLineColors(color: color, updateAppearanceData: false)
                isColorSelected = true
                isSolidColorSelected = true
            } else if preselectParameter(in: tracks, extractor: { $0.color }) != nil {
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
            if folder != nil {
                let paletteName: String? = data.getParameter(for: .colorPalette)
                configureGradientColors(paletteName: paletteName, updateAppearanceData: false)
                isColorSelected = true
                isGradientColorSelected = true
            } else if preselectParameter(in: tracks, extractor: { $0.gradientPaletteName }) != nil {
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
    
    private func configureLineColors(color: Int? = nil, updateAppearanceData: Bool = true) {
        if let color {
            selectedColorItem = appearanceCollection.getColorItem(withValue: Int32(color))
        } else if folder == nil, let trackColor = tracks.first?.color {
            selectedColorItem = appearanceCollection.getColorItem(withValue: Int32(trackColor))
        } else {
            selectedColorItem = appearanceCollection.defaultLineColorItem()
        }

        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
        let selectedColor = Int(selectedColorItem?.colorInt ?? 0)
        if updateAppearanceData {
            initialData.setParameter(.color, value: KotlinInt(integerLiteral: selectedColor))
            data.setParameter(.color, value: KotlinInt(integerLiteral: selectedColor))
            initialData.setParameter(.colorPalette, value: PaletteConstants.shared.DEFAULT_NAME)
            data.setParameter(.colorPalette, value: PaletteConstants.shared.DEFAULT_NAME)
        }
    }
    
    private func configureGradientColors(paletteName: String? = nil, updateAppearanceData: Bool = true) {
        let gradientScaleType = selectedColorType?.toGradientScaleType()
        let paletteItems = GradientPaletteHelper.shared.paletteItems(gradientScaleType: gradientScaleType, sortMode: .lastUsedTime)
        sortedPaletteColorItems.replaceAll(withObjectsSync: paletteItems)
        let selectedPaletteName = paletteName ?? (folder == nil ? tracks.first?.gradientPaletteName : nil)
        selectedPaletteColorItem = GradientPaletteHelper.shared.paletteItemOrDefault(gradientScaleType: gradientScaleType, name: selectedPaletteName)
        if (updateAppearanceData || paletteName?.isEmpty == false), let selectedPaletteColorItem {
            initialData.setParameter(.colorPalette, value: selectedPaletteColorItem.id)
            data.setParameter(.colorPalette, value: selectedPaletteColorItem.id)
        }
    }
    
    private func configureWidth() {
        if folder != nil {
            let width: String? = data.getParameter(for: .width)
            selectedWidth = width.flatMap { appearanceCollection.getWidthForValue($0) }
        } else {
            selectedWidth = preselectParameter(in: tracks) { appearanceCollection.getWidthForValue($0.width) }
        }

        let minValue = OAGPXTrackWidth.getCustomTrackWidthMin()
        let maxValue = OAGPXTrackWidth.getCustomTrackWidthMax()
        customWidthValues = (minValue...maxValue).map { "\($0)" }
        guard let width = selectedWidth else { return }
        isWidthSelected = true
        isCustomWidthSelected = false
        let widthString = width.isCustom() ? width.customValue : width.key
        if folder == nil {
            initialData.setParameter(.width, value: widthString)
            data.setParameter(.width, value: widthString)
        }

        selectedWidthIndex = widthSegmentIndex(for: width)
        isCustomWidthSelected = width.isCustom()
    }
    
    private func configureSplitInterval() {
        let splitInterval: Double?
        if folder != nil {
            guard let splitTypeValue = intValue(for: .splitType), let splitType = EOAGpxSplitType(rawValue: splitTypeValue) else { return }
            selectedSplit = appearanceCollection.getSplitInterval(for: splitType)
            splitInterval = doubleValue(for: .splitInterval)
        } else {
            selectedSplit = preselectParameter(in: tracks) { appearanceCollection.getSplitInterval(for: $0.splitType) }
            splitInterval = tracks.first?.splitInterval
        }
        
        if folder == nil, let firstTrack = tracks.first {
            if firstTrack.splitInterval > 0 && firstTrack.splitType != EOAGpxSplitType.none {
                selectedSplit?.customValue = selectedSplit?.titles[(selectedSplit?.values.firstIndex { ($0).doubleValue == Double(firstTrack.splitInterval) }) ?? 0]
            }
        } else if let splitInterval, splitInterval > 0, selectedSplit?.type != EOAGpxSplitType.none {
            selectedSplit?.customValue = selectedSplit?.titles[(selectedSplit?.values.firstIndex { ($0).doubleValue == splitInterval }) ?? 0]
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
            if folder == nil {
                initialData.setParameter(.splitType, value: splitTypeValue)
                data.setParameter(.splitType, value: splitTypeValue)
            }
            if selectedSplit.isCustom(), let customValue = selectedSplit.customValue, let customIndex = selectedSplit.titles.firstIndex(of: customValue) {
                let intervalValue = selectedSplit.values[customIndex].doubleValue
                if folder == nil {
                    initialData.setParameter(.splitInterval, value: intervalValue)
                    data.setParameter(.splitInterval, value: intervalValue)
                }
            } else {
                if folder == nil {
                    initialData.setParameter(.splitInterval, value: 0)
                    data.setParameter(.splitInterval, value: 0)
                }
            }
        }
    }
    
    private func widthSegmentIndex(for width: OAGPXTrackWidth) -> Int {
        switch width.key {
        case WidthKeys.thin.rawValue:
            return 0
        case WidthKeys.medium.rawValue:
            return 1
        case WidthKeys.bold.rawValue:
            return 2
        default:
            return 3
        }
    }
    
    private func intValue(for parameter: GpxParameter) -> Int? {
        switch data.rawParameter(for: parameter) {
        case let value as Int: return value
        case let value as Int32: return Int(value)
        case let value as NSNumber: return value.intValue
        default: return nil
        }
    }
    
    private func doubleValue(for parameter: GpxParameter) -> Double? {
        switch data.rawParameter(for: parameter) {
        case let value as Double: return value
        case let value as NSNumber: return value.doubleValue
        default: return nil
        }
    }

    private func booleanNumber(for parameter: GpxParameter) -> NSNumber? {
        switch data.rawParameter(for: parameter) {
        case let value as Bool: return NSNumber(value: value)
        case let value as NSNumber: return value
        default: return nil
        }
    }

    private func folderDefaultValue(for parameter: GpxParameter) -> Any? {
        switch parameter {
        case .color, .splitType:
            return intValue(for: parameter).map { KotlinInt(integerLiteral: $0) }
        case .showArrows, .showStartFinish:
            return booleanNumber(for: parameter).map { KotlinBoolean(bool: $0.boolValue) }
        case .splitInterval:
            return doubleValue(for: parameter)
        default:
            return data.rawParameter(for: parameter)
        }
    }
    
    private func hasAppearanceChanges() -> Bool {
        guard folder != nil else { return data != initialData }
        for parameter in GpxParameter.companion.getAppearanceParameters() {
            switch (initialData.rawParameter(for: parameter), data.rawParameter(for: parameter)) {
            case (nil, nil):
                continue
            case let (lhs as NSObject, rhs as NSObject) where lhs.isEqual(rhs):
                continue
            default:
                return true
            }
        }

        return false
    }
    
    private func preselectParameter<T: Equatable>(in tracks: Set<TrackItem>, extractor: (TrackItem) -> T?) -> T? {
        guard let firstTrack = tracks.first, let firstValue = extractor(firstTrack) else { return nil }
        return tracks.allSatisfy { extractor($0) == firstValue } ? firstValue : nil
    }
    
    private func normalizedColoringType(_ type: String) -> String {
        ColoringType.routeStatisticsAttributesStrings.contains(type) ? type.replacingOccurrences(of: "routeInfo", with: "route_info") : type
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
        var sectionsToReload = IndexSet()
        for section in 0..<tableData.sectionCount() {
            let sectionData = tableData.sectionData(for: section)
            let hasUpdatedRow = (0..<sectionData.rowCount()).contains {
                let rowKey = sectionData.getRow($0).key
                return rowKey == key.rawValue || (folder != nil && rowKey == RowKey.applyExistingTracksRowKey.rawValue)
            }
            if hasUpdatedRow {
                sectionsToReload.insert(Int(section))
            }
        }
        
        guard !sectionsToReload.isEmpty else { return }
        tableView.reloadSections(sectionsToReload, with: .automatic)
    }
    
    private func handleWidthSelection(index: Int) {
        let width: OAGPXTrackWidth?
        switch index {
        case 0:
            width = appearanceCollection.getWidthForValue(WidthKeys.thin.rawValue)
        case 1:
            width = appearanceCollection.getWidthForValue(WidthKeys.medium.rawValue)
        case 2:
            width = appearanceCollection.getWidthForValue(WidthKeys.bold.rawValue)
        default:
            let customValue = selectedWidth?.isCustom() == true ? selectedWidth?.customValue : customWidthValues.first
            width = customValue.flatMap { appearanceCollection.getWidthForValue($0) }
        }
        
        guard let width else { return }
        selectedWidth = width
        let isCustom = width.isCustom()
        let widthString = isCustom ? width.customValue : width.key
        data.setParameter(.width, value: widthString)
        isWidthSelected = true
        isCustomWidthSelected = isCustom
        selectedWidthIndex = widthSegmentIndex(for: width)
        updateSection(containingRowKey: .widthRowKey)
    }
    
    private func handleSplitIntervalSelection(index: Int) {
        guard let availableSplits = appearanceCollection.getAvailableSplitIntervals(), index >= 0, index < availableSplits.count else { return }
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
    
    private func getColorHandler() -> OAColorCollectionHandler? {
        guard let colorsCollectionIndexPath,
              let colorCell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell,
              let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler else { return nil }
        
        return colorHandler
    }
    
    @objc private func onColorCellButtonPressed(_ sender: UIButton) {
        guard let tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        if item.key == RowKey.coloringGridRowKey.rawValue {
            guard let colorItem = selectedColorItem else { return }
            let colorPickerVC = UIColorPickerViewController()
            colorPickerVC.delegate = self
            colorPickerVC.selectedColor = UIColor(argb: Int(colorItem.colorInt))
            self.navigationController?.present(colorPickerVC, animated: true, completion: nil)
        }
    }
    
    @objc private func onPaletteCellButtonPressed(_ sender: UIButton) {
        GradientPaletteHelper.shared.showAddPaletteEditor(from: self, paletteCategory: selectedColorType?.toGradientScaleType()?.toPaletteCategory(), sourceView: sender)
    }

    @objc private func sliderChanged(sender: UISlider) {
        guard let tableData else { return }
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        guard let cell = tableView.cellForRow(at: indexPath) as? OASegmentSliderTableViewCell else { return }
        let selectedIndex = Int(cell.sliderView.selectedMark)
        let rowKey: RowKey
        if item.key == RowKey.customWidthModesRowKey.rawValue {
            guard let customWidthValues = item.obj(forKey: Self.widthArrayValue) as? [String], selectedIndex >= 0, selectedIndex < customWidthValues.count else { return }
            let selectedValue = customWidthValues[selectedIndex]
            if let w = selectedWidth, w.isCustom() {
                w.customValue = selectedValue
            }
            data.setParameter(.width, value: selectedValue)
            rowKey = .widthRowKey
        } else if item.key == RowKey.customSplitIntervalRowKey.rawValue {
            guard let splitTitles = item.obj(forKey: Self.widthArrayValue) as? [String], selectedIndex >= 0, selectedIndex < splitTitles.count else { return }
            let selectedValue = splitTitles[selectedIndex]
            if let split = selectedSplit, split.isCustom() {
                split.customValue = selectedValue
                if let customIndex = split.titles.firstIndex(of: selectedValue) {
                    data.setParameter(.splitInterval, value: split.values[customIndex].doubleValue)
                }
            }
            rowKey = .splitIntervalRowKey
        } else {
            return
        }
        
        updateSection(containingRowKey: rowKey)
    }
    
    @objc private func productPurchased(_: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.generateData()
            self.tableView.reloadData()
        }
    }
    
    @objc private func productsRestored(_: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.generateData()
            self.tableView.reloadData()
        }
    }
}

extension TracksChangeAppearanceViewController {
    private func createArrowsMenu() -> UIMenu {
        return createBooleanSelectionMenu(currentValue: selectedShowArrows, parameter: .showArrows, rowKey: .directionArrowsRowKey) { [weak self] newValue in
            self?.selectedShowArrows = newValue
        }
    }
    
    private func createStartFinishMenu() -> UIMenu {
        return createBooleanSelectionMenu(currentValue: selectedShowStartFinish, parameter: .showStartFinish, rowKey: .startFinishIconsRowKey) { [weak self] newValue in
            self?.selectedShowStartFinish = newValue
        }
    }
    
    private func createBooleanSelectionMenu(currentValue: Bool?, parameter: GpxParameter, rowKey: RowKey, update: @escaping (Bool?) -> Void) -> UIMenu {
        let isReset = data.shouldResetParameter(parameter)
        let isOriginal = isReset || (folder != nil && currentValue == nil)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && currentValue == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(parameter, value: nil)
            update(nil)
            self.updateSection(containingRowKey: rowKey)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isOriginal ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(parameter)
            update(nil)
            self.updateSection(containingRowKey: rowKey)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: folder == nil ? [unchangedAction, originalAction] : [originalAction])
        
        let onAction = UIAction(title: localizedString("shared_string_on"), state: !isReset && currentValue == true ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(parameter, value: true)
            update(true)
            self.updateSection(containingRowKey: rowKey)
        }
        let offAction = UIAction(title: localizedString("shared_string_off"), state: !isReset && currentValue == false ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(parameter, value: false)
            update(false)
            self.updateSection(containingRowKey: rowKey)
        }
        let onOffMenu = inlineMenu(withActions: [onAction, offAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, onOffMenu])
    }
    
    private func createColoringMenu() -> UIMenu {
        let isReset = data.shouldResetParameter(.coloringType)
        let isRouteInfoAttribute = selectedColorType?.isRouteInfoAttribute() ?? false
        let isOriginal = isReset || (folder != nil && selectedColorType == nil)
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: !isReset && selectedColorType == nil ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: nil)
            self.data.setParameter(.color, value: nil)
            self.data.setParameter(.colorPalette, value: nil)
            self.selectedColorType = nil
            self.isRouteAttributeTypeSelected = false
            self.resetColorSelectionFlags()
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isOriginal ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.coloringType)
            self.data.resetParameter(.color)
            self.data.resetParameter(.colorPalette)
            self.selectedColorType = nil
            self.isRouteAttributeTypeSelected = false
            self.resetColorSelectionFlags()
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: folder == nil ? [unchangedAction, originalAction] : [originalAction])
        
        let solidColorAction = UIAction(title: localizedString("track_coloring_solid"), state: !isReset && selectedColorType == .trackSolid ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.trackSolid.id)
            self.selectedColorType = .trackSolid
            self.configureLineColors(updateAppearanceData: self.folder == nil)
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: true)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let solidColorMenu = inlineMenu(withActions: [solidColorAction])
        
        let altitudeAction = UIAction(title: localizedString("altitude"), state: !isReset && selectedColorType == .altitude ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.altitude.id)
            self.selectedColorType = .altitude
            self.configureGradientColors(updateAppearanceData: self.folder == nil)
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: false)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let speedAction = UIAction(title: localizedString("shared_string_speed"), state: !isReset && selectedColorType == .speed ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.speed.id)
            self.selectedColorType = .speed
            self.configureGradientColors(updateAppearanceData: self.folder == nil)
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: false)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let slopeAction = UIAction(title: localizedString("shared_string_slope"), state: !isReset && selectedColorType == .slope ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.coloringType, value: ColoringType.slope.id)
            self.selectedColorType = .slope
            self.configureGradientColors(updateAppearanceData: self.folder == nil)
            self.resetColorSelectionFlags()
            self.isColorSelectionEnabled(true, solid: false)
            self.updateSection(containingRowKey: .coloringRowKey)
        }
        let gradientColorMenu = inlineMenu(withActions: [altitudeAction, speedAction, slopeAction])
        
        let proColorActions = ColoringType.routeStatisticsAttributesStrings.map { attribute in
            return createProColorAction(titleKey: attribute + "_name", parameterValue: attribute, selectedString: attribute, isRouteInfoAttribute: isRouteInfoAttribute)
        }
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
        let isOriginal = isReset || (folder != nil && paramValue == nil)
        let fixedWidths: [(titleKey: String, widthKey: String, index: Int)] = [("rendering_value_thin_name", "thin", 0), ("rendering_value_medium_w_name", "medium", 1), ("rendering_value_bold_name", "bold", 2)]
        let unchangedAction = UIAction(title: localizedString("shared_string_unchanged"), state: (!isReset && paramValue == nil) ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.setParameter(.width, value: nil)
            self.selectedWidth = nil
            self.isWidthSelected = false
            self.isCustomWidthSelected = false
            self.updateSection(containingRowKey: .widthRowKey)
        }
        let originalAction = UIAction(title: localizedString("simulate_location_movement_speed_original"), state: isOriginal ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.data.resetParameter(.width)
            self.selectedWidth = nil
            self.isWidthSelected = false
            self.isCustomWidthSelected = false
            self.updateSection(containingRowKey: .widthRowKey)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: folder == nil ? [unchangedAction, originalAction] : [originalAction])
        
        let fixedWidthActions = fixedWidths.map { item in
            return UIAction(title: localizedString(item.titleKey), state: (!isReset && paramValue == item.widthKey) ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.handleWidthSelection(index: item.index)
            }
        }
        let widthMenu = inlineMenu(withActions: fixedWidthActions)
        
        let isCustomSelected = !isReset && paramValue != nil && selectedWidth?.isCustom() == true && paramValue == selectedWidth?.customValue
        let customAction = UIAction(title: localizedString("shared_string_custom"), state: isCustomSelected ? .on : .off) { [weak self] _ in
            guard let self else { return }
            self.handleWidthSelection(index: 3)
        }
        let customWidthMenu = inlineMenu(withActions: [customAction])
        
        return UIMenu(title: "", options: .singleSelection, children: [unchangedOriginalMenu, widthMenu, customWidthMenu])
    }
    
    private func createSplitIntervalMenu() -> UIMenu {
        let paramSplitType: Int32? = selectedSplit.map { Int32($0.type.rawValue) } ?? (folder == nil ? data.getParameter(for: .splitType) : nil)
        let isResetSplitType = data.shouldResetParameter(.splitType)
        let isResetSplitInterval = data.shouldResetParameter(.splitInterval)
        let isUnchanged = paramSplitType == nil && !isResetSplitType && !isResetSplitInterval
        let isOriginalSelected = (isResetSplitType && isResetSplitInterval) || (folder != nil && paramSplitType == nil)
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
            self.selectedSplit = nil
            self.isSplitIntervalSelected = false
            self.isSplitIntervalNoneSelected = false
            self.updateSection(containingRowKey: .splitIntervalRowKey)
        }
        let unchangedOriginalMenu = inlineMenu(withActions: folder == nil ? [unchangedAction, originalAction] : [originalAction])
        
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
            guard sortedColorItems.indices.contains(indexPath.row) else { return }
            let picked = selectedItem as? PaletteItemSolid ?? sortedColorItems[indexPath.row]
            if selectedItem is PaletteItemSolid {
                sortedColorItems[indexPath.row] = picked
            }
            selectedColorItem = picked
            data.setParameter(.colorPalette, value: PaletteConstants.shared.DEFAULT_NAME)
            data.setParameter(.color, value: KotlinInt(integerLiteral: Int(picked.colorInt)))
        } else if isGradientColorSelected {
            let paletteItems = sortedPaletteColorItems.asArray().compactMap { $0 as? PaletteItemGradient }
            guard paletteItems.indices.contains(indexPath.row) else { return }
            let picked = selectedItem as? PaletteItemGradient ?? paletteItems[indexPath.row]
            selectedPaletteColorItem = picked
            data.setParameter(.colorPalette, value: picked.id)
        }
        if collectionView != nil {
            updateSection(containingRowKey: .coloringRowKey)
        }
    }
    
    func reloadCollectionData() {
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
        var selectedItem: PaletteItemSolid?
        if let colorHandler = getColorHandler(), let selectedColor = colorHandler.getSelectedItem() {
            selectedItem = selectedColor
        }
        if selectedItem == nil {
            if folder != nil, let color = intValue(for: .color) {
                selectedItem = appearanceCollection.getColorItem(withValue: Int32(color))
            } else if folder != nil {
                selectedItem = appearanceCollection.defaultLineColorItem()
            } else if let trackColor = tracks.first?.color {
                selectedItem = appearanceCollection.getColorItem(withValue: Int32(trackColor))
            } else {
                selectedItem = appearanceCollection.defaultLineColorItem()
            }
        }
        selectedColorItem = selectedItem
    }
}

extension TracksChangeAppearanceViewController: ColorCollectionViewControllerDelegate {
    func selectColorItem(_ colorItem: PaletteItemSolid) {
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
        let row = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        if row != NSNotFound {
            onCollectionItemSelected(IndexPath(row: row, section: 0), selectedItem: colorItem, collectionView: nil, shouldDismiss: true)
            updateSection(containingRowKey: .coloringRowKey)
        }
    }
    
    func selectPaletteItem(_ paletteItem: PaletteItemGradient) {
        let paletteItems = GradientPaletteHelper.shared.paletteItems(gradientScaleType: selectedColorType?.toGradientScaleType(), sortMode: .lastUsedTime)
        sortedPaletteColorItems.replaceAll(withObjectsSync: paletteItems)
        let index = GradientPaletteHelper.shared.index(of: paletteItem, in: paletteItems)
        if index != NSNotFound {
            onCollectionItemSelected(IndexPath(row: index, section: 0), selectedItem: paletteItem, collectionView: nil, shouldDismiss: true)
            updateSection(containingRowKey: .coloringRowKey)
        }
    }
    
    @discardableResult func addAndGetNewColorItem(_ color: UIColor) -> PaletteItemSolid {
        guard let newColorItem = appearanceCollection.addNewSelectedColor(color) else { return appearanceCollection.defaultLineColorItem() }
        if let colorsIndexPath = colorsCollectionIndexPath, let colorCell = tableView.cellForRow(at: colorsIndexPath) as? OACollectionSingleLineTableViewCell, let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
            sortedColorItems.insert(newColorItem, at: 0)
            colorHandler.addAndSelectColor(IndexPath(row: 0, section: 0), newItem: newColorItem)
        }
        
        return newColorItem
    }
    
    func changeColorItem(_ colorItem: PaletteItemSolid, withColor color: UIColor) {
        let row = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        guard row != NSNotFound, let newColorItem = appearanceCollection.changeColor(colorItem, newColor: color) else { return }
        sortedColorItems[row] = newColorItem
    }
    
    func duplicateColorItem(_ colorItem: PaletteItemSolid) -> PaletteItemSolid {
        guard let duplicatedColorItem = appearanceCollection.duplicateColor(colorItem) else { return colorItem }
        let row = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        if let colorsIndexPath = colorsCollectionIndexPath, row != NSNotFound {
            sortedColorItems.insert(duplicatedColorItem, at: row + 1)
            if let colorCell = tableView.cellForRow(at: colorsIndexPath) as? OACollectionSingleLineTableViewCell,
               let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
                let newIndexPath = IndexPath(row: row + 1, section: 0)
                colorHandler.addColor(newIndexPath, newItem: duplicatedColorItem)
            }
        }
        
        return duplicatedColorItem
    }
    
    func deleteColorItem(_ colorItem: PaletteItemSolid) {
        let row = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        guard let colorsIndexPath = colorsCollectionIndexPath, row != NSNotFound else { return }
        let indexPathForColor = IndexPath(row: row, section: 0)
        let isSelectedColorDeleted = appearanceCollection.isSameColorItem(selectedColorItem, secondItem: colorItem)
        appearanceCollection.deleteColor(colorItem)
        sortedColorItems.remove(at: row)
        if isSelectedColorDeleted {
            selectedColorItem = nil
        }

        if let colorCell = tableView.cellForRow(at: colorsIndexPath) as? OACollectionSingleLineTableViewCell,
           let colorHandler = colorCell.getCollectionHandler() as? OAColorCollectionHandler {
            if isSelectedColorDeleted {
                colorHandler.setSelectedIndexPath(nil)
            }

            colorHandler.removeColor(indexPathForColor)
        }
    }
    
    func reloadData() {
        let gradientScaleType = selectedColorType?.toGradientScaleType()
        let paletteItems = GradientPaletteHelper.shared.paletteItems(gradientScaleType: gradientScaleType, sortMode: .lastUsedTime)
        sortedPaletteColorItems.replaceAll(withObjectsSync: paletteItems)
        if GradientPaletteHelper.shared.index(of: selectedPaletteColorItem, in: paletteItems) == NSNotFound {
            selectedPaletteColorItem = GradientPaletteHelper.shared.defaultPaletteItem(gradientScaleType: gradientScaleType) ?? paletteItems.first
            if let selectedPaletteColorItem {
                data.setParameter(.colorPalette, value: selectedPaletteColorItem.id)
            }
        }
        updateData()
    }
}

extension TracksChangeAppearanceViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        addAndGetNewColorItem(viewController.selectedColor)
    }
}
