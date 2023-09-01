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
    
    weak var delegate: TravelArticleDialogProtocol?
    
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
                if count > 0 {
                    self.cellOpeningStatuses = Array(repeating: false, count: count)
                    self.cellOpeningStatuses[count - 1] = true
                }
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
            headerRow.cellType = OAButtonTableViewCell.getIdentifier()
            headerRow.title = headerItem!.articleId.title
            headerRow.iconName = "ic_action_route_first_intermediate"
            headerRow.setObj(true, forKey: "isHeader")
            headerRow.setObj(headerItem!.articleId, forKey: "article")
            
            let subItems = navigationMap[headerItem!]!
            if subItems.count > 0 {
                let arrowIconName = opened ? "ic_custom_arrow_up" : "ic_custom_arrow_down"
                headerRow.setObj(arrowIconName, forKey: "rightIconName")
            }
            
            if opened && subItems.count > 0 {
                for subheaderItem in subItems {
                    let subheaderRow = section.createNewRow()
                    subheaderRow.cellType = OAButtonTableViewCell.getIdentifier()
                    subheaderRow.title = subheaderItem.articleId.title
                    subheaderRow.setObj(false, forKey: "isHeader")
                    subheaderRow.setObj(subheaderItem.articleId, forKey: "article")
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
        if let articleId = item.obj(forKey: "article") as? TravelArticleIdentifier {
            if delegate != nil {
                delegate!.openArticleByTitle(title: articleId.title!, selectedLang: selectedLang)
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

