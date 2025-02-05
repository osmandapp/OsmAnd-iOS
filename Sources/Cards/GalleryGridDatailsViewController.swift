//
//  GalleryGridDatailsViewController.swift
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 04.02.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

final class GalleryGridDatailsViewController: OABaseNavbarViewController {
    var titleString: String = ""
    var card: ImageCard!
    var metadata: Metadata?
    
    override func registerCells() {
        addCell(OAValueTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String {
        titleString
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    // MARK: Table data
    
    override func generateData() {
        let section = tableData.createNewSection()
        
        if let date = metadata?.date {
            var formattedDate = WikiAlgorithms.formatWikiDate(date)
            if formattedDate.isEmpty {
                formattedDate = date
            }
            if !formattedDate.isEmpty {
                let dateRow = section.createNewRow()
                dateRow.key = "dateKey"
                dateRow.cellType = OAValueTableViewCell.reuseIdentifier
                dateRow.title = localizedString("shared_string_date")
                dateRow.descr = formattedDate
            }
        }
        if let author = metadata?.author, !author.isEmpty {
            let authorRow = section.createNewRow()
            authorRow.key = "authorKey"
            authorRow.cellType = OAValueTableViewCell.reuseIdentifier
            authorRow.title = localizedString("shared_string_author")
            authorRow.descr = author
        }
        
        if let license = metadata?.license, !license.isEmpty {
            let licenseRow = section.createNewRow()
            licenseRow.key = "licenseKey"
            licenseRow.cellType = OAValueTableViewCell.reuseIdentifier
            licenseRow.title = localizedString("shared_string_license")
            licenseRow.descr = license
        }
        
        let sourceRow = section.createNewRow()
        sourceRow.key = "sourceKey"
        sourceRow.cellType = OAValueTableViewCell.reuseIdentifier
        sourceRow.title = localizedString("shared_string_source")
        sourceRow.descr = getSourceTypeName(card: card)
        
        let link: String
        if let wikiImageCard = card as? WikiImageCard {
            link = wikiImageCard.wikiImage?.getUrlWithCommonAttributions() ?? ""
        } else {
            link = !card.imageHiresUrl.isEmpty ? card.imageHiresUrl : card.imageUrl
        }
        
        sourceRow.setObj(link, forKey: "sourceLinkKey")
    }
    
    override func getRow(_ indexPath: IndexPath) -> UITableViewCell? {
        let item = tableData.item(for: indexPath)
        if item.cellType == OAValueTableViewCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: OAValueTableViewCell.reuseIdentifier, for: indexPath) as! OAValueTableViewCell
            cell.descriptionVisibility(false)
            cell.leftIconView.isHidden = true
            cell.titleLabel.text = item.title
            cell.valueLabel.text = item.descr
            if item.obj(forKey: "sourceLinkKey") != nil {
                cell.valueLabel.textColor = .textColorActive
            } else {
                cell.valueLabel.textColor = .textColorSecondary
            }
            cell.accessibilityLabel = item.title
            cell.accessibilityValue = item.descr
            return cell
        }
        return nil
    }
    
    override func onRowSelected(_ indexPath: IndexPath) {
        let item = tableData.item(for: indexPath)
        if let link = item.obj(forKey: "sourceLinkKey") as? String {
            guard let viewController = OAWebViewController(urlAndTitle: link, title: titleString) else { return }
            dismiss()
            OARootViewController.instance()?.mapPanel.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    private func getSourceTypeName(card: ImageCard) -> String {
        card is WikiImageCard ? localizedString("wikimedia") : ""
    }
}
