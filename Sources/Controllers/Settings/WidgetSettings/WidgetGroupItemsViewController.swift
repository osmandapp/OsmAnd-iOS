//
//  WidgetGroupItemsViewController.swift
//  OsmAnd Maps
//
//  Created by Paul on 27.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import Foundation

@objc(OAWidgetGroupItemsViewController)
@objcMembers
class WidgetGroupItemsViewController: OABaseNavbarViewController {
    
    var widgetGroup: WidgetGroup!
    var widgetPanel: WidgetsPanel!
    var addToNext: Bool?
    var selectedWidget: String?
    
    lazy private var widgetRegistry = OARootViewController.instance().mapPanel.mapWidgetRegistry
    
    override func generateData() {
        let section = tableData.createNewSection()
        let sortedWidgets = widgetGroup.getWidgets().sorted { $0.ordinal < $1.ordinal }
        for widget in sortedWidgets {
            let widgetInfo = widgetRegistry.getWidgetInfo(for: widget)
            guard let widgetInfo else { continue }
            let row = section.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.title = widget == .sunPosition ? widgetInfo.getStateIndependentTitle() : widgetInfo.getTitle()
            row.iconName = widgetInfo.widget.widgetType?.iconName
            row.setObj(widgetInfo, forKey: "widget_info")
            row.setObj(widget, forKey: "widget_type")
        }
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell?
        if item.cellType == OASimpleTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier()) as? OASimpleTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASimpleTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASimpleTableViewCell
                cell?.descriptionVisibility(false)
                cell?.accessoryType = .disclosureIndicator
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.leftIconView.image = UIImage(named: item.iconName ?? "")
                
                cell.accessoryView = nil
                if let widgetType = item.obj(forKey: "widget_type") as? WidgetType, !widgetType.isPurchased() {
                    cell.accessoryView = UIImageView(image: .icPaymentLabelPro)
                }
            }
            outCell = cell
        }
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let widgetInfo = item.obj(forKey: "widget_info") as? MapWidgetInfo {
            if let widgetType = item.obj(forKey: "widget_type") as? WidgetType {
                if widgetType.isPurchased() {
                    guard let vc = WidgetConfigurationViewController() else {
                        return
                    }
                    vc.selectedAppMode = OAAppSettings.sharedManager().applicationMode.get()
                    vc.widgetInfo = widgetInfo
                    vc.widgetPanel = widgetPanel
                    vc.addToNext = addToNext
                    vc.selectedWidget = selectedWidget
                    vc.createNew = true
                    navigationController?.pushViewController(vc, animated: true)
                } else if widgetType == .altitudeMapCenter {
                    if let navigationController {
                        OAChoosePlanHelper.showChoosePlanScreen(with: OAFeature.advanced_WIDGETS(), navController: navigationController)
                    }
                }
            }
        }
    }
}

// MARK: Appearance
extension WidgetGroupItemsViewController {
    
    override func getTitle() -> String! {
        widgetGroup.title
    }
    
    override func getNavbarStyle() -> EOABaseNavbarStyle {
        .largeTitle
    }
    
    override func isNavbarSeparatorVisible() -> Bool {
        false
    }
    
    override func getTableHeaderDescriptionAttr() -> NSAttributedString! {
        let attrStr = NSMutableAttributedString(string: widgetGroup.descr ?? "")
        // Set font attribute
        let font = UIFont.systemFont(ofSize: 17)
        attrStr.addAttribute(.font, value: font, range: NSRange(location: 0, length: attrStr.length))

        // Set color attribute
        attrStr.addAttribute(.foregroundColor, value: UIColor.textColorSecondary, range: NSRange(location: 0, length: attrStr.length))
        return attrStr
    }
}
