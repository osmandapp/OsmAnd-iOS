//
//  TravelGuidesContentsViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelGuidesContentsViewController : OABaseNavbarViewController {
    
    var article: TravelArticle? = nil
    var selectedLang: String = ""
    var items: TravelContentItem? = nil
    var selectedSubitemIndex: Int? = nil
    
    weak var delegate: TravelArticleDialogProtocol?
    
    func setupWith(article: TravelArticle, selectedLang: String, contentItems: TravelContentItem, selectedSubitemIndex: Int?) {
        self.article = article
        self.selectedLang = selectedLang
        self.items = contentItems
        self.selectedSubitemIndex = selectedSubitemIndex
    }
    
    //MARK: Data
    
    override func generateData() {
        tableData.clearAllData()
        
        var displayingItems = items!.subItems
        if let selectedSubitemIndex {
            displayingItems = items!.subItems[selectedSubitemIndex].subItems
        }

        let section = tableData.createNewSection()
        for item in displayingItems {
            let headerRow = section.createNewRow()
            headerRow.cellType = OAButtonTableViewCell.getIdentifier()
            headerRow.title = item.name
            headerRow.setObj(item.link!, forKey: "link")
            if item.parent != nil && item.parent!.link != nil {
                headerRow.setObj(item.parent!.link!.substring(from: 1), forKey: "sublink")
            } else {
                headerRow.setObj(item.link!.substring(from: 1), forKey: "sublink")
            }
            
            if item.subItems.count > 0 {
                headerRow.setObj(true, forKey: "hasSubitems")
            }
        }
    }
    
    
    //MARK: Base UI setup
    
    override func getTitle() -> String! {
        if let selectedSubitemIndex {
            return items!.subItems[selectedSubitemIndex].name
        } else {
            return localizedString("shared_string_contents")
        }
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        if selectedSubitemIndex != nil {
            return localizedString("shared_string_contents")
        } else {
            return localizedString("shared_string_close")
        }
    }
    
    override func forceShowShevron() -> Bool {
        return selectedSubitemIndex != nil
    }
    
    override func onLeftNavbarButtonPressed() {
        if selectedSubitemIndex != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
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
                cell?.descriptionVisibility(false)
                cell?.buttonVisibility(true)
                cell?.leftIconVisibility(true)
                cell?.leftEditButtonVisibility(false)
                cell?.leftIconView.contentMode = .center
                
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
                cell.leftIconView.image = UIImage.templateImageNamed("ic_custom_sample")
                cell.leftIconView.tintColor = UIColor.iconColorDefault
                
                cell.button.setTitle(nil, for: .normal)
                cell.button.tag = indexPath.row
                cell.button.removeTarget(nil, action: nil, for: .allEvents)
                cell.button.addTarget(self, action: #selector(onShevronClicked(_:)), for: .touchUpInside)
                
                let hasSubitems = item.bool(forKey: "hasSubitems")
                if hasSubitems {
                    cell.button.setImage(UIImage.templateImageNamed("ic_custom_arrow_right"), for: .normal)
                    cell.button.tintColor = UIColor.iconColorDefault
                }
            }
            outCell = cell
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        let hasSubitems = item.bool(forKey: "hasSubitems")
        if hasSubitems {
            let vc = TravelGuidesContentsViewController()
            vc.setupWith(article: article!, selectedLang: selectedLang, contentItems: items!, selectedSubitemIndex: indexPath.row)
            vc.delegate = delegate
            self.navigationController?.pushViewController(vc, animated: true)
        } else if let link = item.string(forKey: "link") {
            if let sublink = item.string(forKey: "sublink") {
                if delegate != nil {
                    delegate!.moveToAnchor(link: link, title: sublink)
                }
            }
            self.dismiss()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
    
    
    //MARK: Actions
    
    @objc func onShevronClicked(_ sender: Any) {
        let button = sender as! UIButton
        let indexPath = IndexPath(row: button.tag, section: 0)
        onRowSelected(indexPath)
    }
}
