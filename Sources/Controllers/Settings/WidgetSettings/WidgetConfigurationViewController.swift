//
//  WidgetConfigurationViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 23.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let SimpleWidgetStyleUpdated = NSNotification.Name("SimpleWidgetStyleUpdated")
}

@objc(OAWidgetConfigurationViewController)
@objcMembers
class WidgetConfigurationViewController: OABaseButtonsViewController, WidgetStateDelegate {
    
    var widgetInfo: MapWidgetInfo!
    var widgetPanel: WidgetsPanel!
    var selectedAppMode: OAApplicationMode!
    var createNew = false
    var similarAlreadyExist = false
    var widgetKey = ""
    var widgetConfigurationParams: [String: Any]?
    var isFirstGenerateData = true
    
    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setContentOffset(CGPoint(x: 0, y: 1), animated: false)
        
        tableView.register(UINib(nibName: SegmentImagesWithRightLableTableViewCell.reuseIdentifier, bundle: nil), forCellReuseIdentifier: SegmentImagesWithRightLableTableViewCell.reuseIdentifier)
        
        if isCreateNewAndSimilarAlreadyExist || (createNew && !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "")) {
            widgetConfigurationParams = ["selectedAppMode": selectedAppMode!]
        }
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
        
        if let settingsData = widgetInfo.getSettingsData(selectedAppMode) {
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
                let pref = item.obj(forKey: "pref") as? OACommonBoolean
                let hasIcon = item.iconName != nil
                cell.titleLabel.text = item.title
                cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
                var selected = pref?.get(selectedAppMode) ?? false
                if isCreateNewAndSimilarAlreadyExist {
                    if widgetKey == WidgetType.averageSpeed.id {
                        if isFirstGenerateData {
                            widgetConfigurationParams?[AverageSpeedWidget.SKIP_STOPS_PREF_ID] = selected
                        } else {
                            selected = widgetConfigurationParams?[AverageSpeedWidget.SKIP_STOPS_PREF_ID] as? Bool ?? false
                        }
                    } else {
                        fatalError("You need implement value handler for widgetKey")
                    }
                }
                if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "") {
                    widgetConfigurationParams?["isVisibleIcon"] = selected
                }
                cell.switchView.isOn = selected
                cell.leftIconVisibility(hasIcon)
                cell.leftIconView.image = UIImage.templateImageNamed(selected ? item.iconName : item.string(forKey: "hide_icon"))
                cell.leftIconView.tintColor = selected ? UIColor(rgb: Int(selectedAppMode.getIconColor())) : UIColor.iconColorDisabled

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
                cell?.leftIconView.tintColor = UIColor(rgb: Int(selectedAppMode.getIconColor()))
            }
            if let cell {
                if item.key == "external_sensor_key" {
                    cell.descriptionLabel.text = item.descr
                    cell.valueVisibility(false)
                    cell.descriptionVisibility(true)
                } else {
                    cell.descriptionVisibility(false)
                }
                if isCreateNewAndSimilarAlreadyExist {
                    var value: String
                    if isFirstGenerateData {
                        guard let pref = item.obj(forKey: "pref") as? OACommonPreference,
                              let prefLong = pref as? OACommonLong else {
                            return nil
                        }
                        let param = String(prefLong.get(selectedAppMode))
                        value = item.string(forKey: "value")!
                        if widgetKey == WidgetType.averageSpeed.id {
                            widgetConfigurationParams?[AverageSpeedWidget.MEASURED_INTERVAL_PREF_ID] = param
                        } else {
                            fatalError("You need implement value handler for widgetKey")
                        }
                    } else {
                        var _value = ""
                        if widgetKey == WidgetType.averageSpeed.id {
                            _value = widgetConfigurationParams?[AverageSpeedWidget.MEASURED_INTERVAL_PREF_ID] as? String ?? "0"
                            value = AverageSpeedWidget.getIntervalTitle(Int(_value)!)
                        } else {
                            fatalError("You need implement value handler for widgetKey")
                        }
                    }
                    cell.valueLabel.text = value
                } else {
                    cell.valueLabel.text = item.string(forKey: "value")
                }
                if let iconName = item.iconName, !iconName.isEmpty {
                    cell.leftIconVisibility(true)
                    cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
                } else {
                    cell.leftIconVisibility(false)
                }
                cell.titleLabel.text = item.title
            }
            outCell = cell
        } else if item.cellType == SegmentImagesWithRightLableTableViewCell.getIdentifier() {
            let cell = tableView.dequeueReusableCell(withIdentifier: SegmentImagesWithRightLableTableViewCell.reuseIdentifier) as! SegmentImagesWithRightLableTableViewCell
            cell.selectionStyle = .none
            if let icons = item.obj(forKey: "values") as? [String],
               let pref = item.obj(forKey: "prefSegment") as? OACommonInteger {
                let widgetSizeStyle = pref.get(selectedAppMode)
                if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "") {
                    widgetConfigurationParams?["widgetSizeStyle"] = widgetSizeStyle
                }
                cell.configureSegmenedtControl(icons: icons, selectedSegmentIndex: Int(widgetSizeStyle))
            }
            if let title = item.string(forKey: "title") {
                cell.configureTitle(title: title)
            }
            cell.didSelectSegmentIndex = { [weak self] index in
                guard let self,
                      let pref = item.obj(forKey: "prefSegment") as? OACommonInteger else { return }
                pref.set(Int32(index), mode: selectedAppMode)
                if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "") {
                    widgetConfigurationParams?["widgetSizeStyle"] = index
                }
                if item.string(forKey: "behaviour") == "simpleWidget" {
                    NotificationCenter.default.post(name: .SimpleWidgetStyleUpdated,
                                                    object: widgetInfo,
                                                    userInfo: nil)
                }
            }
            outCell = cell
        }
        return outCell
    }
    
    var isCreateNewAndSimilarAlreadyExist: Bool {
        createNew && similarAlreadyExist
    }
    
    @objc func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData!.item(for: indexPath)
        
        if isCreateNewAndSimilarAlreadyExist {
            if widgetKey == WidgetType.averageSpeed.id {
                widgetConfigurationParams?[AverageSpeedWidget.SKIP_STOPS_PREF_ID] = sw.isOn
            } else {
                fatalError("You need implement value handler for widgetKey")
            }
        } else {
            let pref = data.obj(forKey: "pref") as! OACommonBoolean
            pref.set(sw.isOn, mode: selectedAppMode)
        }
        if createNew, !WidgetType.isComplexWidget(widgetInfo.widget.widgetType?.id ?? "") {
            widgetConfigurationParams?["isVisibleIcon"] = sw.isOn
        }
        if let cell = self.tableView.cellForRow(at: indexPath) as? OASwitchTableViewCell, !cell.leftIconView.isHidden {
            UIView.animate(withDuration: 0.2) {
                cell.leftIconView.image = UIImage.templateImageNamed(sw.isOn ? data.iconName : data.string(forKey: "hide_icon"))
                cell.leftIconView.tintColor = sw.isOn ? UIColor(rgb: Int(self.selectedAppMode.getIconColor())) : UIColor.iconColorDisabled
            }
        }
        
        return false
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if item.key == "delete_widget_key" {
            onWidgetDeleted()
            dismiss()
        } else if item.key == "value_pref" {
            let possibleValues = item.obj(forKey: "possible_values") as? [OATableRowData]
            if let possibleValues {
                let vc = WidgetParameterViewController()
                vc.delegate = self
                let section = vc.tableData.createNewSection()
                section.addRows(possibleValues)
                section.footerText = (item.obj(forKey: "footer") as? String) ?? ""
                vc.appMode = selectedAppMode
                vc.screenTitle = item.descr
                if isCreateNewAndSimilarAlreadyExist {
                    guard let pref = item.obj(forKey: "pref") as? OACommonPreference,
                          let prefLong = pref as? OACommonLong else {
                        return
                    }
                    var value: Int?
                    if isFirstGenerateData {
                        value = Int(prefLong.get(selectedAppMode))
                        if widgetKey == WidgetType.averageSpeed.id {
                            widgetConfigurationParams?[AverageSpeedWidget.MEASURED_INTERVAL_PREF_ID] = String(value ?? 0)
                        } else {
                            fatalError("You need implement value handler for widgetKey")
                        }
                    }
                    if widgetKey == WidgetType.averageSpeed.id {
                        vc.widgetConfigurationSelectedValue = widgetConfigurationParams?[AverageSpeedWidget.MEASURED_INTERVAL_PREF_ID] as? String ?? ""
                    } else {
                        fatalError("You need implement value handler for widgetKey")
                    }
                    vc.onWidgetConfigurationParamsAction = { [weak self] result in
                        guard let self else { return }
                        if widgetKey == WidgetType.averageSpeed.id {
                            widgetConfigurationParams?[AverageSpeedWidget.MEASURED_INTERVAL_PREF_ID] = result ?? ""
                        } else {
                            fatalError("You need implement value handler for widgetKey")
                        }
                    }
                } else {
                    vc.pref = item.obj(forKey: "pref") as? OACommonPreference
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
                    if isCreateNewAndSimilarAlreadyExist {
                        // Pairing widget with selected device
                        widgetConfigurationParams?[SensorTextWidget.externalDeviceIdConst] = device.id
                    }
                    self.generateData()
                    tableView.reloadData()
                }
                controller.onSelectCommonOptionsAction = { [weak self] in
                    guard let self else { return }
                    self.generateData()
                    tableView.reloadData()
                }
                navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    private func onWidgetDeleted() {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
        widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: widgetInfo, enabled: NSNumber(value: false), recreateControls: true)
    }
    
    func onWidgetStateChanged() {
        isFirstGenerateData = false
        if widgetInfo.key == WidgetType.markersTopBar.id || widgetInfo.key.hasPrefix(WidgetType.markersTopBar.id + MapWidgetInfo.DELIMITER) {
            OsmAndApp.swiftInstance().data.destinationsChangeObservable.notifyEvent()
        } else if widgetInfo.key == WidgetType.radiusRuler.id || widgetInfo.key.hasPrefix(WidgetType.radiusRuler.id + MapWidgetInfo.DELIMITER) {
            (widgetInfo.widget as? RulerDistanceWidget)?.updateRulerObservable.notifyEvent()
        }
        generateData()
        tableView.reloadData()
    }
}

// MARK: Appearance
extension WidgetConfigurationViewController {
    
    override func getTitle() -> String! {
        widgetInfo.getTitle()
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
        NotificationCenter.default.post(name: NSNotification.Name(WidgetsListViewController.kWidgetAddedNotification),
                                        object: self.widgetInfo,
                                        userInfo: self.widgetConfigurationParams)
        UIView.animate(withDuration: 0) {
            if let viewControllers = self.navigationController?.viewControllers {
                for viewController in viewControllers {
                    if let targetViewController = viewController as? WidgetsListViewController {
                        self.navigationController?.popToViewController(targetViewController, animated: true)
                        break
                    }
                }
            }
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
