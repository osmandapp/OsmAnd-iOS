//
//  TravelGuidesNavigationViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 28.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

class TravelGuidesNavigationViewController : OABaseNavbarViewController {
    
    var article: TravelArticle?
    var selectedLang: String = ""
    var navigationMap: [TravelSearchResult : [TravelSearchResult]] = [:]
    var regionsNames: [String] = []
    var selectedItem: TravelSearchResult?
    
    weak var delegate: TravelArticleDialogProtocol?
    
    func setupWith(article: TravelArticle, selectedLang: String, navigationMap: [TravelSearchResult : [TravelSearchResult]], regionsNames: [String], selectedItem: TravelSearchResult?) {
        self.article = article
        self.selectedLang = selectedLang
        
        if selectedItem != nil {
            self.navigationMap = navigationMap
            self.regionsNames = regionsNames
            self.selectedItem = selectedItem
        } else {
            self.navigationMap = [:]
            self.regionsNames = []
        }
    }
    
    
    //MARK: Data
    
    func fetchData() {
        if selectedItem != nil {
            self.generateData()
            self.tableView.reloadData()
            
        } else if navigationMap.count == 0  {
            
            self.view.addSpinner(inCenterOfCurrentView: true)
            DispatchQueue.global(qos: .default).async {
                self.navigationMap = TravelObfHelper.shared.getNavigationMap(article: self.article!)
                DispatchQueue.main.async {
                    self.regionsNames = self.getRegionNames()
                    self.generateData()
                    self.tableView.reloadData()
                    self.view.removeSpinner()
                }
            }
        }
    }
    
    override func generateData() {
        tableData.clearAllData()
        guard navigationMap.count > 0 else { return }
        
        if selectedItem == nil {
            
            let regionNames = getRegionNames()
            for i in 0..<regionNames.count {
                
                let section = tableData.createNewSection()
                let headerItem = getHeaderItemByTitle(title: regionNames[i])
                
                let row = section.createNewRow()
                row.cellType = OAButtonTableViewCell.getIdentifier()
                row.title = headerItem!.articleId.title
                row.iconName = "ic_custom_book_info"
                row.setObj(headerItem!.articleId, forKey: "article")
                
                let subItems = navigationMap[headerItem!]!
                if subItems.count > 0 {
                    row.setObj(true, forKey: "hasSubitems")
                    row.setObj(headerItem, forKey: "item")
                }
            }
            
        } else {
            let section = tableData.createNewSection()
            let subItems = navigationMap[selectedItem!]!
            for subheaderItem in subItems {
                let row = section.createNewRow()
                row.cellType = OAButtonTableViewCell.getIdentifier()
                row.title = subheaderItem.articleId.title
                row.iconName = "ic_custom_file_info"
                row.setObj(false, forKey: "isHeader")
                row.setObj(subheaderItem.articleId, forKey: "article")
            }
        }
    }
    
    func getRegionNames() -> [String] {
        var names = [String]()
        if let parts = article!.aggregatedPartOf {
            names = parts
                .split(separator: ",")
                .reversed()
                .map({ substring in
                    return String(substring)
                })
            if navigationMap.count > names.count && article!.title != nil {
                names.append(article!.title!)
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchData()
    }
    
    override func getTitle() -> String! {
        if let selectedItem {
            return selectedItem.articleId.title
        } else {
            return localizedString("shared_string_navigation")
        }
    }
    
    override func forceShowShevron() -> Bool {
        return selectedItem != nil
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        if let selectedItem {
            return localizedString("shared_string_navigation")
        } else {
            return localizedString("shared_string_close")
        }
    }
    
    override func onLeftNavbarButtonPressed() {
        if let selectedItem {
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
                cell?.separatorInset = .zero
                cell?.descriptionVisibility(false)
                cell?.buttonVisibility(true)
                cell?.leftIconVisibility(true)
                cell?.leftEditButtonVisibility(false)
                cell?.leftIconView.contentMode = .center
            }
            if let cell {
                cell.titleLabel.text = item.title
                cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
                cell.leftIconView.image = UIImage.templateImageNamed(item.iconName)
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

                outCell = cell
            }
        }
        
        return outCell
    }
    
    override func onRowSelected(_ indexPath: IndexPath!) {
        let item = tableData.item(for: indexPath)
        if let articleId = item.obj(forKey: "article") as? TravelArticleIdentifier {
            let hasSubitems = item.bool(forKey: "hasSubitems")
            if hasSubitems {
                if let item = item.obj(forKey: "item") as? TravelSearchResult {
                    let vc = TravelGuidesNavigationViewController()
                    vc.setupWith(article: article!, selectedLang: selectedLang, navigationMap: navigationMap, regionsNames: [], selectedItem: item)
                    vc.delegate = delegate
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } else {
                if delegate != nil {
                    delegate!.openArticleByTitle(title: articleId.title!, selectedLang: selectedLang)
                }
                self.dismiss()
            }
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

