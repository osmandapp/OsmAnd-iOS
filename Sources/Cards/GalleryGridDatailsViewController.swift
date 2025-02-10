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
        tableView.register(ExpandableTextViewTableCell.self, forCellReuseIdentifier: ExpandableTextViewTableCell.reuseIdentifier)
    }
    
    override func getTitle() -> String {
        titleString
    }
    
    override func getLeftNavbarButtonTitle() -> String {
        localizedString("shared_string_close")
    }
    
    override func hideFirstHeader() -> Bool {
        true
    }
    
    // MARK: Table data
    
    override func generateData() {
        let section = tableData.createNewSection()
        
        if let description = metadata?.description {
            let descriptionRow = section.createNewRow()
            descriptionRow.key = "descriptionrKey"
            descriptionRow.cellType = ExpandableTextViewTableCell.reuseIdentifier
            descriptionRow.title = localizedString("shared_string_author")
            descriptionRow.descr = description
        }
        
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
            cell.titleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
            cell.valueLabel.text = item.descr
            if item.obj(forKey: "sourceLinkKey") != nil {
                cell.valueLabel.textColor = .textColorActive
            } else {
                cell.valueLabel.textColor = .textColorSecondary
            }
            cell.valueLabel.font = cell.titleLabel.font
            cell.accessibilityLabel = item.title
            cell.accessibilityValue = item.descr
            return cell
        }
        
        if item.cellType == ExpandableTextViewTableCell.reuseIdentifier {
            let cell = tableView.dequeueReusableCell(withIdentifier: ExpandableTextViewTableCell.reuseIdentifier, for: indexPath) as! ExpandableTextViewTableCell
            cell.data = item.descr
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

extension ExpandableTextViewTableCell: ExpandableTextViewDelegate {
    
    func didExpandTextView(_ textView: ExpandableTextView) {
        updateCell()
    }

    func didCollapseTextView(_ textView: ExpandableTextView) {
        updateCell()
    }

    func expandableTextViewUpdateHeight(_ textView: ExpandableTextView) {
        updateCell()
    }
}

final class ExpandableTextViewTableCell: UITableViewCell {
    
    var data: String? {
        didSet {
            notesTextView.text = data
        }
    }
    
    private lazy var notesTextView: ExpandableTextView = {
        let v = ExpandableTextView()
        v.font = UIFont.preferredFont(forTextStyle: .subheadline)
        v.textColor = .textColorPrimary
        v.backgroundColor = .clear
        v.moreText = localizedString("show_more")
        v.lessText = localizedString("shared_string_show_less")
        v.delegateExppanable = self
        v.numberOfLines = 2
        v.textReplacementType = .character
        v.linkPosition = .space
        v.isEditable = false
        v.dataDetectorTypes = [.phoneNumber, .link]
        v.tintColor = .textColorActive
        return v
    }()

    required override init(style: UITableViewCell.CellStyle,
                           reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
        contentView.backgroundColor = .groupBg
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        notesTextView.removeFromSuperview()
        contentView.addSubview(notesTextView)
        notesTextView.translatesAutoresizingMaskIntoConstraints = false
        notesTextView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
        notesTextView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
        notesTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        notesTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
    }

    private func updateCell() {
        guard let tableView else { return }
        
        UIView.performWithoutAnimation {
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

private extension UITableViewCell {
    /// Search up the view hierarchy of the table view cell to find the containing table view
    var tableView: UITableView? {
        var table: UIView? = superview
        while !(table is UITableView) && table != nil {
            table = table?.superview
        }
        return table as? UITableView
    }
}
