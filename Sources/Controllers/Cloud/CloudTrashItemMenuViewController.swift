//
//  CloudTrashItemMenuViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 05.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation

@objc(OACloudTrashItemMenuViewController)
@objcMembers
final class CloudTrashItemMenuViewController: OABaseNavbarViewController {
    weak var delegate: CloudTrashDelegate?

    private let trashItem: TrashItem
    private var isProcessSelected = false

    // MARK: - Initialize

    init(with trashItem: TrashItem) {
        self.trashItem = trashItem
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if !isProcessSelected {
            delegate?.resetSelectedIndexPath()
        }
    }

    // MARK: - Base UI

    override func getTitle() -> String {
        localizedString("shared_string_file_info")
    }

    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    // MARK: - Table Data

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OARightIconTableViewCell.reuseIdentifier)
    }

    override func generateData() {
        let fileSection = tableData.createNewSection()
        let fileRow = fileSection.createNewRow()
        fileRow.key = "trashItem"
        fileRow.cellType = OASimpleTableViewCell.getIdentifier()

        let optionsSection = tableData.createNewSection()

        if !trashItem.isLocalDeletion {
            let restoreRow = optionsSection.createNewRow()
            restoreRow.key = "restoreFromTrash"
            restoreRow.cellType = OARightIconTableViewCell.getIdentifier()
            restoreRow.title = localizedString("restore_from_trash")
            restoreRow.secondaryIconName = "ic_custom_reset"
            restoreRow.secondaryIconTintColor = UIColor.iconColorActive
        }

        let downloadRow = optionsSection.createNewRow()
        downloadRow.key = "downloadToDevice"
        downloadRow.cellType = OARightIconTableViewCell.getIdentifier()
        downloadRow.title = localizedString("download_to_device")
        downloadRow.secondaryIconName = "ic_custom_device_download"
        downloadRow.secondaryIconTintColor = UIColor.iconColorActive

        let deleteSection = tableData.createNewSection()
        let deleteRow = deleteSection.createNewRow()
        deleteRow.key = "deleteImmediately"
        deleteRow.cellType = OARightIconTableViewCell.getIdentifier()
        deleteRow.title = localizedString("shared_string_delete_immediately")
        deleteRow.setObj(UIColor.textColorDisruptive, forKey: "titleColor")
        deleteRow.secondaryIconName = "ic_custom_trash_outlined"
        deleteRow.secondaryIconTintColor = UIColor.iconColorDisruptive
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.selectionStyle = .none
            if item.key == "trashItem" {
                cell.titleLabel.text = trashItem.name
                cell.titleLabel.accessibilityLabel = trashItem.name
                cell.descriptionLabel.text = trashItem.descr
                cell.descriptionLabel.accessibilityLabel = trashItem.descr
                cell.leftIconView.image = trashItem.icon
                
                var iconColor: UIColor
                if let profileItem = trashItem.settingsItem as? OAProfileSettingsItem {
                    iconColor = UIColor(rgb: profileItem.appMode.getIconColor())
                } else {
                    iconColor = UIColor.iconColorDefault
                }
                cell.leftIconView.tintColor = iconColor
            }
            return cell
        } else if item.cellType == OARightIconTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: OARightIconTableViewCell.reuseIdentifier, for: indexPath) as! OARightIconTableViewCell
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.titleLabel.textColor = item.obj(forKey: "titleColor") as? UIColor ?? UIColor.textColorPrimary
            cell.titleLabel.accessibilityLabel = item.title
            cell.rightIconView.image = UIImage.templateImageNamed(item.secondaryIconName)
            cell.rightIconView.tintColor = item.secondaryIconTintColor
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        isProcessSelected = true
        let item = tableData.item(for: indexPath)
        dismiss()
        switch item.key {
        case "restoreFromTrash":
            delegate?.restoreItem(trashItem)
        case "downloadToDevice":
            delegate?.downloadItem(trashItem)
        case "deleteImmediately":
            delegate?.deleteItem(trashItem)
        default:
            return
        }
    }
}
