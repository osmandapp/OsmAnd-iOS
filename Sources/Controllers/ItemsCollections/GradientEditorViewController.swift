//
//  GradientEditorViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 06.05.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

private enum GradientEditorSection: Int {
    case preview
    case value
    case color
    case actions
}

private enum GradientEditorRow: String {
    case legend
    case steps
    case value
    case noDataDescription
    case colorTitle
    case colors
    case allColors
    case removeStep
}

@objcMembers
final class GradientEditorViewController: OABaseNavbarViewController {
    private static let undoStackLimit = 50
    
    private let originalId: String?
    private let fileType: GradientFileType
    private let appearanceCollection: OAGPXAppearanceCollection = OAGPXAppearanceCollection.sharedInstance()
    private let onSave: (GradientDraft, String?) -> Bool
    private let initialDraft: GradientDraft
    private let editorBehaviour: GradientEditorBehaviour
    
    private var dataState: EditorDataState
    private var sortedColorItems = [PaletteItemSolid]()
    private var selectedColorItem: PaletteItemSolid?
    private var colorsCollectionIndexPath: IndexPath?
    private var previousStates = [EditorDataState]()
    private var selectedPoint: OsmAndShared.GradientPoint? {
        guard dataState.draft.points.indices.contains(dataState.selectedIndex) else { return nil }
        return dataState.draft.points[dataState.selectedIndex]
    }
    private var isNoDataSelected: Bool {
        dataState.selectedIndex == dataState.draft.points.count
    }
    
