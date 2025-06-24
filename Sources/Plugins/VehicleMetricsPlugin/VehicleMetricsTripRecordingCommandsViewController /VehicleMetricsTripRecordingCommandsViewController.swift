//
//  VehicleMetricsTripRecordingCommandsViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 18.06.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class VehicleMetricsTripRecordingCommandsViewController: OABaseNavbarViewController {
    
    private let appMode: OAApplicationMode
    private let onApplyAction: (() -> Void)?
    
    private lazy var selectionManager: SelectionManager<String> = {
        let allCommands = VehicleMetricsItem.allCommands
        guard let plugin = vehicleMetricsPlugin else {
            return SelectionManager(allItems: allCommands, initiallySelected: [])
        }

        let selectedCommands = plugin.TRIP_RECORDING_VEHICLE_METRICS.get(appMode) ?? []
        return SelectionManager(allItems: allCommands, initiallySelected: selectedCommands)
    }()
    
    private lazy var vehicleMetricsPlugin: VehicleMetricsPlugin? = {
        OAPluginsHelper.getEnabledPlugin(VehicleMetricsPlugin.self) as? VehicleMetricsPlugin
    }()
    
    // MARK: - Init
    
    @objc init(appMode: OAApplicationMode, onApplyAction: (() -> Void)? = nil) {
        self.appMode = appMode
        self.onApplyAction = onApplyAction
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isToolbarHidden = false
        navigationController?.presentationController?.delegate = self
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.isEditing = true
        
        configureToolbar()
        configureRightBarButtonState()
    }
    
    private func updateUIAfterSelectionChange() {
        configureToolbar()
        configureRightBarButtonState()
    }
}

// MARK: - NavBar
extension VehicleMetricsTripRecordingCommandsViewController {
    
    override func getTitle() -> String {
        localizedString("obd_plugin_name")
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_cancel")
    }
    
    override func getRightNavbarButtons() -> [UIBarButtonItem] {
        guard let applyBarButton = createRightNavbarButton(localizedString("shared_string_apply"), iconName: nil, action: #selector(onRightNavbarButtonPressed), menu: nil) else {
            return []
        }
        
        return [applyBarButton]
    }
    
    override func onRightNavbarButtonPressed() {
        guard let plugin = vehicleMetricsPlugin else {
            dismiss()
            return
        }
        
        plugin.TRIP_RECORDING_VEHICLE_METRICS.set(Array(selectionManager.selectedItems), mode: appMode)
        onApplyAction?()
        dismiss()
    }
    
    override func onLeftNavbarButtonPressed() {
        if !selectionManager.hasChanges {
            dismiss()
        } else {
            presentExitWithoutSavingAlert()
        }
    }
    
    private func presentExitWithoutSavingAlert() {
        let alert = UIAlertController(
            title: localizedString("exit_without_saving"),
            message: localizedString("unsaved_changes_will_be_lost"),
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: localizedString("shared_string_cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: localizedString("shared_string_exit"), style: .destructive) { [self] _ in
            dismiss()
        })
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItem
            popover.permittedArrowDirections = .any
        }
        
        present(alert, animated: true)
    }
    
    private func configureRightBarButtonState() {
        setRightBarButtonEnabled(selectionManager.hasChanges)
    }
    
    private func setRightBarButtonEnabled(_ isEnabled: Bool) {
        navigationItem.setRightBarButtonItems(isEnabled: isEnabled, with: isEnabled ? .iconColorActive : .buttonBgColorDisabled)
    }
}

// MARK: - TableView
extension VehicleMetricsTripRecordingCommandsViewController {
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTableHeaderDescriptionAttr() -> NSAttributedString! {
        let attrStr = NSMutableAttributedString(string: localizedString("vehicle_metrics_recording_description"))
        let font = UIFont.systemFont(ofSize: 17)
        attrStr.addAttribute(.font, value: font, range: NSRange(location: 0, length: attrStr.length))
        attrStr.addAttribute(.foregroundColor, value: UIColor.textColorSecondary, range: NSRange(location: 0, length: attrStr.length))
        return attrStr
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        for category in RecordingCategory.allCases {
            let section = tableData.createNewSection()
            section.headerText = category.title
            for item in category.items {
                let row = section.createNewRow()
                row.key = item.command
                row.cellType = OASimpleTableViewCell.reuseIdentifier
                row.title = item.name
                row.icon = item.icon
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
        cell.descriptionVisibility(false)
        cell.titleLabel.text = item.title
        cell.leftIconView.image = item.icon
        
        let isSelected = selectionManager.selectedItems.contains(item.key ?? "")
        cell.configureAccessibility(withTitle: item.title, selected: isSelected)
        if isSelected {
            cell.leftIconView.tintColor = .iconColorActive
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
            cell.leftIconView.tintColor = .iconColorDisabled
        }
        
        return cell
    }
    
    override func onRowSelected(_ indexPath: IndexPath?) {
        toggleSelection(at: indexPath)
    }
    
    override func onRowDeselected(_ indexPath: IndexPath?) {
        toggleSelection(at: indexPath)
    }
    
    private func toggleSelection(at indexPath: IndexPath?) {
        guard let indexPath else { return }
        
        let item = tableData.item(for: indexPath)
        guard let command = item.key else { return }
        
        selectionManager.toggle(command)
        updateUIAfterSelectionChange()
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - Toolbar
extension VehicleMetricsTripRecordingCommandsViewController {
    
    private func configureToolbar() {
        let buttonTitle = selectionManager.areAllSelected
        ? localizedString("shared_string_deselect_all")
        : localizedString("shared_string_select_all")
        
        let selectDeselectButton = UIBarButtonItem(
            title: buttonTitle,
            style: .plain,
            target: self,
            action: #selector(toggleSelectAllCommands)
        )
        
        selectDeselectButton.setTitleTextAttributes(
            [.foregroundColor: UIColor.iconColorActive],
            for: .normal
        )
        
        let items = [selectDeselectButton]
        toolbarItems = items
    }
    
    @objc private func toggleSelectAllCommands() {
        if selectionManager.areAllSelected {
            selectionManager.deselectAll()
        } else {
            selectionManager.selectAll()
        }
        configureRightBarButtonState()
        tableView.reloadData()
        configureToolbar()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension VehicleMetricsTripRecordingCommandsViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        if selectionManager.hasChanges {
            presentExitWithoutSavingAlert()
        }
    }
    
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        !selectionManager.hasChanges
    }
}
