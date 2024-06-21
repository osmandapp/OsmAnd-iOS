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
    private var tags: [NSDictionary]
    private let keysToSections: [String: String] = ["reg_name": "route_name_regional", "loc_name": "route_name_local", "name:": "shared_string_name", "nat_name": "route_name_national", "int_name": "route_name_international", "short_name": "route_name_short", "official_name": "route_name_official", "old_name": "route_name_old", "alt_name": "route_name_alt"]
    
    init(tags: [NSDictionary], detailsType: DetailsType) {
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
        for (key, header) in keysToSections {
            if key == "name:" {
                processNameTagsSection(header: header)
            } else {
                processTagsSectionForKey(key: key, header: header)
            }
        }
    }
    
    private func processNameTagsSection(header: String) {
        let nameTags = tags.filter { ($0["key"] as? String)?.hasPrefix("name:") ?? false }
        if !nameTags.isEmpty {
            createSectionWithTags(filteredTags: nameTags, header: header, key: "country_loc_name")
        }
    }
    
    private func processTagsSectionForKey(key: String, header: String) {
        let filteredTags = tags.filter { $0["key"] as? String == key }
        if !filteredTags.isEmpty {
            createSectionWithTags(filteredTags: filteredTags, header: header, key: key)
        }
    }
    
    private func createSectionWithTags(filteredTags: [NSDictionary], header: String, key: String) {
        let section = tableData.createNewSection()
        section.headerText = localizedString(header)
        for tagDict in filteredTags {
            let row = section.createNewRow()
            row.cellType = OASimpleTableViewCell.getIdentifier()
            row.key = key
            row.title = tagDict["value"] as? String ?? ""
            row.descr = tagDict["localizedTitle"] as? String ?? ""
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