    private lazy var valueInputToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(onValueInputDonePressed))]
        return toolbar
    }()
    
    init(originalId: String? = nil, fileType: GradientFileType, onSave: @escaping (GradientDraft, String?) -> Bool) {
        self.originalId = originalId
        self.fileType = fileType
        self.onSave = onSave
        let paletteItem = originalId.flatMap { GradientPaletteHelper.shared.paletteItem(category: fileType.category, name: $0) }
        let initialDraft = GradientDraft(originalId: originalId, fileType: fileType, points: paletteItem?.points ?? fileType.getDefaultGradientPoints(), noDataColor: paletteItem?.noDataColor?.int32Value)
        self.initialDraft = initialDraft
        self.dataState = EditorDataState(draft: initialDraft, selectedIndex: 0)
        if fileType.rangeType == .relative {
            self.editorBehaviour = fileType == .slopeRelative ? SymmetricRelativeGradientBehaviour() : RelativeGradientBehaviour()
        } else {
            self.editorBehaviour = FixedGradientBehaviour()
        }
        
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getTitle() -> String {
        localizedString(originalId == nil ? "add_palette" : "edit_palette")
    }
    
    override func getSubtitle() -> String {
        let title = localizedString(fileType.category.nameResId)
        let units = displayUnitsSymbol()
        return units.isEmpty ? title : String(format: localizedString("ltr_or_rtl_combine_with_brackets"), title, units)
    }
    
    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(onClosePressed))
    }
    
    override func systemRightBarButtonItems() -> [UIBarButtonItem]? {
        [UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(onDonePressed)),
         UIBarButtonItem(barButtonSystemItem: .undo, target: self, action: #selector(onUndoPressed))]
    }
    
    override func tableStyle() -> UITableView.Style {
        .insetGrouped
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateSelectedColorItem()
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func registerCells() {
        addCell(GradientChartCell.reuseIdentifier)
        addCell(OAFoldersCell.reuseIdentifier)
        addCell(OAInputTableViewCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OACollectionSingleLineTableViewCell.reuseIdentifier)
        addCell(OASearchMoreCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        colorsCollectionIndexPath = nil
        
        let previewSection = tableData.createNewSection()
        let legendRow = previewSection.createNewRow()
        legendRow.cellType = GradientChartCell.reuseIdentifier
        legendRow.key = GradientEditorRow.legend.rawValue
        let stepsRow = previewSection.createNewRow()
        stepsRow.cellType = OAFoldersCell.reuseIdentifier
        stepsRow.key = GradientEditorRow.steps.rawValue
        
        let valueSection = tableData.createNewSection()
        let units = selectedPoint.flatMap { editorBehaviour.isValueEditable($0) ? displayUnitsSymbol() : nil } ?? ""
        valueSection.headerText = units.isEmpty ? localizedString("shared_string_value") : String(format: localizedString("ltr_or_rtl_combine_via_comma"), localizedString("shared_string_value"), units)
        let valueRow = valueSection.createNewRow()
        if isNoDataSelected {
            valueRow.cellType = OASimpleTableViewCell.reuseIdentifier
            valueRow.key = GradientEditorRow.noDataDescription.rawValue
            valueRow.descr = localizedString("gradient_no_data_point_summary")
        } else {
            valueRow.cellType = OAInputTableViewCell.reuseIdentifier
            valueRow.key = GradientEditorRow.value.rawValue
            valueSection.footerText = selectedPoint.flatMap { editorBehaviour.summary(for: $0) } ?? ""
        }
        
        let colorSection = tableData.createNewSection()
        let colorTitleRow = colorSection.createNewRow()
        colorTitleRow.cellType = OASimpleTableViewCell.reuseIdentifier
        colorTitleRow.key = GradientEditorRow.colorTitle.rawValue
        colorTitleRow.title = localizedString("shared_string_color")
        let colorsRow = colorSection.createNewRow()
        colorsRow.cellType = OACollectionSingleLineTableViewCell.reuseIdentifier
        colorsRow.key = GradientEditorRow.colors.rawValue
        colorsCollectionIndexPath = IndexPath(row: 1, section: GradientEditorSection.color.rawValue)
        let allColorsRow = colorSection.createNewRow()
        allColorsRow.cellType = OASimpleTableViewCell.reuseIdentifier
        allColorsRow.key = GradientEditorRow.allColors.rawValue
        allColorsRow.title = localizedString("shared_string_all_colors")
        
        let actionsSection = tableData.createNewSection()
        let removeStepRow = actionsSection.createNewRow()
        removeStepRow.cellType = OASearchMoreCell.reuseIdentifier
        removeStepRow.key = GradientEditorRow.removeStep.rawValue
        removeStepRow.title = localizedString("remove_step")
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        indexPath.section == GradientEditorSection.preview.rawValue && indexPath.row == 1 ? 60 : UITableView.automaticDimension
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        if item.cellType == GradientChartCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: GradientChartCell.reuseIdentifier, for: indexPath) as! GradientChartCell
            cell.selectionStyle = .none
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
            cell.heightConstraint.constant = 80
            cell.chartView.extraTopOffset = 20
            cell.chartView.extraBottomOffset = 24
            GpxUIHelper.setupGradientChart(chart: cell.chartView, useGesturesAndScale: false, xAxisGridColor: .chartAxisGridLine, labelsColor: .textColorSecondary)
            cell.chartView.data = GpxUIHelper.buildGradientChart(chart: cell.chartView, colorPalette: previewColorPalette(), valueFormatter: GradientFormatter.getAxisFormatter(fileType: fileType, analysis: nil))
            cell.chartView.highlightXAxis(value: selectedPoint.map { Double($0.value) }, backgroundColor: .iconColorActive, textColor: .white)
            cell.chartView.notifyDataSetChanged()
            cell.chartView.setNeedsDisplay()
            return cell
        } else if item.cellType == OAFoldersCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAFoldersCell.reuseIdentifier, for: indexPath) as! OAFoldersCell
            cell.selectionStyle = .none
            cell.backgroundColor = .groupBg
            cell.collectionView.backgroundColor = .groupBg
            cell.collectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 77)
            cell.collectionView.foldersDelegate = self
            cell.collectionView.setValues(stepValues(), withSelectedIndex: dataState.selectedIndex)
            cell.collectionView.reloadData()
            cell.rightActionButtonVisibility(true)
            cell.rightActionButton.accessibilityLabel = localizedString("shared_string_add")
            cell.rightActionButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.rightActionButton.addTarget(self, action: #selector(onAddStepPressed), for: .touchUpInside)
            return cell
        } else if item.cellType == OAInputTableViewCell.reuseIdentifier, let point = selectedPoint {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAInputTableViewCell.reuseIdentifier, for: indexPath) as! OAInputTableViewCell
            let isEditable = editorBehaviour.isValueEditable(point)
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.titleVisibility(false)
            cell.descriptionVisibility(false)
            cell.clearButtonVisibility(false)
            cell.inputFieldVisibility(true)
            cell.inputField.textAlignment = .left
            cell.inputField.keyboardType = .numbersAndPunctuation
            cell.inputField.isEnabled = isEditable
            cell.inputField.inputAccessoryView = isEditable ? valueInputToolbar : nil
            cell.inputField.text = isEditable ? GradientFormatter.formatValue(value: point.value, fileType: fileType, showUnits: false) : editorBehaviour.stepLabel(for: point, fileType: fileType, useFullName: true)
            cell.inputField.removeTarget(nil, action: nil, for: .editingChanged)
            if isEditable {
                cell.inputField.addTarget(self, action: #selector(onValueChanged(_:)), for: .editingChanged)
            }
            return cell
        } else if item.cellType == OACollectionSingleLineTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OACollectionSingleLineTableViewCell.reuseIdentifier, for: indexPath) as! OACollectionSingleLineTableViewCell
            cell.selectionStyle = .none
            cell.rightActionButtonVisibility(true)
            cell.rightActionDividerVisibility(true)
            cell.rightActionButton.setImage(UIImage.templateImageNamed("ic_custom_add"), for: .normal)
            cell.rightActionButton.accessibilityLabel = localizedString("shared_string_add_color")
            cell.rightActionButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.rightActionButton.addTarget(self, action: #selector(onColorCellButtonPressed(_:)), for: .touchUpInside)
            cell.disableAnimationsOnStart = true
            let colorHandler = OAColorCollectionHandler(data: [sortedColorItems], collectionView: cell.collectionView)
            colorHandler?.delegate = self
            colorHandler?.hostVC = self
            let selectedIndex = appearanceCollection.index(ofColorItem: selectedColorItem, items: sortedColorItems)
            if selectedIndex != NSNotFound {
                colorHandler?.setSelectedIndexPath(IndexPath(row: selectedIndex, section: 0))
            }
            cell.setCollectionHandler(colorHandler)
            return cell
        } else if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.leftIconVisibility(false)
            let isColorTitle = item.key == GradientEditorRow.colorTitle.rawValue
            cell.setCustomLeftSeparatorInset(isColorTitle)
            if isColorTitle {
                cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0)
            } else {
                cell.updateSeparatorInset()
            }
            if item.key == GradientEditorRow.noDataDescription.rawValue {
                cell.selectionStyle = .none
                cell.titleVisibility(false)
                cell.descriptionVisibility(true)
                cell.textStackView.isHidden = false
                cell.descriptionLabel.text = item.descr
                cell.descriptionLabel.textColor = .textColorPrimary
            } else {
                cell.descriptionVisibility(false)
                cell.titleVisibility(true)
                cell.textStackView.isHidden = false
                cell.titleLabel.text = item.title
                cell.titleLabel.textAlignment = .natural
                if item.key == GradientEditorRow.allColors.rawValue {
                    cell.selectionStyle = .default
                    cell.titleLabel.textColor = .textColorActive
                } else {
                    cell.selectionStyle = .none
                    cell.titleLabel.textColor = .textColorPrimary
                }
            }
            return cell
        } else if item.cellType == OASearchMoreCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASearchMoreCell.reuseIdentifier, for: indexPath) as! OASearchMoreCell
            cell.selectionStyle = editorBehaviour.isRemoveEnabled(dataState.draft, selectedIndex: dataState.selectedIndex) ? .default : .none
            cell.contentView.backgroundColor = .clear
            cell.textView.backgroundColor = .clear
            cell.textView.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textView.textColor = .textColorDisruptive
            cell.textView.text = item.title
            return cell
        }
        
        return UITableViewCell()
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if item.key == GradientEditorRow.allColors.rawValue {
            let selectedItem: Any = selectedColorItem ?? NSNull()
            let colorCollectionVC = ItemsCollectionViewController(collectionType: .colorItems, items: sortedColorItems, selectedItem: selectedItem)
            colorCollectionVC.delegate = self
            if let colorsCollectionIndexPath, let cell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let handler = cell.getCollectionHandler() as? OAColorCollectionHandler {
                colorCollectionVC.hostColorHandler = handler
            }
            showMediumToLargeSheetViewController(colorCollectionVC)
        } else if item.key == GradientEditorRow.removeStep.rawValue,
                  let state = GradientEditorAlgorithms.removeStep(dataState, behaviour: editorBehaviour) {
            updateSelectedColorItem(for: state)
            applyState(state)
        }
    }
    
    private func previewColorPalette() -> OsmAndShared.ColorPalette {
        PaletteMappersKt.toColorPalette(dataState.draft.points)
    }
    
    private func selectedColorValue(in state: EditorDataState? = nil) -> Int32? {
        let state = state ?? dataState
        if state.selectedIndex == state.draft.points.count {
            return state.draft.noDataColor ?? OsmAndShared.ColorPalette.companion.LIGHT_GREY
        }
        
        guard state.draft.points.indices.contains(state.selectedIndex) else { return nil }
        return state.draft.points[state.selectedIndex].color
    }
    
    private func updateSelectedColorItem(for state: EditorDataState? = nil) {
        guard let color = selectedColorValue(in: state) else { return }
        selectedColorItem = appearanceCollection.getColorItem(withValue: color)
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
    }
    
    private func displayUnitsSymbol() -> String {
        let context = PlatformUtil.shared.getOsmAndContext()
        return fileType.displayUnitsType.getUnit(mc: context.getMetricSystem(), am: context.getAltitudeMetric(), sc: context.getSpeedSystem(), ac: context.getAngularSystem(), tu: context.getTemperatureUnits()).getSymbol()
    }
    
    private func stepValues() -> [[String: String]] {
        var values = dataState.draft.points.map {
            ["title": editorBehaviour.stepLabel(for: $0, fileType: fileType)]
        }
        
        if fileType.supportsNoData {
            values.append(["title": localizedString("gpx_logging_no_data")])
        }
        
        return values
    }
    
    private func applyState(_ newState: EditorDataState, addToHistory: Bool = true, reloadStepsRow: Bool = true, reloadValueSection: Bool = true, reloadColorSection: Bool = true, reloadActionsSection: Bool = true) {
        if addToHistory && newState.draft != dataState.draft {
            previousStates.append(EditorDataState(draft: dataState.draft, selectedIndex: dataState.selectedIndex))
            if previousStates.count > Self.undoStackLimit {
                previousStates.removeFirst()
            }
        }
        
        dataState = newState
        generateData()
        var previewRows = [IndexPath(row: 0, section: GradientEditorSection.preview.rawValue)]
        if reloadStepsRow {
            previewRows.append(IndexPath(row: 1, section: GradientEditorSection.preview.rawValue))
        }
        tableView.reloadRows(at: previewRows, with: .none)
        if reloadValueSection {
            tableView.reloadSections(IndexSet(integer: GradientEditorSection.value.rawValue), with: .none)
        }
        if reloadColorSection {
            tableView.reloadSections(IndexSet(integer: GradientEditorSection.color.rawValue), with: .none)
        }
        if reloadActionsSection {
            tableView.reloadSections(IndexSet(integer: GradientEditorSection.actions.rawValue), with: .none)
        }
    }
    
    @objc private func onClosePressed() {
        guard dataState.draft != initialDraft else {
            dismiss(animated: true)
            return
        }
        
        let alert = UIAlertController(title: localizedString("exit_without_saving"), message: localizedString("dismiss_changes_descr"), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_exit"), style: .destructive) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
        alert.popoverPresentationController?.permittedArrowDirections = .any
        present(alert, animated: true)
    }
    
    @objc private func onUndoPressed() {
        guard let state = previousStates.popLast() else { return }
        updateSelectedColorItem(for: state)
        applyState(state, addToHistory: false)
    }
    
    @objc private func onAddStepPressed() {
        guard let state = GradientEditorAlgorithms.addStep(dataState) else { return }
        applyState(state, reloadStepsRow: false)
        if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: GradientEditorSection.preview.rawValue)) as? OAFoldersCell {
            let selectedIndexPath = IndexPath(row: state.selectedIndex, section: 0)
            cell.collectionView.setValues(stepValues(), withSelectedIndex: state.selectedIndex)
            cell.collectionView.reloadData()
            cell.collectionView.layoutIfNeeded()
            cell.collectionView.scrollToItem(at: selectedIndexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    @objc private func onColorCellButtonPressed(_: UIButton) {
        let colorPickerVC = UIColorPickerViewController()
        colorPickerVC.delegate = self
        if let color = selectedColorValue() {
            colorPickerVC.selectedColor = UIColor(argb: Int(color))
        }
        
        navigationController?.present(colorPickerVC, animated: true)
    }
    
    @objc private func onValueChanged(_ textField: UITextField) {
        switch GradientEditorAlgorithms.updateValue(dataState, text: textField.text ?? "", behaviour: editorBehaviour) {
        case .success(let newState):
            if newState != dataState {
                applyState(newState, reloadValueSection: false, reloadColorSection: false, reloadActionsSection: false)
            }
        case .error(let message):
            dataState = EditorDataState(draft: dataState.draft, selectedIndex: dataState.selectedIndex, validationError: message)
        }
    }
    
    @objc private func onValueInputDonePressed() {
        view.endEditing(true)
    }
    
    @objc private func onDonePressed() {
        guard originalId == nil else {
            guard onSave(dataState.draft, nil) else { return }
            dismiss(animated: true)
            return
        }
        
        let alert = UIAlertController(title: localizedString("access_hint_enter_name"), message: nil, preferredStyle: .alert)
        let suggestedName = GradientPaletteHelper.shared.suggestedPaletteName(for: dataState.draft)
        alert.addTextField { $0.text = suggestedName }
        alert.addAction(UIAlertAction(title: localizedString("shared_string_save"), style: .default) { [weak self, weak alert] _ in
            guard let self, let name = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else { return }
            guard !name.isEmpty else {
                OAUtilities.showToast(localizedString("empty_name"), details: nil, duration: 4, in: self.view)
                return
            }
            if self.onSave(self.dataState.draft, name) {
                self.dismiss(animated: true)
            } else {
                OAUtilities.showToast(localizedString("gpx_already_exsists"), details: nil, duration: 4, in: self.view)
            }
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
}

extension GradientEditorViewController: OAFoldersCellDelegate {
    func onItemSelected(_ index: Int) {
        guard index != dataState.selectedIndex, index <= dataState.draft.points.count else { return }
        let state = EditorDataState(draft: dataState.draft, selectedIndex: index)
        updateSelectedColorItem(for: state)
        applyState(state, addToHistory: false, reloadStepsRow: false)
        if let cell = tableView.cellForRow(at: IndexPath(row: 1, section: GradientEditorSection.preview.rawValue)) as? OAFoldersCell {
            cell.collectionView.reloadData()
        }
    }
}

extension GradientEditorViewController: OACollectionCellDelegate {
    func onCollectionItemSelected(_ indexPath: IndexPath, selectedItem: Any?, collectionView: UICollectionView?, shouldDismiss: Bool) {
        guard sortedColorItems.indices.contains(indexPath.row) else { return }
        let picked = selectedItem as? PaletteItemSolid ?? sortedColorItems[indexPath.row]
        if selectedItem is PaletteItemSolid {
            sortedColorItems[indexPath.row] = picked
        }
        
        selectedColorItem = picked
        if let state = GradientEditorAlgorithms.updateColor(dataState, newColor: picked.colorInt) {
            applyState(state, reloadStepsRow: false, reloadValueSection: false, reloadColorSection: false, reloadActionsSection: false)
        }
    }
    
    func reloadCollectionData() {
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
        if let colorsCollectionIndexPath {
            tableView.reloadRows(at: [colorsCollectionIndexPath], with: .none)
        }
    }
}

extension GradientEditorViewController: ColorCollectionViewControllerDelegate {
    func selectColorItem(_ colorItem: PaletteItemSolid) {
        sortedColorItems = Array(appearanceCollection.getAvailableColorsSortingByLastUsed() ?? [])
        let row = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        guard row != NSNotFound else { return }
        onCollectionItemSelected(IndexPath(row: row, section: 0), selectedItem: colorItem, collectionView: nil, shouldDismiss: true)
    }
    
    @discardableResult func addAndGetNewColorItem(_ color: UIColor) -> PaletteItemSolid {
        guard let newColorItem = appearanceCollection.addNewSelectedColor(color) else { return appearanceCollection.defaultLineColorItem() }
        if let colorsCollectionIndexPath, let cell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let handler = cell.getCollectionHandler() as? OAColorCollectionHandler {
            sortedColorItems.insert(newColorItem, at: 0)
            handler.addAndSelectColor(IndexPath(row: 0, section: 0), newItem: newColorItem)
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
        guard let colorsCollectionIndexPath, row != NSNotFound else { return duplicatedColorItem }
        sortedColorItems.insert(duplicatedColorItem, at: row + 1)
        if let cell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let handler = cell.getCollectionHandler() as? OAColorCollectionHandler {
            handler.addColor(IndexPath(row: row + 1, section: 0), newItem: duplicatedColorItem)
        }
        
        return duplicatedColorItem
    }
    
    func deleteColorItem(_ colorItem: PaletteItemSolid) {
        let row = appearanceCollection.index(ofColorItem: colorItem, items: sortedColorItems)
        guard let colorsCollectionIndexPath, row != NSNotFound else { return }
        let isSelectedColorDeleted = appearanceCollection.isSameColorItem(selectedColorItem, secondItem: colorItem)
        appearanceCollection.deleteColor(colorItem)
        sortedColorItems.remove(at: row)
        if isSelectedColorDeleted {
            selectedColorItem = nil
        }
        
        if let cell = tableView.cellForRow(at: colorsCollectionIndexPath) as? OACollectionSingleLineTableViewCell, let handler = cell.getCollectionHandler() as? OAColorCollectionHandler {
            if isSelectedColorDeleted {
                handler.setSelectedIndexPath(nil)
            }
            
            handler.removeColor(IndexPath(row: row, section: 0))
        }
    }
}

extension GradientEditorViewController: UIColorPickerViewControllerDelegate {
    func colorPickerViewControllerDidFinish(_ viewController: UIColorPickerViewController) {
        addAndGetNewColorItem(viewController.selectedColor)
    }
}
