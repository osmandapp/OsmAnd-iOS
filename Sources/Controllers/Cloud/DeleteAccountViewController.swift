//
//  DeleteAccountViewController.swift
//  OsmAnd Maps
//
//  Created by Skalii on 19.02.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

enum DeleteAccountStatus {
    case notStarted, running, finished

    func getTitle() -> String {
        switch self {
        case .notStarted:
            return localizedString("delete_account")
        case .running:
            return localizedString("shared_string_deleting")
        case .finished:
            return localizedString("shared_string_deleting_complete")
        }
    }

    func getDescription() -> String {
        switch self {
        case .running:
            return localizedString("osmand_cloud_deleting_account_descr")
        case .finished:
            return localizedString("osmand_cloud_deleted_account_descr")
        default:
            return ""
        }
    }
}

@objc(OADeleteAccountViewController)
@objcMembers
final class DeleteAccountViewController: OABaseButtonsViewController, OAOnDeleteAccountListener {
    
    private let token: String
    private let progressIndexPath = IndexPath(row: 0, section: 0)
    private var status = DeleteAccountStatus.notStarted
    private var backupHelper: OABackupHelper?
    private var progress: Float = 0.0

    // MARK: - Initialization

    init(token: String) {
        self.token = token
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func commonInit() {
        backupHelper = OABackupHelper.sharedInstance()
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OADividerCell.reuseIdentifier)
        addCell(OADownloadProgressBarCell.reuseIdentifier)
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.separatorStyle = .none
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        backupHelper?.backupListeners.add(self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        backupHelper?.backupListeners.remove(self)
    }

    // MARK: - Base UI

    override func getTitle() -> String {
        status.getTitle()
    }

    override func getLeftNavbarButtonTitle() -> String {
        localizedString(status == .notStarted ? "shared_string_cancel" : "shared_string_close")
    }

    override func isNavbarSeparatorVisible() -> Bool {
        false
    }

    override func getNavbarStyle() -> EOABaseNavbarStyle {
        .largeTitle
    }

    override func getSpaceBetweenButtons() -> CGFloat {
        0.01
    }

    override func getTopButtonTitle() -> String {
        status == .notStarted ? localizedString("action_cant_be_undone") : ""
    }

    override func getBottomButtonTitle() -> String {
        status == .notStarted ? localizedString("delete_account") : ""
    }

    override func getTopButtonColorScheme() -> EOABaseButtonColorScheme {
        .blank
    }

    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .red
    }

    override func isBottomSeparatorVisible() -> Bool {
        false
    }

    // MARK: - Table data

