//
//  WidgetConfigurationViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 23.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetConfigurationViewController)
@objcMembers
class WidgetConfigurationViewController: OABaseButtonsViewController, WidgetStateDelegate {
    
    var widgetInfo: MapWidgetInfo!
    var widgetPanel: WidgetsPanel!
    var selectedAppMode: OAApplicationMode!
    var createNew = false
    
    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.setContentOffset(CGPoint(x: 0, y: 1), animated: false)
    }
    
    override func generateData() {
        tableData.clearAllData()
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
        if (item.cellType == OASimpleTableViewCell.getIdentifier()) {
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
                cell.titleLabel.textColor = hasIcon ? .black : UIColor(rgb: Int( color_primary_red))
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
                let pref = item.obj(forKey: "pref") as! OACommonBoolean
                let hasIcon = item.iconName != nil
                cell.titleLabel.text = item.title
                cell.switchView.removeTarget(nil, action: nil, for: .allEvents)
                let selected = pref.get(selectedAppMode)
                cell.switchView.isOn = selected
                cell.leftIconVisibility(hasIcon)
                cell.leftIconView.image = UIImage.templateImageNamed(selected ? item.iconName : item.string(forKey: "hide_icon"))
                cell.leftIconView.tintColor = UIColor(rgb: selected ? Int(selectedAppMode.getIconColor()) : Int(color_tint_gray))

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
                cell?.descriptionVisibility(false)
                cell?.leftIconView.tintColor = UIColor(rgb: Int(selectedAppMode.getIconColor()))
            }
            if let cell {
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
        }
        return outCell
    }
    
    @objc func onSwitchClick(_ sender: Any) -> Bool {
        guard let sw = sender as? UISwitch else {
            return false
        }
        
        let indexPath = IndexPath(row: sw.tag & 0x3FF, section: sw.tag >> 10)
        let data = tableData!.item(for: indexPath)
        
        let pref = data.obj(forKey: "pref") as! OACommonBoolean
        pref.set(sw.isOn, mode: selectedAppMode)
        
        if let cell = self.tableView.cellForRow(at: indexPath) as? OASwitchTableViewCell, !cell.leftIconView.isHidden {
            UIView.animate(withDuration: 0.2) {
                cell.leftIconView.image = UIImage.templateImageNamed(sw.isOn ? data.iconName : data.string(forKey: "hide_icon"))
                cell.leftIconView.tintColor = UIColor(rgb: sw.isOn ? Int(self.selectedAppMode.getIconColor()) : Int(color_tint_gray))
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
                vc.pref = item.obj(forKey: "pref") as? OACommonPreference
                showMediumSheetViewController(vc, isLargeAvailable: false)
            }
        }
    }
    
    private func onWidgetDeleted() {
        let widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry!
        widgetRegistry.enableDisableWidget(for: selectedAppMode, widgetInfo: widgetInfo, enabled: NSNumber(value: false), recreateControls: true)
    }
    
    func onWidgetStateChanged() {
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
        attrStr.addAttribute(.foregroundColor, value: UIColor(rgb: Int(color_text_footer)), range: NSRange(location: 0, length: attrStr.length))
        return attrStr
    }

    override func getBottomAxisMode() -> NSLayoutConstraint.Axis {
        .vertical
    }
    
    override func getBottomButtonColorScheme() -> EOABaseButtonColorScheme {
        .purple
    }
    
    override func onBottomButtonPressed() {
        UIView.animate(withDuration: 0) {
            if let viewControllers = self.navigationController?.viewControllers {
                for viewController in viewControllers {
                    if let targetViewController = viewController as? WidgetsListViewController {
                        self.navigationController?.popToViewController(targetViewController, animated: true)
                        break
                    }
                }
            }
        } completion: { Bool in
            NotificationCenter.default.post(name: NSNotification.Name(WidgetsListViewController.kWidgetAddedNotification), object: self.widgetInfo)
        }
    }

    override func getBottomButtonTitleAttr() -> NSAttributedString! {
        
        guard createNew else { return nil }
        // Create the attributed string with the desired text and attributes
        let text = "  " + localizedString("add_widget")
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 17),
            .foregroundColor: UIColor.white
        ]
        let attributedString = NSMutableAttributedString(string: text, attributes: attributes)

        // Create the attachment with the "plus.circle.fill" system icon
        let configuration = UIImage.SymbolConfiguration(pointSize: 24)
        let plusCircleFillImage = UIImage(systemName: "plus.circle.fill", withConfiguration: configuration)
        let attachment = NSTextAttachment()
        attachment.image = plusCircleFillImage?.withTintColor(.white, renderingMode: .alwaysOriginal)

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
