//
//  TravelGuidesNavigationViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 28.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelGuidesNavigationViewController : OABaseButtonsViewController {
    
    var article: TravelArticle
    var selectedLang: String
    var cellOpeningStatuses: [Bool]
    var navigationMap: [TravelSearchResult : [TravelSearchResult]]
    
    required init?(coder: NSCoder) {
        self.article = TravelArticle()
        self.selectedLang = ""
        self.navigationMap = [:]
        self.cellOpeningStatuses = []
        super.init(coder: coder)
    }
    
    init(article: TravelArticle, selectedLang: String) {
        self.article = article
        self.selectedLang = selectedLang
        self.navigationMap = [:]
        self.cellOpeningStatuses = []
        super.init()
    }
    
    
    //MARK: Data
    
    func fetchData() {
        self.view.addSpinner()
        DispatchQueue.global(qos: .default).async {
            self.navigationMap = TravelObfHelper.shared.getNavigationMap(article: self.article)
            DispatchQueue.main.async {
                let count = self.navigationMap.count
                self.cellOpeningStatuses = Array(repeating: false, count: count)
                self.cellOpeningStatuses[count - 1] = true
                self.generateData()
                self.tableView.reloadData()
                self.view.removeSpinner()
            }
        }
    }
    
    override func generateData() {
        tableData.clearAllData()
        guard navigationMap.count > 0 else { return }
        
        let regionNames = getRegionNames()
        for i in 0..<regionNames.count {
            
            let section = tableData.createNewSection()
            let opened = cellOpeningStatuses[i]
            let headerItem = getHeaderItemByTitle(title: regionNames[i])
            
            let headerRow = section.createNewRow()
            headerRow.cellType = OASelectionCollapsableCell.getIdentifier()
            headerRow.title = headerItem!.articleId.title
            headerRow.iconName = "ic_action_route_first_intermediate"
            headerRow.setObj(true, forKey: "isHeader")
            
            let subItems = navigationMap[headerItem!]!
            if subItems.count > 0 {
                let arrowIconName = opened ? "ic_custom_arrow_up" : "ic_custom_arrow_down"
                headerRow.setObj(arrowIconName, forKey: "rightIconName")
            }
            
            if opened && subItems.count > 0 {
                for subheaderItem in subItems {
                    let subheaderRow = section.createNewRow()
                    subheaderRow.cellType = OASelectionCollapsableCell.getIdentifier()
                    subheaderRow.title = subheaderItem.articleId.title
                    subheaderRow.setObj(false, forKey: "isHeader")
                }
            }
        }
    }
    
    func getRegionNames() -> [String] {
        var names = [String]()
        if let parts = article.aggregatedPartOf {
            names = parts
                .split(separator: ",")
                .reversed()
                .map({ substring in
                    return String(substring)
                })
            if navigationMap.count > names.count && article.title != nil {
                names.append(article.title!)
            }
        }
        return names
    }
    
    func getHeaderItemByTitle(title: String) -> TravelSearchResult? {
        var headerItem: TravelSearchResult? = nil
        for item in navigationMap.keys {
            let navItem = item
            if navItem.articleId.title == title {
                headerItem = item
                break
            }
        }
        return headerItem
    }
    
    
    //MARK: Base UI setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchData()
    }
    
    override func getTitle() -> String! {
        return localizedString("shared_string_navigation")
    }
    
    override func getBottomButtonTitle() -> String! {
        return localizedString("shared_string_close")
    }
    
    
    //MARK: TableView
    
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
                    cell.separatorInset = .init(top: 0, left: OAUtilities.getLeftMargin() + 20, bottom: 0, right: 0)
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

