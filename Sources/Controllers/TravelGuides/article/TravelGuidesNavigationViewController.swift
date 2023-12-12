//
//  TravelGuidesNavigationViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 28.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

final class TravelGuidesNavigationViewController : OABaseNavbarViewController {
    
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
            self.navigationMap = navigationMap
            self.regionsNames = []
        }
    }
    
    
    //MARK: Data
    
    func fetchData() {
        if selectedItem != nil {
            generateData()
            tableView.reloadData()
            
        } else if navigationMap.isEmpty  {
            
            guard let article else { return }
            view.addSpinner(inCenterOfCurrentView: true)
            DispatchQueue.global(qos: .default).async {
                self.navigationMap = TravelObfHelper.shared.getNavigationMap(article: article)
                DispatchQueue.main.async {
                    if self.navigationMap.isEmpty {
                        OAUtilities.showToast(nil, details: localizedString("travel_guides_no_file_error"), duration: 4, in: self.view)
                    } else {
                        self.regionsNames = self.getRegionNames()
                        self.generateData()
                        self.tableView.reloadData()
                    }
                    self.view.removeSpinner()
                }
            }
        } else {
            self.regionsNames = self.getRegionNames()
            self.generateData()
            self.tableView.reloadData()
        }
    }
    
    override func generateData() {
        tableData.clearAllData()
        guard !navigationMap.isEmpty else { return }
        
        if let selectedItem {
            let section = tableData.createNewSection()
            if let subItems = navigationMap[selectedItem] {
                for subheaderItem in subItems {
                    let row = section.createNewRow()
                    row.cellType = OAButtonTableViewCell.getIdentifier()
                    row.title = subheaderItem.articleId.title
                    row.iconName = "ic_custom_file_info"
                    row.setObj(false, forKey: "isHeader")
                    row.setObj(subheaderItem.articleId, forKey: "article")
                }
            }
            
        } else {
            
            let regionNames = getRegionNames()
            for i in 0..<regionNames.count {
                
                let section = tableData.createNewSection()
                if let headerItem = getHeaderItemByTitle(title: regionNames[i]) {
                    
                    let row = section.createNewRow()
                    row.cellType = OAButtonTableViewCell.getIdentifier()
                    row.title = headerItem.articleId.title
                    row.iconName = "ic_custom_book_info"
                    row.setObj(headerItem.articleId, forKey: "article")
                    row.setObj(i, forKey: "index")
                    
                    if let subItems = navigationMap[headerItem] {
                        if !subItems.isEmpty {
                            row.setObj(true, forKey: "hasSubitems")
                            row.setObj(headerItem, forKey: "item")
                        }
                    }
                }
            }
        }
    }
    
    func getRegionNames() -> [String] {
        var names = [String]()
        if let article, let parts = article.aggregatedPartOf {
            names = parts
                .split(separator: ",")
                .reversed()
                .map { String($0) }
            
            if navigationMap.count > names.count {
                if let title = article.title {
                    names.append(title)
                }
            }
        }
        return names
    }
    
    func getHeaderItemByTitle(title: String) -> TravelSearchResult? {
        navigationMap.keys.first(where: { $0.articleId.title == title })
    }
    
    
    //MARK: Base UI setup
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedItem != nil {
            navigationItem.leftItemsSupplementBackButton = true
            navigationController?.navigationBar.topItem?.backButtonTitle = localizedString("shared_string_navigation")
            navigationItem.setLeftBarButton(nil, animated: false)
        }
    }
    
    override func getTitle() -> String! {
        if let selectedItem {
            return selectedItem.articleId.title
        } else {
            return localizedString("shared_string_navigation")
        }
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        if selectedItem == nil {
            return localizedString("shared_string_close")
        } else {
            return nil
        }
    }
    
    override func onLeftNavbarButtonPressed() {
        if selectedItem != nil {
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
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named:iconName)
                }
                cell.leftIconView.tintColor = UIColor.iconColorDefault
                
                cell.button.setTitle(nil, for: .normal)
                cell.button.removeTarget(nil, action: nil, for: .allEvents)
                cell.button.addTarget(self, action: #selector(onShevronClicked(_:)), for: .touchUpInside)
                if let index = item.obj(forKey: "index") as? Int {
                    cell.button.tag = index
                }
                
                let hasSubitems = item.bool(forKey: "hasSubitems")
                if hasSubitems {
                    cell.button.setImage(UIImage(named: "ic_custom_arrow_right"), for: .normal)
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
            if let delegate, let title = articleId.title {
                delegate.openArticleByTitle(title: title, newSelectedLang: selectedLang)
            }
            dismiss()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNormalMagnitude
    }
    
    
    //MARK: Actions
    
    @objc func onShevronClicked(_ sender: Any) {
        if let button = sender as? UIButton {
            let indexPath = IndexPath(row: 0, section: button.tag)
            let item = tableData.item(for: indexPath)
            if let articleId = item.obj(forKey: "article") as? TravelArticleIdentifier {
                let hasSubitems = item.bool(forKey: "hasSubitems")
                if hasSubitems {
                    if let item = item.obj(forKey: "item") as? TravelSearchResult {
                        if let article {
                            let vc = TravelGuidesNavigationViewController()
                            vc.setupWith(article: article, selectedLang: selectedLang, navigationMap: navigationMap, regionsNames: [], selectedItem: item)
                            vc.delegate = delegate
                            navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
    }
}

