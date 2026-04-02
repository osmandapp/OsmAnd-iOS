//
//  WidgetConfigurationViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 23.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

final class WidgetConfigurationViewController: OABaseButtonsViewController, WidgetStateDelegate {
    
    private static let excludedUISettingsWidgetKeys: Set<String> = [WidgetType.nextTurn.id, WidgetType.secondNextTurn.id, WidgetType.smallNextTurn.id]
    
    var widgetInfo: MapWidgetInfo!
    var widgetPanel: WidgetsPanel!
    var selectedAppMode: OAApplicationMode!
    var createNew = false
    var similarAlreadyExist = false
    var widgetKey = ""
    var widgetConfigurationParams: [String: Any]?
    var isFirstGenerateData = true
    var onWidgetStateChangedAction: (() -> Void)?
    var addToNext: Bool?
    var selectedWidget: String?
    
    var isCreateNewAndSimilarAlreadyExist: Bool {
        createNew && similarAlreadyExist
    }
    
    private lazy var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setContentOffset(CGPoint(x: 0, y: 1), animated: false)
        if createNew && !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "") {
            if let selectedAppMode {
                widgetConfigurationParams = ["selectedAppMode": selectedAppMode]
            }
        } else {
            widgetConfigurationParams = [:]
        }
        configureNavigationButtons()
    }
    
    override func registerNotifications() {
        super.registerNotifications()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow(_:)),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
        addCell(OASwitchTableViewCell.reuseIdentifier)
        addCell(OAValueTableViewCell.reuseIdentifier)
        addCell(SegmentImagesWithRightLabelTableViewCell.reuseIdentifier)
        addCell(OAButtonTableViewCell.reuseIdentifier)
        addCell(OAInputTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        // Add section for simple widgets
        if !WidgetType.isComplexWidget(widgetInfo.key) && (!Self.excludedUISettingsWidgetKeys.contains(widgetInfo.key) || widgetPanel.isPanelVertical) {
            if let settingsData = widgetInfo.getSettingsDataForSimpleWidget(selectedAppMode, widgetsPanel: widgetPanel, widgetConfigurationParams) {
                for i in 0 ..< settingsData.sectionCount() {
                    tableData.addSection(settingsData.sectionData(for: i))
                }
            }
        }
        
        if let settingsData = widgetInfo.getSettingsData(selectedAppMode, widgetConfigurationParams, isCreate: createNew) {
            for i in 0 ..< settingsData.sectionCount() {
                tableData.addSection(settingsData.sectionData(for: i))
            }
        }
        
        if !createNew {
            let deleteSection = tableData.createNewSection()
            let deleteRow = deleteSection.createNewRow()
            deleteRow.cellType = OASimpleTableViewCell.getIdentifier()
            deleteRow.key = "delete_widget_key"
            deleteRow.title = localizedString("shared_string_delete")
        }
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell!
        if item.cellType == OASimpleTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.reuseIdentifier, for: indexPath) as! OASimpleTableViewCell
            let hasDescr = item.descr != nil && !item.descr!.isEmpty
            let hasIcon = item.iconName != nil
            cell.descriptionVisibility(hasDescr)
            cell.leftIconVisibility(hasIcon)
            cell.titleLabel.textColor = hasIcon ? .textColorPrimary : .buttonBgColorDisruptive
            cell.titleLabel.text = item.title
            cell.leftIconView.image = UIImage(named: item.iconName ?? "")
            outCell = cell
        } else if item.cellType == OASwitchTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.reuseIdentifier, for: indexPath) as! OASwitchTableViewCell
            cell.descriptionVisibility(false)
            let hasIcon = item.iconName != nil
            cell.titleLabel.text = item.title
            cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
            var selected = false
            if let pref = item.obj(forKey: "pref") as? OACommonBoolean {
                if !createNew {
                    selected = pref.get(selectedAppMode)
                } else {
                    if let value = widgetConfigurationParams?[pref.key] as? Bool {
                        selected = value
                    } else {
                        selected = pref.defValue
                    }
                }
                
                if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? ""), pref.key.hasPrefix("simple_widget_show_icon") {
                    widgetConfigurationParams?["isVisibleIcon"] = selected
                }
            }
            
            cell.switchView.isOn = selected
            cell.leftIconVisibility(hasIcon)
            cell.leftIconView.image = UIImage.templateImageNamed(selected ? item.iconName : item.string(forKey: "hide_icon"))
            cell.leftIconView.tintColor = selected ? selectedAppMode.getProfileColor() : UIColor.iconColorDisabled
            cell.switchView.tag = indexPath.section << 10 | indexPath.row
            cell.switchView.addTarget(self, action: #selector(onSwitchClick(_:)), for: .valueChanged)
            outCell = cell
        } else if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.accessoryType = .disclosureIndicator
            cell.leftIconView.tintColor = selectedAppMode.getProfileColor()
            if item.key == "external_sensor_key" {
                cell.descriptionLabel.text = item.descr
                cell.valueVisibility(false)
                cell.descriptionVisibility(true)
            } else {
                cell.valueVisibility(true)
                cell.descriptionVisibility(false)
            }
            
            cell.valueLabel.text = item.string(forKey: "value")
            if let iconName = item.iconName, !iconName.isEmpty {
                cell.leftIconVisibility(true)
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            } else {
                cell.leftIconVisibility(false)
            }
            cell.titleLabel.text = item.title
            outCell = cell
        } else if item.cellType == SegmentImagesWithRightLabelTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentImagesWithRightLabelTableViewCell.reuseIdentifier) as! SegmentImagesWithRightLabelTableViewCell
            cell.selectionStyle = .none
            if let icons = item.obj(forKey: "values") as? [UIImage],
               let pref = item.obj(forKey: "prefSegment") as? OACommonWidgetSizeStyle {
                var widgetSizeStyle: EOAWidgetSizeStyle = .medium
                if !createNew {
                    widgetSizeStyle = pref.get(selectedAppMode)
                } else {
                    if let rawValue = widgetConfigurationParams?["widgetSizeStyle"] as? Int,
                       let style = EOAWidgetSizeStyle(rawValue: rawValue) {
                        widgetSizeStyle = style
                    } else {
                        if let widgetsPanel = item.obj(forKey: "widgetsPanel") as? WidgetsPanel, !widgetsPanel.isPanelVertical {
                            widgetSizeStyle = .small
                        } else {
                            widgetSizeStyle = .medium
                        }
                    }
                }
                
                if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "") {
                    widgetConfigurationParams?["widgetSizeStyle"] = widgetSizeStyle.rawValue
                }
                cell.configureSegmentedControl(icons: icons, selectedSegmentIndex: widgetSizeStyle.rawValue)
            }
            
            if let title = item.string(forKey: "title") {
                cell.configureTitle(title: title)
            }
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self, let pref = item.obj(forKey: "prefSegment") as? OACommonWidgetSizeStyle else { return }
                if !createNew {
                    pref.set(EOAWidgetSizeStyle(rawValue: index) ?? .medium, mode: selectedAppMode)
                }
                if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "") {
                    widgetConfigurationParams?["widgetSizeStyle"] = index
                }
                if item.string(forKey: "behaviour") == "simpleWidget", !createNew {
                    updateWidgetStyleForRow(with: widgetInfo)
                    OARootViewController.instance().mapPanel.recreateControls()
                }
                if !widgetPanel.isPanelVertical {
                    generateData()
                    tableView.reloadData()
                }
            }
            outCell = cell
        } else if item.cellType == OAButtonTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.reuseIdentifier) as! OAButtonTableViewCell
            let value = item.obj(forKey: "value") as? String
            if cell.contentHeightConstraint == nil {
                let constraint = cell.contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
                constraint.isActive = true
                cell.contentHeightConstraint = constraint
            }
            cell.selectionStyle = .none
            cell.leftIconVisibility(shouldShowLeftIcon(forKey: item.key))
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
            cell.leftIconView.tintColor = selectedAppMode.getProfileColor()
            var config = UIButton.Configuration.plain()
            config.baseForegroundColor = .textColorActive
            config.contentInsets = .zero
            cell.button.configuration = config
            cell.button.menu = buildButtonMenu(for: item, currentValue: value, indexPath: indexPath)
            cell.button.showsMenuAsPrimaryAction = true
            cell.button.changesSelectionAsPrimaryAction = true
            cell.button.setContentHuggingPriority(.required, for: .horizontal)
            cell.button.setContentCompressionResistancePriority(.required, for: .horizontal)
            outCell = cell
        } else if item.cellType == OAInputTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAInputTableViewCell.reuseIdentifier, for: indexPath) as! OAInputTableViewCell
            cell.selectionStyle = .none
            cell.leftIconVisibility(false)
            cell.descriptionVisibility(false)
            cell.titleLabel.text = item.title
            cell.inputFieldVisibility(true)

            let currentValue = item.obj(forKey: "value") as? String ?? ""
            let defaultValue = item.obj(forKey: "default_value") as? String ?? ""
            cell.inputField.text = currentValue
            cell.inputField.placeholder = item.descr
            cell.inputField.keyboardType = .URL
            cell.inputField.autocorrectionType = .no
            cell.inputField.autocapitalizationType = .none
            cell.inputField.returnKeyType = .done
            cell.inputField.delegate = self
            cell.inputField.tag = indexPath.section << 10 | indexPath.row

            let showClear = !currentValue.isEmpty && currentValue != defaultValue
            cell.clearButtonVisibility(showClear)
            cell.clearButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.clearButton.tag = indexPath.section << 10 | indexPath.row
            cell.clearButton.addTarget(self, action: #selector(onClearURLButtonPressed(_:)), for: .touchUpInside)
            cell.clearButtonArea.removeTarget(nil, action: nil, for: .allEvents)
            cell.clearButtonArea.tag = indexPath.section << 10 | indexPath.row
            cell.clearButtonArea.addTarget(self, action: #selector(onClearURLButtonPressed(_:)), for: .touchUpInside)
            outCell = cell
        }
        return outCell
    }
    
    private func shouldShowLeftIcon(forKey key: String?) -> Bool {
        guard let key else { return true }
        let keysWithoutIcon: Set<String> = ["average_obd_mode_key", "fuel_consumption_mode_key", "recording_widget_mode_key"]
        return !keysWithoutIcon.contains(key)
    }
    
    private func buildButtonMenu(for item: OATableRowData, currentValue: String?, indexPath: IndexPath) -> UIMenu? {
        if let pref = item.obj(forKey: "pref") as? OACommonWidgetDisplayPriority, let defValue = RouteInfoDisplayPriority(rawValue: pref.defValue)?.key {
            return createDisplayPriorityMenuWith(value: currentValue ?? defValue, pref: pref, indexPath: indexPath)
        } else if let boolPref = item.obj(forKey: "pref") as? OACommonBoolean, let options = item.obj(forKey: "possible_values") as? [OATableRowData], let currentValue {
            return createBooleanMenuWith(currentValue: currentValue, pref: boolPref, options: options, indexPath: indexPath)
        } else if item.key == "fuel_consumption_mode_key", let pref = item.obj(forKey: "pref") as? OACommonString, let options = item.obj(forKey: "possible_values") as? [OATableRowData], let currentValue {
            return createStringMenuWith(currentValue: currentValue, pref: pref, options: options, indexPath: indexPath)
        } else if item.key == "recording_widget_mode_key", let pref = item.obj(forKey: "pref") as? OACommonInteger, let options = item.obj(forKey: "possible_values") as? [OATableRowData], let currentValue {
            return createIntegerMenuWith(currentValue: currentValue, pref: pref, options: options, indexPath: indexPath)
        }
        
        return nil
    }
    
    private func createDisplayPriorityMenuWith(value: String, pref: OACommonWidgetDisplayPriority, indexPath: IndexPath) -> UIMenu {
        let actions = RouteInfoDisplayPriority.allCases.map { displayPriority in
            UIAction(title: displayPriority.title,
                     image: UIImage.templateImageNamed(displayPriority.iconName),
                     state: displayPriority.key == value ? .on : .off) { [weak self] _ in
                guard let self else { return }
                
                if createNew {
                    widgetConfigurationParams?[pref.key] = displayPriority.key
                } else {
                    pref.setValueFrom(displayPriority.key, appMode: selectedAppMode)
                }
                generateData()
                onWidgetStateChangedAction?()
                tableView.reloadData()
            }
        }
        return UIMenu(options: .singleSelection, children: actions)
    }
    
    private func createBooleanMenuWith(currentValue: String, pref: OACommonBoolean, options: [OATableRowData], indexPath: IndexPath) -> UIMenu {
        let actions = options.compactMap { row -> UIAction? in
            guard let title = row.title?.trimmingCharacters(in: .whitespaces), !title.isEmpty else { return nil }
            let state: UIMenuElement.State = title == currentValue ? .on : .off
            return UIAction(title: title, image: UIImage.templateImageNamed(row.iconName), state: state) { [weak self] _ in
                guard let self else { return }
                let newBool = ((row.obj(forKey: "value") as? Int) ?? 0) == 1
                if self.createNew {
                    self.widgetConfigurationParams?[pref.key] = newBool
                } else {
                    pref.set(newBool)
                }
                
                self.onWidgetStateChanged()
            }
        }
        
        return UIMenu(options: .singleSelection, children: actions)
    }
        
    private func createStringMenuWith(currentValue: String, pref: OACommonString, options: [OATableRowData], indexPath: IndexPath) -> UIMenu {
        let actions = options.compactMap { row -> UIAction? in
            guard let title = row.title?.trimmingCharacters(in: .whitespaces), !title.isEmpty else { return nil }
            let raw = row.obj(forKey: "value") as? String ?? ""
            let state: UIMenuElement.State = raw == currentValue ? .on : .off
            return UIAction(title: title, state: state) { [weak self] _ in
                guard let self else { return }
                if self.createNew {
                    self.widgetConfigurationParams?[pref.key] = raw
                } else {
                    pref.set(raw)
                }
                
                self.onWidgetStateChanged()
            }
        }
        
        return UIMenu(options: .singleSelection, children: actions)
    }
    
    private func createIntegerMenuWith(currentValue: String, pref: OACommonInteger, options: [OATableRowData], indexPath: IndexPath) -> UIMenu {
        let actions = options.compactMap { row -> UIAction? in
            guard let title = row.title?.trimmingCharacters(in: .whitespaces), !title.isEmpty else { return nil }
            let state: UIMenuElement.State = title == currentValue ? .on : .off
            return UIAction(title: title, state: state) { [weak self] _ in
                guard let self else { return }
                let newRaw = (row.obj(forKey: "value") as? Int) ?? 0
                if self.createNew {
                    self.widgetConfigurationParams?[pref.key] = "\(newRaw)"
                } else {
                    pref.set(Int32(newRaw))
                }
                
                self.onWidgetStateChanged()
            }
        }
        
        return UIMenu(options: .singleSelection, children: actions)
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if widgetInfo.handleRowSelected(item, viewController: self) {
            return
        }
        if item.key == "delete_widget_key" {
            onWidgetDeleted()
        } else if item.key == "value_pref" {
            let possibleValues = item.obj(forKey: "possible_values") as? [OATableRowData]
            if let possibleValues {
                let vc = WidgetParameterViewController()
                vc.delegate = self
                vc.isCreateNew = createNew
                let section = vc.tableData.createNewSection()
                section.addRows(possibleValues)
                section.footerText = (item.obj(forKey: "footer") as? String) ?? ""
                vc.appMode = selectedAppMode
                vc.screenTitle = item.descr ?? item.title
                vc.pref = item.obj(forKey: "pref") as? OACommonPreference
                if let widgetConfigurationParams, let pref = vc.pref, let value = widgetConfigurationParams[pref.key] {
                    vc.widgetConfigurationParams = [pref.key: value]
                } else {
                    vc.widgetConfigurationParams = [:]
                }
                vc.onWidgetChangeParamsAction = { [weak self] params in
                    guard let self,
                          let result = params.first else { return }
                    widgetConfigurationParams?[result.key] = result.value
                }
                showMediumSheetViewController(vc, isLargeAvailable: false)
            }
        } else if item.key == "external_sensor_key" {
            let storyboard = UIStoryboard(name: "BLEPairedSensors", bundle: nil)
            if let controller = storyboard.instantiateViewController(withIdentifier: "BLEPairedSensors") as? BLEPairedSensorsViewController {
                controller.pairedSensorsType = .widget
                controller.appMode = OAAppSettings.sharedManager().applicationMode.get()
                if let widget = widgetInfo?.widget as? SensorTextWidget {
                    controller.widgetType = widget.widgetType
                    controller.widget = widget
                }
                controller.onSelectDeviceAction = { [weak self] device in
                    guard let self else { return }
                    if createNew {
                        // Pairing widget with selected device
                        widgetConfigurationParams?[SensorTextWidget.externalDeviceIdConst] = device.id
                    }
                    generateData()
                    tableView.reloadData()
                }
                controller.onSelectCommonOptionsAction = { [weak self] in
                    guard let self else { return }
                    generateData()
                    tableView.reloadData()
                }
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    func onWidgetStateChanged() {
        isFirstGenerateData = false
        if widgetInfo.key == WidgetType.markersTopBar.id || widgetInfo.key.hasPrefix(WidgetType.markersTopBar.id + MapWidgetInfo.DELIMITER) {
            OsmAndApp.swiftInstance().data.destinationsChangeObservable.notifyEvent()
        } else if widgetInfo.key == WidgetType.radiusRuler.id || widgetInfo.key.hasPrefix(WidgetType.radiusRuler.id + MapWidgetInfo.DELIMITER) {
            (widgetInfo.widget as? RulerDistanceWidget)?.updateRulerObservable.notifyEvent()
        } else if let textWidget = self.widgetInfo.widget as? OBDTextWidget {
            textWidget.updatePrefs(prefsChanged: true)
        }
        generateData()
        onWidgetStateChangedAction?()
        tableView.reloadData()
    }
    
    private func configureNavigationButtons() {
        if navigationController?.viewControllers.count == 1 {
            navigationItem.setLeftBarButton(nil, animated: false)
            navigationItem.setRightBarButton(UIBarButtonItem(title: localizedString("shared_string_done"),
                                                             style: .plain,
                                                             target: self,
                                                             action: #selector(onRightNavbarButtonPressed)),
                                             animated: false)
        } else {
            navigationItem.setRightBarButton(nil, animated: false)
        }
    }
    
    private func onWidgetDeleted() {
        let alert = WidgetUtils.deleteWidgetAlert(with: selectedAppMode, widgetInfo: widgetInfo, completion: dismiss)
        present(alert, animated: true)
    }
    
    private func updateWidgetStyleForRow(with mapWidgetInfo: MapWidgetInfo) {
        let enabledWidgetsFilter = Int(KWidgetModeAvailable | kWidgetModeEnabled | kWidgetModeMatchingPanels)
        guard let pagedWidgets = widgetRegistry.getPagedWidgets(forPanel: selectedAppMode,
                                                                panel: widgetPanel,
                                                                filterModes: enabledWidgetsFilter),
              let widget = mapWidgetInfo.widget as? OATextInfoWidget else {
            return
        }
        
        guard widgetPanel.isPanelVertical else {
            (pagedWidgets
                .compactMap { $0.array as? [MapWidgetInfo] }
                .first { $0.contains { $0.key == mapWidgetInfo.key } }?
                .first { $0.key == mapWidgetInfo.key }?
                .widget as? OATextInfoWidget)?
                .updateWith(style: widget.widgetSizeStyle, appMode: selectedAppMode)
            return
        }

        pagedWidgets
            .compactMap { $0.array as? [MapWidgetInfo] }
            .first { $0.contains { $0.key == mapWidgetInfo.key } }?
            .compactMap { $0.widget as? OATextInfoWidget }
            .forEach { $0.updateWith(style: widget.widgetSizeStyle, appMode: selectedAppMode) }
    }
    
    @objc private func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData.item(for: indexPath)
        
        let pref = data.obj(forKey: "pref") as! OACommonBoolean
        if !createNew {
            pref.set(sw.isOn, mode: selectedAppMode)
        }
        widgetConfigurationParams?[pref.key] = sw.isOn
        
        if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? ""), pref.key.hasPrefix("simple_widget_show_icon") {
            widgetConfigurationParams?["isVisibleIcon"] = sw.isOn
        }
        
        if let textInfoWidget = widgetInfo.widget as? OATextInfoWidget {
            textInfoWidget.configureSimpleLayout()
        }

        if let cell = tableView.cellForRow(at: indexPath) as? OASwitchTableViewCell, !cell.leftIconView.isHidden {
            UIView.animate(withDuration: 0.2) {
                cell.leftIconView.image = UIImage.templateImageNamed(sw.isOn ? data.iconName : data.string(forKey: "hide_icon"))
                cell.leftIconView.tintColor = sw.isOn ? self.selectedAppMode.getProfileColor() : UIColor.iconColorDisabled
            }
        }
        
        return false
    }

    @objc private func onClearURLButtonPressed(_ sender: UIButton) {
        let indexPath = IndexPath(row: sender.tag & 0x3FF, section: sender.tag >> 10)
        let item = tableData.item(for: indexPath)
        let defaultValue = item.obj(forKey: "default_value") as? String ?? ""

        if let pref = item.obj(forKey: "pref") as? OACommonString {
            if createNew {
                widgetConfigurationParams?[pref.key] = defaultValue
            } else {
                pref.set(defaultValue, mode: selectedAppMode)
            }
        }

        generateData()
        tableView.reloadData()
    }
}

// MARK: - Keyboard Avoidance

extension WidgetConfigurationViewController {

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            var insets = self.tableView.contentInset
            insets.bottom = keyboardFrame.height
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
              let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt else {
            return
        }
        let options = UIView.AnimationOptions(rawValue: curveValue << 16)
        UIView.animate(withDuration: duration, delay: 0, options: options) {
            var insets = self.tableView.contentInset
            insets.bottom = 0
            self.tableView.contentInset = insets
            self.tableView.scrollIndicatorInsets = insets
        }
    }
}

