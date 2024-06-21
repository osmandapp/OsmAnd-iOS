//
//  NameTagsDetailsViewController.swift
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 20.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

import UIKit

@objc enum DetailsType: Int {
    case routeNameTags, poiNameTags
}

@objc(OANameTagsDetailsViewController)
@objcMembers
final class NameTagsDetailsViewController: OABaseNavbarViewController {
    private var detailsType: DetailsType
    private var tags: [String: [String: Any]]
    
    init(tags: [String: [String: Any]], detailsType: DetailsType) {
        self.tags = tags
        self.detailsType = detailsType
        super.init(nibName: "OABaseNavbarViewController", bundle: nil)
        initTableData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func registerCells() {
        addCell(OASimpleTableViewCell.reuseIdentifier)
    }
    
    override func getTitle() -> String? {
        localizedString("shared_string_name")
    }
    
    override func getLeftNavbarButtonTitle() -> String? {
        localizedString("shared_string_cancel")
    }
    
    override func generateData() {
        tableData.clearAllData()
        
        if let regionalName = tags["reg_name"] {
            let regSection = tableData.createNewSection()
            regSection.headerText = localizedString("route_name_regional")
            let row = regSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "reg_name"
            row.title = regionalName["value"] as? String ?? ""
            row.descr = regionalName["localizedTitle"] as? String ?? ""
        }
        if let localName = tags["loc_name"] {
            let localSection = tableData.createNewSection()
            localSection.headerText = localizedString("route_name_local")
            let row = localSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "loc_name"
            row.title = localName["value"] as? String ?? ""
            row.descr = localName["localizedTitle"] as? String ?? ""
        }
        let filteredTags = tags.filter { $0.key.hasPrefix("name:") }
        if !filteredTags.isEmpty {
            let section = tableData.createNewSection()
            section.headerText = localizedString("shared_string_name")
            filteredTags.forEach { _, valueDict in
                let title = valueDict["value"] as? String ?? ""
                let localizedTitle = valueDict["localizedTitle"] as? String ?? ""
                let row = section.createNewRow()
                row.cellType = OASimpleTableViewCell.getIdentifier()
                row.key = "country_loc_name"
                row.title = title
                row.descr = localizedTitle
            }
        }
        if let natName = tags["nat_name"] {
            let natSection = tableData.createNewSection()
            natSection.headerText = localizedString("route_name_national")
            let row = natSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "nat_name"
            row.title = natName["value"] as? String ?? ""
            row.descr = natName["localizedTitle"] as? String ?? ""
        }
        if let intName = tags["int_name"] {
            let intSection = tableData.createNewSection()
            intSection.headerText = localizedString("route_name_international")
            let row = intSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "int_name"
            row.title = intName["value"] as? String ?? ""
            row.descr = intName["localizedTitle"] as? String ?? ""
        }
        if let shortName = tags["short_name"] {
            let shortSection = tableData.createNewSection()
            shortSection.headerText = localizedString("route_name_short")
            let row = shortSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "short_name"
            row.title = shortName["value"] as? String ?? ""
            row.descr = shortName["localizedTitle"] as? String ?? ""
        }
        if let officialName = tags["official_name"] {
            let officialSection = tableData.createNewSection()
            officialSection.headerText = localizedString("route_name_official")
            let row = officialSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "official_name"
            row.title = officialName["value"] as? String ?? ""
            row.descr = officialName["localizedTitle"] as? String ?? ""
        }
        if let oldName = tags["old_name"] {
            let oldSection = tableData.createNewSection()
            oldSection.headerText = localizedString("route_name_old")
            let row = oldSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "old_name"
            row.title = oldName["value"] as? String ?? ""
            row.descr = oldName["localizedTitle"] as? String ?? ""
        }
        if let altName = tags["alt_name"] {
            let altSection = tableData.createNewSection()
            altSection.headerText = localizedString("route_name_alt")
            let row = altSection.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = "alt_name"
            row.title = altName["value"] as? String ?? ""
            row.descr = altName["localizedTitle"] as? String ?? ""
        }
    }
    
    override func getRow(_ indexPath: IndexPath?) -> UITableViewCell? {
        guard let indexPath else { return nil }
        let item = tableData.item(for: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: OASimpleTableViewCell.getIdentifier(), for: indexPath) as! OASimpleTableViewCell
        cell.selectionStyle = .none
        cell.leftIconVisibility(false)
        cell.descriptionVisibility(!(item.descr?.isEmpty ?? true))
        cell.titleLabel.text = item.title
        cell.descriptionLabel.text = item.descr
        return cell
    }
}
