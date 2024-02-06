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
    func onFileDeleteProgress(_ deleteAll: Bool)
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

    // MARK: - Initializing

    override func commonInit() {
        backupHelper = OABackupHelper.sharedInstance()
        settingsHelper = OANetworkSettingsHelper.sharedInstance()
    }

    override func registerNotifications() {
        addNotification(NSNotification.Name(kBackupProgressUpdateNotification), selector: #selector(onBackupProgressUpdate(notification:)))
        addNotification(NSNotification.Name(kBackupSyncFinishedNotification), selector: #selector(onBackupSyncFinished(notification:)))
    }

    deinit {
        backupHelper?.remove(self)
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

    override func generateData() {
        tableData.clearAllData()
        let preparing = backupHelper?.isBackupPreparing()
        let groups: [String: TrashGroup] = collectTrashGroups()
        if groups.isEmpty, preparing == false {
            let emptySection = tableData.createNewSection()
            let emptyRow = emptySection.createNewRow()
            emptyRow.cellType = OALargeImageTitleDescrTableViewCell.getIdentifier()
            emptyRow.key = "empty"
            emptyRow.title = localizedString("trash_is_empty")
            emptyRow.descr = String(format: localizedString("trash_is_empty_banner_desc"), Self.daysForTrashClearing)
            emptyRow.iconName = "ic_custom_trash_outlined"
            emptyRow.iconTintColor = UIColor.iconColorDefault
        } else {
            for (name, group) in groups {
                let section = tableData.createNewSection()
                section.headerText = name
                for item in group.getItems() {
                    let row = section.createNewRow()
                    row.cellType = OASimpleTableViewCell.getIdentifier()
                    row.setObj(item, forKey: "trashItem")
                }
            }
        }
    }

    private func collectTrashItems() -> [TrashItem] {
        var items: [TrashItem] = []
        if let backup: OAPrepareBackupResult = backupHelper?.backup {
            let info: OABackupInfo = backup.backupInfo
            let filesToDelete: NSMutableArray = info.filesToDelete
            if filesToDelete.count > 0 {
                for file: OARemoteFile in info.filesToDelete as! [OARemoteFile] {
                    items.append(TrashItem(oldFile: file, deletedFile: nil))
                }
            }
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
            items.sort(by: { i1, i2 in
                i1.time > i2.time
            })
            
            for item in items {
                let time: Int = item.time
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "LLLL yyyy"
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
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.accessoryType = .disclosureIndicator
            }
            if let cell {
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
                }
            }
            return cell
        } else if item.cellType == OALargeImageTitleDescrTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OALargeImageTitleDescrTableViewCell.getIdentifier()) as? OALargeImageTitleDescrTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OALargeImageTitleDescrTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OALargeImageTitleDescrTableViewCell
                cell?.selectionStyle = .none
                cell?.showButton(false)
            }
            if let cell {
                cell.titleLabel?.text = item.title
                cell.titleLabel?.accessibilityLabel = item.title
                cell.descriptionLabel?.text = item.descr
                cell.descriptionLabel?.accessibilityLabel = item.descr
                cell.cellImageView?.tintColor = item.iconTintColor
                if let icon = item.iconName {
                    cell.cellImageView?.image = OAUtilities.resize(UIImage(named: icon), newSize: CGSize(width: 60.0, height: 60.0)).withRenderingMode(.alwaysTemplate)
                }
            }
            if cell?.needsUpdateConstraints() == true {
                cell?.setNeedsUpdateConstraints()
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
            self.updateRowProgress(.started, indexPath: selectedIndexPath)
        }

        settingsHelper?.syncSettingsItems(trashItem.oldFile.name,
                                          localFile: nil,
                                          remoteFile: trashItem.oldFile,
                                          filesType: trashItem.isLocalDeletion ? .unique : .old,
                                          operation: .download,
                                          shouldReplace: shouldReplace,
                                          restoreDeleted: !trashItem.isLocalDeletion) { (message: String?, details: String?) in
            OAUtilities.showToast(message, details: details, duration: 4, in: self.view)
        }
    }

    private func updateRowProgress(_ type: TrashItemProcessType, indexPath: IndexPath?) {
        if let indexPath, let cell = tableView.cellForRow(at: indexPath) {
            var progressView = cell.accessoryView as? FFCircularProgressView
            if progressView == nil, type == .started {
                progressView = FFCircularProgressView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
                progressView?.iconView = UIView()
                progressView?.tintColor = UIColor.iconColorActive
                cell.accessoryView = progressView
            }
            if type == .started {
                progressView?.iconPath = UIBezierPath()
                progressView?.startSpinProgressBackgroundLayer()
            } else if type == .done {
                if let progressView {
                    progressView.iconPath = tickPath(progressView)
                    progressView.stopSpinProgressBackgroundLayer()
                }
                cell.accessoryType = .none
                cell.accessoryView = nil
            }
        }
    }

    private func tickPath(_ progressView: FFCircularProgressView) -> UIBezierPath {
        let radius: CGFloat = min(progressView.frame.size.width, progressView.frame.size.height) / 2
        let path = UIBezierPath()
        let tickWidth: CGFloat = radius * 0.3
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 0, y: tickWidth * 2))
        path.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth * 2))
        path.addLine(to: CGPoint(x: tickWidth * 3, y: tickWidth))
        path.addLine(to: CGPoint(x: tickWidth, y: tickWidth))
        path.addLine(to: CGPoint(x: tickWidth, y: 0))
        path.close()

        path.apply(CGAffineTransformMakeRotation(-(.pi / 4)))
        path.apply(CGAffineTransformMakeTranslation(radius * 0.46, 1.02 * radius))

        return path
    }

    // MARK: - OASyncBackupTask

    @objc private func onBackupProgressUpdate(notification: NSNotification) {
        if let selectedIndexPath {
            DispatchQueue.main.async {
                self.updateRowProgress(.inProgress, indexPath: selectedIndexPath)
            }
        }
    }

    @objc private func onBackupSyncFinished(notification: NSNotification) {
        if let error = notification.userInfo?["error"] as? String {
            DispatchQueue.main.async {
                OAUtilities.showToast(nil, details: OABackupError(error: error).getLocalizedError(), duration: 4, in: self.view)
            }
        } else if settingsHelper?.isBackupSyncing() == false && backupHelper?.isBackupPreparing() == false {
            if let selectedIndexPath {
                DispatchQueue.main.async {
                    self.updateRowProgress(.done, indexPath: selectedIndexPath)
                    self.resetSelectedIndexPath()
                }
            }
            backupHelper?.prepareBackup()
        }
    }

    // MARK: - OAOnPrepareBackupListener

    func onBackupPreparing() {
        DispatchQueue.main.async {
            if self.tableView.refreshControl?.isRefreshing == false {
                self.tableView.refreshControl?.beginRefreshing()
            }
            self.reloadDataWith(animated: true, completion: nil)
        }
    }

    func onBackupPrepared(_ backupResult: OAPrepareBackupResult) {
        DispatchQueue.main.async {
            self.reloadDataWith(animated: true, completion: nil)
            self.tableView.refreshControl?.endRefreshing()
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
        DispatchQueue.main.async {
            if !deleteAll, let indexPath = self.selectedIndexPath {
                self.updateRowProgress(.started, indexPath: indexPath)
            } else if self.tableView.refreshControl?.isRefreshing == false {
                self.tableView.refreshControl?.beginRefreshing()
            }
        }
    }

    func onFileDeleteProgress(_ deleteAll: Bool) {
        if !deleteAll, let indexPath = self.selectedIndexPath {
            DispatchQueue.main.async {
                self.updateRowProgress(.inProgress, indexPath: indexPath)
            }
        }
    }

    func onFilesDeleteDone(_ message: String, errors: [OARemoteFile: String], deleteAll: Bool) {
        let hasErrors = !errors.isEmpty
        if hasErrors || !message.isEmpty {
            DispatchQueue.main.async {
                if !deleteAll, let indexPath = self.selectedIndexPath {
                    self.updateRowProgress(.done, indexPath: indexPath)
                }
                OAUtilities.showToast(hasErrors ? localizedString("subscribe_email_error") : message,
                                      details: hasErrors ? errors.values.joined(separator: "\n") : nil,
                                      duration: 4,
                                      in: self.view)
            }
        }
        backupHelper?.prepareBackup()
    }

    func onFilesDeleteError(_ message: String) {
        DispatchQueue.main.async {
            OAUtilities.showToast(localizedString("subscribe_email_error"),
                                  details: OABackupError(error: message).getLocalizedError(),
                                  duration: 4,
                                  in: self.view)
        }
        backupHelper?.prepareBackup()
    }
}

private final class TrashDeletionListener: NSObject, OAOnDeleteFilesListener {

    weak var delegate: CloudTrashDeletionDelegate?
    private let messageDone: String
    private var deleteAll: Bool = false

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
        delegate?.onFileDeleteProgress(deleteAll)
    }
    
    func onFilesDeleteDone(_ errors: [OARemoteFile: String]) {
        delegate?.onFilesDeleteDone(messageDone, errors: errors, deleteAll: deleteAll)
    }
    
    func onFilesDeleteError(_ status: Int, message: String) {
        delegate?.onFilesDeleteError(message)
    }
}