// MARK: - UITextFieldDelegate
extension WidgetConfigurationViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        let indexPath = IndexPath(row: textField.tag & 0x3FF, section: textField.tag >> 10)
        let item = tableData.item(for: indexPath)
        let newValue = textField.text ?? ""

        if let pref = item.obj(forKey: "pref") as? OACommonString {
            if createNew {
                widgetConfigurationParams?[pref.key] = newValue
            } else {
                pref.set(newValue, mode: selectedAppMode)
            }
        }

        generateData()
        tableView.reloadData()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: Appearance
extension WidgetConfigurationViewController {
    
    override func getTitle() -> String {
        if createNew {
            let widgetType = widgetInfo.widget.widgetType
            if widgetType == .sideMarker1 || widgetType == .sideMarker2 {
                return widgetInfo.getWidgetDefaultTitle()
            }
        }
        return widgetInfo.getTitle()
    }
    
    override func getNavbarStyle() -> EOABaseNavbarStyle {
        .largeTitle
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func getTableHeaderDescriptionAttr() -> NSAttributedString {
        guard let widgetType = widgetInfo.getWidgetType() else { return NSAttributedString(string: "") }
        let attrStr = NSMutableAttributedString(string: widgetType.descr)
        // Set font attribute
        let font = UIFont.systemFont(ofSize: 17)
        attrStr.addAttribute(.font, value: font, range: NSRange(location: 0, length: attrStr.length))

        // Set color attribute
        attrStr.addAttribute(.foregroundColor, value: UIColor.textColorSecondary, range: NSRange(location: 0, length: attrStr.length))
        return attrStr
    }

    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .vertical
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .purple
    }
    
