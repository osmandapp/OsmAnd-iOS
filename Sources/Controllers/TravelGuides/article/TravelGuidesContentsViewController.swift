//
//  TravelGuidesContentsViewController.swift
//  OsmAnd Maps
//
//  Created by nnngrach on 25.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

import UIKit

final class TravelGuidesContentsViewController : OABaseNavbarViewController {
    
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
        
        guard let items else { return }
        var displayingItems = items.subItems
        if let selectedSubitemIndex {
            displayingItems = items.subItems[selectedSubitemIndex].subItems
        }

        let section = tableData.createNewSection()
        for item in displayingItems {
            let row = section.createNewRow()
            row.cellType = OAButtonTableViewCell.getIdentifier()
            row.title = item.name
            if let itemLink = item.link {
                row.setObj(itemLink, forKey: "link")
                
                if let parent = item.parent, let link = parent.link {
                    row.setObj(link.substring(from: 1), forKey: "sublink")
                } else {
                    row.setObj(itemLink.substring(from: 1), forKey: "sublink")
                }
                
                row.iconName = selectedSubitemIndex != nil ? "ic_custom_file_info" : "ic_custom_book_info"
                
                if !item.subItems.isEmpty {
                    row.setObj(true, forKey: "hasSubitems")
                }
            }
        }
    }
    
    
    //MARK: Base UI setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if selectedSubitemIndex != nil {
            navigationItem.leftItemsSupplementBackButton = true
            navigationController?.navigationBar.topItem?.backButtonTitle = localizedString("shared_string_contents")
            navigationItem.setLeftBarButton(nil, animated: false)
        }
    }
    
    override func getTitle() -> String! {
        if let selectedSubitemIndex {
            if let items {
                return items.subItems[selectedSubitemIndex].name
            }
        }
        return localizedString("shared_string_contents")
    }
    
    override func getLeftNavbarButtonTitle() -> String! {
        if selectedSubitemIndex == nil {
            return localizedString("shared_string_close")
        } else {
            return nil
        }
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
                
                if let iconName = item.iconName {
                    cell.leftIconView.image = UIImage(named:iconName)
                }
                cell.leftIconView.tintColor = UIColor.iconColorDefault
                
                cell.button.setTitle(nil, for: .normal)
                cell.button.tag = indexPath.row
                cell.button.removeTarget(nil, action: nil, for: .allEvents)
                cell.button.addTarget(self, action: #selector(onShevronClicked(_:)), for: .touchUpInside)
                
                let hasSubitems = item.bool(forKey: "hasSubitems")
                if hasSubitems {
                    cell.button.setImage(UIImage(named: "ic_custom_arrow_right"), for: .normal)
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
            navigationController?.pushViewController(vc, animated: true)
        } else if let link = item.string(forKey: "link") {
            if let sublink = item.string(forKey: "sublink"), let delegate {
                delegate.moveToAnchor(link: link, title: sublink)
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
            let indexPath = IndexPath(row: button.tag, section: 0)
            onRowSelected(indexPath)
        }
    }
}
