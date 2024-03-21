//
//  CloudTrashViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 01.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import Foundation
import OSLog

protocol CloudTrashDelegate: AnyObject {
    func resetSelectedIndexPath()
    func restoreItem(_ trashItem: TrashItem)
    func downloadItem(_ trashItem: TrashItem)
    func deleteItem(_ trashItem: TrashItem)
}

protocol CloudTrashDeletionDelegate: AnyObject {
    func onFilesDeleteStarted(_ deleteAll: Bool)
    func onFilesDeleteDone(_ message: String, errors: [OARemoteFile: String], deleteAll: Bool)
    func onFilesDeleteError(_ message: String)
}

enum TrashItemProcessType {
    case started, inProgress, done
}

@objc(OACloudTrashViewController)
@objcMembers
final class CloudTrashViewController: OABaseNavbarViewController, OAOnPrepareBackupListener, CloudTrashDelegate, CloudTrashDeletionDelegate {

    private static let daysForTrashClearing = 30
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: CloudTrashViewController.self)
    )

    private var backupHelper: OABackupHelper?
    private var settingsHelper: OANetworkSettingsHelper?
    private var selectedIndexPath: IndexPath?
    private lazy var dateFormatter = DateFormatter()
    private var emptyTrashIcon: UIImage?

    // MARK: - Initializing

    override func commonInit() {
        backupHelper = OABackupHelper.sharedInstance()
        settingsHelper = OANetworkSettingsHelper.sharedInstance()
        dateFormatter.dateFormat = "LLLL yyyy"
        emptyTrashIcon = OAUtilities.resize(UIImage(named: "ic_custom_trash_outlined"), newSize: CGSize(width: 60.0, height: 60.0)).withRenderingMode(.alwaysTemplate)
    }

    override func registerNotifications() {
        addNotification(NSNotification.Name(kBackupSyncFinishedNotification), selector: #selector(onBackupSyncFinished(notification:)))
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.refreshControl = UIRefreshControl()
        backupHelper?.add(self)
        tableView.refreshControl?.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        if shouldPrepareBackup() {
            backupHelper?.prepareBackup()
        }
    }

    deinit {
        backupHelper?.remove(self)
    }

    // MARK: - Base UI

    override func getTitle() -> String {
        localizedString("shared_string_trash")
    }

    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        [createRightNavbarButton(nil, iconName: "ic_navbar_trash", action: #selector(onRightNavbarButtonPressed), menu: nil)]
    }

    override func getNavbarColorScheme() -> EOABaseNavbarColorScheme {
        .orange
    }

    // MARK: - Table data

    override func registerCells() {
        addCell(OALargeImageTitleDescrTableViewCell.reuseIdentifier)
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }

    override func generateData() {
        tableData.clearAllData()
        let preparing = backupHelper?.isBackupPreparing()
        let groups: [String: TrashGroup] = collectTrashGroups()
        if groups.isEmpty, preparing == false {
            let emptySection = tableData.createNewSection()
            let emptyRow = emptySection.createNewRow()
            emptyRow.cellType = OALargeImageTitleDescrTableViewCell.reuseIdentifier
            emptyRow.key = "empty"
            emptyRow.title = localizedString("trash_is_empty")
            emptyRow.descr = String(format: localizedString("trash_is_empty_banner_desc"), Self.daysForTrashClearing)
            emptyRow.iconTintColor = UIColor.iconColorDefault
        } else {
            let orderedNames = groups.keys.sorted {
                return groups[$0]?.getItems().first?.time ?? 0 > groups[$1]?.getItems().first?.time ?? 0
            }
            for name in orderedNames {
                if let group = groups[name] {
                    let section = tableData.createNewSection()
                    section.headerText = name
                    for item in group.getItems() {
                        let row = section.createNewRow()
                        row.cellType = OASimpleTableViewCell.reuseIdentifier
                        row.setObj(item, forKey: "trashItem")
                    }
                }
            }
        }
    }

    private func collectTrashItems() -> [TrashItem] {
        var items: [TrashItem] = []
        if let backup: OAPrepareBackupResult = backupHelper?.backup {
            let oldFiles: [String: OARemoteFile] = backup.getRemoteFiles(.old)
            let deletedFiles: [String: OARemoteFile] = backup.getRemoteFiles(.deleted)
            if !oldFiles.isEmpty && !deletedFiles.isEmpty {
                for (key, file) in deletedFiles {
                    if let oldFile: OARemoteFile = oldFiles[key] {
                        items.append(TrashItem(oldFile: oldFile, deletedFile: file))
                    }
                }
            }
        }
        return items
    }

    private func collectTrashGroups() -> [String: TrashGroup] {
        var groups: [String: TrashGroup] = [:]
        var items: [TrashItem] = collectTrashItems()
        if !items.isEmpty {
            items.sort(by: {
                $0.time > $1.time
            })

            for item in items {
                let time: Int = item.time
                let name = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(time))).capitalized
                var group: TrashGroup? = groups[name]
                if group == nil {
                    group = TrashGroup(name: name)
                    groups[name] = group
                }
                group?.addItem(item: item)
            }
        }
        return groups
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item: OATableRowData = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            cell.accessoryType = .disclosureIndicator
            if let trashItem = item.obj(forKey: "trashItem") as? TrashItem {
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

                if indexPath == selectedIndexPath {
                    addProgress(to: cell)
                } else {
                    removeProgress(from: cell)
                }
            }
            return cell
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.reuseIdentifier, for: indexPath) as! OALargeImageTitleDescrTableViewCell
            cell.selectionStyle = .none
            cell.showButton(false)
            cell.cellImageView?.image = emptyTrashIcon
            cell.titleLabel?.text = item.title
            cell.titleLabel?.accessibilityLabel = item.title
            cell.descriptionLabel?.text = item.descr
            cell.descriptionLabel?.accessibilityLabel = item.descr
            cell.cellImageView?.tintColor = item.iconTintColor
            if cell.needsUpdateConstraints() {
                cell.setNeedsUpdateConstraints()
            }
            return cell
        }
        return nil
    }

    override func getCustomHeight(forHeader section: Int) -> CGFloat {
        if section == 0, tableData.sectionData(for: 0).headerText.isEmpty {
            return CGFloat(kHeaderHeightDefault)
        } else {
            return super.getCustomHeight(forHeader: section)
        }
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item: OATableRowData = tableData.item(for: indexPath)
        if let trashItem = item.obj(forKey: "trashItem") as? TrashItem {
            selectedIndexPath = indexPath
            let cloudTrashItemViewController = CloudTrashItemMenuViewController(with: trashItem)
            cloudTrashItemViewController.delegate = self
            showMediumSheetViewController(cloudTrashItemViewController, isLargeAvailable: false)
        }
    }

    // MARK: - Selectors

    override func onRightNavbarButtonPressed() {
        let alert = UIAlertController(title: localizedString("delete_all_items"),
                                      message: localizedString("delete_all_items_desc"),
                                      preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            self?.clearTrash()
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        let popPresenter = alert.popoverPresentationController
        popPresenter?.barButtonItem = getRightNavbarButtons().first
        popPresenter?.permittedArrowDirections = UIPopoverArrowDirection.any

        present(alert, animated: true)
    }

    @objc private func onRefresh() {
        if settingsHelper?.isBackupSyncing() == false, backupHelper?.isBackupPreparing() == false {
            backupHelper?.prepareBackup()
        } else {
            tableView.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Additions

    private func shouldPrepareBackup() -> Bool {
        settingsHelper?.isBackupSyncing() == false && backupHelper?.isBackupPreparing() == false && backupHelper?.backup?.backupInfo == nil
    }

    private func clearTrash() {
        var files: [OARemoteFile] = []
        for item: TrashItem in collectTrashItems() {
            files.append(contentsOf: item.remoteFiles)
        }

        let trashDeletionListener = TrashDeletionListener(with: localizedString("trash_is_empty"), deleteAll: true)
        trashDeletionListener.delegate = self
        backupHelper?.deleteFilesSync(files, byVersion: true, listener: trashDeletionListener)
    }

    private func downloadItem(_ trashItem: TrashItem, shouldReplace: Bool) {
        if let selectedIndexPath {
            tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
        }

        settingsHelper?.syncSettingsItems(trashItem.oldFile.name,
                                          localFile: nil,
                                          remoteFile: trashItem.oldFile,
                                          filesType: .old,
                                          operation: .download,
                                          shouldReplace: shouldReplace,
                                          restoreDeleted: true) { (message: String?, details: String?) in
            OAUtilities.showToast(message, details: details, duration: 4, in: self.view)
        }
    }

    private func addProgress(to cell: UITableViewCell) {
        var progressView = cell.accessoryView as? FFCircularProgressView
        if progressView == nil {
            progressView = FFCircularProgressView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
            progressView?.iconView = UIView()
            progressView?.tintColor = UIColor.iconColorActive
            cell.accessoryView = progressView
            progressView?.iconPath = UIBezierPath()
            progressView?.startSpinProgressBackgroundLayer()
        }
    }

    private func removeProgress(from cell: UITableViewCell) {
        if let progressView = cell.accessoryView as? FFCircularProgressView {
            progressView.createTickPath()
            progressView.stopSpinProgressBackgroundLayer()
            cell.accessoryView = nil
            cell.accessoryType = .disclosureIndicator
        }
    }

    // MARK: - OASyncBackupTask

    @objc private func onBackupSyncFinished(notification: NSNotification) {
        if let error = notification.userInfo?["error"] as? String {
            OAUtilities.showToast(nil, details: OABackupError(error: error).getLocalizedError(), duration: 4, in: view)
        } else if settingsHelper?.isBackupSyncing() == false && backupHelper?.isBackupPreparing() == false {
            backupHelper?.prepareBackup()
        }
    }

    // MARK: - OAOnPrepareBackupListener

    func onBackupPreparing() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if tableView.refreshControl?.isRefreshing == false {
                tableView.refreshControl?.beginRefreshing()
            }
            reloadDataWith(animated: true, completion: nil)
        }
    }

    func onBackupPrepared(_ backupResult: OAPrepareBackupResult) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            resetSelectedIndexPath()
            reloadDataWith(animated: true, completion: nil)
            tableView.refreshControl?.endRefreshing()
        }
    }

    // MARK: - CloudTrashDelegate

    func resetSelectedIndexPath() {
        selectedIndexPath = nil
    }

    func restoreItem(_ trashItem: TrashItem) {
        guard trashItem.settingsItem != nil else {
            Self.logger.error("Failed to restore item: \(String(describing: trashItem.oldFile.name)), SettingsItem is null")
            return
        }
        if let deletedFile = trashItem.deletedFile {
            let trashDeletionListener = TrashDeletionListener(with: String(format: localizedString("cloud_item_restored"), trashItem.name))
            trashDeletionListener.delegate = self
            backupHelper?.deleteFilesSync([deletedFile], byVersion: true, listener: trashDeletionListener)
        }
    }

    func downloadItem(_ trashItem: TrashItem) {
        guard trashItem.settingsItem != nil else {
            Self.logger.error("Failed to download item: \(String(describing: trashItem.oldFile.name)), SettingsItem is null")
            return
        }
        if backupHelper?.backup.localFiles[trashItem.oldFile.getTypeNamePath()] != nil {
            downloadItem(trashItem, shouldReplace: false) // TODO: - android uses FileExistBottomSheet here
        } else {
            downloadItem(trashItem, shouldReplace: true)
        }
    }

    func deleteItem(_ trashItem: TrashItem) {
        let alert = UIAlertController(title: localizedString("shared_string_delete_item"),
                                      message: String(format: localizedString("permanent_delete_warning"), trashItem.name),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            let trashDeletionListener = TrashDeletionListener(with: String(format: localizedString("shared_string_is_deleted"), trashItem.name))
            trashDeletionListener.delegate = self
            self?.backupHelper?.deleteFilesSync(trashItem.remoteFiles,
                                                byVersion: true,
                                                listener: trashDeletionListener)
        })
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - CloudTrashDeletionDelegate

    func onFilesDeleteStarted(_ deleteAll: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !deleteAll, let selectedIndexPath {
                tableView.reloadRows(at: [selectedIndexPath], with: .automatic)
            } else if tableView.refreshControl?.isRefreshing == false {
                tableView.refreshControl?.beginRefreshing()
            }
        }
    }

    func onFilesDeleteDone(_ message: String, errors: [OARemoteFile: String], deleteAll: Bool) {
        let hasErrors = !errors.isEmpty
        if hasErrors || !message.isEmpty {
            resetSelectedIndexPath()
            OAUtilities.showToast(hasErrors ? localizedString("subscribe_email_error") : message,
                                  details: hasErrors ? errors.values.joined(separator: "\n") : nil,
                                  duration: 4,
                                  in: view)
        }
        backupHelper?.prepareBackup()
    }

    func onFilesDeleteError(_ message: String) {
        OAUtilities.showToast(localizedString("subscribe_email_error"),
                              details: OABackupError(error: message).getLocalizedError(),
                              duration: 4,
                              in: view)
        backupHelper?.prepareBackup()
    }
}

private final class TrashDeletionListener: NSObject, OAOnDeleteFilesListener {

    weak var delegate: CloudTrashDeletionDelegate?
    private let messageDone: String
    private var deleteAll = false

    init(with messageDone: String) {
        self.messageDone = messageDone
    }

    init(with messageDone: String, deleteAll: Bool) {
        self.messageDone = messageDone
        self.deleteAll = deleteAll
    }

    func onFilesDeleteStarted(_ files: [OARemoteFile]) {
        delegate?.onFilesDeleteStarted(deleteAll)
    }
    
    func onFileDeleteProgress(_ file: OARemoteFile, progress: Int) {
    }
    
    func onFilesDeleteDone(_ errors: [OARemoteFile: String]) {
        delegate?.onFilesDeleteDone(messageDone, errors: errors, deleteAll: deleteAll)
    }
    
    func onFilesDeleteError(_ status: Int, message: String) {
        delegate?.onFilesDeleteError(message)
    }
}