    override func onBottomButtonPressed() {
        guard let navigationController else { return }
        
        if let targetViewController = navigationController.viewControllers.compactMap({ $0 as? WidgetsListViewController }).first {
            targetViewController.addWidget(newWidget: widgetInfo, params: widgetConfigurationParams)
            navigationController.popToViewController(targetViewController, animated: true)
        } else {
            if let addToNext, let selectedWidget {
                let newWidgetsInfos = WidgetUtils.createNewWidgets(widgetsIds: [widgetInfo.key],
                                                                   panel: widgetPanel,
                                                                   appMode: selectedAppMode,
                                                                   selectedWidget: selectedWidget,
                                                                   widgetParams: widgetConfigurationParams,
                                                                   addToNext: addToNext)
                if let info = newWidgetsInfos.first, info.widgetPanel.isPanelVertical {
                    updateWidgetStyleForRow(with: info)
                    OARootViewController.instance().mapPanel.recreateControls()
                }
            }
            navigationController.dismiss(animated: true)
        }
    }

    override func getBottomButtonTitleAttr() -> NSAttributedString? {
        guard createNew else { return nil }
        // Create the attributed string with the desired text and attributes
        let text = "  " + localizedString("add_widget")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.buttonTextColorPrimary
        ]
        let attributedString = NSMutableAttributedString(string: text, attributes: attributes)

        // Create the attachment with the "plus.circle.fill" system icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 24)
        let plusCircleFillImage = UIImage(systemName: "plus.circle.fill", withConfiguration: configuration)
        let attachment = NSTextAttachment()
        attachment.image = plusCircleFillImage?.withTintColor(.buttonTextColorPrimary, renderingMode: .alwaysOriginal)

        // Set the bounds of the attachment to match the font size of the attributed string
        if let font = attributes[.font] as? UIFont {
            let fontHeight = font.lineHeight
            let attachmentHeight = attachment.image!.size.height
            let yOffset = (fontHeight - attachmentHeight) / 2.0
            attachment.bounds = CGRect(x: 0, y: yOffset, width: attachment.image!.size.width, height: attachmentHeight)
            attachment.bounds.origin.y += font.descender // Adjust the baseline offset of the attachment
        }

        // Create an attributed string from the attachment
        let attachmentString = NSAttributedString(attachment: attachment)

        // Append the attachment string to the original attributed string
        attributedString.insert(attachmentString, at: 0)
        
        return attributedString
    }
}