    override func generateData() {
        tableData.clearAllData()
        let infoSection = tableData.createNewSection()
        if status == .notStarted {
            let deleteConfirmRow = infoSection.createNewRow()
            deleteConfirmRow.cellType = OASimpleTableViewCell.reuseIdentifier
            deleteConfirmRow.title = localizedString("osmand_cloud_delete_account_descr")
            
            let allDataDeletedRow = infoSection.createNewRow()
            allDataDeletedRow.cellType = OASimpleTableViewCell.reuseIdentifier
            let deletedText = localizedString("shared_string_deleted").lowercased()
            let allDataDeletedTitle = NSMutableAttributedString(string: String(format: localizedString("osmand_cloud_deletion_all_data_warning"), deletedText),
                                                                attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
            allDataDeletedTitle.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .headline),
                                             range: allDataDeletedTitle.mutableString.range(of: deletedText))
            allDataDeletedRow.setObj(allDataDeletedTitle, forKey: "attributedTitle")
            allDataDeletedRow.icon = UIImage.icCustomFileDelete
            allDataDeletedRow.iconTintColor = .textColorDisruptive
            
            let accoundDetailsDeletedRow = infoSection.createNewRow()
            accoundDetailsDeletedRow.cellType = OASimpleTableViewCell.reuseIdentifier
            let accoundDetailsDeletedTitle = NSMutableAttributedString(string: String(format: localizedString("osmand_cloud_deletion_account_warning"), deletedText),
                                                                       attributes: [.font: UIFont.preferredFont(forTextStyle: .body)])
            accoundDetailsDeletedTitle.addAttribute(.font, value: UIFont.preferredFont(forTextStyle: .headline),
                                                    range: accoundDetailsDeletedTitle.mutableString.range(of: deletedText))
            accoundDetailsDeletedRow.setObj(accoundDetailsDeletedTitle, forKey: "attributedTitle")
            accoundDetailsDeletedRow.icon = UIImage.icCustomUserProfileDelete
            accoundDetailsDeletedRow.iconTintColor = .textColorDisruptive
            
            let secondaryDevicesRow = infoSection.createNewRow()
            secondaryDevicesRow.cellType = OASimpleTableViewCell.reuseIdentifier
            secondaryDevicesRow.title = localizedString("osmand_cloud_deletion_secondary_devices_warning")
            secondaryDevicesRow.icon = UIImage.icCustomSecondaryDevicesDisabled
            secondaryDevicesRow.iconTintColor = .textColorDisruptive
            
            infoSection.addRow(from: [kCellTypeKey: OADividerCell.reuseIdentifier])
            
            let manageSubscriptionsRow = infoSection.createNewRow()
            manageSubscriptionsRow.key = "manageSubscriptions"
            manageSubscriptionsRow.cellType = OASimpleTableViewCell.reuseIdentifier
            let manageSubscriptions = localizedString("manage_subscriptions")
            let manageSubscriptionsTitle = NSMutableAttributedString(string: String(format: "%@ %@", localizedString("osmand_cloud_deletion_subscriptions_warning"), manageSubscriptions),
                                                                     attributes: [.font: UIFont.preferredFont(forTextStyle: .subheadline),
                                                                                  .foregroundColor: UIColor.textColorSecondary])
            manageSubscriptionsTitle.addAttribute(.foregroundColor,
                                                  value: UIColor.textColorActive,
                                                  range: manageSubscriptionsTitle.mutableString.range(of: manageSubscriptions))
            manageSubscriptionsRow.setObj(manageSubscriptionsTitle, forKey: "attributedTitle")
        } else {
            infoSection.footerText = status.getDescription()
            let progressRow = infoSection.createNewRow()
            progressRow.cellType = OADownloadProgressBarCell.reuseIdentifier
        }
    }

    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            if let key = item.key, key == "manageSubscriptions" {
                cell.selectionStyle = .default
            } else {
                cell.selectionStyle = .none
            }
            cell.backgroundColor = .clear
            cell.descriptionVisibility(false)
            if let attributedTitle = item.obj(forKey: "attributedTitle") as? NSAttributedString {
                cell.titleLabel.text = nil
                cell.titleLabel.attributedText = attributedTitle
                cell.titleLabel.accessibilityLabel = attributedTitle.string
            } else {
                cell.titleLabel.attributedText = nil
                cell.titleLabel.text = item.title
                cell.titleLabel.accessibilityLabel = item.title
            }
            if let icon = item.icon {
                cell.leftIconView.image = icon
                cell.leftIconVisibility(true)
            } else {
                cell.leftIconView.image = nil
                cell.leftIconVisibility(false)
            }

            if let iconTintColor = item.iconTintColor {
                cell.leftIconView.tintColor = iconTintColor
            } else {
                cell.leftIconView.tintColor = .iconColorDefault
            }
            return cell
        } else if item.cellType == OADividerCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADividerCell.reuseIdentifier, for: indexPath) as! OADividerCell
            cell.backgroundColor = .clear
            cell.dividerColor = .customSeparator
            cell.dividerInsets = UIEdgeInsets.zero
            cell.dividerHight = 1.0 / UIScreen.main.scale
            return cell
        } else if item.cellType == OADownloadProgressBarCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OADownloadProgressBarCell.reuseIdentifier, for: indexPath) as! OADownloadProgressBarCell
            cell.showLabels(false)
            cell.backgroundColor = .clear
            cell.progressBarView.setProgress(progress, animated: true)
            cell.updateConstraintsIfNeeded()
            return cell
        }
        return nil
    }

    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let key = item.key, key == "manageSubscriptions" {
            show(OAPurchasesViewController())
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = tableData.item(for: indexPath)
        if item.cellType == OADividerCell.reuseIdentifier {
            return 1.0 / UIScreen.main.scale
        } else {
            return UITableView.automaticDimension
        }
    }

    // MARK: - Selectors

    override func onLeftNavbarButtonPressed() {
        if let navigationController, status == .finished {
            guard let controller = navigationController.viewControllers.first(where: { $0 is OAMainSettingsViewController }) else {
                return super.onLeftNavbarButtonPressed()
            }
            navigationController.popToViewController(controller, animated: true)
        } else {
            super.onLeftNavbarButtonPressed()
        }
    }

    override func onBottomButtonPressed() {
        let alert = UIAlertController(title: localizedString("osmand_cloud_delete_account_confirmation"),
                                      message: "\(localizedString("osmand_cloud_delete_account_descr"))\n\n\(localizedString("action_cant_be_undone"))",
                                      preferredStyle: .alert)
        let deleteAction = UIAlertAction(title: localizedString("shared_string_delete"), style: .destructive) { [weak self] _ in
            guard let self else { return }
            status = .running
            updateUIAnimated { _ in
                self.updateProgress(0.33)
                self.backupHelper?.deleteAccount(OAAppSettings.sharedManager().backupUserEmail.get(), token: self.token)
            }
        }
        alert.addAction(deleteAction)
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))

        alert.preferredAction = deleteAction

        present(alert, animated: true)
    }

    // MARK: - Additions

    private func updateProgress(_ progress: Float) {
        self.progress = progress
        tableView.reloadRows(at: [progressIndexPath], with: .none)
    }

    // MARK: - OAOnDeleteAccountListener

    func onDeleteAccount(_ status: Int, message: String, error: OABackupError?) {
        self.status = .finished
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.updateProgress(0.75)
            updateUIAnimated(nil)
            if error == nil {
                backupHelper?.logout()
            }
            if let text = error != nil ? error?.getLocalizedError() : message, !text.isEmpty {
                OAUtilities.showToast(text, details: nil, duration: 4, in: view)
            }
            self.updateProgress(1.0)
        }
    }
}
