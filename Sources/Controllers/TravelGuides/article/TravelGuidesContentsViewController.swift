//
//  TravelGuidesContentsViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelGuidesContentsViewController : OABaseButtonsViewController {
    
    var article: TravelArticle
    var selectedLang: String
    var items: TravelContentItem
    var cellOpeningStatuses: [Bool]
    
    required init?(coder: NSCoder) {
        self.article = TravelArticle()
        self.selectedLang = ""
        self.items = TravelContentItem(name: "", link: nil)
        cellOpeningStatuses = []
        super.init(coder: coder)
    }
    
    init(article: TravelArticle, selectedLang: String) {
        self.article = article
        self.selectedLang = selectedLang
        self.items = TravelJsonParser.parseJsonContents(jsonText: article.contentsJson ?? "")
        
        cellOpeningStatuses = []
        for _ in self.items.subItems {
            cellOpeningStatuses.append(false)
        }
        
        super.init()
    }
    
    //MARK: Base UI setup
    
    override func getTitle() -> String! {
        return localizedString("shared_string_contents")
    }
    
    override func getBottomButtonTitle() -> String! {
        return localizedString("shared_string_close")
    }
    
    
    override func generateData() {
        tableData.clearAllData()

        for i in 0..<items.subItems.count {
            
            let section = tableData.createNewSection()
            let opened = cellOpeningStatuses[i]
            
            let headerItem = items.subItems[i]
            let headerRow = section.createNewRow()
            headerRow.cellType = OASelectionCollapsableCell.getIdentifier()
            headerRow.title = headerItem.name
            headerRow.iconName = "ic_action_route_first_intermediate"
            headerRow.setObj(true, forKey: "isHeader")
            if headerItem.subItems.count > 0 {
                let arrowIconName = opened ? "ic_custom_arrow_up" : "ic_custom_arrow_down"
                headerRow.setObj(arrowIconName, forKey: "rightIconName")
            }
            
            if opened && headerItem.subItems.count > 0 {
                for subheaderItem in headerItem.subItems {
                    let subheaderRow = section.createNewRow()
                    subheaderRow.cellType = OASelectionCollapsableCell.getIdentifier()
                    subheaderRow.title = subheaderItem.name
                    subheaderRow.setObj(false, forKey: "isHeader")
                }
            }
        }
    }
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == OASelectionCollapsableCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OASelectionCollapsableCell.getIdentifier()) as? OASelectionCollapsableCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OASelectionCollapsableCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OASelectionCollapsableCell
                cell?.selectionStyle = .none
                cell?.separatorInset = .zero
                cell?.showOptionsButton(false)
                cell?.makeSelectable(false)
            }
            if let cell {
                cell.titleView.text = item.title
                
                let isHeader = item.bool(forKey: "isHeader")
                
                if isHeader {
                    cell.titleView.font = UIFont.preferredFont(forTextStyle: .headline)
                    cell.titleView.textColor = UIColor(rgb: color_primary_purple)
                    
                    if let leftIconName = item.iconName {
                        cell.leftIconView.image = UIImage.templateImageNamed(leftIconName)
                        cell.leftIconView.tintColor = UIColor(rgb: color_primary_purple)
                    } else {
                        cell.leftIconView.image = nil
                    }
                    
                    if let rightIconName = item.string(forKey: "rightIconName") {
                        cell.arrowIconView.image = UIImage.templateImageNamed(rightIconName)
                        cell.arrowIconView.tintColor = UIColor(rgb: color_primary_purple)
                    } else {
                        cell.arrowIconView.image = nil
                    }
                    
                    let tag = indexPath.section << 10 | indexPath.row
                    cell.openCloseGroupButton.tag = tag
                    cell.openCloseGroupButton.removeTarget(nil, action: nil, for: .allEvents)
                    cell.openCloseGroupButton.addTarget(self, action: #selector(openCloseGroupButtonAction(_:)), for: .touchUpInside)
                    cell.separatorInset = .zero
                    
                } else {
                    
                    cell.titleView.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    cell.titleView.textColor = UIColor(rgb: color_primary_purple)
                    cell.leftIconView.image = nil
                    cell.arrowIconView.image = nil
                    cell.openCloseGroupButton.removeTarget(nil, action: nil, for: .allEvents)
                    cell.separatorInset = .init(top: 0, left: 62, bottom: 0, right: 0)
                }
                
                outCell = cell
            }
        }
        
        return outCell
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    
    //MARK: Actions
    
    override func onBottomButtonPressed() {
        self.dismiss()
    }
    
    @objc func openCloseGroupButtonAction(_ sender: Any) {
        let button = sender as! UIButton
        let indexPath = IndexPath(row: button.tag & 0x3FF, section: button.tag >> 10)
        
        let opened = cellOpeningStatuses[indexPath.section]
        cellOpeningStatuses[indexPath.section] = !opened
        
        generateData()
        tableView.beginUpdates()
        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        tableView.endUpdates()
    }
}
