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
    
    weak var delegate: TravelArticleDialogProtocol?
    
    required init?(coder: NSCoder) {
        self.article = TravelArticle()
        self.selectedLang = ""
        self.items = TravelContentItem(name: "", link: nil)
        self.cellOpeningStatuses = []
        super.init(coder: coder)
    }
    
    init(article: TravelArticle, selectedLang: String) {
        self.article = article
        self.selectedLang = selectedLang
        self.items = TravelJsonParser.parseJsonContents(jsonText: article.contentsJson ?? "")
        
        self.cellOpeningStatuses = []
        for _ in self.items.subItems {
            self.cellOpeningStatuses.append(false)
        }
        
        super.init()
    }
    
    
    //MARK: Data
    
    override func generateData() {
        tableData.clearAllData()

        for i in 0..<items.subItems.count {
            
            let section = tableData.createNewSection()
            let opened = cellOpeningStatuses[i]
            
            let headerItem = items.subItems[i]
            let headerRow = section.createNewRow()
            headerRow.cellType = OAButtonTableViewCell.getIdentifier()
            headerRow.title = headerItem.name
            headerRow.setObj(headerItem.link!, forKey: "link")
            headerRow.iconName = "ic_action_route_first_intermediate"
            headerRow.setObj(true, forKey: "isHeader")
            if headerItem.subItems.count > 0 {
                let arrowIconName = opened ? "ic_custom_arrow_up" : "ic_custom_arrow_down"
                headerRow.setObj(arrowIconName, forKey: "rightIconName")
            }
            
            if opened && headerItem.subItems.count > 0 {
                for subheaderItem in headerItem.subItems {
                    let subheaderRow = section.createNewRow()
                    subheaderRow.cellType = OAButtonTableViewCell.getIdentifier()
                    subheaderRow.title = subheaderItem.name
                    subheaderRow.setObj(subheaderItem.link!, forKey: "link")
                    subheaderRow.setObj(false, forKey: "isHeader")
                    subheaderRow.setObj("subheaderItem.articleId", forKey: "article")
                }
            }
        }
    }
    
    
    //MARK: Base UI setup
    
    override func getTitle() -> String! {
        return localizedString("shared_string_contents")
    }
    
    override func getBottomButtonTitle() -> String! {
        return localizedString("shared_string_close")
    }
    
    
    //MARK: TableView
    
    override func getRow(_ indexPath: IndexPath!) -> UITableViewCell! {
        let item = tableData.item(for: indexPath)
        var outCell: UITableViewCell? = nil
        
        if item.cellType == OAButtonTableViewCell.getIdentifier() {
            var cell = tableView.dequeueReusableCell(withIdentifier: OAButtonTableViewCell.getIdentifier()) as? OAButtonTableViewCell
            if cell == nil {
                let nib = Bundle.main.loadNibNamed(OAButtonTableViewCell.getIdentifier(), owner: self, options: nil)
                cell = nib?.first as? OAButtonTableViewCell
                cell?.separatorInset = .zero
                cell?.descriptionVisibility(false)
                cell?.buttonVisibility(true)
                cell?.leftIconVisibility(true)
                cell?.leftEditButtonVisibility(false)
                cell?.leftIconView.contentMode = .center
                
            }
            if let cell {
                cell.titleLabel.text = item.title
                
                let isHeader = item.bool(forKey: "isHeader")
                
                if isHeader {
                    cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
                    cell.titleLabel.textColor = UIColor(rgb: color_primary_purple)
                    
                    if let leftIconName = item.iconName {
                        cell.leftIconView.image = UIImage.templateImageNamed(leftIconName)
                        cell.leftIconView.tintColor = UIColor(rgb: color_primary_purple)
                    } else {
                        cell.leftIconView.image = nil
                    }
                    
                    cell.button.setTitle(nil, for: .normal)
                    if let rightIconName = item.string(forKey: "rightIconName") {
                        cell.button.setImage(UIImage.templateImageNamed(rightIconName), for: .normal)
                        cell.button.tintColor = UIColor(rgb: color_primary_purple)
                    } else {
                        cell.button.setImage(nil, for: .normal)
                    }
                    
                    let tag = indexPath.section << 10 | indexPath.row
                    cell.button.tag = tag
                    cell.button.removeTarget(nil, action: nil, for: .allEvents)
                    cell.button.addTarget(self, action: #selector(openCloseGroupButtonAction(_:)), for: .touchUpInside)
                    cell.separatorInset = .zero
                    
                } else {
                    
                    cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
                    cell.titleLabel.textColor = UIColor(rgb: color_primary_purple)
                    cell.leftIconView.image = nil
                    cell.button.setTitle(nil, for: .normal)
                    cell.button.setImage(nil, for: .normal)
                    cell.button.removeTarget(nil, action: nil, for: .allEvents)
                    cell.separatorInset = .init(top: 0, left: OAUtilities.getLeftMargin(), bottom: 0, right: 0)
                }
                
                outCell = cell
            }
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if let link = item.string(forKey: "link") {
            if delegate != nil {
                delegate?.moveToAnchor(link: link, title: selectedLang)
            }
        }
        self.dismiss()
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
