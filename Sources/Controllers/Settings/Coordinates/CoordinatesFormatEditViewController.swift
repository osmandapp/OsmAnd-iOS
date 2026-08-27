//
//  CoordinatesFormatEditViewController.swift
//  OsmAnd Maps
//
//  Created by Vitaliy Sova on 11.08.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//

import UIKit

@objcMembers
final class CoordinatesFormatEditViewController: OABaseSettingsViewController {

    private static let formatIdKey = "formatId"
    private static let formatsSection = 0
    private static let addRowKey = "add"

    private var editableIds: [String] = []
    private var applyButton: UIBarButtonItem?

    private var formatStorage: CoordinateFormatSettingsStorage {
        OAAppSettings.sharedManager().coordinateFormatSettingsStorage
    }

    private var isEditChanged: Bool {
        editableIds != formatStorage.preferredIds(appMode)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.sectionHeaderTopPadding = 0
        tableView.setEditing(true, animated: false)
        tableView.allowsSelectionDuringEditing = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        relayoutTableHeaderViewIfNeeded()
    }
    
    override func postInit() {
        super.postInit()
        editableIds = formatStorage.preferredIds(appMode)
    }

    // MARK: - NavBar
    
    override func getTitle() -> String? {
        localizedString("coordinates_format")
    }
    
    override func getSubtitle() -> String? {
        nil
    }

    override func systemLeftBarButtonItem() -> UIBarButtonItem? {
        let item = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(onLeftNavbarButtonPressed)
        )
        item.accessibilityLabel = localizedString("shared_string_close")
        return item
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        let image = UIImage.icCheckmarkDefault.withTintColor(.white, renderingMode: .alwaysOriginal)
        let button = UIBarButtonItem(image: image, style: .done, target: self, action: #selector(onRightNavbarButtonPressed))
        button.accessibilityLabel = localizedString("shared_string_apply")
        button.isEnabled = isEditChanged
        applyButton = button
        return [button]
    }

    override func onLeftNavbarButtonPressed() {
        closeIfPossible()
    }

    override func onRightNavbarButtonPressed() {
        applyChanges()
    }
    
    // MARK: - Table
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    override func hideFirstHeader() -> Bool {
        true
    }
    
    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        section == 1 ? 8 : UITableView.automaticDimension
    }
    
    override func getCustomHeight(forFooter section: Int) -> CGFloat {
        if section == 0 { return 8 }
        return 0.01
    }
    
    override func setupTableHeaderView() {
        tableView.tableHeaderView = CoordinateFormatTableHeader.makeDescriptionHeader(width: view.bounds.width)
    }

    override func generateData() {
        tableData.clearAllData()

        let formatsSection = tableData.createNewSection()
        let formats = CoordinateFormatHelper.resolve(editableIds)
        for (index, format) in formats.enumerated() {
            let row = formatsSection.createNewRow()
            row.cellType = OASimpleTableViewCell.reuseIdentifier
            row.title = format.title
            row.descr = CoordinateFormatHelper.summary(format, primary: index == 0)
            row.setObj(format.id, forKey: Self.formatIdKey)
        }

        let addSection = tableData.createNewSection()
        let addRow = addSection.createNewRow()
        addRow.key = Self.addRowKey
        addRow.cellType = OASimpleTableViewCell.reuseIdentifier
        addRow.title = localizedString("shared_string_add")
    }

    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        guard item.cellType == OASimpleTableViewCell.reuseIdentifier,
              let cell = tableView.dequeueReusableCell(
                withIdentifier: OASimpleTableViewCell.reuseIdentifier,
                for: indexPath
              ) as? OASimpleTableViewCell else { return nil }

        let isAddRow = item.key == Self.addRowKey
        cell.selectionStyle = isAddRow ? .default : .none
        cell.accessoryType = .none
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(!isAddRow && !(item.descr ?? "").isEmpty)
        cell.titleLabel.text = item.title
        cell.titleLabel.textColor = isAddRow ? .textColorActive : .textColorPrimary
        cell.descriptionLabel.text = item.descr
        cell.descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        cell.descriptionLabel.numberOfLines = 1

        if isAddRow {
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.title
            cell.accessibilityTraits = .button
        } else {
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = item.title
            cell.accessibilityValue = item.descr
            cell.accessibilityTraits = .staticText
            cell.accessibilityHint = localizedString("shared_string_move")
        }
        
        return cell
    }

    override func onRowSelected(_ indexPath: IndexPath?) {
        guard let indexPath else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        guard tableData.item(for: indexPath).key == Self.addRowKey else { return }
        onAddAction()
    }

    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == Self.formatsSection
    }

    override func tableView(_ tableView: UITableView,
                            canMoveRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == Self.formatsSection
    }
    
    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        guard indexPath.section == Self.formatsSection else { return .none }
        return editableIds.count > 1 ? .delete : .none
    }
    
    override func tableView(_ tableView: UITableView,
                            shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        indexPath.section == Self.formatsSection
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, indexPath.section == Self.formatsSection else { return }
        removeItem(at: indexPath.row)
    }

    override func tableView(_ tableView: UITableView,
                            moveRowAt sourceIndexPath: IndexPath,
                            to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.section == Self.formatsSection,
              destinationIndexPath.section == Self.formatsSection,
              sourceIndexPath.row != destinationIndexPath.row,
              editableIds.indices.contains(sourceIndexPath.row),
              editableIds.indices.contains(destinationIndexPath.row) else { return }
        let id = editableIds.remove(at: sourceIndexPath.row)
        editableIds.insert(id, at: destinationIndexPath.row)
        reloadDraft(animated: false)
    }

    override func tableView(_ tableView: UITableView,
                            targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
                            toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        proposedDestinationIndexPath.section == Self.formatsSection
            ? proposedDestinationIndexPath
            : IndexPath(row: max(editableIds.count - 1, 0), section: Self.formatsSection)
    }

    private func reloadDraft(animated: Bool) {
        generateData()
        if animated {
            tableView.reloadSections(IndexSet(integer: Self.formatsSection), with: .automatic)
        } else {
            tableView.reloadData()
        }
        applyButton?.isEnabled = isEditChanged
    }
    
    private func relayoutTableHeaderViewIfNeeded() {
        guard let header = tableView.tableHeaderView else { return }
        let width = tableView.bounds.width
        guard CoordinateFormatTableHeader.relayoutTableHeaderViewIfNeeded(header, width: width) else { return }
        tableView.tableHeaderView = header
    }
    
    // MARK: - Alerts
    
    private func showDiscardChangesAlert() {
        let alert = UIAlertController(
            title: localizedString("coordinate_format_cancel_changes_title"),
            message: localizedString("coordinate_format_cancel_changes_message"),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: localizedString("shared_string_discard"),
            style: .destructive
        ) { _ in
            self.dismiss()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Actions

    private func removeItem(at index: Int) {
        guard editableIds.indices.contains(index) else { return }
        guard editableIds.count > 1 else {
            OAUtilities.showToast(
                localizedString("coordinate_format_last_item_warning"),
                details: nil,
                duration: 4,
                in: view
            )
            return
        }
        editableIds.remove(at: index)
        reloadDraft(animated: true)
    }

    private func applyChanges() {
        guard isEditChanged else { return }
        formatStorage.setPreferredIds(appMode, ids: editableIds)
        delegate?.onSettingsChanged()
        dismiss()
    }

    private func closeIfPossible() {
        if isEditChanged {
            showDiscardChangesAlert()
        } else {
            dismiss()
        }
    }

    @objc private func onAddAction() {
        // Add format screen is not implemented yet.
    }
}
