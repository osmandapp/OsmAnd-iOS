//
//  WidgetConfigurationViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 23.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

final class WidgetConfigurationViewController: OABaseButtonsViewController, WidgetStateDelegate {
    
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
    
    override func registerCells() {
        addCell(SegmentImagesWithRightLabelTableViewCell.reuseIdentifier)
    }
    
    override func generateData() {
        tableData.clearAllData()
        // Add section for simple widgets
        if !WidgetType.isComplexWidget(widgetInfo.key), widgetPanel == .topPanel || widgetPanel == .bottomPanel {
            if let settingsData = widgetInfo.getSettingsDataForSimpleWidget(selectedAppMode) {
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
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell!
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
            }
            if let cell = cell {
                let hasDescr = item.descr != nil && !item.descr!.isEmpty
                let hasIcon = item.iconName != nil
                cell.descriptionVisibility(hasDescr)
                cell.leftIconVisibility(hasIcon)
                cell.titleLabel.textColor = hasIcon ? .textColorPrimary : .buttonBgColorDisruptive
                cell.titleLabel.text = item.title
                cell.leftIconView.image = UIImage(named: item.iconName ?? "")
            }
            outCell = cell
        } else if item.cellType == OASwitchTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASwitchTableViewCell.getIdentifier()) as? OASwitchTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASwitchTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASwitchTableViewCell
                cell?.descriptionVisibility(false)
            }
            if let cell {
                let hasIcon = item.iconName != nil
                cell.titleLabel.text = item.title
                cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
                var selected = false
                if let pref = item.obj(forKey: "pref") as? OACommonBoolean {
                    if !createNew {
                        selected = pref.get(selectedAppMode)
                    } else {
                        if let prefKey = pref.key,
                           let value = widgetConfigurationParams?[prefKey] as? Bool {
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
            }
        } else if item.cellType == OAValueTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.getIdentifier()) as? OAValueTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAValueTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAValueTableViewCell
                cell?.accessoryType = .disclosureIndicator
                cell?.leftIconView.tintColor = selectedAppMode.getProfileColor()
            }
            if let cell {
                if item.key == "external_sensor_key" {
                    cell.descriptionLabel.text = item.descr
                    cell.valueVisibility(false)
                    cell.descriptionVisibility(true)
                } else {
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
            }
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
                    if let prefKey = pref.key,
                       let rawValue = widgetConfigurationParams?["widgetSizeStyle"] as? Int,
                       let style = EOAWidgetSizeStyle(rawValue: rawValue) {
                        widgetSizeStyle = style
                    } else {
                        widgetSizeStyle = EOAWidgetSizeStyle(rawValue: Int(pref.defValue)) ?? .medium
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
                guard let self,
                      let pref = item.obj(forKey: "prefSegment") as? OACommonWidgetSizeStyle else { return }
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
            }
            outCell = cell
        }
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if (widgetInfo.handleRowSelected(item, viewController: self)) {
            return
        }
        if item.key == "delete_widget_key" {
            onWidgetDeleted()
            dismiss()
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
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
        widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: widgetInfo, enabled: false, recreateControls: true)
    }
    
    private func updateWidgetStyleForRow(with mapWidgetInfo: MapWidgetInfo) {
        let enabledWidgetsFilter = Int(KWidgetModeAvailable | kWidgetModeEnabled | kWidgetModeMatchingPanels)
        guard let pagedWidgets = widgetRegistry.getPagedWidgets(forPanel: selectedAppMode,
                                                                panel: widgetPanel,
                                                                filterModes: enabledWidgetsFilter),
              let widget = widgetInfo.widget as? OATextInfoWidget else {
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
        let data = tableData!.item(for: indexPath)
        
        let pref = data.obj(forKey: "pref") as! OACommonBoolean
        if !createNew {
            pref.set(sw.isOn, mode: selectedAppMode)
        }
        widgetConfigurationParams?[pref.key] = sw.isOn
        
        if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? ""), pref.key.hasPrefix("simple_widget_show_icon") {
            widgetConfigurationParams?["isVisibleIcon"] = sw.isOn
        }
        if let cell = tableView.cellForRow(at: indexPath) as? OASwitchTableViewCell, !cell.leftIconView.isHidden {
            UIView.animate(withDuration: 0.2) {
                cell.leftIconView.image = UIImage.templateImageNamed(sw.isOn ? data.iconName : data.string(forKey: "hide_icon"))
                cell.leftIconView.tintColor = sw.isOn ? self.selectedAppMode.getProfileColor() : UIColor.iconColorDisabled
            }
        }
        
        return false
    }
}

// MARK: Appearance
extension WidgetConfigurationViewController {
    
    override func getTitle() -> String! {
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
    
    override func getTableHeaderDescriptionAttr() -> NSAttributedString! {
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
                }
            }
            navigationController.dismiss(animated: true)
        }
    }

    override func getBottomButtonTitleAttr() -> NSAttributedString! {
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
